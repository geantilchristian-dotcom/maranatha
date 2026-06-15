const express = require('express');
const router  = express.Router();
const https   = require('https');

const cache = new Map(); // "bookNum:chapter" → [{verse, text}]

function httpsGet(url, redirectCount = 0) {
  if (redirectCount > 5) return Promise.reject(new Error('Trop de redirections'));
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const req = https.get({
      hostname: parsed.hostname,
      path:     parsed.pathname + parsed.search,
      headers:  { 'User-Agent': 'MaranathaApp/1.0', Accept: 'application/json' },
    }, res => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        const loc = res.headers.location;
        if (!loc) return reject(new Error('Redirect sans Location'));
        const next = loc.startsWith('http') ? loc : `https://${parsed.hostname}${loc}`;
        return httpsGet(next, redirectCount + 1).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) return reject(new Error('HTTP ' + res.statusCode));
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', c => raw += c);
      res.on('end', () => resolve(raw));
    });
    req.on('error', reject);
    req.setTimeout(9000, () => { req.destroy(); reject(new Error('timeout')); });
  });
}

// ── Source 1 : getbible.net v2 (livres numérotés 1-66) ──
async function fetchGetBible(bookNum, chapter) {
  const raw  = await httpsGet(`https://getbible.net/v2/lsg/${bookNum}/${chapter}.json`);
  const data = JSON.parse(raw);
  if (!data.verses) throw new Error('pas de versets');
  return Object.values(data.verses).map(v => ({ verse: Number(v.verse), text: v.text.trim() }));
}

// ── Source 2 : bible-api.com (noms anglais, traduction lsg) ──
const BOOK_APIS = [
  'genesis','exodus','leviticus','numbers','deuteronomy','joshua','judges','ruth',
  '1+samuel','2+samuel','1+kings','2+kings','1+chronicles','2+chronicles','ezra',
  'nehemiah','esther','job','psalms','proverbs','ecclesiastes','song+of+solomon',
  'isaiah','jeremiah','lamentations','ezekiel','daniel','hosea','joel','amos',
  'obadiah','jonah','micah','nahum','habakkuk','zephaniah','haggai','zechariah','malachi',
  'matthew','mark','luke','john','acts','romans','1+corinthians','2+corinthians',
  'galatians','ephesians','philippians','colossians','1+thessalonians','2+thessalonians',
  '1+timothy','2+timothy','titus','philemon','hebrews','james','1+peter','2+peter',
  '1+john','2+john','3+john','jude','revelation',
];

async function fetchBibleApi(bookNum, chapter) {
  const raw  = await httpsGet(`https://bible-api.com/${BOOK_APIS[bookNum-1]}+${chapter}?translation=lsg`);
  const data = JSON.parse(raw);
  if (!data.verses || !data.verses.length) throw new Error('pas de versets');
  return data.verses.map(v => ({ verse: Number(v.verse), text: v.text.trim() }));
}

// ── Source 3 : bolls.life ──
async function fetchBolls(bookNum, chapter) {
  const raw    = await httpsGet(`https://bolls.life/get-text/LSG/${bookNum}/${chapter}/`);
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed) || !parsed.length) throw new Error('pas de versets');
  return parsed.map((v, i) => ({ verse: i + 1, text: String(v.text || v).trim() }));
}

// ── Route GET /api/bible/:bookNum/:chapter ──
router.get('/:bookNum/:chapter', async (req, res) => {
  const bookNum = parseInt(req.params.bookNum, 10);
  const chapter = parseInt(req.params.chapter, 10);
  if (!bookNum || !chapter || bookNum < 1 || bookNum > 66 || chapter < 1)
    return res.status(400).json({ error: 'Paramètres invalides' });

  const key = `${bookNum}:${chapter}`;
  if (cache.has(key)) return res.json({ verses: cache.get(key), cached: true });

  const sources = [fetchGetBible, fetchBibleApi, fetchBolls];
  const errors  = [];
  for (const fn of sources) {
    try {
      const verses = await fn(bookNum, chapter);
      cache.set(key, verses);
      return res.json({ verses });
    } catch (e) {
      errors.push(`${fn.name}: ${e.message}`);
    }
  }
  console.error(`[bible] Echec toutes sources book=${bookNum} ch=${chapter}:`, errors);
  res.status(502).json({ error: 'Bible temporairement indisponible', details: errors });
});

module.exports = router;
