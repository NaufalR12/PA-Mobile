import express from "express";
import User from "../model/User.js";
import Transaction from "../model/Transaction.js";
import Category from "../model/Category.js";
import { verifyToken } from "../middleware/Auth.js";
import multer from "multer";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";
import { UserController } from "../controller/UserController.js";

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// Auth routes
router.post("/register", UserController.register);
router.post("/login", UserController.login);
router.post("/refresh-token", UserController.refreshToken); // Tambahkan route ini

// Profile routes
router.get("/me", verifyToken, UserController.getProfile);
router.get("/profile/photo", verifyToken, UserController.getProfilePhoto);
router.put(
  "/profile",
  verifyToken,
  upload.single("foto_profil"),
  UserController.updateProfile
);
router.post("/logout", verifyToken, UserController.logout);

// Delete user account
router.delete("/delete", verifyToken, UserController.deleteAccount);

export default router;
