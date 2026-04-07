import { Router, type IRouter } from "express";
import healthRouter from "./health";
import diffusionRouter from "./diffusion";

const router: IRouter = Router();

router.use(healthRouter);
router.use(diffusionRouter);

export default router;
