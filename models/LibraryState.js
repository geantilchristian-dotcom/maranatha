const mongoose = require("mongoose");
const libraryStateSchema =
  new mongoose.Schema(
    {
      key: {
        type: String,
        unique: true,
        default: "main",
        index: true,
      },
      /*
       * On conserve volontairement la structure exacte
       * utilisÃ©e par l'interface actuelle.
       *
       * Cela Ã©vite de casser le design ou les donnÃ©es
       * existantes pendant la migration.
       */
      value: {
        type: mongoose.Schema.Types.Mixed,
      default: () => ({ recent: [], live: [], audio: [], video: [], book: [] }),
      },
      updatedAt: {
        type: Date,
        default: Date.now,
      },
    },
    {
      minimize: false,
    }
  );
module.exports =
  mongoose.models.LibraryState ||
  mongoose.model(
    "LibraryState",
    libraryStateSchema
  );
