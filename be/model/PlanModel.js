import db from "../config/database.js";

export const createPlan = (data) => {
  const { userId, categoryId, amount, description, remainingAmount } = data;
  return db.query(
    "INSERT INTO plans (userId, categoryId, amount, description, remainingAmount) VALUES (?, ?, ?, ?, ?)",
    [userId, categoryId, amount, description, remainingAmount]
  );
};

export const getPlansByUserId = (userId) => {
  return db.query("SELECT * FROM plans WHERE userId = ?", [userId]);
};

export const getPlanById = (id) => {
  return db.query("SELECT * FROM plans WHERE id = ?", [id]);
};

export const getPlanByCategoryAndUser = (categoryId, userId) => {
  return db.query("SELECT * FROM plans WHERE categoryId = ? AND userId = ?", [
    categoryId,
    userId,
  ]);
};

export const updatePlan = (id, data) => {
  const { amount, description, remainingAmount } = data;
  return db.query(
    "UPDATE plans SET amount = ?, description = ?, remainingAmount = ? WHERE id = ?",
    [amount, description, remainingAmount, id]
  );
};

export const deletePlan = (id) => {
  return db.query("DELETE FROM plans WHERE id = ?", [id]);
};

export const updateRemainingAmount = (id, amount) => {
  return db.query(
    "UPDATE plans SET remainingAmount = remainingAmount - ? WHERE id = ?",
    [amount, id]
  );
};
