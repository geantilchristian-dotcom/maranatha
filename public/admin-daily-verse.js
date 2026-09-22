(function () {
  'use strict';

  const API_BASE = window.location.origin + '/api';

  function auth() {
    try {
      if (typeof window.authHeaders === 'function') {
        return window.authHeaders();
      }
    } catch (_error) {}

    return {};
  }

  function byId(id) {
    return document.getElementById(id);
  }

  function normalizeHex(value, fallback) {
    const text = String(value || '').trim();

    if (/^#[0-9a-fA-F]{6}$/.test(text)) {
      return text.toUpperCase();
    }

    return fallback;
  }

  function ensureStyles() {
    if (byId('daily-verse-admin-style')) return;

    const style = document.createElement('style');
    style.id = 'daily-verse-admin-style';

    style.textContent = `
      .dv-admin-card{
        margin-top:24px;
      }

      .dv-grid{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:14px;
      }

      .dv-full{
        grid-column:1 / -1;
      }

      .dv-colors{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:12px;
      }

      .dv-color-line{
        display:flex;
        gap:9px;
        align-items:center;
      }

      .dv-color-line input[type="color"]{
        width:46px;
        height:42px;
        padding:0;
        border:0;
        border-radius:9px;
        background:transparent;
        cursor:pointer;
      }

      .dv-preview{
        display:grid;
        grid-template-columns:105px minmax(0,1fr);
        min-height:150px;
        border-radius:12px;
        overflow:hidden;
        border:1px solid rgba(255,255,255,.10);
        margin-top:6px;
      }

      .dv-preview-side{
        padding:16px 13px;
        display:flex;
        flex-direction:column;
        justify-content:space-between;
        font-size:8px;
        font-weight:900;
        letter-spacing:1.6px;
        line-height:1.4;
      }

      .dv-preview-main{
        padding:22px 18px;
        display:flex;
        flex-direction:column;
      }

      .dv-preview-verse{
        font-size:14px;
        line-height:1.5;
        font-weight:700;
        font-style:italic;
      }

      .dv-preview-ref{
        margin-top:8px;
        font-size:10px;
        opacity:.70;
      }

      .dv-preview-motto{
        margin-top:auto;
        font-size:8px;
        letter-spacing:.9px;
        font-weight:900;
      }

      .dv-actions{
        display:flex;
        justify-content:flex-end;
        align-items:center;
        gap:12px;
        margin-top:14px;
      }

      .dv-status{
        color:rgba(255,255,255,.45);
        font-size:10px;
      }

      .dv-toggle{
        display:flex;
        align-items:center;
        gap:10px;
        color:rgba(255,255,255,.75);
        font-size:11px;
      }

      @media(max-width:650px){
        .dv-grid,
        .dv-colors{
          grid-template-columns:1fr;
        }

        .dv-preview{
          grid-template-columns:82px minmax(0,1fr);
        }
      }
    `;

    document.head.appendChild(style);
  }

  function template() {
    return `
      <div class="section-title dv-admin-card">
        <svg width="17" height="17" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
          <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
        </svg>
        Verset du jour — Accueil
      </div>

      <div class="card" id="daily-verse-admin">
        <div class="dv-grid">
          <div class="form-group dv-full">
            <label>Texte du verset *</label>
            <textarea id="dv-text"
              rows="4"
              placeholder="Ex: Car je connais les projets que j'ai formés sur vous..."></textarea>
          </div>

          <div class="form-group">
            <label>Référence biblique</label>
            <input
              id="dv-reference"
              type="text"
              placeholder="Ex: Jérémie 29:11" />
          </div>

          <div class="form-group">
            <label>Publication</label>
            <label class="dv-toggle">
              <input id="dv-active" type="checkbox" />
              Afficher ce verset sur l'accueil
            </label>
          </div>

          <div class="dv-colors dv-full">
            <div class="form-group">
              <label>Couleur du fond</label>

              <div class="dv-color-line">
                <input
                  id="dv-bg-picker"
                  type="color"
                  value="#F5F9FF" />

                <input
                  id="dv-bg"
                  type="text"
                  value="#F5F9FF"
                  placeholder="#F5F9FF" />
              </div>
            </div>

            <div class="form-group">
              <label>Couleur du texte</label>

              <div class="dv-color-line">
                <input
                  id="dv-text-picker"
                  type="color"
                  value="#102A56" />

                <input
                  id="dv-text-color"
                  type="text"
                  value="#102A56"
                  placeholder="#102A56" />
              </div>
            </div>
          </div>

          <div class="form-group dv-full">
            <label>Aperçu avant publication</label>

            <div id="dv-preview" class="dv-preview">
              <div id="dv-preview-side" class="dv-preview-side">
                <div>VERSET<br>DU JOUR</div>
                <div>▭</div>
                <div>AUJOURD'HUI</div>
              </div>

              <div id="dv-preview-main" class="dv-preview-main">
                <div id="dv-preview-verse" class="dv-preview-verse">
                  Votre verset apparaîtra ici.
                </div>

                <div id="dv-preview-ref" class="dv-preview-ref">
                  Référence
                </div>

                <div class="dv-preview-motto">
                  UNE FOI • UN PEUPLE • UNE MISSION
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="dv-actions">
          <span id="dv-status" class="dv-status"></span>

          <button
            type="button"
            class="btn-submit"
            id="dv-publish">
            Publier le verset
          </button>
        </div>
      </div>
    `;
  }

  function updatePreview() {
    const bg = normalizeHex(
      byId('dv-bg')?.value,
      '#F5F9FF',
    );

    const text = normalizeHex(
      byId('dv-text-color')?.value,
      '#102A56',
    );

    const verse =
      (byId('dv-text')?.value || '').trim() ||
      'Votre verset apparaîtra ici.';

    const reference =
      (byId('dv-reference')?.value || '').trim() ||
      'Référence';

    const preview = byId('dv-preview');
    const side = byId('dv-preview-side');
    const main = byId('dv-preview-main');
    const verseEl = byId('dv-preview-verse');
    const refEl = byId('dv-preview-ref');

    if (!preview || !side || !main || !verseEl || !refEl) {
      return;
    }

    main.style.background = bg;
    side.style.background = bg;
    main.style.color = text;
    side.style.color = text;
    verseEl.style.color = text;
    refEl.style.color = text;

    verseEl.textContent = `« ${verse} »`;
    refEl.textContent = reference;
  }

  function wireColorPair(textId, pickerId) {
    const text = byId(textId);
    const picker = byId(pickerId);

    if (!text || !picker) return;

    text.addEventListener('input', function () {
      const value = normalizeHex(text.value, picker.value);

      if (/^#[0-9A-F]{6}$/.test(value)) {
        picker.value = value;
      }

      updatePreview();
    });

    picker.addEventListener('input', function () {
      text.value = picker.value.toUpperCase();
      updatePreview();
    });
  }

  async function loadDailyVerse() {
    const status = byId('dv-status');

    try {
      if (status) status.textContent = 'Chargement...';

      const response = await fetch(
        API_BASE + '/settings/home',
        {
          headers: {
            Accept: 'application/json',
          },
        },
      );

      if (!response.ok) {
        throw new Error('HTTP ' + response.status);
      }

      const data = await response.json();
      const verse =
        data &&
        data.dailyVerse &&
        typeof data.dailyVerse === 'object'
          ? data.dailyVerse
          : {};

      byId('dv-text').value =
        String(verse.text || '');

      byId('dv-reference').value =
        String(verse.reference || '');

      byId('dv-active').checked =
        verse.active === true;

      const bg = normalizeHex(
        verse.backgroundColor,
        '#F5F9FF',
      );

      const textColor = normalizeHex(
        verse.textColor,
        '#102A56',
      );

      byId('dv-bg').value = bg;
      byId('dv-bg-picker').value = bg;

      byId('dv-text-color').value = textColor;
      byId('dv-text-picker').value = textColor;

      updatePreview();

      if (status) {
        status.textContent =
          verse.active === true
            ? 'Verset actuellement publié'
            : 'Aucun verset actif';
      }
    } catch (error) {
      if (status) {
        status.textContent =
          'Impossible de charger le verset.';
      }
    }
  }

  async function publishDailyVerse() {
    const button = byId('dv-publish');
    const status = byId('dv-status');

    const verseText =
      (byId('dv-text')?.value || '').trim();

    if (!verseText) {
      window.alert(
        'Écrivez le texte du verset avant de publier.',
      );
      return;
    }

    const payload = {
      dailyVerse: {
        active: byId('dv-active')?.checked === true,
        text: verseText,
        reference:
          (byId('dv-reference')?.value || '').trim(),
        backgroundColor: normalizeHex(
          byId('dv-bg')?.value,
          '#F5F9FF',
        ),
        textColor: normalizeHex(
          byId('dv-text-color')?.value,
          '#102A56',
        ),
      },
    };

    try {
      if (button) button.disabled = true;
      if (status) status.textContent = 'Publication...';

      const response = await fetch(
        API_BASE + '/settings/home',
        {
          method: 'PUT',
          headers: {
            ...auth(),
            'Content-Type': 'application/json',
            Accept: 'application/json',
          },
          body: JSON.stringify(payload),
        },
      );

      const data = await response
        .json()
        .catch(() => ({}));

      if (!response.ok) {
        throw new Error(
          data.error ||
          data.message ||
          'Publication impossible.',
        );
      }

      if (status) {
        status.textContent =
          payload.dailyVerse.active
            ? 'Publié avec succès'
            : 'Enregistré mais masqué sur l’accueil';
      }
    } catch (error) {
      if (status) {
        status.textContent =
          error && error.message
            ? error.message
            : 'Publication impossible.';
      }
    } finally {
      if (button) button.disabled = false;
    }
  }

  function inject() {
    ensureStyles();

    const pane = byId('pane-params');

    if (!pane) return;
    if (byId('daily-verse-admin')) return;

    pane.insertAdjacentHTML(
      'afterbegin',
      template(),
    );

    const ids = [
      'dv-text',
      'dv-reference',
      'dv-active',
    ];

    ids.forEach(function (id) {
      const field = byId(id);

      if (field) {
        field.addEventListener(
          'input',
          updatePreview,
        );

        field.addEventListener(
          'change',
          updatePreview,
        );
      }
    });

    wireColorPair(
      'dv-bg',
      'dv-bg-picker',
    );

    wireColorPair(
      'dv-text-color',
      'dv-text-picker',
    );

    const publish = byId('dv-publish');

    if (publish) {
      publish.addEventListener(
        'click',
        publishDailyVerse,
      );
    }

    document
      .querySelectorAll(
        '.tab-btn[data-tab="params"]',
      )
      .forEach(function (button) {
        button.addEventListener(
          'click',
          loadDailyVerse,
        );
      });

    loadDailyVerse();
  }

  if (document.readyState === 'loading') {
    document.addEventListener(
      'DOMContentLoaded',
      inject,
    );
  } else {
    inject();
  }
})();
