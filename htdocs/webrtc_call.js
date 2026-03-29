/*
  Sheber.kz WebRTC (audio) calls without phone numbers.
  Signaling: simple polling via PHP API + MySQL tables (webrtc_calls, webrtc_signals).
  Works in modern browsers over HTTPS (required for getUserMedia on most browsers).
*/

(function () {
  const ICE_SERVERS = [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
  ];

  function qs(sel) { return document.querySelector(sel); }
  function esc(s) {
    return String(s || '').replace(/[&<>"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  }

  async function apiGet(url) {
    const r = await fetch(url, { credentials: 'include' });
    const j = await r.json().catch(() => null);
    if (!r.ok || !j || j.ok === false) throw new Error((j && j.error) || 'error');
    return j.data;
  }

  let CSRF_TOKEN = '';
  async function ensureCsrf() {
    if (CSRF_TOKEN) return CSRF_TOKEN;
    try {
      const r = await fetch('/api/csrf.php', { credentials: 'include' });
      const j = await r.json().catch(() => null);
      if (r.ok && j && j.ok && j.data && j.data.csrf_token) CSRF_TOKEN = String(j.data.csrf_token);
    } catch {}
    return CSRF_TOKEN;
  }

  async function apiPost(url, data) {
    await ensureCsrf();
    const fd = new FormData();
    Object.keys(data || {}).forEach(k => fd.append(k, data[k]));
    const r = await fetch(url, {
      method: 'POST',
      body: fd,
      credentials: 'include',
      headers: { 'X-CSRF-Token': CSRF_TOKEN },
    });
    const j = await r.json().catch(() => null);
    if (!r.ok || !j || j.ok === false) throw new Error((j && j.error) || 'error');
    return j.data;
  }

  const state = {
    enabled: true,
    order: null,
    user: null,
    callId: 0,
    initiatorId: 0,
    lastSignalId: 0,
    pc: null,
    localStream: null,
    remoteStream: null,
    activePollTimer: null,
    signalPollTimer: null,
    inChat: false,
    incoming: false,
    inCall: false,
  };

  function ensureUI() {
    if (qs('#sheberCallModal')) return;

    const wrap = document.createElement('div');
    wrap.id = 'sheberCallModal';
    wrap.style.cssText = [
      'position:fixed',
      'inset:0',
      'background:rgba(0,0,0,.55)',
      'display:none',
      'z-index:9999',
      'align-items:center',
      'justify-content:center',
      'padding:16px'
    ].join(';');

    wrap.innerHTML = `
      <div style="width:100%; max-width:420px; background:var(--surface, #111); color:var(--text-main, #fff); border:1px solid var(--border, rgba(255,255,255,.12)); border-radius:18px; padding:14px 14px 12px; box-shadow:0 20px 60px rgba(0,0,0,.35);">
        <div style="display:flex; gap:10px; align-items:center; justify-content:space-between;">
          <div style="min-width:0;">
            <div id="sheberCallTitle" style="font-weight:800; font-size:16px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">Звонок</div>
            <div id="sheberCallStatus" style="opacity:.8; font-size:12px; margin-top:2px;">—</div>
          </div>
          <button id="sheberCallClose" style="background:transparent; border:0; color:inherit; opacity:.85; cursor:pointer; padding:6px; border-radius:10px;">✕</button>
        </div>

        <div style="margin-top:12px; display:flex; gap:10px; align-items:center; justify-content:center;">
          <button id="sheberCallAccept" style="display:none; padding:10px 14px; border-radius:14px; border:1px solid var(--border, rgba(255,255,255,.15)); background:var(--accent, #2EC4B6); color:#000; font-weight:800; cursor:pointer;">Принять</button>
          <button id="sheberCallReject" style="display:none; padding:10px 14px; border-radius:14px; border:1px solid var(--border, rgba(255,255,255,.15)); background:transparent; color:inherit; font-weight:800; cursor:pointer;">Отклонить</button>
        </div>

        <div style="margin-top:10px; display:flex; gap:10px; align-items:center; justify-content:center;">
          <button id="sheberCallMute" style="display:none; padding:10px 14px; border-radius:14px; border:1px solid var(--border, rgba(255,255,255,.15)); background:transparent; color:inherit; font-weight:800; cursor:pointer;">Mute</button>
          <button id="sheberCallHangup" style="display:none; padding:10px 14px; border-radius:14px; border:1px solid var(--border, rgba(255,255,255,.15)); background:rgba(255,255,255,.08); color:inherit; font-weight:800; cursor:pointer;">Сбросить</button>
        </div>

        <audio id="sheberRemoteAudio" autoplay playsinline></audio>
      </div>
    `;

    document.body.appendChild(wrap);

    qs('#sheberCallClose').onclick = () => {
      // Закрытие окна без разрыва звонка (если идёт) — оставим управлять кнопкой "Сбросить"
      hideModal();
    };
    qs('#sheberCallHangup').onclick = () => hangup('local');
    qs('#sheberCallReject').onclick = () => rejectIncoming();
    qs('#sheberCallAccept').onclick = () => acceptIncoming();
    qs('#sheberCallMute').onclick = () => toggleMute();
  }

  function showModal(title, status) {
    ensureUI();
    const m = qs('#sheberCallModal');
    if (!m) return;
    qs('#sheberCallTitle').textContent = title || 'Звонок';
    qs('#sheberCallStatus').textContent = status || '—';
    m.style.display = 'flex';
  }
  function hideModal() {
    const m = qs('#sheberCallModal');
    if (m) m.style.display = 'none';
  }
  function setButtons({ accept=false, reject=false, mute=false, hangupBtn=false }) {
    const a = qs('#sheberCallAccept');
    const r = qs('#sheberCallReject');
    const m = qs('#sheberCallMute');
    const h = qs('#sheberCallHangup');
    if (a) a.style.display = accept ? 'inline-flex' : 'none';
    if (r) r.style.display = reject ? 'inline-flex' : 'none';
    if (m) m.style.display = mute ? 'inline-flex' : 'none';
    if (h) h.style.display = hangupBtn ? 'inline-flex' : 'none';
  }

  function stopTimers() {
    if (state.activePollTimer) { clearInterval(state.activePollTimer); state.activePollTimer = null; }
    if (state.signalPollTimer) { clearInterval(state.signalPollTimer); state.signalPollTimer = null; }
  }

  async function startCall() {
    if (!state.order || !state.user) return;

    // Защита: только если мастер назначен
    const masterId = Number(state.order.master_id || 0);
    const st = String(state.order.status || 'new');
    if (!masterId || st === 'completed' || st === 'cancelled') return;

    try {
      showModal('Звонок', 'Подключаем микрофон…');
      setButtons({ mute:false, hangupBtn:true, accept:false, reject:false });

      const cr = await apiPost('api/call_create.php', { order_id: String(state.order.id) });
      state.callId = Number(cr.call_id || 0);
      state.incoming = false;
      state.inCall = true;
      state.lastSignalId = 0;

      await setupPeerConnection(true);
      await createAndSendOffer();

      startSignalPolling();

      qs('#sheberCallStatus').textContent = 'Звоним…';
    } catch (e) {
      hideModal();
      if (window.showToast) window.showToast('Звонок недоступен');
      cleanupMedia();
    }
  }

  async function setupPeerConnection(isInitiator) {
    cleanupPeer();

    state.pc = new RTCPeerConnection({ iceServers: ICE_SERVERS });
    state.remoteStream = new MediaStream();

    const remoteAudio = qs('#sheberRemoteAudio');
    if (remoteAudio) remoteAudio.srcObject = state.remoteStream;

    state.pc.ontrack = (ev) => {
      try {
        ev.streams[0].getTracks().forEach(t => state.remoteStream.addTrack(t));
      } catch {}
    };

    state.pc.onicecandidate = (ev) => {
      if (!ev.candidate || !state.callId) return;
      const payload = JSON.stringify({ candidate: ev.candidate });
      apiPost('api/call_signal_send.php', {
        call_id: String(state.callId),
        type: 'candidate',
        payload
      }).catch(() => {});
    };

    // audio only
    state.localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
    state.localStream.getTracks().forEach(track => state.pc.addTrack(track, state.localStream));

    // UI
    setButtons({ mute:true, hangupBtn:true, accept:false, reject:false });
    qs('#sheberCallStatus').textContent = isInitiator ? 'Звоним…' : 'Соединяем…';
  }

  async function createAndSendOffer() {
    if (!state.pc || !state.callId) return;
    const offer = await state.pc.createOffer({ offerToReceiveAudio: true });
    await state.pc.setLocalDescription(offer);
    await apiPost('api/call_signal_send.php', {
      call_id: String(state.callId),
      type: 'offer',
      payload: JSON.stringify({ sdp: offer })
    });
  }

  async function acceptIncoming() {
    state.incoming = false;
    state.inCall = true;
    setButtons({ accept:false, reject:false, mute:true, hangupBtn:true });
    qs('#sheberCallStatus').textContent = 'Подключаем микрофон…';
    try {
      await setupPeerConnection(false);
      // ждём offer в сигнал-пуле; если он уже пришёл — обработается сразу
      qs('#sheberCallStatus').textContent = 'Соединяем…';
    } catch {
      hideModal();
      cleanupMedia();
      if (window.showToast) window.showToast('Нет доступа к микрофону');
    }
  }

  async function rejectIncoming() {
    if (!state.callId) { hideModal(); return; }
    apiPost('api/call_signal_send.php', { call_id: String(state.callId), type:'reject', payload:'' }).catch(()=>{});
    await apiPost('api/call_end.php', { call_id: String(state.callId) }).catch(()=>{});
    hangup('reject');
  }

  async function hangup(reason) {
    const cid = state.callId;
    cleanupPeer();
    cleanupMedia();
    stopTimers();
    state.callId = 0;
    state.incoming = false;
    state.inCall = false;
    hideModal();
    if (cid) {
      apiPost('api/call_end.php', { call_id: String(cid) }).catch(() => {});
    }
    if (reason === 'remote' && window.showToast) window.showToast('Звонок завершён');
  }

  function cleanupPeer() {
    if (state.pc) {
      try { state.pc.ontrack = null; state.pc.onicecandidate = null; state.pc.close(); } catch {}
      state.pc = null;
    }
  }
  function cleanupMedia() {
    if (state.localStream) {
      try { state.localStream.getTracks().forEach(t => t.stop()); } catch {}
      state.localStream = null;
    }
    state.remoteStream = null;
    const ra = qs('#sheberRemoteAudio');
    if (ra) ra.srcObject = null;
  }

  function toggleMute() {
    if (!state.localStream) return;
    const track = state.localStream.getAudioTracks()[0];
    if (!track) return;
    track.enabled = !track.enabled;
    const btn = qs('#sheberCallMute');
    if (btn) btn.textContent = track.enabled ? 'Mute' : 'Unmute';
  }

  function startActivePolling() {
    stopTimers();
    if (!state.order || !state.user) return;

    state.activePollTimer = setInterval(async () => {
      if (!state.inChat) return;
      if (state.callId) return; // уже знаем call

      try {
        const data = await apiGet('api/call_get_active.php?order_id=' + encodeURIComponent(String(state.order.id)));
        const call = data.call;
        if (!call) return;

        state.callId = Number(call.id || 0);
        state.initiatorId = Number(call.initiator_id || 0);
        state.lastSignalId = 0;
        startSignalPolling();
      } catch {}
    }, 2500);
  }

  function startSignalPolling() {
    if (!state.callId) return;
    if (state.signalPollTimer) clearInterval(state.signalPollTimer);
    state.signalPollTimer = setInterval(pollSignals, 900);
    // сразу
    pollSignals().catch(() => {});
  }

  async function pollSignals() {
    if (!state.callId) return;
    const data = await apiGet('api/call_signal_poll.php?call_id=' + encodeURIComponent(String(state.callId)) + '&after_id=' + encodeURIComponent(String(state.lastSignalId || 0)));
    const me = Number(data.me || 0);
    const signals = Array.isArray(data.signals) ? data.signals : [];
    if (signals.length === 0) return;

    for (const s of signals) {
      const sid = Number(s.id || 0);
      if (sid > state.lastSignalId) state.lastSignalId = sid;

      const from = Number(s.from_user_id || 0);
      const type = String(s.type || '');
      const payload = String(s.payload || '');

      if (type === 'start') {
        // входящий звонок
        if (!state.inCall) {
          state.incoming = (from !== me);
          if (state.incoming) {
            showModal('Входящий звонок', 'Принять звонок?');
            setButtons({ accept:true, reject:true, mute:false, hangupBtn:false });
          }
        }
        continue;
      }

      if (type === 'reject') {
        if (from !== me) {
          hangup('remote');
        }
        continue;
      }

      if (type === 'hangup') {
        if (from !== me) {
          hangup('remote');
        }
        continue;
      }

      if (from === me) continue; // свои сигналы игнорируем

      if (type === 'offer') {
        // если это входящий и мы ещё не приняли — ждём accept
        if (!state.pc) {
          // оффер пришёл раньше нажатия «Принять» — покажем модал и подождём
          state.incoming = true;
          showModal('Входящий звонок', 'Принять звонок?');
          setButtons({ accept:true, reject:true, mute:false, hangupBtn:false });
          // сохраним offer временно
          state._pendingOffer = payload;
          continue;
        }
        await handleOffer(payload);
        continue;
      }

      if (type === 'answer') {
        await handleAnswer(payload);
        continue;
      }

      if (type === 'candidate') {
        await handleCandidate(payload);
        continue;
      }
    }
  }

  async function handleOffer(payload) {
    if (!state.pc || !payload) return;
    const j = JSON.parse(payload);
    const sdp = j && j.sdp;
    if (!sdp) return;
    await state.pc.setRemoteDescription(new RTCSessionDescription(sdp));
    const ans = await state.pc.createAnswer();
    await state.pc.setLocalDescription(ans);
    await apiPost('api/call_signal_send.php', {
      call_id: String(state.callId),
      type: 'answer',
      payload: JSON.stringify({ sdp: ans })
    });
    qs('#sheberCallStatus').textContent = 'В разговоре';
    setButtons({ mute:true, hangupBtn:true, accept:false, reject:false });
  }

  async function handleAnswer(payload) {
    if (!state.pc || !payload) return;
    const j = JSON.parse(payload);
    const sdp = j && j.sdp;
    if (!sdp) return;
    await state.pc.setRemoteDescription(new RTCSessionDescription(sdp));
    qs('#sheberCallStatus').textContent = 'В разговоре';
  }

  async function handleCandidate(payload) {
    if (!state.pc || !payload) return;
    try {
      const j = JSON.parse(payload);
      const cand = j && j.candidate;
      if (!cand) return;
      await state.pc.addIceCandidate(new RTCIceCandidate(cand));
    } catch {}
  }

  // When user presses Accept after offer already received
  async function acceptIfPendingOffer() {
    if (state._pendingOffer && state.pc) {
      const p = state._pendingOffer;
      state._pendingOffer = null;
      await handleOffer(p);
    }
  }

  // patch acceptIncoming to process pending offer
  const _acceptIncoming = acceptIncoming;
  acceptIncoming = async function () {
    await _acceptIncoming();
    await acceptIfPendingOffer().catch(() => {});
  };

  function bindCallButton() {
    const btn = qs('#orderCallBtn');
    if (!btn) return;
    btn.onclick = () => startCall();
  }

  function updateCallButtonVisibility() {
    const btn = qs('#orderCallBtn');
    if (!btn) return;
    if (!state.order || !state.user) { btn.style.display = 'none'; return; }

    const masterId = Number(state.order.master_id || 0);
    const st = String(state.order.status || 'new');
    const meId = Number(state.user.id || 0);
    const isClient = (Number(state.order.client_id || 0) === meId);
    const isMaster = (masterId > 0 && masterId === meId);
    const allowed = masterId > 0 && (isClient || isMaster) && (st !== 'completed' && st !== 'cancelled');

    btn.style.display = allowed ? 'inline-flex' : 'none';
  }

  // Public API
  window.SheberCall = {
    onChatOpened(order, user) {
      state.order = order || null;
      state.user = user || null;
      state.inChat = true;
      state.callId = 0;
      state.lastSignalId = 0;
      state.inCall = false;
      state.incoming = false;
      bindCallButton();
      updateCallButtonVisibility();
      startActivePolling();
    },
    onChatClosed() {
      state.inChat = false;
      stopTimers();
      if (state.inCall || state.callId) {
        hangup('local');
      }
      state.order = null;
      state.user = null;
    }
  };
})();
