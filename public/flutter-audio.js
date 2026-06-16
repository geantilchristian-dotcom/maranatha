// flutter-audio.js — Pont natif Flutter/audioplayers (v20260617a)
// Injecté par server.js dans chaque réponse GET /.
//
// v20260617a :
//   • Retry si FlutterAudio n'est pas encore injecté (race condition WebView)
//   • Vérification sermon actif au démarrage (sermon démarré avant chargement page)

(function () {
  var _inited = false;

  function init() {
    if (_inited) return;
    if (typeof FlutterAudio === 'undefined') return;
    _inited = true;

    // ── État interne ────────────────────────────────────────────────────
    var _isPlaying   = false;
    var _currentUrl  = '';

    // ── Override preparerAudio ──────────────────────────────────────────
    window.preparerAudio = function (url) {
      if (!url) return;
      if (url === _currentUrl && _isPlaying) return;
      _currentUrl = url;

      var audio = document.getElementById('main-audio');
      if (audio) { audio.src = url; audio.ontimeupdate = null; audio.onended = null; }
      window.activeAudioUrl = url;
      window.userPaused     = false;

      var mp = document.getElementById('mini-player');
      if (mp) mp.classList.add('visible');

      var titre = (document.getElementById('mp-title') || {}).textContent || 'Prédication';
      if (typeof setPlayIcon === 'function') setPlayIcon(false);

      FlutterAudio.postMessage(JSON.stringify({ action: 'autoplay', url: url, titre: titre }));
    };

    // ── Override ouvrirAudio ────────────────────────────────────────────
    window.ouvrirAudio = function (url) {
      if (!url) return;
      if (url === _currentUrl && _isPlaying) return;
      _currentUrl = url;

      var audio = document.getElementById('main-audio');
      if (audio) { audio.src = url; audio.ontimeupdate = null; audio.onended = null; }
      window.activeAudioUrl = url;
      window.userPaused     = false;

      var mp = document.getElementById('mini-player');
      if (mp) mp.classList.add('visible');

      var titre = (document.getElementById('mp-title') || {}).textContent || 'Prédication';
      if (typeof setPlayIcon === 'function') setPlayIcon(false);
      FlutterAudio.postMessage(JSON.stringify({ action: 'autoplay', url: url, titre: titre }));
      window._pendingAutoplay = null;
    };

    // ── Override demarrerOuToggle ───────────────────────────────────────
    window.demarrerOuToggle = function () {
      FlutterAudio.postMessage(JSON.stringify({ action: 'toggle' }));
    };
    window.togglePlay = window.demarrerOuToggle;

    // ── Override seek / skip ────────────────────────────────────────────
    window.seekAudio = function (e) {
      var track = document.getElementById('mp-progress');
      if (!track) return;
      FlutterAudio.postMessage(JSON.stringify({ action: 'seek', pct: e.offsetX / track.offsetWidth }));
    };
    window.skipBack    = function () { FlutterAudio.postMessage(JSON.stringify({ action: 'skipBack' })); };
    window.skipForward = function () { FlutterAudio.postMessage(JSON.stringify({ action: 'skipForward' })); };

    // ── Récepteur progression Flutter → UI ─────────────────────────────
    window._flutterUpdate = function (data) {
      var pos     = data.pos     || 0;
      var dur     = data.dur     || 0;
      var playing = data.playing || false;

      _isPlaying = playing;
      if (typeof setPlayIcon === 'function') setPlayIcon(playing);

      if (dur > 0) {
        function fmt(s) {
          return Math.floor(s / 60) + ':' + String(Math.floor(s % 60)).padStart(2, '0');
        }
        var fill = document.getElementById('mp-fill');
        var tc   = document.getElementById('time-current');
        var tt   = document.getElementById('time-total');
        if (fill) fill.style.width = ((pos / dur) * 100) + '%';
        if (tc)   tc.textContent = fmt(pos);
        if (tt)   tt.textContent = fmt(dur);
      }
    };

    // ── Callback fin de sermon ──────────────────────────────────────────
    window._sermonTermine = function () {
      _isPlaying  = false;
      _currentUrl = '';
      window.activeAudioUrl = '';
      if (typeof setPlayIcon === 'function') setPlayIcon(false);
      var fill = document.getElementById('mp-fill');
      var tc   = document.getElementById('time-current');
      if (fill) fill.style.width = '0%';
      if (tc)   tc.textContent = '0:00';
      if (typeof showToast === 'function') showToast('Sermon terminé — disponible dans la bibliothèque');
    };

    // ── Vérifier si un sermon est déjà en cours au démarrage ───────────
    // (cas : sermon démarré avant que la page soit chargée)
    setTimeout(function() {
      try {
        fetch('/api/sermons')
          .then(function(r){ return r.ok ? r.json() : []; })
          .then(function(sermons) {
            if (!Array.isArray(sermons)) return;
            var live = sermons.find(function(s){ return s.statut === 'en_cours' && s.audioUrl; });
            if (live && live.audioUrl && !_isPlaying) {
              window.preparerAudio(live.audioUrl);
            }
          });
      } catch(e) {}
    }, 2000);

    console.log('[FlutterAudio] Pont natif v20260617a initialisé');
  }

  // ── Retry si FlutterAudio pas encore disponible ─────────────────────
  function tryInit(n) {
    if (_inited) return;
    init();
    if (!_inited && n > 0) setTimeout(function(){ tryInit(n - 1); }, 300);
  }

  if (document.readyState === 'complete') { tryInit(10); }
  else { window.addEventListener('load', function(){ tryInit(10); }); }
})();
