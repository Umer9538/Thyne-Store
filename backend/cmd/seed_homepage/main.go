package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"thyne-jewels-backend/internal/config"
	"thyne-jewels-backend/internal/models"
)

func main() {
	fmt.Println("🌟 Dynamic Homepage Test Data Seeder")
	fmt.Println("=====================================")
	fmt.Println()

	// Load config
	cfg := config.Load()

	// Connect to MongoDB
	fmt.Println("📡 Connecting to MongoDB...")
	clientOptions := options.Client().ApplyURI(cfg.Database.URI)
	client, err := mongo.Connect(context.Background(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(context.Background())

	// Ping MongoDB
	if err := client.Ping(context.Background(), nil); err != nil {
		log.Fatal(err)
	}
	fmt.Println("✅ Connected to MongoDB")
	fmt.Println()

	db := client.Database(cfg.Database.Name)

	// Get product IDs (we'll use existing products)
	productsCollection := db.Collection("products")
	ctx := context.Background()

	var products []models.Product
	cursor, err := productsCollection.Find(ctx, primitive.M{}, options.Find().SetLimit(5))
	if err != nil {
		log.Fatal(err)
	}
	if err := cursor.All(ctx, &products); err != nil {
		log.Fatal(err)
	}

	if len(products) == 0 {
		log.Fatal("❌ No products found! Please add products first.")
	}

	fmt.Printf("📦 Found %d products to use\n", len(products))
	fmt.Println()

	// 1. CREATE DEAL OF DAY
	fmt.Println("📍 Creating Deal of Day...")
	dealCollection := db.Collection("deals_of_day")

	deal := models.DealOfDay{
		ID:              primitive.NewObjectID(),
		ProductID:       products[0].ID,
		OriginalPrice:   products[0].Price,
		DealPrice:       products[0].Price * 0.7, // 30% off
		DiscountPercent: 30,
		StartTime:       time.Now(),
		EndTime:         time.Now().Add(24 * time.Hour),
		Stock:           50,
		SoldCount:       5,
		IsActive:        true,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	_, err = dealCollection.InsertOne(ctx, deal)
	if err != nil {
		fmt.Printf("⚠️  Warning: Could not create deal: %v\n", err)
	} else {
		fmt.Printf("✅ Deal of Day created for: %s\n", products[0].Name)
		fmt.Printf("   Original: $%.2f → Deal: $%.2f (30%% off)\n", deal.OriginalPrice, deal.DealPrice)
		fmt.Printf("   Valid until: %s\n", deal.EndTime.Format("2006-01-02 15:04"))
	}
	fmt.Println()

	// 2. CREATE FLASH SALE
	fmt.Println("📍 Creating Flash Sale...")
	flashSaleCollection := db.Collection("flash_sales")

	var flashProductIDs []primitive.ObjectID
	for i := 1; i < len(products) && i < 4; i++ {
		flashProductIDs = append(flashProductIDs, products[i].ID)
	}

	flashSale := models.FlashSale{
		ID:          primitive.NewObjectID(),
		Title:       "Weekend Flash Sale",
		Description: "Huge discounts on selected items - Limited time only!",
		BannerImage: "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338",
		ProductIDs:  flashProductIDs,
		StartTime:   time.Now(),
		EndTime:     time.Now().Add(48 * time.Hour),
		Discount:    40,
		IsActive:    true,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	_, err = flashSaleCollection.InsertOne(ctx, flashSale)
	if err != nil {
		fmt.Printf("⚠️  Warning: Could not create flash sale: %v\n", err)
	} else {
		fmt.Printf("✅ Flash Sale created: %s\n", flashSale.Title)
		fmt.Printf("   Products: %d items\n", len(flashSale.ProductIDs))
		fmt.Printf("   Discount: %d%%\n", flashSale.Discount)
		fmt.Printf("   Valid until: %s\n", flashSale.EndTime.Format("2006-01-02 15:04"))
	}
	fmt.Println()

	// 3. CREATE BRANDS
	fmt.Println("📍 Creating Brands...")
	brandCollection := db.Collection("brands")

	brands := []models.Brand{
		{
			ID:          primitive.NewObjectID(),
			Name:        "Tiffany & Co",
			Logo:        "https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Tiffany_%26_Co._logo.svg/240px-Tiffany_%26_Co._logo.svg.png",
			Description: "Luxury jewelry and specialty retailer",
			IsActive:    true,
			Priority:    1,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		},
		{
			ID:          primitive.NewObjectID(),
			Name:        "Cartier",
			Logo:        "https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Cartier_logo.svg/240px-Cartier_logo.svg.png",
			Description: "French luxury goods conglomerate",
			IsActive:    true,
			Priority:    2,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		},
		{
			ID:          primitive.NewObjectID(),
			Name:        "Bulgari",
			Logo:        "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Bulgari_logo.svg/240px-Bulgari_logo.svg.png",
			Description: "Italian luxury jewelry and watches",
			IsActive:    true,
			Priority:    3,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		},
	}

	for _, brand := range brands {
		_, err := brandCollection.InsertOne(ctx, brand)
		if err != nil {
			fmt.Printf("⚠️  Warning: Could not create brand %s: %v\n", brand.Name, err)
		} else {
			fmt.Printf("✅ Brand created: %s\n", brand.Name)
		}
	}

	fmt.Println()

	// 4. CREATE 360° SHOWCASE
	fmt.Println("📍 Creating 360° Showcase...")
	showcase360Collection := db.Collection("showcases_360")

	showcase360 := models.Showcase360{
		ID:        primitive.NewObjectID(),
		ProductID: products[1].ID,
		Title:     "360° View: Diamond Pendant",
		Description: "Rotate and zoom to see every detail",
		Images360: []string{
			"https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=800",
			"https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800",
			"https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800",
			"https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800",
		},
		VideoURL:     "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
		ThumbnailURL: "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400",
		Priority:     1,
		IsActive:     true,
		StartTime:    nil,
		EndTime:      nil,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	_, err = showcase360Collection.InsertOne(ctx, showcase360)
	if err != nil {
		fmt.Printf("⚠️  Warning: Could not create 360° showcase: %v\n", err)
	} else {
		fmt.Printf("✅ 360° Showcase created for: %s\n", products[1].Name)
		fmt.Printf("   Images: %d angles\n", len(showcase360.Images360))
		fmt.Printf("   Video included: %t\n", showcase360.VideoURL != "")
	}
	fmt.Println()

	// 5. CREATE BUNDLE DEALS
	fmt.Println("📍 Creating Bundle Deals...")
	bundleDealCollection := db.Collection("bundle_deals")

	// Bridal Bundle
	bridalBundle := models.BundleDeal{
		ID:          primitive.NewObjectID(),
		Title:       "Complete Bridal Set",
		Description: "Necklace, Earrings & Ring - Perfect for your special day",
		BannerImage: "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=1200",
		Items: []models.BundleItem{
			{ProductID: products[0].ID, Quantity: 1},
			{ProductID: products[1].ID, Quantity: 1},
			{ProductID: products[2].ID, Quantity: 1},
		},
		OriginalPrice:   products[0].Price + products[1].Price + products[2].Price,
		BundlePrice:     (products[0].Price + products[1].Price + products[2].Price) * 0.75, // 25% off
		DiscountPercent: 25,
		Category:        "Bridal",
		Priority:        1,
		IsActive:        true,
		StartTime:       nil,
		EndTime:         nil,
		Stock:           20,
		SoldCount:       3,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	_, err = bundleDealCollection.InsertOne(ctx, bridalBundle)
	if err != nil {
		fmt.Printf("⚠️  Warning: Could not create bridal bundle: %v\n", err)
	} else {
		fmt.Printf("✅ Bundle Deal created: %s\n", bridalBundle.Title)
		fmt.Printf("   Items: %d products\n", len(bridalBundle.Items))
		fmt.Printf("   Original: $%.2f → Bundle: $%.2f (25%% off)\n",
			bridalBundle.OriginalPrice, bridalBundle.BundlePrice)
		fmt.Printf("   You save: $%.2f\n",
			bridalBundle.OriginalPrice-bridalBundle.BundlePrice)
	}

	// Gift Set Bundle
	if len(products) >= 5 {
		giftBundle := models.BundleDeal{
			ID:          primitive.NewObjectID(),
			Title:       "Perfect Gift Set",
			Description: "Curated collection for the perfect gift",
			BannerImage: "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=1200",
			Items: []models.BundleItem{
				{ProductID: products[3].ID, Quantity: 1},
				{ProductID: products[4].ID, Quantity: 1},
			},
			OriginalPrice:   products[3].Price + products[4].Price,
			BundlePrice:     (products[3].Price + products[4].Price) * 0.80, // 20% off
			DiscountPercent: 20,
			Category:        "Gift Set",
			Priority:        2,
			IsActive:        true,
			StartTime:       nil,
			EndTime:         nil,
			Stock:           30,
			SoldCount:       8,
			CreatedAt:       time.Now(),
			UpdatedAt:       time.Now(),
		}

		_, err = bundleDealCollection.InsertOne(ctx, giftBundle)
		if err != nil {
			fmt.Printf("⚠️  Warning: Could not create gift bundle: %v\n", err)
		} else {
			fmt.Printf("✅ Bundle Deal created: %s\n", giftBundle.Title)
			fmt.Printf("   Items: %d products\n", len(giftBundle.Items))
			fmt.Printf("   Original: $%.2f → Bundle: $%.2f (20%% off)\n",
				giftBundle.OriginalPrice, giftBundle.BundlePrice)
		}
	}

	fmt.Println()
	fmt.Println("=====================================")
	fmt.Println("✅ Test data creation complete!")
	fmt.Println("=====================================")
	fmt.Println()
	fmt.Println("Now refresh your Flutter app to see:")
	fmt.Println("  • Deal of Day with 30% off (24 hours)")
	fmt.Println("  • Flash Sale with 40% off (48 hours)")
	fmt.Println("  • 3 Brand logos")
	fmt.Println("  • 360° Product Showcase with rotation & video")
	fmt.Println("  • 2 Bundle Deals (Bridal Set & Gift Set)")
	fmt.Println()
	fmt.Println("Note: Recently Viewed will appear after you view products")
	fmt.Println("=====================================")
}
