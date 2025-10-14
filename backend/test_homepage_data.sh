#!/bin/bash

# Test data script for dynamic homepage
# This creates sample deals, flash sales, and brands

BASE_URL="http://localhost:8080/api/v1"

echo "=================================================="
echo "Dynamic Homepage Test Data Creator"
echo "=================================================="
echo ""

# Note: You need admin authentication to create these items
# If you don't have an admin token, you'll need to:
# 1. Create an admin account
# 2. Login to get a token
# 3. Add the token below

# Replace this with your actual admin token
# Get it by logging in as admin and copying the token from the response
ADMIN_TOKEN=""

if [ -z "$ADMIN_TOKEN" ]; then
  echo "⚠️  No admin token provided!"
  echo ""
  echo "To get an admin token:"
  echo "1. Login as admin using your app or:"
  echo "   curl -X POST $BASE_URL/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@example.com\",\"password\":\"your_password\"}'"
  echo ""
  echo "2. Copy the 'accessToken' from the response"
  echo "3. Edit this script and add it to ADMIN_TOKEN variable above"
  echo ""
  read -p "Do you want to continue without authentication? (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Set headers
if [ -n "$ADMIN_TOKEN" ]; then
  AUTH_HEADER="Authorization: Bearer $ADMIN_TOKEN"
else
  AUTH_HEADER="X-Skip-Auth: true"
fi

echo "Creating test data..."
echo ""

# 1. CREATE DEAL OF DAY
echo "📍 Creating Deal of Day..."
DEAL_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/homepage/deal-of-day" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "productId": "68d56575e0f468d0541e9b1c",
    "discountPercent": 30,
    "stock": 50,
    "startTime": "'$(date -u -v+0H +"%Y-%m-%dT%H:%M:%SZ")'",
    "endTime": "'$(date -u -v+24H +"%Y-%m-%dT%H:%M:%SZ")'"
  }')

echo "$DEAL_RESPONSE" | python3 -m json.tool
echo ""
echo "✅ Deal of Day created!"
echo ""

# 2. CREATE FLASH SALE
echo "📍 Creating Flash Sale..."
FLASH_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/homepage/flash-sale" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "title": "Weekend Flash Sale",
    "description": "Huge discounts on selected items - Limited time only!",
    "bannerImage": "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338",
    "productIds": [
      "68d56575e0f468d0541e9b1b",
      "68dfd3dc0665ee044efd6b6b",
      "68d56575e0f468d0541e9b19"
    ],
    "startTime": "'$(date -u -v+0H +"%Y-%m-%dT%H:%M:%SZ")'",
    "endTime": "'$(date -u -v+48H +"%Y-%m-%dT%H:%M:%SZ")'",
    "discount": 40
  }')

echo "$FLASH_RESPONSE" | python3 -m json.tool
echo ""
echo "✅ Flash Sale created!"
echo ""

# 3. CREATE BRANDS
echo "📍 Creating Brands..."

# Brand 1: Tiffany & Co
BRAND1_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/homepage/brands" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "name": "Tiffany & Co",
    "logo": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Tiffany_%26_Co._logo.svg/240px-Tiffany_%26_Co._logo.svg.png",
    "description": "Luxury jewelry and specialty retailer",
    "priority": 1
  }')

echo "Brand 1: Tiffany & Co"
echo "$BRAND1_RESPONSE" | python3 -m json.tool
echo ""

# Brand 2: Cartier
BRAND2_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/homepage/brands" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "name": "Cartier",
    "logo": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Cartier_logo.svg/240px-Cartier_logo.svg.png",
    "description": "French luxury goods conglomerate",
    "priority": 2
  }')

echo "Brand 2: Cartier"
echo "$BRAND2_RESPONSE" | python3 -m json.tool
echo ""

# Brand 3: Bulgari
BRAND3_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/homepage/brands" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "name": "Bulgari",
    "logo": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Bulgari_logo.svg/240px-Bulgari_logo.svg.png",
    "description": "Italian luxury jewelry and watches",
    "priority": 3
  }')

echo "Brand 3: Bulgari"
echo "$BRAND3_RESPONSE" | python3 -m json.tool
echo ""

echo "✅ All brands created!"
echo ""

# 4. VERIFY HOMEPAGE DATA
echo "=================================================="
echo "Verifying homepage data..."
echo "=================================================="
echo ""

HOMEPAGE_DATA=$(curl -s "$BASE_URL/homepage")
echo "$HOMEPAGE_DATA" | python3 -m json.tool | head -100

echo ""
echo "=================================================="
echo "✅ Test data creation complete!"
echo "=================================================="
echo ""
echo "Now refresh your Flutter app to see:"
echo "  • Deal of Day with 30% off (24 hours)"
echo "  • Flash Sale with 40% off (48 hours)"
echo "  • 3 Brand logos"
echo ""
echo "Note: Recently Viewed will appear after you view products"
echo "=================================================="
