import express from "express";
import User from "../model/User.js";
import Transaction from "../model/Transaction.js";
import Category from "../model/Category.js";
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

// Profile routes
router.get("/me", UserController.getProfile);
router.put("/profile", UserController.updateProfile);
router.put(
  "/profile/photo",
  upload.single("foto_profil"),
  UserController.updateProfilePhoto
);
router.get("/profile/photo", UserController.getProfilePhoto);
router.post("/logout", UserController.logout);
router.delete("/delete", UserController.deleteAccount);

export default router;
