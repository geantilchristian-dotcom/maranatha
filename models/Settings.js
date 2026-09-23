const mongoose = require('mongoose');
const heroBannerSchema =
  new mongoose.Schema(
    {
      id: {
        type: String,
        default: '',
      },
      imageUrl: {
        type: String,
        default: '',
      },
      title: {
        type: String,
        default: '',
      },
      link: {
        type: String,
        default: '#',
      },
      active: {
        type: Boolean,
        default: true,
      },
      text: {
        type: String,
        default: '',
      },
      reference: {
        type: String,
        default: '',
      },
      buttonLabel: {
        type: String,
        default: '',
      },
      ordre: {
        type: Number,
        default: 0,
      },
    },
    {
      _id: false,
    }
  );
const programmeItemSchema =
  new mongoose.Schema(
    {
      id: {
        type: String,
        default: '',
      },
      titre: {
        type: String,
        default: '',
      },
      badge: {
        type: String,
        default: 'PROGRAMME',
      },
      type: {
        type: String,
        default: '',
      },
      dateStr: {
        type: String,
        default: '',
      },
      heureStr: {
        type: String,
        default: '',
      },
      heureFin: {
        type: String,
        default: '',
      },
      lieu: {
        type: String,
        default: '',
      },
      pasteur: {
        type: String,
        default: '',
      },
      description: {
        type: String,
        default: '',
      },
      imageUrl: {
        type: String,
        default: '',
      },
      statut: {
        type: String,
        default: 'planifie',
      },
      cible: {
        type: String,
        default: 'programme',
      },
      visible: {
        type: Boolean,
        default: true,
      },
      ordre: {
        type: Number,
        default: 0,
      },
    },
    {
      _id: false,
    }
  );
const settingsSchema =
  new mongoose.Schema(
    {
      key: {
        type: String,
        default: 'splash',
        unique: true,
      },
      // =====================================================
      // SPLASH
      // =====================================================
      nomEglise: {
        type: String,
        default: 'Maranatha',
      },
      verset: {
        type: String,
        default:
          'Viens, Seigneur Jésus — Apocalypse 22 : 20',
      },
      sousTitre: {
        type: String,
        default: 'Ministère Évangélique',
      },
      logoUrl: {
        type: String,
        default: '/logo.jpg',
      },
      couleurFond: {
        type: String,
        default: '#001220',
      },
      couleurAccent: {
        type: String,
        default: '#D4AF37',
      },
      dureeSplash: {
        type: Number,
        default: 3,
      },
      // =====================================================
      // HOME
      // =====================================================
      youtubeUrl: {
        type: String,
        default: '',
      },
      ytLabel: {
        type: String,
        default: 'Regarder sur YouTube',
      },
      youtubeLinks: {
        type: [
          {
            url: {
              type: String,
              default: '',
            },
            label: {
              type: String,
              default: 'Regarder sur YouTube',
            },
          },
        ],
        default: [],
      },
      // Ancienne Parole du jour
      dailyVerse: {
        active: {
          type: Boolean,
          default: false,
        },
        text: {
          type: String,
          default: '',
        },
        reference: {
          type: String,
          default: '',
        },
        backgroundColor: {
          type: String,
          default: '#F5F9FF',
        },
        textColor: {
          type: String,
          default: '#102A56',
        },
      },
      // Nouvelle Parole du jour V3
      dailyWord: {
        type: mongoose.Schema.Types.Mixed,
        default: () => ({
          matin: null,
          soir: null,
          history: [],
        }),
      },
      heroBanners: {
        type: [heroBannerSchema],
        default: [],
      },
      programme: {
        type: [programmeItemSchema],
        default: [],
      },
      // =====================================================
      // DONS
      // =====================================================
      airtel: {
        type: String,
        default: '',
      },
      orange: {
        type: String,
        default: '',
      },
      vodacom: {
        type: String,
        default: '',
      },
      nomTitulaire: {
        type: String,
        default: '',
      },
      nomBanque: {
        type: String,
        default: '',
      },
      numeroCompte: {
        type: String,
        default: '',
      },
      iban: {
        type: String,
        default: '',
      },
      bic: {
        type: String,
        default: '',
      },
      instructions: {
        type: String,
        default: '',
      },
      telephone1: {
        type: String,
        default: '',
      },
      telephone2: {
        type: String,
        default: '',
      },
      // =====================================================
      // RESEAUX SOCIAUX
      // =====================================================
      facebookUrl: {
        type: String,
        default: '',
      },
      youtubeChannelUrl: {
        type: String,
        default: '',
      },
      tiktokUrl: {
        type: String,
        default: '',
      },
      instagramUrl: {
        type: String,
        default: '',
      },
    },
    {
      timestamps: true,
      minimize: false,
    }
  );
module.exports =
  mongoose.models.Settings ||
  mongoose.model(
    'Settings',
    settingsSchema
  );