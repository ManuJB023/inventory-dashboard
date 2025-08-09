module.exports = (sequelize, DataTypes) => {
  const Product = sequelize.define('Product', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        len: [2, 200]
      }
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    sku: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        len: [3, 50]
      }
    },
    barcode: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      validate: {
        min: 0
      }
    },
    cost: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true,
      validate: {
        min: 0
      }
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      validate: {
        min: 0
      }
    },
    minStockLevel: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 5,
      validate: {
        min: 0
      }
    },
    maxStockLevel: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 0
      }
    },
    unit: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'pcs',
      validate: {
        len: [1, 20]
      }
    },
    weight: {
      type: DataTypes.DECIMAL(8, 2),
      allowNull: true,
      validate: {
        min: 0
      }
    },
    dimensions: {
      type: DataTypes.JSON,
      allowNull: true
    },
    imageUrl: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        isUrl: true
      }
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    categoryId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'categories',
        key: 'id'
      }
    },
    supplierId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'suppliers',
        key: 'id'
      }
    }
  }, {
    tableName: 'products',
    timestamps: true,
    indexes: [
      {
        fields: ['sku']
      },
      {
        fields: ['categoryId']
      },
      {
        fields: ['supplierId']
      }
    ]
  });

  // Associations
  Product.associate = function(models) {
    // Product belongs to Category
    Product.belongsTo(models.Category, {
      foreignKey: 'categoryId',
      as: 'category'
    });

    // Product belongs to Supplier
    Product.belongsTo(models.Supplier, {
      foreignKey: 'supplierId',
      as: 'supplier'
    });

    // Product has many InventoryTransactions
    Product.hasMany(models.InventoryTransaction, {
      foreignKey: 'productId',
      as: 'transactions'
    });
  };

  // Instance methods
  Product.prototype.isLowStock = function() {
    return this.quantity <= this.minStockLevel;
  };

  Product.prototype.updateStock = function(quantity, type = 'add') {
    if (type === 'add') {
      this.quantity += quantity;
    } else if (type === 'subtract') {
      this.quantity = Math.max(0, this.quantity - quantity);
    } else if (type === 'set') {
      this.quantity = Math.max(0, quantity);
    }
    return this.save();
  };

  return Product;
};