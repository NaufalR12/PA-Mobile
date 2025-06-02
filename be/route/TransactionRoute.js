import express from "express";
import { TransactionController } from "../controller/TransactionController.js";

const router = express.Router();

// Get transactions by date range (harus di atas /:id)
router.get("/date-range", TransactionController.getByDateRange);

// Get transaction by ID
router.get("/:id", TransactionController.getById);

// Get all transactions for user
router.get("/", TransactionController.getByUserId);

// Create transaction
router.post("/", TransactionController.create);

// Update transaction
router.put("/:id", TransactionController.update);

// Delete transaction
router.delete("/:id", TransactionController.delete);

export default router;
