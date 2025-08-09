module.exports = (sequelize, DataTypes) => {
  const InventoryTransaction = sequelize.define('InventoryTransaction', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    type: {
      type: DataTypes.ENUM('in', 'out', 'adjustment'),
      allowNull: false
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 1
      }
    },
    previousQuantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 0
      }
    },
    newQuantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 0
      }
    },
    reason: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        len: [0, 255]
      }
    },
    reference: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        len: [0, 100]
      }
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    unitCost: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true,
      validate: {
        min: 0
      }
    },
    totalCost: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: true,
      validate: {
        min: 0
      }
    },
    productId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'products',
        key: 'id'
      }
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    }
  }, {
    tableName: 'inventory_transactions',
    timestamps: true,
    indexes: [
      {
        fields: ['productId']
      },
      {
        fields: ['userId']
      },
      {
        fields: ['type']
      },
      {
        fields: ['createdAt']
      }
    ]
  });

  // Associations
  InventoryTransaction.associate = function(models) {
    // Transaction belongs to Product
    InventoryTransaction.belongsTo(models.Product, {
      foreignKey: 'productId',
      as: 'product'
    });

    // Transaction belongs to User
    InventoryTransaction.belongsTo(models.User, {
      foreignKey: 'userId',
      as: 'user'
    });
  };

  // Class methods
  InventoryTransaction.createTransaction = async function(productId, userId, type, quantity, options = {}) {
    const { Product } = sequelize.models;
    
    const product = await Product.findByPk(productId);
    if (!product) {
      throw new Error('Product not found');
    }

    const previousQuantity = product.quantity;
    let newQuantity;

    switch (type) {
      case 'in':
        newQuantity = previousQuantity + quantity;
        break;
      case 'out':
        newQuantity = Math.max(0, previousQuantity - quantity);
        break;
      case 'adjustment':
        newQuantity = quantity;
        break;
      default:
        throw new Error('Invalid transaction type');
    }

    // Create transaction record
    const transaction = await this.create({
      type,
      quantity: type === 'adjustment' ? Math.abs(newQuantity - previousQuantity) : quantity,
      previousQuantity,
      newQuantity,
      reason: options.reason,
      reference: options.reference,
      notes: options.notes,
      unitCost: options.unitCost,
      totalCost: options.unitCost ? options.unitCost * quantity : null,
      productId,
      userId
    });

    // Update product quantity
    await product.updateStock(newQuantity, 'set');

    return transaction;
  };

  return InventoryTransaction;
};