import { Router, type IRouter } from "express";
import { db, diffusionTable } from "@workspace/db";
import { UpdateSermonBody } from "@workspace/api-zod";
import multer from "multer";
import path from "path";
import fs from "fs";
import express from "express";

const router: IRouter = Router();

const uploadsDir = path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (_req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname.replace(/\s+/g, "_"));
  },
});

const upload = multer({ storage });

// Serve uploaded files
router.use("/uploads", express.static(uploadsDir));

router.get("/prochaine-diffusion", async (req, res): Promise<void> => {
  const rows = await db.select().from(diffusionTable).limit(1);
  if (rows.length === 0) {
    const [created] = await db
      .insert(diffusionTable)
      .values({
        titre: "Maranatha",
        h_matin: "06:00",
        t_matin: "Matin de Gloire",
        h_soir: "18:00",
        t_soir: "Culte Maranatha",
      })
      .returning();
    req.log.info("Created default diffusion row");
    res.json(created);
    return;
  }
  res.json(rows[0]);
});

router.post("/update-sermon", upload.single("audioFile"), async (req, res): Promise<void> => {
  let bodyData: Record<string, unknown>;

  if (req.body && typeof req.body.jsonData === "string") {
    try {
      bodyData = JSON.parse(req.body.jsonData) as Record<string, unknown>;
    } catch {
      res.status(400).json({ error: "Invalid jsonData" });
      return;
    }
  } else {
    bodyData = req.body as Record<string, unknown>;
  }

  const parsed = UpdateSermonBody.safeParse(bodyData);
  if (!parsed.success) {
    req.log.warn({ errors: parsed.error.message }, "Invalid request body");
    res.status(400).json({ error: parsed.error.message });
    return;
  }

  const updateData: Record<string, unknown> = { ...parsed.data };

  if (req.file) {
    updateData.audio = `/api/uploads/${req.file.filename}`;
    req.log.info({ filename: req.file.filename }, "New audio file received");
  }

  const rows = await db.select().from(diffusionTable).limit(1);
  let updated;
  if (rows.length === 0) {
    if (!updateData.titre) updateData.titre = "Maranatha";
    [updated] = await db
      .insert(diffusionTable)
      .values(updateData as { titre: string })
      .returning();
  } else {
    [updated] = await db
      .update(diffusionTable)
      .set(updateData)
      .returning();
  }

  req.log.info("Diffusion updated successfully");
  res.json(updated);
});

export default router;
