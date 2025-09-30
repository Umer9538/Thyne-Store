package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	baseURL := "http://localhost:8080/api"
	
	// Test product creation
	productData := map[string]interface{}{
		"name":          "Test Diamond Ring",
		"description":   "A beautiful test diamond ring",
		"price":         25000.0,
		"originalPrice": 30000.0,
		"stockQuantity": 10,
		"category":      "Rings",
		"subcategory":   "Engagement Rings",
		"metalType":     "Gold",
		"stoneType":     "Diamond",
		"material":      "18K Gold",
		"weight":        5.2,
		"size":          "Size 7",
		"images":        []string{"https://example.com/ring1.jpg"},
		"isAvailable":   true,
		"isFeatured":    false,
		"tags":          []string{"diamond", "engagement", "gold"},
	}

	jsonData, _ := json.Marshal(productData)
	
	// Test create product endpoint
	resp, err := http.Post(
		baseURL+"/admin/products", 
		"application/json", 
		bytes.NewBuffer(jsonData),
	)
	
	if err != nil {
		log.Printf("Error testing create product: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 || resp.StatusCode == 201 {
		fmt.Println("✅ Admin product creation API is working!")
	} else {
		fmt.Printf("❌ Admin product creation failed with status: %d\n", resp.StatusCode)
	}

	// Test get categories
	resp2, err := http.Get(baseURL + "/admin/categories")
	if err != nil {
		log.Printf("Error testing get categories: %v", err)
		return
	}
	defer resp2.Body.Close()

	if resp2.StatusCode == 200 {
		fmt.Println("✅ Admin categories API is working!")
	} else {
		fmt.Printf("❌ Admin categories failed with status: %d\n", resp2.StatusCode)
	}

	// Test dashboard stats
	resp3, err := http.Get(baseURL + "/admin/dashboard/stats")
	if err != nil {
		log.Printf("Error testing dashboard stats: %v", err)
		return
	}
	defer resp3.Body.Close()

	if resp3.StatusCode == 200 {
		fmt.Println("✅ Admin dashboard stats API is working!")
	} else {
		fmt.Printf("❌ Admin dashboard stats failed with status: %d\n", resp3.StatusCode)
	}

	fmt.Println("\n🎉 Admin API implementation test completed!")
	fmt.Println("Note: Authentication middleware needs to be properly configured for full functionality.")
}
