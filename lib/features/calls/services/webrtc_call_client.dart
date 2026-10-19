import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'gemini_live_translator.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/utils/network_tracker.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

enum WebRtcCallState {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  closed,
}

enum CallNetworkQuality {
  good,
  fair,
  poor,
}

extension CallNetworkQualityX on CallNetworkQuality {
  String get label {
    switch (this) {
      case CallNetworkQuality.good:
        return 'Good';
      case CallNetworkQuality.fair:
        return 'Fair';
      case CallNetworkQuality.poor:
        return 'Poor';
    }
  }

  String get emoji {
    switch (this) {
      case CallNetworkQuality.good:
        return '🟢';
      case CallNetworkQuality.fair:
        return '🟡';
      case CallNetworkQuality.poor:
        return '🔴';
    }
  }
}

class WebRtcCallClient {
  final FirebaseFirestore? firestore;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  StreamSubscription? _callDocSubscription;
  StreamSubscription? _remoteCandidatesSubscription;

  final StreamController<WebRtcCallState> _stateController =
      StreamController<WebRtcCallState>.broadcast();
  final StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();

  final StreamController<CallNetworkQuality> _networkQualityController =
      StreamController<CallNetworkQuality>.broadcast();
  Stream<CallNetworkQuality> get networkQualityStream =>
      _networkQualityController.stream;
  CallNetworkQuality _currentNetworkQuality = CallNetworkQuality.good;
  CallNetworkQuality get currentNetworkQuality => _currentNetworkQuality;

  RTCDataChannel? _dataChannel;
  final StreamController<Uint8List> _remoteTranslatedAudioController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get remoteTranslatedAudioStream =>
      _remoteTranslatedAudioController.stream;

  Stream<WebRtcCallState> get stateStream => _stateController.stream;
  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;

  WebRtcCallState _currentState = WebRtcCallState.idle;
  WebRtcCallState get currentState => _currentState;

  bool _isCaller = false;
  String? _currentCallId;

  WebRtcCallClient({FirebaseFirestore? firestore})
      : firestore = firestore ?? _safeFirestore();

  static FirebaseFirestore? _safeFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _iceConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Dynamically updates ICE configuration from secure backend relay
  static Future<void> refreshIceServers() async {
    try {
      final idToken = await GeminiLiveTranslator.getAuthToken();
      final res = await http.get(
        Uri.parse(AppConfig.iceServersUrl),
        headers: {
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['iceServers'] is List) {
          _iceConfiguration = {
            'iceServers': data['iceServers'],
            'sdpSemantics': 'unified-plan',
          };
        }
      }
    } catch (e, st) {
      debugPrint('[WebRtcCallClient] fetchIceServers error: $e\n$st');
    }
  }

  /// Tunes the SDP for voice clarity, forward error correction, and packet loss resilience:
  /// - Enables Opus In-Band Forward Error Correction (FEC): useinbandfec=1
  /// - Enables Discontinuous Transmission (DTX) for bandwidth savings during silence: usedtx=1
  /// - Sets minptime=10 for lower latency voice framing
  static String tuneAudioSdp(String sdp) {
    if (sdp.isEmpty) return sdp;

    // 1. Find the Opus payload type (e.g. a=rtpmap:111 opus/48000/2)
    final opusRegex = RegExp(r'a=rtpmap:(\d+)\s+opus/48000/2', caseSensitive: false);
    final match = opusRegex.firstMatch(sdp);
    if (match == null) {
      return sdp;
    }

    final pt = match.group(1);
    if (pt == null || pt.isEmpty) return sdp;

    final fmtpRegex = RegExp('a=fmtp:$pt\\s+([^\r\n]*)', caseSensitive: false);
    final fmtpMatch = fmtpRegex.firstMatch(sdp);

    if (fmtpMatch != null) {
      final existingParams = fmtpMatch.group(1) ?? '';
      final paramMap = <String, String>{};

      for (final param in existingParams.split(';')) {
        final kv = param.trim().split('=');
        if (kv.isNotEmpty && kv[0].isNotEmpty) {
          paramMap[kv[0].toLowerCase()] = kv.length > 1 ? kv[1] : '';
        }
      }

      paramMap['useinbandfec'] = '1';
      paramMap['usedtx'] = '1';
      if (!paramMap.containsKey('maxaveragebitrate')) {
        paramMap['maxaveragebitrate'] = '32000';
      }
      if (!paramMap.containsKey('minptime')) {
        paramMap['minptime'] = '10';
      }

      final newParams = paramMap.entries
          .map((e) => e.value.isNotEmpty ? '${e.key}=${e.value}' : e.key)
          .join(';');

      return sdp.replaceRange(
        fmtpMatch.start,
        fmtpMatch.end,
        'a=fmtp:$pt $newParams',
      );
    } else {
      final rtpmapLine = match.group(0)!;
      final lineBreak = sdp.contains('\r\n') ? '\r\n' : '\n';
      return sdp.replaceFirst(
        rtpmapLine,
        '$rtpmapLine${lineBreak}a=fmtp:$pt minptime=10;useinbandfec=1;usedtx=1;maxaveragebitrate=32000',
      );
    }
  }

  Timer? _rtpStatsTimer;
  int _lastRtpBytesSent = 0;
  int _lastRtpBytesReceived = 0;
  int _lastPacketsLost = 0;
  int _lastPacketsReceived = 0;

  /// Sets maximum audio bitrate in bps on RTCRtpSender encodings via setParameters (B2)
  Future<void> setAudioBitrate(int bitrateBps) async {
    if (_peerConnection == null) return;
    try {
      final senders = await _peerConnection!.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'audio') {
          final params = sender.parameters;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            for (final encoding in params.encodings!) {
              encoding.maxBitrate = bitrateBps;
            }
            await sender.setParameters(params);
            debugPrint('[WebRtcCallClient] Set audio maxBitrate to $bitrateBps bps via RTCRtpSender');
          }
        }
      }
    } catch (e) {
      debugPrint('[WebRtcCallClient] setAudioBitrate note: $e');
    }
  }

  void _startRtpStatsTracking() {
    _stopRtpStatsTracking();
    _lastRtpBytesSent = 0;
    _lastRtpBytesReceived = 0;
    _lastPacketsLost = 0;
    _lastPacketsReceived = 0;

    _rtpStatsTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_peerConnection == null) return;
      try {
        final reports = await _peerConnection!.getStats();
        int totalSent = 0;
        int totalReceived = 0;
        int totalPacketsLost = 0;
        int totalPacketsReceived = 0;
        double lastRttSeconds = 0.0;
        double lastJitterSeconds = 0.0;

        for (final report in reports) {
          if (report.type == 'outbound-rtp') {
            final bs = report.values['bytesSent'];
            if (bs != null) {
              totalSent += int.tryParse(bs.toString()) ?? 0;
            }
          } else if (report.type == 'inbound-rtp') {
            final br = report.values['bytesReceived'];
            if (br != null) {
              totalReceived += int.tryParse(br.toString()) ?? 0;
            }
            final pl = report.values['packetsLost'];
            if (pl != null) {
              totalPacketsLost += int.tryParse(pl.toString()) ?? 0;
            }
            final pr = report.values['packetsReceived'];
            if (pr != null) {
              totalPacketsReceived += int.tryParse(pr.toString()) ?? 0;
            }
            final jit = report.values['jitter'];
            if (jit != null) {
              lastJitterSeconds = double.tryParse(jit.toString()) ?? 0.0;
            }
          } else if (report.type == 'candidate-pair' || report.type == 'remote-inbound-rtp') {
            final rtt = report.values['currentRoundTripTime'] ?? report.values['roundTripTime'];
            if (rtt != null) {
              lastRttSeconds = double.tryParse(rtt.toString()) ?? 0.0;
            }
          }
        }

        if (_lastRtpBytesSent == 0 && totalSent > 0) {
          _lastRtpBytesSent = totalSent;
        } else if (totalSent > _lastRtpBytesSent) {
          final delta = totalSent - _lastRtpBytesSent;
          NetworkTracker.recordBytesSent(delta);
          _lastRtpBytesSent = totalSent;
        }

        if (_lastRtpBytesReceived == 0 && totalReceived > 0) {
          _lastRtpBytesReceived = totalReceived;
        } else if (totalReceived > _lastRtpBytesReceived) {
          final delta = totalReceived - _lastRtpBytesReceived;
          NetworkTracker.recordBytesReceived(delta);
          _lastRtpBytesReceived = totalReceived;
        }

        // Adaptive Network Quality & Bitrate Tuning (D1 & D3)
        final deltaLost = totalPacketsLost - _lastPacketsLost;
        final deltaReceived = totalPacketsReceived - _lastPacketsReceived;
        _lastPacketsLost = totalPacketsLost;
        _lastPacketsReceived = totalPacketsReceived;

        double packetLossRate = 0.0;
        if (deltaLost + deltaReceived > 0 && deltaLost >= 0) {
          packetLossRate = deltaLost / (deltaLost + deltaReceived);
        }

        final rttMs = lastRttSeconds * 1000;
        final jitterMs = lastJitterSeconds * 1000;

        // Auto-Degrade Ladder (D3):
        // 🔴 Poor: Loss > 5% or RTT > 400ms or Jitter > 80ms
        // 🟡 Fair: Loss > 2% or RTT > 220ms or Jitter > 35ms
        // 🟢 Good: Loss <= 2% and RTT <= 220ms and Jitter <= 35ms
        CallNetworkQuality quality;
        if (packetLossRate > 0.05 || rttMs > 400 || jitterMs > 80) {
          quality = CallNetworkQuality.poor;
        } else if (packetLossRate > 0.02 || rttMs > 220 || jitterMs > 35) {
          quality = CallNetworkQuality.fair;
        } else {
          quality = CallNetworkQuality.good;
        }

        if (quality != _currentNetworkQuality) {
          _currentNetworkQuality = quality;
          if (!_networkQualityController.isClosed) {
            _networkQualityController.add(quality);
          }

          // D3: 3-tier adaptive bitrate ladder
          switch (quality) {
            case CallNetworkQuality.poor:
              setAudioBitrate(16000);
              debugPrint('[WebRtcCallClient] 🔴 Poor network (loss: ${(packetLossRate * 100).toStringAsFixed(1)}%, RTT: ${rttMs.toStringAsFixed(0)}ms, jitter: ${jitterMs.toStringAsFixed(0)}ms). Degraded bitrate to 16kbps.');
              break;
            case CallNetworkQuality.fair:
              setAudioBitrate(24000);
              debugPrint('[WebRtcCallClient] 🟡 Fair network (loss: ${(packetLossRate * 100).toStringAsFixed(1)}%, RTT: ${rttMs.toStringAsFixed(0)}ms, jitter: ${jitterMs.toStringAsFixed(0)}ms). Step-down bitrate to 24kbps.');
              break;
            case CallNetworkQuality.good:
              final lessDataManual = SharedPref.instance.getBool('storage_less_data_calls') ?? false;
              setAudioBitrate(lessDataManual ? 16000 : 32000);
              debugPrint('[WebRtcCallClient] 🟢 Good network restored. Bitrate set to ${lessDataManual ? 16000 : 32000}bps.');
              break;
          }
        }
      } catch (e) {
        debugPrint('[WebRtcCallClient] RTP stats tracking error: $e');
      }
    });
  }

  void _stopRtpStatsTracking() {
    _rtpStatsTimer?.cancel();
    _rtpStatsTimer = null;
  }

  void _updateState(WebRtcCallState state) {
    _currentState = state;
    if (state == WebRtcCallState.connected) {
      _startRtpStatsTracking();
      final lessData = SharedPref.instance.getBool('storage_less_data_calls') ?? false;
      setAudioBitrate(lessData ? 16000 : 32000);
    } else if (state == WebRtcCallState.closed || state == WebRtcCallState.failed) {
      _stopRtpStatsTracking();
    }
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Initialize local audio stream with Hardware Echo Cancellation & Noise Suppression
  Future<MediaStream?> initLocalStream() async {
    try {
      final lessData =
          SharedPref.instance.getBool('storage_less_data_calls') ?? false;
      final mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'highpassFilter': true,
          if (lessData) 'sampleRate': 16000,
          if (lessData) 'channelCount': 1,
        },
        'video': false,
      };

      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return _localStream;
    } catch (e) {
      debugPrint('Failed to get user media: $e');
      return null;
    }
  }

  /// Initiates an outgoing call: creates offer and listens for answer
  Future<void> startOutgoingCall(String callId) async {
    _isCaller = true;
    _currentCallId = callId;
    _updateState(WebRtcCallState.connecting);

    try {
      await _createPeerConnection();

      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });

      final tunedOfferSdp = tuneAudioSdp(offer.sdp ?? '');
      final tunedOffer = RTCSessionDescription(tunedOfferSdp, offer.type);
      await _peerConnection!.setLocalDescription(tunedOffer);

      // Save Offer to Firestore call document
      if (firestore != null) {
        await firestore!.collection('calls').doc(callId).set({
          'offer': {
            'sdp': tunedOffer.sdp,
            'type': tunedOffer.type,
          },
        }, SetOptions(merge: true));

        // Listen for Answer from callee
        _callDocSubscription = firestore!
            .collection('calls')
            .doc(callId)
            .snapshots()
            .listen((snapshot) async {
          if (!snapshot.exists) return;
          final data = snapshot.data();
          if (data == null) return;

          if (data.containsKey('answer') &&
              _peerConnection != null &&
              await _peerConnection?.getRemoteDescription() == null) {
            final answerMap = data['answer'] as Map<String, dynamic>;
            final tunedAnswerSdp = tuneAudioSdp(answerMap['sdp'] ?? '');
            final answer = RTCSessionDescription(
              tunedAnswerSdp,
              answerMap['type'],
            );
            await _peerConnection!.setRemoteDescription(answer);
            debugPrint('Caller successfully set remote answer description with Opus FEC');
            await _drainPendingCandidates();
          }
        });

        // Listen for Callee ICE Candidates
        _remoteCandidatesSubscription = firestore!
            .collection('calls')
            .doc(callId)
            .collection('calleeCandidates')
            .snapshots()
            .listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null && _peerConnection != null) {
                final candidate = RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                );
                await _addOrQueueCandidate(candidate);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting outgoing WebRTC call: $e');
      _updateState(WebRtcCallState.failed);
    }
  }

  /// Accepts an incoming call: sets offer, creates answer and streams audio
  Future<void> answerIncomingCall(
    String callId,
    Map<String, dynamic> offerData,
  ) async {
    _isCaller = false;
    _currentCallId = callId;
    _updateState(WebRtcCallState.connecting);

    try {
      await _createPeerConnection();

      // Set Remote Description from Caller's Offer with Opus FEC tuning
      final tunedRemoteOfferSdp = tuneAudioSdp(offerData['sdp'] ?? '');
      final offer = RTCSessionDescription(
        tunedRemoteOfferSdp,
        offerData['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
      await _drainPendingCandidates();

      // Create Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });

      final tunedAnswerSdp = tuneAudioSdp(answer.sdp ?? '');
      final tunedAnswer = RTCSessionDescription(tunedAnswerSdp, answer.type);
      await _peerConnection!.setLocalDescription(tunedAnswer);

      // Save Answer to Firestore
      if (firestore != null) {
        await firestore!.collection('calls').doc(callId).set({
          'answer': {
            'sdp': tunedAnswer.sdp,
            'type': tunedAnswer.type,
          },
        }, SetOptions(merge: true));

        // Listen for Caller ICE Candidates
        _remoteCandidatesSubscription = firestore!
            .collection('calls')
            .doc(callId)
            .collection('callerCandidates')
            .snapshots()
            .listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null && _peerConnection != null) {
                final candidate = RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                );
                await _addOrQueueCandidate(candidate);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error answering WebRTC call: $e');
      _updateState(WebRtcCallState.failed);
    }
  }

  final List<RTCIceCandidate> _pendingCandidates = [];

  Future<void> _addOrQueueCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    try {
      final remoteDesc = await _peerConnection!.getRemoteDescription();
      if (remoteDesc != null) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        _pendingCandidates.add(candidate);
      }
    } catch (e) {
      debugPrint('Error handling candidate: $e');
    }
  }

  Future<void> _drainPendingCandidates() async {
    if (_peerConnection == null || _pendingCandidates.isEmpty) return;
    final copy = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final candidate in copy) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('Error draining candidate: $e');
      }
    }
  }

  Future<void> restartIce() async {
    if (_peerConnection == null) return;
    try {
      debugPrint('[WebRtcCallClient] Triggering ICE restart');
      await _peerConnection!.restartIce();
    } catch (e) {
      debugPrint('[WebRtcCallClient] restartIce failed: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    await refreshIceServers();
    _peerConnection = await createPeerConnection(_iceConfiguration);

    if (_localStream == null) {
      await initLocalStream();
    }

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Configure Opus Codec Preferences with In-Band FEC on Audio Transceiver
    try {
      final transceivers = await _peerConnection!.getTransceivers();
      for (final transceiver in transceivers) {
        if (transceiver.receiver.track?.kind == 'audio' ||
            transceiver.sender.track?.kind == 'audio') {
          await transceiver.setCodecPreferences([
            RTCRtpCodecCapability(
              mimeType: 'audio/opus',
              clockRate: 48000,
              channels: 2,
              sdpFmtpLine: 'minptime=10;useinbandfec=1;usedtx=1',
            ),
          ]);
          debugPrint('[WebRtcCallClient] Set Opus FEC preferences on transceiver');
        }
      }
    } catch (e) {
      debugPrint('[WebRtcCallClient] Transceiver setCodecPreferences note: $e');
    }

    // ICE Candidate gathering
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (_currentCallId == null || firestore == null) return;
      final collectionName =
          _isCaller ? 'callerCandidates' : 'calleeCandidates';

      try {
        await firestore!
            .collection('calls')
            .doc(_currentCallId)
            .collection(collectionName)
            .add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error writing ICE candidate: $e');
      }
    };

    // Connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('WebRTC Connection State: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateState(WebRtcCallState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateState(WebRtcCallState.disconnected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateState(WebRtcCallState.failed);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _updateState(WebRtcCallState.closed);
          break;
        default:
          break;
      }
    };

    // Receive Remote Track
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
        debugPrint('Received remote WebRTC audio track!');
      }
    };

    // Setup DataChannel for live translated PCM audio stream
    if (_isCaller) {
      final dcInit = RTCDataChannelInit()
        ..ordered = false
        ..maxRetransmits = 2; // (B3) Up to 2 retransmits eliminates glitches while maintaining under 80ms latency
      _dataChannel =
          await _peerConnection!.createDataChannel('liveTranslateAudio', dcInit);
      if (_dataChannel != null) {
        _setupDataChannel(_dataChannel!);
      }
    }

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _setupDataChannel(channel);
    };
  }

  void _setupDataChannel(RTCDataChannel channel) {
    channel.onMessage = (RTCDataChannelMessage msg) {
      if (msg.isBinary) {
        NetworkTracker.recordBytesReceived(msg.binary.length);
        _remoteTranslatedAudioController.add(msg.binary);
      }
    };
  }

  /// Sends 24kHz PCM translated audio chunk to remote peer over WebRTC DataChannel
  void sendTranslatedAudio(Uint8List pcmBytes) {
    if (_dataChannel != null &&
        _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        _dataChannel!.send(RTCDataChannelMessage.fromBinary(pcmBytes));
        NetworkTracker.recordBytesSent(pcmBytes.length);
      } catch (e) {
        debugPrint('Error sending translated audio over DataChannel: $e');
      }
    }
  }

  /// Switch audio routing between Loudspeaker and Earpiece on Android
  void setSpeakerphone(bool enabled) {
    try {
      Helper.setSpeakerphoneOn(enabled);
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }
  }

  /// Sets remote audio track volume (e.g. 1.0 for normal, 0.15 for UN interpreter ducking, 0.0 for mute)
  void setRemoteAudioVolume(double volume) {
    if (_remoteStream != null) {
      for (final audioTrack in _remoteStream!.getAudioTracks()) {
        audioTrack.enabled = volume > 0.001;
        Helper.setVolume(volume, audioTrack);
      }
    }
  }

  /// Toggle microphone mute
  void setMicrophoneMute(bool muted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
  }

  /// Clean up and end call session
  Future<void> endCall() async {
    _updateState(WebRtcCallState.closed);
    _stopRtpStatsTracking();

    await _callDocSubscription?.cancel();
    _callDocSubscription = null;

    await _remoteCandidatesSubscription?.cancel();
    _remoteCandidatesSubscription = null;

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
    }

    if (_remoteStream != null) {
      await _remoteStream?.dispose();
      _remoteStream = null;
    }

    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _peerConnection = null;

    _currentCallId = null;
    _isCaller = false;
  }

  void dispose() {
    endCall();
    if (!_stateController.isClosed) _stateController.close();
    if (!_remoteStreamController.isClosed) _remoteStreamController.close();
    if (!_remoteTranslatedAudioController.isClosed) {
      _remoteTranslatedAudioController.close();
    }
    if (!_networkQualityController.isClosed) {
      _networkQualityController.close();
    }
  }
}
