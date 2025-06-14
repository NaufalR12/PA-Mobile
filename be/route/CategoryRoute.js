import express from "express";
import { CategoryController } from "../controller/CategoryController.js";

const router = express.Router();

// Create category
router.post("/", CategoryController.create);

// Get all categories
router.get("/", CategoryController.getAll);

// Get categories by type
router.get("/type/:type", CategoryController.getByType);

// Update category
router.put("/:id", CategoryController.update);

// Delete category
router.delete("/:id", CategoryController.delete);

export default router;
