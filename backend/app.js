const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { body, param, query, validationResult } = require('express-validator');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Middleware
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
    },
  },
}));
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
app.use(compression());
app.use(limiter);
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Database connection with retry logic
const { Sequelize, DataTypes } = require('sequelize');

console.log("=== Database Configuration Debug ===");
console.log("DB_HOST:", process.env.DB_HOST || "localhost");
console.log("DB_PORT:", process.env.DB_PORT || 5432);
console.log("DB_NAME:", process.env.DB_NAME || "inventory_db");
console.log("DB_USER:", process.env.DB_USER || "postgres");
console.log("DB_PASSWORD:", process.env.DB_PASSWORD ? "***SET***" : "***UNDEFINED***");
console.log("=====================================");

const sequelize = new Sequelize(
  process.env.DB_NAME || 'inventory_db',
  process.env.DB_USER || 'postgres',
  process.env.DB_PASSWORD || 'postgres123',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    dialectOptions: {
      ssl: process.env.DB_SSL === 'true' ? {
        require: true,
        rejectUnauthorized: false
      } : false
    },
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    retry: {
      match: [
        /CONNECTION_REFUSED/,
        /connection refused/,
        /ECONNREFUSED/,
        /ENOTFOUND/,
        /ENETUNREACH/,
        /ETIMEDOUT/
      ],
      max: 5
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// Validation middleware
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// Models
const Product = sequelize.define('Product', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 255]
    }
  },
  description: {
    type: DataTypes.TEXT,
  },
  sku: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 100]
    }
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  },
  category: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 100]
    }
  },
  quantity: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    validate: {
      min: 0
    }
  },
  lowStockThreshold: {
    type: DataTypes.INTEGER,
    defaultValue: 10,
    validate: {
      min: 0
    }
  },
  supplier: {
    type: DataTypes.STRING,
    validate: {
      len: [0, 255]
    }
  },
}, {
  timestamps: true,
  indexes: [
    { fields: ['sku'] },
    { fields: ['category'] },
    { fields: ['quantity'] },
    { fields: ['name'] },
  ],
});

const StockMovement = sequelize.define('StockMovement', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  productId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: Product,
      key: 'id',
    },
  },
  type: {
    type: DataTypes.ENUM('IN', 'OUT', 'ADJUSTMENT'),
    allowNull: false,
  },
  quantity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 0
    }
  },
  reason: {
    type: DataTypes.STRING,
    validate: {
      len: [0, 255]
    }
  },
  notes: {
    type: DataTypes.TEXT,
  },
  performedBy: {
    type: DataTypes.STRING,
    defaultValue: 'system'
  }
}, {
  timestamps: true,
  indexes: [
    { fields: ['productId'] },
    { fields: ['type'] },
    { fields: ['createdAt'] },
  ],
});

// Associations
Product.hasMany(StockMovement, { foreignKey: 'productId', onDelete: 'CASCADE' });
StockMovement.belongsTo(Product, { foreignKey: 'productId' });

// Validation rules
const productValidation = [
  body('name').notEmpty().isLength({ min: 1, max: 255 }).trim(),
  body('sku').notEmpty().isLength({ min: 1, max: 100 }).trim(),
  body('price').isFloat({ min: 0 }),
  body('category').notEmpty().isLength({ min: 1, max: 100 }).trim(),
  body('quantity').optional().isInt({ min: 0 }),
  body('lowStockThreshold').optional().isInt({ min: 0 }),
  body('supplier').optional().isLength({ max: 255 }).trim(),
  body('description').optional().trim()
];

const stockMovementValidation = [
  body('productId').isUUID(),
  body('type').isIn(['IN', 'OUT', 'ADJUSTMENT']),
  body('quantity').isInt({ min: 0 }),
  body('reason').optional().isLength({ max: 255 }).trim(),
  body('notes').optional().trim(),
  body('performedBy').optional().isLength({ max: 255 }).trim()
];

// Routes with validation
// GET /api/products - Get all products with filtering and pagination
app.get('/api/products', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('category').optional().trim(),
  query('lowStock').optional().isBoolean(),
  query('search').optional().trim()
], handleValidationErrors, async (req, res) => {
  try {
    const { page = 1, limit = 20, category, lowStock, search } = req.query;
    const offset = (page - 1) * limit;
    
    const where = {};
    if (category) where.category = category;
    if (lowStock === 'true') {
      where.quantity = { [Sequelize.Op.lte]: sequelize.col('lowStockThreshold') };
    }
    if (search) {
      where[Sequelize.Op.or] = [
        { name: { [Sequelize.Op.iLike]: `%${search}%` } },
        { sku: { [Sequelize.Op.iLike]: `%${search}%` } },
        { description: { [Sequelize.Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Product.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']],
    });

    res.json({
      success: true,
      products: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch products',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/products/:id - Get single product
app.get('/api/products/:id', [
  param('id').isUUID()
], handleValidationErrors, async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [{
        model: StockMovement,
        limit: 10,
        order: [['createdAt', 'DESC']]
      }]
    });
    
    if (!product) {
      return res.status(404).json({ 
        success: false, 
        error: 'Product not found' 
      });
    }
    
    res.json({ success: true, product });
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch product',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/products - Create new product
app.post('/api/products', productValidation, handleValidationErrors, async (req, res) => {
  try {
    const product = await Product.create(req.body);
    res.status(201).json({ success: true, product });
  } catch (error) {
    console.error('Error creating product:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ 
        success: false, 
        error: 'SKU already exists' 
      });
    } else if (error.name === 'SequelizeValidationError') {
      res.status(400).json({ 
        success: false, 
        error: 'Validation failed',
        details: error.errors.map(e => ({ field: e.path, message: e.message }))
      });
    } else {
      res.status(500).json({ 
        success: false, 
        error: 'Failed to create product',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
});

// PUT /api/products/:id - Update product
app.put('/api/products/:id', [
  param('id').isUUID(),
  ...productValidation
], handleValidationErrors, async (req, res) => {
  try {
    const [updated] = await Product.update(req.body, {
      where: { id: req.params.id },
    });
    
    if (updated) {
      const product = await Product.findByPk(req.params.id);
      res.json({ success: true, product });
    } else {
      res.status(404).json({ 
        success: false, 
        error: 'Product not found' 
      });
    }
  } catch (error) {
    console.error('Error updating product:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(400).json({ 
        success: false, 
        error: 'SKU already exists' 
      });
    } else {
      res.status(500).json({ 
        success: false, 
        error: 'Failed to update product',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
});

// DELETE /api/products/:id - Delete product
app.delete('/api/products/:id', [
  param('id').isUUID()
], handleValidationErrors, async (req, res) => {
  try {
    const deleted = await Product.destroy({
      where: { id: req.params.id },
    });
    
    if (deleted) {
      res.json({ success: true, message: 'Product deleted successfully' });
    } else {
      res.status(404).json({ 
        success: false, 
        error: 'Product not found' 
      });
    }
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to delete product',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/stock-movements - Record stock movement
app.post('/api/stock-movements', stockMovementValidation, handleValidationErrors, async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { productId, type, quantity, reason, notes, performedBy } = req.body;
    
    // Check if product exists
    const product = await Product.findByPk(productId, { transaction });
    if (!product) {
      await transaction.rollback();
      return res.status(404).json({ 
        success: false, 
        error: 'Product not found' 
      });
    }
    
    // Calculate new quantity
    let newQuantity = product.quantity;
    if (type === 'IN') {
      newQuantity += quantity;
    } else if (type === 'OUT') {
      newQuantity -= quantity;
      if (newQuantity < 0) {
        await transaction.rollback();
        return res.status(400).json({ 
          success: false, 
          error: 'Insufficient stock',
          available: product.quantity,
          requested: quantity
        });
      }
    } else if (type === 'ADJUSTMENT') {
      newQuantity = quantity; // Direct adjustment to specific quantity
    }
    
    // Create stock movement record
    const movement = await StockMovement.create({
      productId,
      type,
      quantity: type === 'ADJUSTMENT' ? quantity : quantity,
      reason,
      notes,
      performedBy: performedBy || 'system'
    }, { transaction });
    
    // Update product quantity
    await product.update({ quantity: newQuantity }, { transaction });
    
    await transaction.commit();
    
    res.status(201).json({ 
      success: true, 
      movement,
      newQuantity,
      previousQuantity: product.quantity
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Error recording stock movement:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to record stock movement',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/stock-movements - Get stock movement history
app.get('/api/stock-movements', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('productId').optional().isUUID(),
  query('type').optional().isIn(['IN', 'OUT', 'ADJUSTMENT'])
], handleValidationErrors, async (req, res) => {
  try {
    const { page = 1, limit = 50, productId, type } = req.query;
    const offset = (page - 1) * limit;
    
    const where = {};
    if (productId) where.productId = productId;
    if (type) where.type = type;
    
    const { count, rows } = await StockMovement.findAndCountAll({
      where,
      include: [{ model: Product, attributes: ['name', 'sku'] }],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']],
    });
    
    res.json({
      success: true,
      movements: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching stock movements:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch stock movements',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/dashboard/stats - Dashboard statistics
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    const [
      totalProducts,
      totalValue,
      lowStockCount,
      topCategories,
      recentMovements
    ] = await Promise.all([
      Product.count(),
      Product.sum('price'),
      Product.count({
        where: {
          quantity: { [Sequelize.Op.lte]: sequelize.col('lowStockThreshold') }
        }
      }),
      Product.findAll({
        attributes: [
          'category',
          [sequelize.fn('COUNT', sequelize.col('category')), 'count'],
          [sequelize.fn('SUM', sequelize.col('quantity')), 'totalQuantity'],
          [sequelize.fn('AVG', sequelize.col('price')), 'avgPrice']
        ],
        group: ['category'],
        order: [[sequelize.fn('COUNT', sequelize.col('category')), 'DESC']],
        limit: 5,
      }),
      StockMovement.findAll({
        include: [{ model: Product, attributes: ['name', 'sku'] }],
        order: [['createdAt', 'DESC']],
        limit: 10
      })
    ]);
    
    res.json({
      success: true,
      stats: {
        totalProducts,
        totalValue: parseFloat(totalValue) || 0,
        lowStockCount,
        topCategories: topCategories.map(cat => ({
          category: cat.category,
          count: parseInt(cat.dataValues.count),
          totalQuantity: parseInt(cat.dataValues.totalQuantity),
          avgPrice: parseFloat(cat.dataValues.avgPrice) || 0
        })),
        recentMovements
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch dashboard statistics',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/categories - Get all categories
app.get('/api/categories', async (req, res) => {
  try {
    const categories = await Product.findAll({
      attributes: [
        'category',
        [sequelize.fn('COUNT', sequelize.col('category')), 'productCount']
      ],
      group: ['category'],
      order: [['category', 'ASC']],
    });
    
    res.json({
      success: true,
      categories: categories.map(cat => ({
        name: cat.category,
        productCount: parseInt(cat.dataValues.productCount)
      }))
    });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch categories',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Health check
app.get('/health', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'ERROR', 
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message
    });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    success: false, 
    error: 'Route not found' 
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ 
    success: false, 
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
});

// Database connection with retry logic
const connectToDatabase = async (retries = 5) => {
  for (let i = 0; i < retries; i++) {
    try {
      await sequelize.authenticate();
      console.log('✓ Database connection established successfully.');
      return;
    } catch (error) {
      console.error(`Database connection attempt ${i + 1}/${retries} failed:`, error.message);
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
};

// Initialize database and start server
const initializeApp = async () => {
  try {
    await connectToDatabase();
    
    await sequelize.sync({ 
      alter: process.env.NODE_ENV === 'development',
      force: false 
    });
    console.log('✓ Database synchronized successfully.');
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`✓ Server running on port ${PORT}`);
      console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`✓ Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('✗ Failed to initialize application:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n📋 Shutting down gracefully...');
  try {
    await sequelize.close();
    console.log('✓ Database connection closed.');
    process.exit(0);
  } catch (error) {
    console.error('✗ Error during shutdown:', error);
    process.exit(1);
  }
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

initializeApp();

module.exports = app;