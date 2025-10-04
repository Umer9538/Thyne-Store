// Comprehensive database seeding script for Thyne Jewels
// This script seeds all collections without removing existing data

// Switch to the thyne_jewels database
db = db.getSiblingDB('thyne_jewels');

const now = new Date();

print('🌱 Starting comprehensive database seeding...');

// Helper function to check if data exists
function seedIfEmpty(collectionName, data, checkField = null) {
    const collection = db.getCollection(collectionName);
    let shouldSeed = false;
    
    if (checkField) {
        // Check for specific field values
        shouldSeed = data.every(item => !collection.findOne({[checkField]: item[checkField]}));
    } else {
        // Check if collection is empty
        shouldSeed = collection.countDocuments() === 0;
    }
    
    if (shouldSeed) {
        collection.insertMany(data);
        print(`✅ Seeded ${data.length} documents in ${collectionName}`);
        return data.length;
    } else {
        print(`⏭️  Skipped ${collectionName} - data already exists`);
        return 0;
    }
}

// 1. Seed Users (additional users beyond existing ones)
const additionalUsers = [
    {
        name: 'Sarah Johnson',
        email: 'sarah.johnson@example.com',
        phone: '+1234567890',
        password: '$2a$12$5U6OxbrjSw9qkPUQ4MPTsOz0vAoF088p/d4GJaVNPJRtkBVjTQXq6', // Password@123
        isActive: true,
        isVerified: true,
        isAdmin: false,
        addresses: [
            {
                _id: ObjectId(),
                street: '123 Jewelry Lane',
                city: 'Mumbai',
                state: 'Maharashtra',
                zipCode: '400001',
                country: 'IN',
                isDefault: true,
                createdAt: now,
                updatedAt: now
            }
        ],
        createdAt: now,
        updatedAt: now,
    },
    {
        name: 'Michael Chen',
        email: 'michael.chen@example.com',
        phone: '+1234567891',
        password: '$2a$12$5U6OxbrjSw9qkPUQ4MPTsOz0vAoF088p/d4GJaVNPJRtkBVjTQXq6', // Password@123
        isActive: true,
        isVerified: true,
        isAdmin: false,
        addresses: [
            {
                _id: ObjectId(),
                street: '456 Diamond Street',
                city: 'Delhi',
                state: 'Delhi',
                zipCode: '110001',
                country: 'IN',
                isDefault: true,
                createdAt: now,
                updatedAt: now
            }
        ],
        createdAt: now,
        updatedAt: now,
    },
    {
        name: 'Priya Sharma',
        email: 'priya.sharma@example.com',
        phone: '+1234567892',
        password: '$2a$12$5U6OxbrjSw9qkPUQ4MPTsOz0vAoF088p/d4GJaVNPJRtkBVjTQXq6', // Password@123
        isActive: true,
        isVerified: false,
        isAdmin: false,
        addresses: [],
        createdAt: now,
        updatedAt: now,
    }
];

seedIfEmpty('users', additionalUsers, 'email');

// 2. Seed Additional Products
const additionalProducts = [
    {
        name: 'Emerald Tennis Bracelet',
        description: 'Stunning emerald tennis bracelet featuring lab-grown emeralds set in 14K yellow gold. Perfect for special occasions.',
        price: 65000,
        originalPrice: 75000,
        images: [
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
            'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0'
        ],
        category: 'Bracelets',
        subcategory: 'Tennis',
        metalType: '14K Yellow Gold',
        stoneType: 'Emerald',
        weight: 15.2,
        stockQuantity: 4,
        rating: 4.7,
        reviewCount: 67,
        tags: ['emerald', 'tennis', 'bracelet', 'luxury'],
        isAvailable: true,
        isFeatured: true,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Sapphire Pendant Necklace',
        description: 'Elegant sapphire pendant necklace with a brilliant blue sapphire center stone surrounded by diamonds.',
        price: 48000,
        images: [
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338'
        ],
        category: 'Necklaces',
        subcategory: 'Pendant',
        metalType: '18K White Gold',
        stoneType: 'Sapphire',
        weight: 8.5,
        stockQuantity: 7,
        rating: 4.9,
        reviewCount: 92,
        tags: ['sapphire', 'pendant', 'diamonds', 'elegant'],
        isAvailable: true,
        isFeatured: false,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Ruby Drop Earrings',
        description: 'Exquisite ruby drop earrings featuring pear-shaped rubies with diamond accents in rose gold setting.',
        price: 38000,
        originalPrice: 42000,
        images: [
            'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908'
        ],
        category: 'Earrings',
        subcategory: 'Drops',
        metalType: '14K Rose Gold',
        stoneType: 'Ruby',
        weight: 4.2,
        stockQuantity: 6,
        rating: 4.8,
        reviewCount: 78,
        tags: ['ruby', 'drops', 'rose gold', 'elegant'],
        isAvailable: true,
        isFeatured: true,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Vintage Art Deco Ring',
        description: 'Beautiful vintage-inspired Art Deco ring with geometric patterns and diamond accents.',
        price: 72000,
        images: [
            'https://images.unsplash.com/photo-1605100804763-247f67b3557e'
        ],
        category: 'Rings',
        subcategory: 'Vintage',
        metalType: '18K Yellow Gold',
        stoneType: 'Diamond',
        weight: 5.8,
        size: '7',
        stockQuantity: 3,
        rating: 4.6,
        reviewCount: 45,
        tags: ['vintage', 'art deco', 'diamond', 'unique'],
        isAvailable: true,
        isFeatured: false,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Gold Chain Necklace',
        description: 'Classic gold chain necklace perfect for layering or wearing alone. Available in multiple lengths.',
        price: 28000,
        images: [
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f'
        ],
        category: 'Necklaces',
        subcategory: 'Chain',
        metalType: '14K Yellow Gold',
        weight: 12.0,
        stockQuantity: 15,
        rating: 4.5,
        reviewCount: 134,
        tags: ['gold', 'chain', 'classic', 'layering'],
        isAvailable: true,
        isFeatured: false,
        createdAt: now,
        updatedAt: now
    }
];

// Only add products that don't already exist (check by name)
const existingProductNames = db.products.find({}, {name: 1}).toArray().map(p => p.name);
const newProducts = additionalProducts.filter(p => !existingProductNames.includes(p.name));
if (newProducts.length > 0) {
    db.products.insertMany(newProducts);
    print(`✅ Seeded ${newProducts.length} new products`);
} else {
    print('⏭️  Skipped products - all products already exist');
}

// 3. Seed Additional Coupons
const additionalCoupons = [
    {
        code: 'WELCOME25',
        name: 'Welcome Discount',
        description: '25% off on your first purchase above ₹2000',
        type: 'percentage',
        value: 25,
        minAmount: 2000,
        maxDiscount: 8000,
        usageLimit: 500,
        usedCount: 0,
        isActive: true,
        validFrom: now,
        validUntil: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000), // 6 months
        createdAt: now,
        updatedAt: now
    },
    {
        code: 'LUXURY15',
        name: 'Luxury Collection',
        description: '15% off on luxury jewelry above ₹50000',
        type: 'percentage',
        value: 15,
        minAmount: 50000,
        maxDiscount: 15000,
        usageLimit: 200,
        usedCount: 0,
        isActive: true,
        validFrom: now,
        validUntil: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 2 months
        createdAt: now,
        updatedAt: now
    },
    {
        code: 'FLAT5000',
        name: 'Flat Discount',
        description: 'Flat ₹5000 off on orders above ₹30000',
        type: 'fixed',
        value: 5000,
        minAmount: 30000,
        usageLimit: 100,
        usedCount: 0,
        isActive: true,
        validFrom: now,
        validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 1 month
        createdAt: now,
        updatedAt: now
    }
];

seedIfEmpty('coupons', additionalCoupons, 'code');

// 4. Seed Reviews
const sampleReviews = [
    {
        userId: ObjectId(),
        userName: 'Sarah Johnson',
        productId: ObjectId(),
        rating: 5,
        comment: 'Absolutely stunning piece! The quality is exceptional and it arrived beautifully packaged. Highly recommend!',
        images: [],
        isVerified: true,
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
    },
    {
        userId: ObjectId(),
        userName: 'Michael Chen',
        productId: ObjectId(),
        rating: 4,
        comment: 'Beautiful jewelry, exactly as described. Fast shipping and great customer service.',
        images: [],
        isVerified: true,
        createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
    },
    {
        userId: ObjectId(),
        userName: 'Priya Sharma',
        productId: ObjectId(),
        rating: 5,
        comment: 'Perfect for my anniversary! My wife loves it. The craftsmanship is outstanding.',
        images: [],
        isVerified: true,
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000)
    }
];

seedIfEmpty('reviews', sampleReviews);

// 5. Seed Guest Sessions
const sampleGuestSessions = [
    {
        sessionId: 'guest_' + Date.now() + '_001',
        email: 'guest1@example.com',
        name: 'Guest User 1',
        cartItems: [],
        createdAt: now,
        lastActivity: now,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    },
    {
        sessionId: 'guest_' + Date.now() + '_002',
        phone: '+1234567899',
        cartItems: [],
        createdAt: now,
        lastActivity: now,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    }
];

seedIfEmpty('guest_sessions', sampleGuestSessions, 'sessionId');

// 6. Seed Loyalty Programs
const sampleLoyaltyPrograms = [
    {
        userId: ObjectId(),
        totalPoints: 1250,
        currentPoints: 850,
        tier: 'silver',
        loginStreak: 5,
        lastLoginDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        totalSpent: 125000,
        totalOrders: 8,
        transactions: [
            {
                _id: ObjectId(),
                type: 'earned',
                points: 125,
                description: 'Points earned from order #TJ123456',
                orderId: ObjectId(),
                createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
            },
            {
                _id: ObjectId(),
                type: 'redeemed',
                points: -400,
                description: 'Redeemed voucher SAVE400',
                createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
            }
        ],
        vouchers: [],
        joinedAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
        updatedAt: now
    }
];

seedIfEmpty('loyalty_programs', sampleLoyaltyPrograms);

// 7. Seed Vouchers
const sampleVouchers = [
    {
        code: 'LOYALTY500',
        title: 'Loyalty Reward Voucher',
        description: '₹500 off on your next purchase',
        type: 'loyalty',
        discountType: 'fixed',
        value: 500,
        minOrderValue: 2000,
        maxDiscount: 500,
        pointsCost: 500,
        maxRedemptions: 1000,
        maxPerUser: 1,
        validFrom: now,
        validUntil: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
        usageConditions: {},
        isActive: true,
        imageUrl: '',
        terms: [
            'Valid for 90 days from issue date',
            'Cannot be combined with other offers',
            'Minimum order value ₹2000'
        ],
        createdAt: now,
        updatedAt: now
    },
    {
        code: 'WELCOME1000',
        title: 'Welcome Bonus Voucher',
        description: '₹1000 off on orders above ₹5000',
        type: 'welcome',
        discountType: 'fixed',
        value: 1000,
        minOrderValue: 5000,
        maxDiscount: 1000,
        pointsCost: 0,
        maxRedemptions: 500,
        maxPerUser: 1,
        validFrom: now,
        validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        usageConditions: {},
        isActive: true,
        imageUrl: '',
        terms: [
            'Valid for new customers only',
            'One-time use per customer',
            'Minimum order value ₹5000'
        ],
        createdAt: now,
        updatedAt: now
    }
];

seedIfEmpty('vouchers', sampleVouchers, 'code');

// 8. Seed Badges
const sampleBadges = [
    {
        name: 'First Purchase',
        description: 'Congratulations on your first purchase!',
        iconUrl: '🛍️',
        criteria: 'Complete your first order',
        rarity: 'common',
        points: 50,
        isActive: true,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Loyal Customer',
        description: 'Thank you for being a loyal customer!',
        iconUrl: '⭐',
        criteria: 'Complete 10 orders',
        rarity: 'rare',
        points: 200,
        isActive: true,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Big Spender',
        description: 'You love luxury jewelry!',
        iconUrl: '💎',
        criteria: 'Spend over ₹100,000',
        rarity: 'epic',
        points: 500,
        isActive: true,
        createdAt: now,
        updatedAt: now
    },
    {
        name: 'Review Master',
        description: 'Thank you for your valuable reviews!',
        iconUrl: '📝',
        criteria: 'Submit 20 product reviews',
        rarity: 'rare',
        points: 150,
        isActive: true,
        createdAt: now,
        updatedAt: now
    }
];

seedIfEmpty('badges', sampleBadges, 'name');

// 9. Seed Referral Program Configuration
const referralProgramConfig = [
    {
        isActive: true,
        referrerReward: 200,
        refereeReward: 100,
        minOrderValue: 1000,
        maxReferrals: 10,
        validityDays: 30,
        description: 'Refer friends and earn rewards when they make their first purchase!',
        terms: [
            'Referee must be a new customer',
            'Minimum order value of ₹1000 required',
            'Rewards credited after successful order completion',
            'Referral link valid for 30 days',
            'Maximum 10 referrals per user'
        ],
        createdAt: now,
        updatedAt: now
    }
];

seedIfEmpty('referral_programs', referralProgramConfig);

// 10. Seed Sample Carts (for existing users)
const sampleCarts = [
    {
        userId: ObjectId(),
        items: [
            {
                productId: ObjectId(),
                quantity: 1,
                addedAt: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
            }
        ],
        discount: 0,
        createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
        updatedAt: now
    }
];

seedIfEmpty('carts', sampleCarts);

// 11. Seed Sample Wishlists
const sampleWishlists = [
    {
        userId: ObjectId(),
        productIds: [ObjectId(), ObjectId()],
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        updatedAt: now
    }
];

seedIfEmpty('wishlist', sampleWishlists);

// 12. Create indexes for better performance
print('📊 Creating database indexes...');

try {
    // Users indexes
    db.users.createIndex({ email: 1 }, { unique: true });
    db.users.createIndex({ phone: 1 }, { unique: true });
    db.users.createIndex({ isActive: 1 });
    
    // Products indexes
    db.products.createIndex({ name: "text", description: "text" });
    db.products.createIndex({ category: 1, subcategory: 1 });
    db.products.createIndex({ isAvailable: 1, isFeatured: 1 });
    db.products.createIndex({ price: 1 });
    db.products.createIndex({ rating: -1 });
    
    // Orders indexes
    db.orders.createIndex({ orderNumber: 1 }, { unique: true });
    db.orders.createIndex({ userId: 1 });
    db.orders.createIndex({ guestSessionId: 1 });
    db.orders.createIndex({ status: 1 });
    db.orders.createIndex({ createdAt: -1 });
    
    // Coupons indexes
    db.coupons.createIndex({ code: 1 }, { unique: true });
    db.coupons.createIndex({ isActive: 1 });
    
    // Reviews indexes
    db.reviews.createIndex({ productId: 1 });
    db.reviews.createIndex({ userId: 1 });
    db.reviews.createIndex({ rating: -1 });
    
    // Guest sessions indexes
    db.guest_sessions.createIndex({ sessionId: 1 }, { unique: true });
    db.guest_sessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    
    // Loyalty programs indexes
    db.loyalty_programs.createIndex({ userId: 1 }, { unique: true });
    db.loyalty_programs.createIndex({ tier: 1 });
    
    // Vouchers indexes
    db.vouchers.createIndex({ code: 1 }, { unique: true });
    db.vouchers.createIndex({ type: 1 });
    db.vouchers.createIndex({ isActive: 1 });
    
    // Carts indexes
    db.carts.createIndex({ userId: 1 });
    db.carts.createIndex({ guestSessionId: 1 });
    
    // Wishlist indexes
    db.wishlist.createIndex({ userId: 1 });
    
    print('✅ Database indexes created successfully');
} catch (error) {
    print('⚠️  Some indexes may already exist: ' + error.message);
}

print('🎉 Comprehensive database seeding completed successfully!');
print('📈 Database is now ready with sample data for all collections.');
