import express from "express";
import { PlanController } from "../controller/PlanController.js";
import { verifyToken } from "../middleware/Auth.js";

const router = express.Router();

// Create plan
router.post("/", verifyToken, PlanController.create);

// Get all plans for user
router.get("/", verifyToken, PlanController.getByUserId);

// Get plan by ID
router.get("/:id", verifyToken, PlanController.getById);

// Update plan
router.put("/:id", verifyToken, PlanController.update);

// Delete plan
router.delete("/:id", verifyToken, PlanController.delete);

export default router;
