const express = require('express');
const multer = require('multer');
const adminOnly = require('../utils/adminAuth');
const {
  uploadImage,
  uploadLibraryAsset,
} = require('../utils/mediaCloudinary');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 60 * 1024 * 1024 },
});

function extension(name) {
  const match = String(name || '').toLowerCase().match(/\.[a-z0-9]+$/);
  return match ? match[0] : '';
}

function validateKind(file, kind) {
  const mime = String(file?.mimetype || '').toLowerCase();
  const ext = extension(file?.originalname);

  const rules = {
    photo: () => mime.startsWith('image/') && ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext),
    video: () => mime.startsWith('video/') || ['.mp4', '.webm', '.mov', '.m4v'].includes(ext),
    audio: () => mime.startsWith('audio/') || ['.mp3', '.m4a', '.aac', '.ogg', '.wav'].includes(ext),
    book: () => mime === 'application/pdf' || ext === '.pdf',
    pdf: () => mime === 'application/pdf' || ext === '.pdf',
  };

  return Boolean(rules[kind] && rules[kind]());
}

router.post('/image', adminOnly, upload.single('file'), async (req, res) => {
  try {
    if (!req.file || !validateKind(req.file, 'photo')) {
      return res.status(400).json({ error: 'Choisissez une image JPG, PNG ou WEBP.' });
    }
    if (req.file.size > 15 * 1024 * 1024) {
      return res.status(413).json({ error: 'Image trop lourde. Maximum 15 Mo.' });
    }

    const result = await uploadImage(req.file.buffer, req.file.originalname);
    return res.status(201).json({ success: true, ...result });
  } catch (error) {
    console.error('[uploads/image]', error.message);
    return res.status(500).json({ error: 'Upload image impossible' });
  }
});

router.post('/asset', adminOnly, upload.single('file'), async (req, res) => {
  try {
    const kind = String(req.query.kind || '').trim().toLowerCase();
    if (!req.file || !validateKind(req.file, kind)) {
      return res.status(400).json({ error: 'Le type du fichier ne correspond pas au contenu choisi.' });
    }

    const result = await uploadLibraryAsset(
      req.file.buffer,
      req.file.originalname,
      kind,
    );

    return res.status(201).json({ success: true, kind, ...result });
  } catch (error) {
    console.error('[uploads/asset]', error.message);
    return res.status(500).json({ error: 'Upload fichier impossible' });
  }
});

router.use((error, _req, res, _next) => {
  if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'Fichier trop lourd. Maximum 60 Mo.' });
  }
  return res.status(400).json({ error: 'Fichier invalide' });
});

module.exports = router;
