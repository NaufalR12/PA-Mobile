const express = require("express");
const router = express.Router();
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { User, Transaction, Category } = require("../models");
const auth = require("../middleware/auth");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Get user profile
router.get("/me", auth, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ["password"] },
    });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// Update user profile
router.put("/profile", auth, async (req, res) => {
  try {
    const { name, email, gender } = req.body;
    const user = await User.findByPk(req.user.id);

    if (name) user.name = name;
    if (email) user.email = email;
    if (gender) user.gender = gender;

    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// Delete user account
router.delete("/delete", auth, async (req, res) => {
  try {
    const userId = req.user.id;

    // Hapus semua transaksi user
    await Transaction.destroy({
      where: { userId },
    });

    // Hapus semua kategori user
    await Category.destroy({
      where: { userId },
    });

    // Hapus foto profil jika ada
    const user = await User.findByPk(userId);
    if (user && user.foto_profil) {
      const filePath = path.join(__dirname, "../uploads", user.foto_profil);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    // Hapus user
    await User.destroy({
      where: { id: userId },
    });

    res.status(200).json({
      status: "success",
      message: "Akun berhasil dihapus",
    });
  } catch (error) {
    console.error("Error deleting user:", error);
    res.status(500).json({
      status: "error",
      message: "Gagal menghapus akun",
    });
  }
});

module.exports = router;
