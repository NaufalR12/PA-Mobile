import express from "express";
import { TransactionController } from "../controller/TransactionController.js";
import { verifyToken } from "../middleware/Auth.js";

const router = express.Router();

// Get transactions by date range (harus di atas /:id)
router.get("/date-range", verifyToken, TransactionController.getByDateRange);

// Get transaction by ID
router.get("/:id", verifyToken, TransactionController.getById);

// Get all transactions for user
router.get("/", verifyToken, TransactionController.getByUserId);

// Create transaction
router.post("/", verifyToken, TransactionController.create);

// Update transaction
router.put("/:id", verifyToken, TransactionController.update);

// Delete transaction
router.delete("/:id", verifyToken, TransactionController.delete);

export default router;
