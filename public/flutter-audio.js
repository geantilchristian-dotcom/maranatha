// flutter-audio.js — Pont natif Flutter/audioplayers (v20260616c)
// Injecté par server.js dans chaque réponse GET /.
// Override preparerAudio ET ouvrirAudio pour lecture native sans clic.

(function () {
  function init() {
    if (typeof FlutterAudio === 'undefined') return; // navigateur normal

    // Override preparerAudio ─ couvre l'ancien index.html (Render en cache)
    var _origPreparer = window.preparerAudio;
    window.preparerAudio = function (url) {
      if (_origPreparer) _origPreparer.call(window, url);
      if (!url) return;
      var titre = (document.getElementById('mp-title') || {}).textContent || 'Prédication';
      FlutterAudio.postMessage(JSON.stringify({ action: 'autoplay', url: url, titre: titre }));
      if (typeof setPlayIcon === 'function') setPlayIcon(true);
    };

    // Override ouvrirAudio ─ couvre le nouvel index.html
    window.ouvrirAudio = function (url) {
      if (!url) return;
      var audio = document.getElementById('main-audio');
      if (audio) audio.src = url;
      window.activeAudioUrl = url;
      window.userPaused = false;
      var titre = (document.getElementById('mp-title') || {}).textContent || 'Prédication';
      FlutterAudio.postMessage(JSON.stringify({ action: 'autoplay', url: url, titre: titre }));
      if (typeof setPlayIcon === 'function') setPlayIcon(true);
      window._pendingAutoplay = null;
    };

    // Override demarrerOuToggle
    window.demarrerOuToggle = function () {
      FlutterAudio.postMessage(JSON.stringify({ action: 'toggle' }));
    };
    window.togglePlay = window.demarrerOuToggle;

    // Override seek / skip
    window.seekAudio = function (e) {
      var track = document.getElementById('mp-progress');
      if (!track) return;
      FlutterAudio.postMessage(JSON.stringify({ action: 'seek', pct: e.offsetX / track.offsetWidth }));
    };
    window.skipBack    = function () { FlutterAudio.postMessage(JSON.stringify({ action: 'skipBack' })); };
    window.skipForward = function () { FlutterAudio.postMessage(JSON.stringify({ action: 'skipForward' })); };

    // Récepteur progression Flutter → UI
    window._flutterUpdate = function (data) {
      var pos = data.pos, dur = data.dur, playing = data.playing;
      if (dur > 0) {
        function fmt(s) { return Math.floor(s/60)+':'+String(Math.floor(s%60)).padStart(2,'0'); }
        var fill = document.getElementById('mp-fill');
        var tc   = document.getElementById('time-current');
        var tt   = document.getElementById('time-total');
        if (fill) fill.style.width = ((pos/dur)*100) + '%';
        if (tc)   tc.textContent = fmt(pos);
        if (tt)   tt.textContent = fmt(dur);
      }
      if (typeof setPlayIcon === 'function') setPlayIcon(playing);
    };

    console.log('[FlutterAudio] Pont natif v20260616c initialisé');
  }

  if (document.readyState === 'complete') { init(); }
  else { window.addEventListener('load', init); }
})();
