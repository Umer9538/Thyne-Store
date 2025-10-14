# Event & Festival Management Feature Guide

## Overview

This feature enables admins to create special events, festivals, and promotions with dynamic banners, discount popups, and theme customization. Perfect for seasonal sales, festivals like Diwali, Christmas, Valentine's Day, etc.

## Features Implemented

### 1. **Event Management**
- Create and manage festival/event entries
- Schedule events with dates
- Mark events as recurring (annual festivals)
- Suggest product categories for each event

### 2. **Banner Management**
- Create dynamic banners for homepage
- Schedule banners with start/end dates
- Set priority levels for multiple banners
- Tag banners with festival themes
- Auto-hide expired banners

### 3. **Theme Customization**
- Change app colors dynamically
- Pre-defined themes for popular festivals:
  - Diwali (Orange/Amber)
  - Christmas (Red/Green/Gold)
  - Valentine's Day (Pink/Red)
  - New Year (Blue/Gold)
  - Default (Green)

### 4. **Event Promotions**
- Create discounts tied to events
- Three discount types:
  - **Percentage**: e.g., 25% off
  - **Fixed Amount**: e.g., ₹500 off
  - **BOGO**: Buy One Get One
- Apply promotions to:
  - All products
  - Specific categories
  - Specific products
- Set minimum purchase requirements
- Set maximum discount caps

### 5. **Promotional Popups**
- Show discount popups on home screen
- Control popup frequency:
  - **Once**: Show only once ever
  - **Daily**: Show once per day
  - **Session**: Show every app session
- Add custom images to popups
- Auto-dismiss or manual dismiss

### 6. **Dynamic Discount Badges**
- Product cards automatically show event discounts
- Special festival badges with gradient styling
- Priority given to event discounts over regular sales
- Shows event name alongside discount

## How to Use

### For Admins

#### Creating an Event

1. Navigate to Admin Panel → Events → Calendar
2. Click "New Event" button
3. Fill in event details:
   - **Name**: e.g., "Diwali 2025"
   - **Type**: festival/sale/promotion/holiday
   - **Date**: Event date and time
   - **Description**: Optional details
   - **Theme Color**: Hex color code (e.g., #FF6F00)
   - **Suggested Categories**: Select relevant product categories
   - **Recurring**: Check if annual event
   - **Active**: Toggle to enable/disable

#### Creating a Banner

1. Navigate to Admin Panel → Homepage Manager
2. Click "New Banner"
3. Fill in banner details:
   - **Title**: Banner headline
   - **Image**: Upload or provide URL
   - **Description**: Optional subtitle
   - **Type**: main/promotional/festival/flash_sale
   - **Festival Tag**: Link to specific festival
   - **Priority**: Higher number = shows first (0-10)
   - **Start/End Date**: Schedule visibility
   - **Target**: Optional link/product/category
   - **Active**: Toggle to enable/disable

#### Switching Themes

1. Navigate to Admin Panel → Theme Switcher
2. Select from pre-defined festival themes
3. Click "Activate Theme"
4. Changes apply immediately to all users

#### Creating a Promotion

1. Navigate to Admin Panel → Promotions
2. Click "New Promotion"
3. Fill in promotion details:
   - **Event**: Link to created event
   - **Title**: e.g., "Diwali Mega Sale"
   - **Description**: Promotion details
   - **Discount Type**: percentage/fixed/bogo
   - **Discount Value**: Amount or percentage
   - **Min Purchase**: Optional minimum amount
   - **Max Discount**: Optional cap on discount
   - **Applicable To**: all/category/product
   - **Categories/Products**: Select if not "all"
   - **Start/End Date**: Promotion period
   - **Show as Popup**: Enable popup display
   - **Popup Image**: Custom popup image
   - **Popup Frequency**: once/daily/session

## API Endpoints

### Public Endpoints (No Auth Required)

```
GET /api/v1/events/upcoming
- Get upcoming events

GET /api/v1/banners/active
- Get currently active banners

GET /api/v1/theme/active
- Get active theme configuration

GET /api/v1/promotions/active
- Get active promotions

GET /api/v1/promotions/popups
- Get promotions to show as popups
```

### Admin Endpoints (Auth + Admin Role Required)

#### Events
```
POST   /api/v1/admin/events
GET    /api/v1/admin/events
GET    /api/v1/admin/events/:id
PUT    /api/v1/admin/events/:id
DELETE /api/v1/admin/events/:id
```

#### Banners
```
POST   /api/v1/admin/banners
GET    /api/v1/admin/banners
GET    /api/v1/admin/banners/:id
PUT    /api/v1/admin/banners/:id
DELETE /api/v1/admin/banners/:id
```

#### Themes
```
POST   /api/v1/admin/themes
GET    /api/v1/admin/themes
POST   /api/v1/admin/themes/:id/activate
DELETE /api/v1/admin/themes/:id
```

#### Promotions
```
POST   /api/v1/admin/promotions
DELETE /api/v1/admin/promotions/:id
```

## Database Collections

### events
```javascript
{
  _id: ObjectId,
  name: String,
  type: String, // 'festival', 'sale', 'promotion', 'holiday'
  date: Date,
  description: String (optional),
  themeColor: String (optional),
  iconUrl: String (optional),
  isRecurring: Boolean,
  suggestedCategories: [String],
  bannerTemplate: String (optional),
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### banners
```javascript
{
  _id: ObjectId,
  title: String,
  imageUrl: String,
  description: String (optional),
  type: String, // 'main', 'promotional', 'festival', 'flash_sale'
  targetUrl: String (optional),
  targetProductId: String (optional),
  targetCategory: String (optional),
  startDate: Date,
  endDate: Date (optional),
  isActive: Boolean,
  priority: Number,
  festivalTag: String (optional),
  createdAt: Date,
  updatedAt: Date
}
```

### themes
```javascript
{
  _id: ObjectId,
  name: String,
  type: String, // 'festival', 'seasonal', 'custom'
  primaryColor: String, // hex color
  secondaryColor: String,
  accentColor: String,
  logoUrl: String (optional),
  backgroundImage: String (optional),
  startDate: Date (optional),
  endDate: Date (optional),
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### event_promotions
```javascript
{
  _id: ObjectId,
  eventId: ObjectId,
  eventName: String,
  title: String,
  description: String,
  discountType: String, // 'percentage', 'fixed', 'bogo'
  discountValue: Number,
  minPurchase: Number (optional),
  maxDiscount: Number (optional),
  applicableTo: String, // 'all', 'category', 'product'
  categories: [String],
  productIds: [String],
  startDate: Date,
  endDate: Date,
  isActive: Boolean,
  showAsPopup: Boolean,
  popupImageUrl: String (optional),
  popupFrequency: String, // 'once', 'daily', 'session'
  createdAt: Date,
  updatedAt: Date
}
```

## Example Use Cases

### 1. Diwali Festival Sale

1. **Create Event**: "Diwali 2025" (Oct 24, 2025)
2. **Activate Theme**: Diwali theme (Orange/Amber colors)
3. **Create Banners**: 
   - Main hero banner with Diwali imagery
   - Countdown banner for last day
4. **Create Promotions**:
   - 25% off on all jewelry
   - Extra 10% on gold items
   - BOGO on selected items
5. **Enable Popups**: Daily popup with special offers

### 2. Valentine's Day Special

1. **Create Event**: "Valentine's Day" (Feb 14, 2025)
2. **Activate Theme**: Valentine theme (Pink/Red)
3. **Create Banners**: Romantic couple images
4. **Create Promotions**:
   - 20% off on rings and pendants
   - Free gift wrapping
5. **Enable Popups**: Session popup for couple packages

### 3. Flash Sale

1. **Create Event**: "24-Hour Flash Sale"
2. **Keep Theme**: Default
3. **Create Banners**: Countdown timer banner
4. **Create Promotions**:
   - Flat ₹1000 off on purchases above ₹10,000
   - 30% off on clearance items
5. **Enable Popups**: Once popup to announce sale

## Technical Details

### Frontend Components

- **EventPromotionPopup**: Animated popup widget
- **PromotionManager**: Service to manage popup display logic
- **ProductCard**: Enhanced with event discount badges
- **EventCalendarScreen**: Admin event management
- **BannerFormScreen**: Admin banner creation
- **HomepageManagerScreen**: Admin banner management
- **ThemeSwitcherScreen**: Admin theme activation

### Backend Components

- **event.go**: Event, Banner, Theme, Promotion models
- **event_repository.go**: Database operations
- **event_handler.go**: API endpoint handlers
- **main.go**: Route registration

### Dependencies Added

- `shared_preferences`: For storing popup display history
- `table_calendar`: For event calendar view

## Testing

### Test Event Creation
```bash
curl -X POST http://localhost:8080/api/v1/admin/events \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Diwali 2025",
    "type": "festival",
    "date": "2025-10-24T00:00:00Z",
    "description": "Festival of Lights",
    "themeColor": "#FF6F00",
    "isRecurring": true,
    "suggestedCategories": ["Rings", "Necklaces"],
    "isActive": true
  }'
```

### Test Banner Creation
```bash
curl -X POST http://localhost:8080/api/v1/admin/banners \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Diwali Sale",
    "imageUrl": "https://example.com/diwali-banner.jpg",
    "type": "festival",
    "festivalTag": "diwali",
    "startDate": "2025-10-20T00:00:00Z",
    "endDate": "2025-10-25T00:00:00Z",
    "priority": 10,
    "isActive": true
  }'
```

### Test Promotion Creation
```bash
curl -X POST http://localhost:8080/api/v1/admin/promotions \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "EVENT_ID_HERE",
    "eventName": "Diwali",
    "title": "Diwali Mega Sale",
    "description": "Get up to 25% off on all jewelry",
    "discountType": "percentage",
    "discountValue": 25,
    "minPurchase": 5000,
    "applicableTo": "all",
    "startDate": "2025-10-20T00:00:00Z",
    "endDate": "2025-10-25T00:00:00Z",
    "isActive": true,
    "showAsPopup": true,
    "popupFrequency": "daily"
  }'
```

## Troubleshooting

### Banners Not Showing
- Check `isActive` is true
- Verify `startDate` is in the past
- Verify `endDate` (if set) is in the future
- Check banner priority (higher = first)

### Promotions Not Appearing
- Verify promotion is within date range
- Check `isActive` is true
- For popups, check device storage hasn't blocked it

### Theme Not Changing
- Only one theme can be active at a time
- Ensure theme activation API call succeeded
- App may need restart on some devices

### Discount Badges Not Showing
- Check promotion `applicableTo` matches product/category
- Verify promotion dates are current
- Check product is `isAvailable`

## Future Enhancements

- [ ] Email notifications for scheduled events
- [ ] Analytics dashboard for promotion performance
- [ ] A/B testing for different banner designs
- [ ] Geolocation-based promotions
- [ ] User segment targeting
- [ ] Push notifications for flash sales
- [ ] Social media integration for event sharing

## Support

For issues or questions, contact the development team or refer to:
- Backend API Documentation: `/docs`
- Flutter Documentation: `lib/README.md`

