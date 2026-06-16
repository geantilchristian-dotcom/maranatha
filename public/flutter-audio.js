// flutter-audio.js — Pont natif Flutter/audioplayers (v20260616d)
// Injecté par server.js dans chaque réponse GET /.
//
// Fixes v20260616d :
//   • Bouton play/pause : ne plus appeler _origPreparer (qui reset l'icône à ▶)
//   • Pas de répétition : ReleaseMode.stop géré côté Flutter + déduplication URL
//   • Fond : AudioContext stayAwake géré côté Flutter
//   • Fin de sermon : _sermonTermine() → affiche toast + icône ▶

(function () {
  function init() {
    if (typeof FlutterAudio === 'undefined') return; // navigateur normal — rien à faire

    // ── État interne ────────────────────────────────────────────────────
    var _isPlaying   = false;
    var _currentUrl  = '';

    // ── Override preparerAudio ──────────────────────────────────────────
    // IMPORTANT : on ne appelle PAS _origPreparer car il appelle setPlayIcon(false)
    // ce qui remet le bouton en ▶ juste après qu'on l'a mis en ⏸.
    // On gère nous-mêmes tout ce qui est nécessaire.
    window.preparerAudio = function (url) {
      if (!url) return;
      // Déduplication : même URL déjà en cours → ne pas redémarrer
      if (url === _currentUrl && _isPlaying) return;
      _currentUrl = url;

      // Mise à jour minimale de l'élément <audio> (pour compatibilité UI)
      var audio = document.getElementById('main-audio');
      if (audio) {
        audio.src = url;
        // Réinitialise les handlers natifs de l'élément audio (ils ne seront pas utilisés)
        audio.ontimeupdate = null;
        audio.onended = null;
      }
      window.activeAudioUrl = url;
      window.userPaused     = false;

      // Afficher le player si caché
      var mp = document.getElementById('mini-player');
      if (mp) mp.classList.add('visible');

      // Récupérer le titre depuis l'UI
      var titre = (document.getElementById('mp-title') || {}).textContent || 'Prédication';

      // Mettre l'icône en ▶ le temps que Flutter confirme (délai sécuritaire)
      if (typeof setPlayIcon === 'function') setPlayIcon(false);

      // Envoyer à Flutter pour lecture native
      FlutterAudio.postMessage(JSON.stringify({ action: 'autoplay', url: url, titre: titre }));
    };

    // ── Override ouvrirAudio ────────────────────────────────────────────
    // Même logique que preparerAudio
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
    // Appelé par Flutter toutes les secondes avec {pos, dur, playing}
    window._flutterUpdate = function (data) {
      var pos     = data.pos     || 0;
      var dur     = data.dur     || 0;
      var playing = data.playing || false;

      _isPlaying = playing;

      // Mettre à jour le bouton play/pause
      if (typeof setPlayIcon === 'function') setPlayIcon(playing);

      // Mettre à jour la barre de progression et les timecodes
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
    // Appelé par Flutter quand l'audio se termine (onPlayerComplete)
    window._sermonTermine = function () {
      _isPlaying  = false;
      _currentUrl = '';
      window.activeAudioUrl = '';
      if (typeof setPlayIcon === 'function') setPlayIcon(false);
      // Remettre la barre à 0
      var fill = document.getElementById('mp-fill');
      var tc   = document.getElementById('time-current');
      if (fill) fill.style.width = '0%';
      if (tc)   tc.textContent = '0:00';
      // Toast de confirmation
      if (typeof showToast === 'function') showToast('Sermon terminé — disponible dans la bibliothèque');
    };

    console.log('[FlutterAudio] Pont natif v20260616d initialisé');
  }

  if (document.readyState === 'complete') { init(); }
  else { window.addEventListener('load', init); }
})();
