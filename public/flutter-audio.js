// Pont audio natif Maranatha — v4
// Synchronise le lecteur premium HTML avec le vrai lecteur Flutter Android.
(function () {
  'use strict';

  if (window.__MARANATHA_NATIVE_BRIDGE_V4__) return;
  window.__MARANATHA_NATIVE_BRIDGE_V4__ = true;

  var initialized = false;
  var currentUrl = '';
  var playing = false;
  var nativeVolume = 0.70;
  var seeking = false;
  var waveTimer = null;
  var waveTick = 0;

  function byId(id) {
    return document.getElementById(id);
  }

  function bridgeAvailable() {
    return typeof window.FlutterAudio !== 'undefined' &&
      typeof window.FlutterAudio.postMessage === 'function';
  }

  function post(action, payload) {
    if (!bridgeAvailable()) return false;
    try {
      window.FlutterAudio.postMessage(
        JSON.stringify(Object.assign({ action: action }, payload || {}))
      );
      return true;
    } catch (error) {
      console.error('[Maranatha/FlutterAudio]', error);
      return false;
    }
  }

  function format(seconds) {
    var safe = Math.max(0, Math.floor(Number(seconds) || 0));
    var minutes = Math.floor(safe / 60);
    var secs = String(safe % 60).padStart(2, '0');
    return String(minutes).padStart(2, '0') + ':' + secs;
  }

  function titleFromUi() {
    var element = byId('audio-title') || byId('mp-title');
    var title = element && element.textContent ? element.textContent.trim() : '';
    return title || 'Prédication Maranatha';
  }

  function getPlayer() {
    return byId('premium-player') || byId('mini-player');
  }

  function getBars() {
    return Array.from(
      document.querySelectorAll('#premium-player .wave span, #mini-player .wave span')
    );
  }

  function resetNativeWave() {
    getBars().forEach(function (bar, index) {
      var base = 5 + ((index % 4) * 2);
      bar.style.height = base + 'px';
      bar.style.opacity = '0.45';
    });
  }

  function stopNativeWave() {
    if (waveTimer) {
      clearInterval(waveTimer);
      waveTimer = null;
    }
    resetNativeWave();
  }

  function startNativeWave() {
    if (waveTimer) return;
    var bars = getBars();
    if (!bars.length) return;

    waveTimer = setInterval(function () {
      if (!playing) {
        stopNativeWave();
        return;
      }

      waveTick += 1;
      bars.forEach(function (bar, index) {
        var a = Math.sin((waveTick + index * 1.7) * 0.62);
        var b = Math.sin((waveTick * 0.73 + index * 0.91) * 0.47);
        var energy = Math.max(0.08, Math.min(1, (a + b + 2) / 4));
        var height = 6 + Math.round(energy * 26);
        bar.style.height = height + 'px';
        bar.style.opacity = String(0.45 + energy * 0.55);
      });
    }, 95);
  }

  function applyVisualState(isPlaying) {
    playing = isPlaying === true;

    var player = getPlayer();
    if (player) {
      player.classList.toggle('playing', playing);
    }

    var icon = byId('play-icon');
    if (icon) {
      icon.innerHTML = playing
        ? '<rect x="7" y="5" width="3.5" height="14" rx="1"></rect><rect x="13.5" y="5" width="3.5" height="14" rx="1"></rect>'
        : '<path d="M8 5v14l11-7z"></path>';
    }

    var button = byId('play-button');
    if (button) {
      button.setAttribute('aria-label', playing ? 'Pause' : 'Lecture');
      button.setAttribute('title', playing ? 'Pause' : 'Lecture');
    }

    if (playing) {
      startNativeWave();
    } else {
      stopNativeWave();
    }
  }

  // Compatibilité avec l'ancien pont qui appelait setPlayIcon().
  window.setPlayIcon = applyVisualState;

  function updateProgress(position, duration) {
    position = Math.max(0, Number(position) || 0);
    duration = Math.max(0, Number(duration) || 0);

    var current = byId('current-time') || byId('time-current');
    var total = byId('duration') || byId('time-total');
    var seek = byId('seek');
    var fill = byId('mp-fill');

    if (current) current.textContent = format(position);

    if (total && duration > 0) {
      total.textContent = format(duration);
    }

    var pct = duration > 0
      ? Math.max(0, Math.min(100, (position / duration) * 100))
      : 0;

    if (seek && !seeking) {
      seek.value = String(pct);
    }

    if (fill) {
      fill.style.width = pct + '%';
    }
  }

  function updateVolumeUi(value) {
    nativeVolume = Math.max(0, Math.min(1, Number(value)));
    if (!Number.isFinite(nativeVolume)) nativeVolume = 0.70;

    var slider = byId('volume');
    var label = byId('volume-value');
    var mini = byId('volume-mini-level');
    var percent = Math.round(nativeVolume * 100);

    if (slider) slider.value = String(percent);
    if (label) label.textContent = percent + '%';
    if (mini) mini.style.width = percent + '%';

    var button = byId('volume-button');
    if (button) {
      button.setAttribute(
        'aria-label',
        percent === 0 ? 'Volume coupé' : 'Volume ' + percent + '%'
      );
      button.setAttribute(
        'title',
        percent === 0 ? 'Volume coupé' : 'Volume ' + percent + '%'
      );
    }
  }

  function prepareNative(url, title) {
    if (!url) return;

    currentUrl = String(url);

    // Le <audio> HTML n'est plus la source sonore dans l'application.
    var audio = byId('main-audio');
    if (audio) {
      try { audio.pause(); } catch (_) {}
      try { audio.removeAttribute('src'); } catch (_) {}
      try { audio.load(); } catch (_) {}
    }

    applyVisualState(false);

    post('autoplay', {
      url: currentUrl,
      titre: title || titleFromUi()
    });

    // Réapplique le volume choisi après le lancement natif.
    setTimeout(function () {
      post('volume', { value: nativeVolume });
    }, 250);
  }

  function fetchLiveAndPrepare() {
    fetch('/api/sermons', { cache: 'no-store' })
      .then(function (response) {
        return response.ok ? response.json() : [];
      })
      .then(function (items) {
        if (!Array.isArray(items)) return;

        var live = items.find(function (item) {
          return item &&
            item.statut === 'en_cours' &&
            item.audioUrl;
        });

        if (!live) return;

        var title = byId('audio-title') || byId('mp-title');
        if (title) {
          title.textContent = live.titre || 'Prédication Maranatha';
        }

        // Ne relance pas toutes les 60 secondes un sermon que l'utilisateur a mis en pause.
        if (String(live.audioUrl) === currentUrl) return;

        prepareNative(live.audioUrl, live.titre);
      })
      .catch(function (error) {
        console.warn('[Maranatha] Vérification audio impossible', error);
      });
  }

  function installNativeControls() {
    // Capture avant les anciens handlers HTML afin qu'ils ne commandent plus
    // main-audio dans l'application Android.
    document.addEventListener('pointerdown', function (event) {
      if (!bridgeAvailable()) return;
      var target = event.target && event.target.closest
        ? event.target.closest('#play-button')
        : null;
      if (!target) return;
      event.stopImmediatePropagation();
    }, true);

    document.addEventListener('click', function (event) {
      if (!bridgeAvailable()) return;

      var target = event.target && event.target.closest
        ? event.target.closest('#play-button, #previous-button, #next-button')
        : null;

      if (!target) return;

      event.preventDefault();
      event.stopImmediatePropagation();

      if (target.id === 'play-button') {
        post('toggle', {
          url: currentUrl,
          titre: titleFromUi()
        });
        return;
      }

      if (target.id === 'previous-button') {
        post('skipBack');
        return;
      }

      if (target.id === 'next-button') {
        post('skipForward');
      }
    }, true);

    document.addEventListener('input', function (event) {
      if (!bridgeAvailable()) return;
      var target = event.target;
      if (!target) return;

      if (target.id === 'seek') {
        seeking = true;
        var pct = Math.max(0, Math.min(1, Number(target.value || 0) / 100));
        post('seek', { pct: pct });
        event.stopImmediatePropagation();
        return;
      }

      if (target.id === 'volume') {
        var level = Math.max(0, Math.min(1, Number(target.value || 0) / 100));
        updateVolumeUi(level);
        post('volume', { value: level });
      }
    }, true);

    document.addEventListener('change', function (event) {
      if (!bridgeAvailable()) return;
      var target = event.target;
      if (target && target.id === 'seek') {
        seeking = false;
        var pct = Math.max(0, Math.min(1, Number(target.value || 0) / 100));
        post('seek', { pct: pct });
        event.stopImmediatePropagation();
      }
    }, true);
  }

  function init() {
    if (initialized || !bridgeAvailable()) return false;

    initialized = true;
    window.__MARANATHA_NATIVE_APP__ = true;

    window.preparerAudio = function (url) {
      if (!url) return;
      if (String(url) === currentUrl) return;
      prepareNative(url, titleFromUi());
    };

    window.ouvrirAudio = window.preparerAudio;

    window.demarrerOuToggle = function () {
      post('toggle', {
        url: currentUrl,
        titre: titleFromUi()
      });
    };

    window.togglePlay = window.demarrerOuToggle;
    window.skipBack = function () { post('skipBack'); };
    window.skipForward = function () { post('skipForward'); };

    window.setNativeVolume = function (value) {
      updateVolumeUi(value);
      post('volume', { value: nativeVolume });
    };

    window._flutterUpdate = function (data) {
      data = data || {};

      if (Object.prototype.hasOwnProperty.call(data, 'playing')) {
        applyVisualState(data.playing === true);
      }

      if (
        Object.prototype.hasOwnProperty.call(data, 'pos') ||
        Object.prototype.hasOwnProperty.call(data, 'dur')
      ) {
        updateProgress(
          Object.prototype.hasOwnProperty.call(data, 'pos') ? data.pos : 0,
          Object.prototype.hasOwnProperty.call(data, 'dur') ? data.dur : 0
        );
      }

      if (Object.prototype.hasOwnProperty.call(data, 'volume')) {
        updateVolumeUi(data.volume);
      }
    };

    window._sermonTermine = function () {
      currentUrl = '';
      applyVisualState(false);
      updateProgress(0, 0);
    };

    installNativeControls();
    updateVolumeUi(nativeVolume);
    applyVisualState(false);

    post('volume', { value: nativeVolume });

    setTimeout(fetchLiveAndPrepare, 700);

    document.addEventListener('visibilitychange', function () {
      if (!document.hidden) {
        setTimeout(fetchLiveAndPrepare, 250);
      }
    });

    console.log('[Maranatha] Pont audio natif v4 actif');
    return true;
  }

  var attempts = 0;
  var timer = setInterval(function () {
    attempts += 1;
    if (init() || attempts >= 80) {
      clearInterval(timer);
    }
  }, 150);

  window.addEventListener('pageshow', function () {
    if (initialized) {
      setTimeout(fetchLiveAndPrepare, 250);
    } else {
      init();
    }
  });

  document.addEventListener('DOMContentLoaded', init);
})();