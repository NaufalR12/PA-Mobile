import express from "express";
import { CategoryController } from "../controller/CategoryController.js";
import { verifyToken } from "../middleware/Auth.js";

const router = express.Router();

// Create category
router.post("/", verifyToken, CategoryController.create);

// Get all categories
router.get("/", verifyToken, CategoryController.getAll);

// Get categories by type
router.get("/type/:type", verifyToken, CategoryController.getByType);

// Update category
router.put("/:id", verifyToken, CategoryController.update);

// Delete category
router.delete("/:id", verifyToken, CategoryController.delete);

export default router;
