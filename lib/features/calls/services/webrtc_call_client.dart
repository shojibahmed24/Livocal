import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum WebRtcCallState {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  closed,
}

class WebRtcCallClient {
  final FirebaseFirestore firestore;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  StreamSubscription? _callDocSubscription;
  StreamSubscription? _remoteCandidatesSubscription;

  final StreamController<WebRtcCallState> _stateController =
      StreamController<WebRtcCallState>.broadcast();
  final StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();

  Stream<WebRtcCallState> get stateStream => _stateController.stream;
  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;

  WebRtcCallState _currentState = WebRtcCallState.idle;
  WebRtcCallState get currentState => _currentState;

  bool _isCaller = false;
  String? _currentCallId;

  WebRtcCallClient({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  static const Map<String, dynamic> _iceConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun.relay.metered.ca:80'},
      {
        'urls': 'turn:standard.relay.metered.ca:80',
        'username': '19e5ee2930dceaa8605b4cbc',
        'credential': '3zFl5+uHvCOLLxhs',
      },
      {
        'urls': 'turn:standard.relay.metered.ca:80?transport=tcp',
        'username': '19e5ee2930dceaa8605b4cbc',
        'credential': '3zFl5+uHvCOLLxhs',
      },
      {
        'urls': 'turn:standard.relay.metered.ca:443',
        'username': '19e5ee2930dceaa8605b4cbc',
        'credential': '3zFl5+uHvCOLLxhs',
      },
      {
        'urls': 'turns:standard.relay.metered.ca:443?transport=tcp',
        'username': '19e5ee2930dceaa8605b4cbc',
        'credential': '3zFl5+uHvCOLLxhs',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  void _updateState(WebRtcCallState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Initialize local audio stream with Hardware Echo Cancellation & Noise Suppression
  Future<MediaStream?> initLocalStream() async {
    try {
      final mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'highpassFilter': true,
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

      await _peerConnection!.setLocalDescription(offer);

      // Save Offer to Firestore call document
      await firestore.collection('calls').doc(callId).set({
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      }, SetOptions(merge: true));

      // Listen for Answer from callee
      _callDocSubscription = firestore
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
          final answer = RTCSessionDescription(
            answerMap['sdp'],
            answerMap['type'],
          );
          await _peerConnection!.setRemoteDescription(answer);
          debugPrint('Caller successfully set remote answer description');
          await _drainPendingCandidates();
        }
      });

      // Listen for Callee ICE Candidates
      _remoteCandidatesSubscription = firestore
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

      // Set Remote Description from Caller's Offer
      final offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
      await _drainPendingCandidates();

      // Create Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });

      await _peerConnection!.setLocalDescription(answer);

      // Save Answer to Firestore
      await firestore.collection('calls').doc(callId).set({
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      }, SetOptions(merge: true));

      // Listen for Caller ICE Candidates
      _remoteCandidatesSubscription = firestore
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

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceConfiguration);

    if (_localStream == null) {
      await initLocalStream();
    }

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // ICE Candidate gathering
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (_currentCallId == null) return;
      final collectionName =
          _isCaller ? 'callerCandidates' : 'calleeCandidates';

      try {
        await firestore
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
  }

  /// Sets remote audio track volume (e.g. 1.0 for normal, 0.15 for UN interpreter ducking, 0.0 for mute)
  void setRemoteAudioVolume(double volume) {
    if (_remoteStream != null) {
      for (final audioTrack in _remoteStream!.getAudioTracks()) {
        audioTrack.enabled = volume > 0.01;
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
    _stateController.close();
    _remoteStreamController.close();
  }
}
