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
  .note{margin-top:14px;padding:10px 12px;border-radius:10px;background:rgba(52,211,153,.06);border:1px solid rgba(52,211,153,.18);font-size:11px;color:#9fb3c8;line-height:1.5}
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
  <audio id="remote" autoplay playsinline></audio>
  <div class="err" id="err"></div>
  <p class="note">
    Browser rooms are voice-only. Live translation runs in the Livocal app.
  </p>
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


</script>
</body>
</html>`;
}
