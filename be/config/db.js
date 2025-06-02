import { Sequelize } from "sequelize";
import dotenv from "dotenv";
import User from "../model/User.js";
import Category from "../model/Category.js";
import Transaction from "../model/Transaction.js";

// Load environment variables
const result = dotenv.config();
if (result.error) {
  console.error("Error loading .env file in db.js:", result.error);
} else {
  console.log(".env file loaded successfully in db.js");
}

// Log database configuration (without password)
console.log("Database Configuration:");
console.log("DB_HOST:", process.env.DB_HOST);
console.log("DB_NAME:", process.env.DB_NAME);
console.log("DB_USERNAME:", process.env.DB_USERNAME);
console.log("DB_PASSWORD:", process.env.DB_PASSWORD ? "Set" : "Not Set");

const sequelize = new Sequelize(
  process.env.DB_NAME || "moneytracker",
  process.env.DB_USERNAME || "root", // Changed from DB_USER to DB_USERNAME
  process.env.DB_PASSWORD || "",
  {
    host: process.env.DB_HOST || "localhost",
    dialect: "mysql",
    logging: console.log, // Enable logging temporarily for debugging
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
    dialectOptions: {
      connectTimeout: 60000, // Increase connection timeout
    },
  }
);

// Define associations
User.hasMany(Transaction, { foreignKey: "userId" });
Category.hasMany(Transaction, { foreignKey: "categoryId" });

export const syncDatabase = async () => {
  try {
    console.log("Attempting to connect to database...");
    console.log("Connection details:", {
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      username: process.env.DB_USERNAME,
      // password is intentionally omitted for security
    });

    await sequelize.authenticate();
    console.log("Database connection has been established successfully.");

    // Sync database dengan force: false untuk menghindari penghapusan data
    await sequelize.sync({ alter: true });
    console.log("Database synchronized successfully");
  } catch (error) {
    console.error("Error syncing database:", error);
    console.error("Full error details:", {
      name: error.name,
      message: error.message,
      parent: error.parent
        ? {
            code: error.parent.code,
            errno: error.parent.errno,
            message: error.parent.message,
          }
        : null,
    });
    throw error;
  }
};

export default sequelize;
