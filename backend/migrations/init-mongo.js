// MongoDB initialization script
// This script runs when the MongoDB container starts for the first time

// Switch to the thyne_jewels database
db = db.getSiblingDB('thyne_jewels');

// Create collections with validation rules
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'email', 'phone', 'password'],
      properties: {
        name: {
          bsonType: 'string',
          minLength: 2,
          maxLength: 100
        },
        email: {
          bsonType: 'string',
          pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        },
        phone: {
          bsonType: 'string',
          minLength: 10,
          maxLength: 15
        },
        password: {
          bsonType: 'string',
          minLength: 6
        },
        isActive: {
          bsonType: 'bool'
        },
        isVerified: {
          bsonType: 'bool'
        }
      }
    }
  }
});

db.createCollection('products', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'description', 'price', 'images', 'category', 'subcategory', 'metalType', 'stockQuantity'],
      properties: {
        name: {
          bsonType: 'string',
          minLength: 2,
          maxLength: 200
        },
        description: {
          bsonType: 'string',
          minLength: 10,
          maxLength: 2000
        },
        price: {
          bsonType: 'double',
          minimum: 0
        },
        images: {
          bsonType: 'array',
          minItems: 1,
          items: {
            bsonType: 'string'
          }
        },
        category: {
          bsonType: 'string'
        },
        subcategory: {
          bsonType: 'string'
        },
        metalType: {
          bsonType: 'string'
        },
        stockQuantity: {
          bsonType: 'int',
          minimum: 0
        },
        rating: {
          bsonType: 'double',
          minimum: 0,
          maximum: 5
        },
        reviewCount: {
          bsonType: 'int',
          minimum: 0
        },
        isAvailable: {
          bsonType: 'bool'
        },
        isFeatured: {
          bsonType: 'bool'
        }
      }
    }
  }
});

db.createCollection('carts');
db.createCollection('orders');
db.createCollection('reviews');
db.createCollection('guest_sessions');
db.createCollection('coupons');
db.createCollection('wishlist');

// Insert sample categories
db.products.insertMany([
  {
    name: 'Diamond Solitaire Ring',
    description: 'A stunning solitaire diamond ring set in 18K white gold. The center stone is a brilliant cut diamond with exceptional clarity and sparkle.',
    price: 85000,
    originalPrice: 100000,
    images: [
      'https://images.unsplash.com/photo-1605100804763-247f67b3557e',
      'https://images.unsplash.com/photo-1603561591411-07134e71a2a9'
    ],
    category: 'Rings',
    subcategory: 'Engagement',
    metalType: '18K White Gold',
    stoneType: 'Diamond',
    weight: 3.5,
    size: '6',
    stockQuantity: 5,
    rating: 4.8,
    reviewCount: 124,
    tags: ['diamond', 'engagement', 'solitaire'],
    isAvailable: true,
    isFeatured: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Rose Gold Eternity Band',
    description: 'Delicate eternity band featuring lab-grown diamonds set in rose gold. Perfect for stacking or wearing alone.',
    price: 35000,
    images: [
      'https://images.unsplash.com/photo-1602751584552-8ba73aad10e1'
    ],
    category: 'Rings',
    subcategory: 'Wedding',
    metalType: '14K Rose Gold',
    stoneType: 'Lab Diamond',
    weight: 2.8,
    size: '7',
    stockQuantity: 8,
    rating: 4.6,
    reviewCount: 89,
    tags: ['rose gold', 'wedding', 'eternity'],
    isAvailable: true,
    isFeatured: false,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Pearl Strand Necklace',
    description: 'Classic Akoya pearl necklace with 18K gold clasp. Each pearl is hand-selected for its luster and quality.',
    price: 55000,
    originalPrice: 65000,
    images: [
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f'
    ],
    category: 'Necklaces',
    subcategory: 'Pearl',
    metalType: '18K Yellow Gold',
    stoneType: 'Pearl',
    weight: 45,
    stockQuantity: 3,
    rating: 4.9,
    reviewCount: 156,
    tags: ['pearl', 'classic', 'elegant'],
    isAvailable: true,
    isFeatured: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Diamond Stud Earrings',
    description: 'Classic diamond studs featuring brilliant cut diamonds in a four-prong setting.',
    price: 42000,
    images: [
      'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908'
    ],
    category: 'Earrings',
    subcategory: 'Studs',
    metalType: '18K White Gold',
    stoneType: 'Diamond',
    weight: 2.0,
    stockQuantity: 6,
    rating: 4.7,
    reviewCount: 203,
    tags: ['diamond', 'studs', 'classic'],
    isAvailable: true,
    isFeatured: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

// Insert sample coupons
db.coupons.insertMany([
  {
    code: 'FIRST10',
    name: 'First Order Discount',
    description: '10% off on your first order',
    type: 'percentage',
    value: 10,
    minAmount: 1000,
    maxDiscount: 5000,
    usageLimit: 1000,
    usedCount: 0,
    isActive: true,
    validFrom: new Date(),
    validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    code: 'JEWEL20',
    name: 'Jewelry Special',
    description: '20% off on jewelry items',
    type: 'percentage',
    value: 20,
    minAmount: 5000,
    maxDiscount: 10000,
    usageLimit: 500,
    usedCount: 0,
    isActive: true,
    validFrom: new Date(),
    validUntil: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 3 months from now
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

// Insert sample orders
const sampleOrders = [
  {
    orderNumber: 'TJ' + Date.now() + '101',
    userId: null,
    guestSessionId: 'guest_seed_1',
    items: [
      { name: 'Diamond Ring', quantity: 1, price: 20000, productId: ObjectId(), image: '' },
      { name: 'Gold Earrings', quantity: 1, price: 5000, productId: ObjectId(), image: '' },
    ],
    shippingAddress: { street: '123 Main St', city: 'Mumbai', state: 'Maharashtra', zipCode: '400001', country: 'IN' },
    paymentMethod: 'razorpay',
    paymentStatus: 'paid',
    status: 'delivered',
    subtotal: 25000,
    tax: 4500,
    shipping: 0,
    discount: 0,
    total: 29500,
    createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(),
    deliveredAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
  },
  {
    orderNumber: 'TJ' + Date.now() + '102',
    userId: null,
    guestSessionId: 'guest_seed_2',
    items: [
      { name: 'Silver Necklace', quantity: 1, price: 15000, productId: ObjectId(), image: '' },
    ],
    shippingAddress: { street: '456 Park Ave', city: 'Delhi', state: 'Delhi', zipCode: '110001', country: 'IN' },
    paymentMethod: 'razorpay',
    paymentStatus: 'paid',
    status: 'processing',
    subtotal: 15000,
    tax: 2700,
    shipping: 0,
    discount: 0,
    total: 17700,
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(),
  },
  {
    orderNumber: 'TJ' + Date.now() + '103',
    userId: null,
    guestSessionId: 'guest_seed_3',
    items: [
      { name: 'Gold Bracelet', quantity: 1, price: 8000, productId: ObjectId(), image: '' },
    ],
    shippingAddress: { street: '789 Garden Rd', city: 'Bangalore', state: 'Karnataka', zipCode: '560001', country: 'IN' },
    paymentMethod: 'cod',
    paymentStatus: 'pending',
    status: 'pending',
    subtotal: 8000,
    tax: 1440,
    shipping: 0,
    discount: 0,
    total: 9440,
    createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(),
  },
];

if (db.orders.countDocuments() === 0) {
  db.orders.insertMany(sampleOrders);
  print('Inserted sample orders');
} else {
  print('Orders collection not empty, skipping sample orders');
}

print('Database initialized successfully!');
