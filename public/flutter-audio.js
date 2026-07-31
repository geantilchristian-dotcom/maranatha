// Pont audio natif Maranatha — v3
// Ce fichier ne fonctionne que dans l'application Flutter WebView.
(function () {
  'use strict';

  var initialized = false;
  var currentUrl = '';
  var playing = false;

  function bridgeAvailable() {
    return typeof window.FlutterAudio !== 'undefined' &&
      typeof window.FlutterAudio.postMessage === 'function';
  }

  function post(action, payload) {
    if (!bridgeAvailable()) return false;

    try {
      window.FlutterAudio.postMessage(JSON.stringify(Object.assign({ action: action }, payload || {})));
      return true;
    } catch (error) {
      console.error('[Maranatha/FlutterAudio]', error);
      return false;
    }
  }

  function titleFromUi() {
    var element = document.getElementById('mp-title');
    var title = element && element.textContent ? element.textContent.trim() : '';
    return title || 'Prédication Maranatha';
  }

  function prepareNative(url, title) {
    if (!url) return;

    currentUrl = url;
    window.activeAudioUrl = url;
    window.userPaused = false;
    try { activeAudioUrl = url; } catch (_) {}
    try { userPaused = false; } catch (_) {}

    var audio = document.getElementById('main-audio');
    if (audio) {
      audio.pause();
      audio.removeAttribute('src');
      audio.load();
      audio.ontimeupdate = null;
      audio.onended = null;
    }

    var player = document.getElementById('mini-player');
    if (player) player.classList.add('visible');

    if (typeof window.setPlayIcon === 'function') {
      window.setPlayIcon(false);
    }

    post('autoplay', {
      url: url,
      titre: title || titleFromUi(),
    });
  }

  function init() {
    if (initialized || !bridgeAvailable()) return false;
    initialized = true;
    window.__MARANATHA_NATIVE_APP__ = true;

    window.preparerAudio = function (url) {
      if (!url) return;
      if (url === currentUrl && playing) return;
      prepareNative(url, titleFromUi());
    };

    window.ouvrirAudio = function (url) {
      if (!url) return;
      if (url === currentUrl && playing) return;
      prepareNative(url, titleFromUi());
    };

    window.demarrerOuToggle = function () {
      post('toggle', { url: currentUrl, titre: titleFromUi() });
    };
    window.togglePlay = window.demarrerOuToggle;

    window.seekAudio = function (event) {
      var track = document.getElementById('mp-progress');
      if (!track || !track.offsetWidth) return;
      post('seek', { pct: event.offsetX / track.offsetWidth });
    };

    window.skipBack = function () { post('skipBack'); };
    window.skipForward = function () { post('skipForward'); };

    window._flutterUpdate = function (data) {
      data = data || {};
      var position = Number(data.pos || 0);
      var duration = Number(data.dur || 0);
      playing = data.playing === true;

      if (typeof window.setPlayIcon === 'function') {
        window.setPlayIcon(playing);
      }

      function format(seconds) {
        var safe = Math.max(0, Math.floor(seconds || 0));
        return Math.floor(safe / 60) + ':' + String(safe % 60).padStart(2, '0');
      }

      var fill = document.getElementById('mp-fill');
      var current = document.getElementById('time-current');
      var total = document.getElementById('time-total');

      if (fill) {
        fill.style.width = duration > 0 ? Math.min(100, (position / duration) * 100) + '%' : '0%';
      }
      if (current) current.textContent = format(position);
      if (total) total.textContent = format(duration);
    };

    window._sermonTermine = function () {
      playing = false;
      currentUrl = '';
      window.activeAudioUrl = '';
      try { activeAudioUrl = ''; } catch (_) {}
      if (typeof window.setPlayIcon === 'function') window.setPlayIcon(false);

      var fill = document.getElementById('mp-fill');
      var current = document.getElementById('time-current');
      if (fill) fill.style.width = '0%';
      if (current) current.textContent = '0:00';
    };

    // Rattrape un sermon déjà démarré avant l'ouverture de l'application.
    setTimeout(function () {
      fetch('/api/sermons', { cache: 'no-store' })
        .then(function (response) { return response.ok ? response.json() : []; })
        .then(function (items) {
          if (!Array.isArray(items)) return;
          var live = items.find(function (item) {
            return item && item.statut === 'en_cours' && item.audioUrl;
          });
          if (live && !playing) {
            var title = document.getElementById('mp-title');
            if (title) title.textContent = live.titre || 'Prédication Maranatha';
            prepareNative(live.audioUrl, live.titre);
          }
        })
        .catch(function () {});
    }, 900);

    console.log('[Maranatha] Pont audio natif v3 actif');
    return true;
  }

  var attempts = 0;
  var timer = setInterval(function () {
    attempts += 1;
    if (init() || attempts >= 60) clearInterval(timer);
  }, 200);

  window.addEventListener('pageshow', init);
  document.addEventListener('DOMContentLoaded', init);
})();
