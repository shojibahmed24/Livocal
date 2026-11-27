'use strict';

/** Browser voice room (host + guest) for F7.1 — no translation. */

function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function renderRoomPage({
  role,
  roomId,
  token,
  peerName,
  guestUrl,
}) {
  const isHost = role === 'host';
  const name = esc(peerName || 'Livocal');
  const title = isHost ? `Guest room — ${name}` : `Join ${name}`;
  const shareBlock = isHost
    ? `<div class="share">
        <div class="label">Guest link</div>
        <input id="guestUrl" readonly value="${esc(guestUrl)}">
        <button class="btn ghost" id="copyBtn" type="button">Copy link</button>
      </div>`
    : '';

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title}</title>
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#04070d;color:#f1f5f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;display:flex;min-height:100vh;align-items:center;justify-content:center;padding:18px}
  .card{max-width:460px;width:100%;background:#0c1424;border:1px solid rgba(255,255,255,.08);border-radius:20px;padding:22px;text-align:center}
  h1{font-size:20px;margin:0 0 4px} .sub{color:#8b98ad;font-size:12.5px;margin:0 0 14px}
  .status{display:inline-block;padding:5px 12px;border-radius:999px;font-size:11px;font-weight:800;color:#34d399;background:rgba(52,211,153,.12);border:1px solid rgba(52,211,153,.3)}
  .btn{width:100%;margin-top:10px;padding:13px;border:0;border-radius:12px;font-weight:800;font-size:13.5px;cursor:pointer;background:#34d399;color:#04120c}
  .btn.ghost{background:transparent;border:1px solid rgba(255,255,255,.16);color:#f1f5f9}
  .btn:disabled{opacity:.5;cursor:not-allowed}
  .share{margin-top:14px;text-align:left}
  .share .label{font-size:10.5px;letter-spacing:.08em;text-transform:uppercase;color:#8b98ad;margin-bottom:5px}
  .share input{width:100%;padding:10px;border-radius:10px;border:1px solid rgba(255,255,255,.12);background:#0a1220;color:#f1f5f9;font-size:11.5px}
  audio{width:100%;margin-top:14px}
  .foot{margin-top:16px;font-size:10.5px;color:#94a3b8}
  .err{color:#ff6b6b;font-size:12px;margin-top:10px}
  .tr{margin-top:14px;text-align:left;border-top:1px solid rgba(255,255,255,.08);padding-top:12px}
  .tr summary{font-size:12px;font-weight:700;color:#c7d2fe;cursor:pointer;list-style:none}
  .tr summary::-webkit-details-marker{display:none}
  .tr summary:before{content:'▸ ';color:#8b98ad}
  .tr[open] summary:before{content:'▾ '}
  .trrow{display:flex;align-items:center;justify-content:space-between;gap:8px;margin:10px 0}
  .trrow span{font-size:11px;color:#8b98ad}
  .tr select{flex:1;max-width:150px;padding:8px;border-radius:9px;border:1px solid rgba(255,255,255,.14);background:#0a1220;color:#f1f5f9;font-size:11.5px}
  .caption{margin-top:8px;padding:10px;border-radius:10px;background:#0a1220;border:1px solid rgba(255,255,255,.08);font-size:12px;color:#cbd5e1;min-height:20px;line-height:1.45}
  .caption.live{color:#34d399;border-color:rgba(52,211,153,.35)}
</style>
</head>
<body>
<div class="card">
  <h1>${isHost ? 'Guest room' : 'Join call'}</h1>
  <p class="sub">${isHost ? `Share the link — guests join from their browser.` : `Talking with ${name}`}</p>
  <div class="status" id="status">Ready</div>
  ${shareBlock}
  <button class="btn" id="startBtn" type="button">Start microphone</button>
  <button class="btn ghost" id="hangBtn" type="button" disabled>Leave</button>
  <details class="tr">
    <summary>Translated speech</summary>
    <div class="trrow">
      <span>Translate my speech to</span>
      <select id="targetLang">
        <option value="English">English</option>
        <option value="Bengali">Bengali</option>
        <option value="Hindi">Hindi</option>
        <option value="Arabic">Arabic</option>
        <option value="Spanish">Spanish</option>
        <option value="French">French</option>
        <option value="German">German</option>
      </select>
    </div>
    <button class="btn ghost" id="talkBtn" type="button">Hold to speak</button>
    <div class="caption" id="caption">Hold the button, speak one sentence, then release.</div>
  </details>
  <audio id="remote" autoplay playsinline></audio>
  <div class="err" id="err"></div>
  <div class="foot">Voice only · Powered by Livocal</div>
</div>
<script>
  var ROLE = ${JSON.stringify(role)};
  var ROOM = ${JSON.stringify(roomId)};
  var TOKEN = ${JSON.stringify(token)};
  var peerName = ${JSON.stringify(peerName || '')};
  var ws = null, pc = null, localStream = null, started = false;
  var statusEl = document.getElementById('status');
  var errEl = document.getElementById('err');
  var remoteAudio = document.getElementById('remote');
  var startBtn = document.getElementById('startBtn');
  var hangBtn = document.getElementById('hangBtn');

  function setStatus(text) { statusEl.textContent = text; }
  function fail(text) { errEl.textContent = text; }

  async function iceServers() {
    try {
      var res = await fetch('/api/public/ice');
      if (res.ok) {
        var data = await res.json();
        if (Array.isArray(data.iceServers)) return data.iceServers;
      }
    } catch (e) {}
    return [{ urls: 'stun:stun.l.google.com:19302' }];
  }

  async function start() {
    if (started) return;
    started = true;
    startBtn.disabled = true;
    setStatus('Connecting…');
    try {
      localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      pc = new RTCPeerConnection({ iceServers: await iceServers() });
      localStream.getTracks().forEach(function (track) { pc.addTrack(track, localStream); });
      pc.ontrack = function (event) {
        remoteAudio.srcObject = event.streams[0];
        setStatus('Connected');
      };
      pc.onicecandidate = function (event) {
        if (event.candidate && ws && ws.readyState === 1) {
          ws.send(JSON.stringify({ type: 'ice', candidate: event.candidate }));
        }
      };

      var proto = location.protocol === 'https:' ? 'wss://' : 'ws://';
      ws = new WebSocket(proto + location.host + '/ws/room?token=' + encodeURIComponent(TOKEN));
      ws.onopen = function () {
        hangBtn.disabled = false;
        setStatus('Waiting for the other side…');
        if (ROLE === 'guest') sendOffer();
      };
      ws.onmessage = async function (event) {
        var msg = JSON.parse(event.data);
        if (msg.type === 'peer-joined' && ROLE === 'host') {
          setStatus('Guest joined');
        } else if (msg.type === 'host-ready' && ROLE === 'guest') {
          sendOffer();
        } else if (msg.type === 'offer' && ROLE === 'host') {
          await pc.setRemoteDescription(new RTCSessionDescription(msg.sdp));
          var answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          ws.send(JSON.stringify({ type: 'answer', sdp: answer }));
        } else if (msg.type === 'answer' && ROLE === 'guest') {
          await pc.setRemoteDescription(new RTCSessionDescription(msg.sdp));
        } else if (msg.type === 'ice' && msg.candidate) {
          try { await pc.addIceCandidate(new RTCIceCandidate(msg.candidate)); } catch (e) {}
        } else if (msg.type === 'peer-left') {
          setStatus('Other side left');
        } else if (msg.type === 'full') {
          fail('This room already has two people.');
        }
      };
      ws.onclose = function () { setStatus('Disconnected'); };
    } catch (e) {
      fail('Microphone access failed: ' + e.message);
      setStatus('Failed');
      started = false;
      startBtn.disabled = false;
    }
  }

  async function sendOffer() {
    if (!pc || !ws || ws.readyState !== 1) return;
    var offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    ws.send(JSON.stringify({ type: 'offer', sdp: offer }));
    setStatus('Ringing…');
  }

  function hangup() {
    if (pc) { try { pc.close(); } catch (e) {} pc = null; }
    if (ws) { try { ws.close(); } catch (e) {} ws = null; }
    if (localStream) { localStream.getTracks().forEach(function (t) { t.stop(); }); localStream = null; }
    remoteAudio.srcObject = null;
    started = false;
    startBtn.disabled = false;
    hangBtn.disabled = true;
    setStatus('Left');
  }

  startBtn.addEventListener('click', start);
  hangBtn.addEventListener('click', hangup);
  var copyBtn = document.getElementById('copyBtn');
  if (copyBtn) {
    copyBtn.addEventListener('click', async function () {
      var input = document.getElementById('guestUrl');
      try { await navigator.clipboard.writeText(input.value); copyBtn.textContent = 'Copied'; } catch (e) { input.select(); }
    });
  }

  // ── Translated speech (F7.2 v1) ──────────────────────────────────────────
  var talkBtn = document.getElementById('talkBtn');
  var captionEl = document.getElementById('caption');
  var targetSel = document.getElementById('targetLang');
  var LANG_CODES = {
    English: 'en-US', Bengali: 'bn-BD', Hindi: 'hi-IN', Arabic: 'ar-SA',
    Spanish: 'es-ES', French: 'fr-FR', German: 'de-DE'
  };
  var capturing = false;
  var captureCtx = null, captureProc = null, captureSrc = null;
  var captureSink = null, captureStream = null, captureTimer = null;
  var captureParts = [], captureRate = 44100;

  function setCaption(text, live) {
    captionEl.textContent = text;
    captionEl.className = live ? 'caption live' : 'caption';
  }

  function mergeParts(parts) {
    var total = 0, i;
    for (i = 0; i < parts.length; i++) total += parts[i].length;
    var out = new Float32Array(total), offset = 0;
    for (i = 0; i < parts.length; i++) {
      out.set(parts[i], offset);
      offset += parts[i].length;
    }
    return out;
  }

  function downsample(data, from, to) {
    if (to >= from) return data;
    var ratio = from / to, length = Math.floor(data.length / ratio);
    var out = new Float32Array(length), pos = 0;
    for (var i = 0; i < length; i++) {
      var next = Math.floor((i + 1) * ratio), sum = 0, count = 0;
      for (var j = pos; j < next && j < data.length; j++) {
        sum += data[j];
        count++;
      }
      out[i] = count ? sum / count : 0;
      pos = next;
    }
    return out;
  }

  function wavBase64(samples, rate) {
    var length = samples.length;
    var buffer = new ArrayBuffer(44 + length * 2);
    var view = new DataView(buffer);
    function writeString(offset, text) {
      for (var i = 0; i < text.length; i++) view.setUint8(offset + i, text.charCodeAt(i));
    }
    writeString(0, 'RIFF');
    view.setUint32(4, 36 + length * 2, true);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, 1, true);
    view.setUint32(24, rate, true);
    view.setUint32(28, rate * 2, true);
    view.setUint16(32, 2, true);
    view.setUint16(34, 16, true);
    writeString(36, 'data');
    view.setUint32(40, length * 2, true);
    for (var i = 0; i < length; i++) {
      var s = Math.max(-1, Math.min(1, samples[i]));
      view.setInt16(44 + i * 2, s < 0 ? s * 0x8000 : s * 0x7fff, true);
    }
    var bytes = new Uint8Array(buffer), binary = '', step = 0x8000;
    for (var k = 0; k < bytes.length; k += step) {
      binary += String.fromCharCode.apply(null, bytes.subarray(k, k + step));
    }
    return btoa(binary);
  }

  async function startTalk() {
    if (capturing) return;
    capturing = true;
    captureParts = [];
    talkBtn.textContent = 'Listening… release to translate';
    setCaption('Listening…', true);
    captureTimer = setTimeout(releaseTalk, 20000);
    try {
      captureStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      captureCtx = new (window.AudioContext || window.webkitAudioContext)();
      captureRate = captureCtx.sampleRate;
      captureSrc = captureCtx.createMediaStreamSource(captureStream);
      captureProc = captureCtx.createScriptProcessor(4096, 1, 1);
      captureSink = captureCtx.createGain();
      captureSink.gain.value = 0;
      captureProc.onaudioprocess = function (event) {
        if (!capturing) return;
        var channel = event.inputBuffer.getChannelData(0);
        var copy = new Float32Array(channel.length);
        copy.set(channel);
        captureParts.push(copy);
      };
      captureSrc.connect(captureProc);
      captureProc.connect(captureSink);
      captureSink.connect(captureCtx.destination);
    } catch (err) {
      capturing = false;
      if (captureTimer) clearTimeout(captureTimer);
      talkBtn.textContent = 'Hold to speak';
      setCaption('Microphone unavailable: ' + err.message);
    }
  }

  function releaseTalk() {
    if (!capturing) return;
    capturing = false;
    if (captureTimer) { clearTimeout(captureTimer); captureTimer = null; }
    talkBtn.textContent = 'Translating…';
    try { if (captureSrc) captureSrc.disconnect(); } catch (e) {}
    try { if (captureProc) captureProc.disconnect(); } catch (e) {}
    try { if (captureSink) captureSink.disconnect(); } catch (e) {}
    try { if (captureCtx) captureCtx.close(); } catch (e) {}
    if (captureStream) {
      captureStream.getTracks().forEach(function (track) { track.stop(); });
    }
    captureCtx = null; captureProc = null; captureSrc = null;
    captureSink = null; captureStream = null;

    var merged = mergeParts(captureParts);
    captureParts = [];
    if (merged.length < captureRate * 0.3) {
      talkBtn.textContent = 'Hold to speak';
      setCaption('Too short — hold the button while you speak.');
      return;
    }
    var pcm = downsample(merged, captureRate, 16000);
    var target = targetSel.value || 'English';
    fetch('/api/public/translate-audio', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        audio: wavBase64(pcm, 16000),
        mimeType: 'audio/wav',
        targetLanguage: target
      })
    }).then(function (res) {
      if (!res.ok) throw new Error('translate ' + res.status);
      return res.json();
    }).then(function (data) {
      talkBtn.textContent = 'Hold to speak';
      var text = data && data.text ? String(data.text).trim() : '';
      if (!text) {
        setCaption('No speech detected — try again.');
        return;
      }
      setCaption(text, true);
      try {
        var utter = new SpeechSynthesisUtterance(text);
        utter.lang = LANG_CODES[target] || 'en-US';
        utter.rate = 1;
        window.speechSynthesis.speak(utter);
      } catch (e) {}
    }).catch(function (err) {
      talkBtn.textContent = 'Hold to speak';
      setCaption('Translation unavailable: ' + err.message);
    });
  }

  talkBtn.addEventListener('mousedown', function (e) { e.preventDefault(); startTalk(); });
  talkBtn.addEventListener('mouseup', function (e) { e.preventDefault(); releaseTalk(); });
  talkBtn.addEventListener('mouseleave', function () { releaseTalk(); });
  talkBtn.addEventListener('touchstart', function (e) { e.preventDefault(); startTalk(); });
  talkBtn.addEventListener('touchend', function (e) { e.preventDefault(); releaseTalk(); });
</script>
</body>
</html>`;
}
