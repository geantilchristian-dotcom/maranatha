import { pgTable, text, serial, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const diffusionTable = pgTable("diffusion", {
  id: serial("id").primaryKey(),
  titre: text("titre").notNull().default("Maranatha"),
  v_ref: text("v_ref"),
  v_txt: text("v_txt"),
  pochette: text("pochette"),
  audio: text("audio"),
  q1: text("q1"),
  q2: text("q2"),
  q3: text("q3"),
  q4: text("q4"),
  h_matin: text("h_matin").default("06:00"),
  t_matin: text("t_matin").default("Matin de Gloire"),
  h_soir: text("h_soir").default("18:00"),
  t_soir: text("t_soir").default("Culte Maranatha"),
  n_airtel: text("n_airtel"),
  n_orange: text("n_orange"),
  n_voda: text("n_voda"),
  n_whatsapp: text("n_whatsapp"),
  updated_at: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
});

export const insertDiffusionSchema = createInsertSchema(diffusionTable).omit({ id: true, updated_at: true });
export type InsertDiffusion = z.infer<typeof insertDiffusionSchema>;
export type Diffusion = typeof diffusionTable.$inferSelect;
