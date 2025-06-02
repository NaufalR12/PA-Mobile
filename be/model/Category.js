import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";
import User from "./User.js";

const Category = sequelize.define(
  "Category",
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    }
  },
  {
    tableName: "categories",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: false,
  }
);

// Set up association
Category.belongsTo(User, { foreignKey: 'userId' });
User.hasMany(Category, { foreignKey: 'userId' });

export default Category;
