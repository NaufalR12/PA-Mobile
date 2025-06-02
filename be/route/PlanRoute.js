import express from "express";
import { PlanController } from "../controller/PlanController.js";

const router = express.Router();

// Create plan
router.post("/", PlanController.create);

// Get all plans for user
router.get("/", PlanController.getByUserId);

// Get plan by ID
router.get("/:id", PlanController.getById);

// Update plan
router.put("/:id", PlanController.update);

// Delete plan
router.delete("/:id", PlanController.delete);

export default router;
