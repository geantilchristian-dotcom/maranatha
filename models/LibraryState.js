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
       * utilisée par l'interface actuelle.
       *
       * Cela évite de casser le design ou les données
       * existantes pendant la migration.
       */
      value: {
        type: mongoose.Schema.Types.Mixed,
        default: [],
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