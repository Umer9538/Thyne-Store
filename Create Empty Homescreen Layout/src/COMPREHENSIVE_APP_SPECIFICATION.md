# Thyne - Comprehensive Application Specification

## 1. Overview & Design Philosophy

### 1.1 Core Concept
Thyne is a modern mobile-first homescreen application featuring a luxurious, minimal dark theme with smooth animations and a comprehensive commerce experience. The app combines e-commerce, social community, and AI-powered creation tools in a unified, elegant interface inspired by Cred's design aesthetic.

### 1.2 Design Principles

**Visual Hierarchy**
- App-level components and modules: Rounded corners (rounded-2xl, rounded-3xl, rounded-full)
- Module-internal components: Sharp edges (no rounding)
- Clear separation between global navigation and module-specific content

**Color System - Module-wise Theming**
- **Commerce Module**: Green/Emerald/Teal palette with neon-y glowy aesthetic
  - Primary: `emerald-400` (dark) / `emerald-600` (light)
  - Gradients: `from-emerald-600 via-teal-600 to-emerald-600`
  - Shadows: `shadow-emerald-600/40`
  
- **Community Module**: Red/Rose/Pink palette with neon-y glowy aesthetic
  - Primary: `red-400` (dark) / `red-600` (light)
  - Gradients: `from-red-600 via-rose-600 to-pink-600`
  - Shadows: `shadow-red-600/40`
  
- **Create Module**: Blue/Cyan/Sky palette with neon-y glowy aesthetic
  - Primary: `blue-400` (dark) / `blue-600` (light)
  - Gradients: `from-blue-600 via-cyan-600 to-sky-600`
  - Shadows: `shadow-blue-600/40`

**Dark Theme Aesthetic**
- Base colors: `black` or `black/40` with backdrop blur
- Text: `white/90` (primary), `white/60` (secondary), `white/40` (tertiary), `white/30` (placeholder)
- Borders: `white/[0.03]` (default), `white/5` or `white/10` (hover/active)
- Backgrounds: `black/40`, `white/[0.03]`, `white/5`, `white/10`
- Glass morphism: `backdrop-blur-2xl` extensively used

**Light Theme Aesthetic** (complementary)
- Base colors: `white` or `white/60` with backdrop blur
- Text: `black/90` (primary), `black/60` (secondary), `black/40` (tertiary), `black/30` (placeholder)
- Borders: `black/[0.03]` (default), `black/5` or `black/10` (hover/active)
- Backgrounds: `white/60`, `black/[0.03]`, `black/5`, `black/10`

**Typography System**
- NO Tailwind font size, weight, or line-height classes used (except when user explicitly requests)
- Typography defined in `styles/globals.css` with custom text classes:
  - `text-display-lg`: 96px display text
  - `text-display-md`: 72px display text
  - `text-display-sm`: 56px display text
  - `text-heading-xl`: 48px headings
  - `text-heading-lg`: 40px headings
  - `text-heading-md`: 32px headings
  - `text-heading-sm`: 24px headings
  - `text-body-lg`: 18px body text
  - `text-body-md`: 16px body text (default)
  - `text-body-sm`: 14px body text
  - `text-body-xs`: 12px body text
  - `text-label`: 10px uppercase labels with letter spacing

**Animation Philosophy**
- Smooth, premium feel with custom easing: `[0.32, 0.72, 0, 1]` or `[0.4, 0, 0.2, 1]`
- Spring animations for tab transitions: `{ type: 'spring', stiffness: 400-500, damping: 30-40 }`
- Micro-interactions: `whileHover={{ scale: 1.03-1.1 }}`, `whileTap={{ scale: 0.95-0.98 }}`
- Neon glow effects: Outer blur glow + inner gradient background
- Duration: 0.3-0.5s for most transitions
- Smooth collapse/expand animations with height and opacity transitions

**Spacing & Layout**
- Consistent padding: `px-6` (24px) for main container, `px-5` (20px) for nav bars
- Gap spacing: `gap-3` (12px), `gap-4` (16px), `gap-6` (24px)
- Top padding for content areas:
  - Commerce: `pt-[180px]` (accounts for collapsible app bar + commerce top nav + spacing)
  - Community: `pt-[228px]` (accounts for collapsible app bar + community top nav + spacing)
  - Create: `pt-[228px]` (accounts for collapsible app bar + create top nav + spacing)
- Bottom padding: `pb-[200px]` (accounts for search bar + bottom nav + spacing)
- 20px breathing room between collapsible app bar and module top navs

## 2. Application Architecture

### 2.1 Tech Stack
- **Framework**: React with TypeScript
- **Styling**: Tailwind CSS v4.0 (no config file, tokens in globals.css)
- **Animations**: Motion (formerly Framer Motion) from `motion/react`
- **Icons**: Lucide React
- **UI Components**: shadcn/ui component library
- **State Management**: React useState hooks (no external state library)
- **Routing**: Client-side tab navigation (no router library)

### 2.2 File Structure

```
/App.tsx                              # Main application component
/styles/globals.css                   # Global styles, typography tokens
/data/jewelryData.ts                  # Mock jewelry product data
/components/
  ├── CollapsibleAppBar.tsx           # Global app bar (top)
  ├── CollapsibleBottomToolbar.tsx    # Bottom nav + search bar
  ├── SearchOverlay.tsx               # AI search overlay
  ├── CommerceTopNav.tsx              # Commerce module navigation
  ├── CommunityTopNav.tsx             # Community module navigation
  ├── CreateTopNav.tsx                # Create module navigation
  ├── ProductDetail.tsx               # Product detail page
  ├── BundleDetail.tsx                # Bundle detail page
  ├── Wishlist.tsx                    # Wishlist screen
  ├── ShoppingBag.tsx                 # Shopping bag screen
  ├── ProductList.tsx                 # Full product list view
  ├── CommunitySection.tsx            # Community main component
  ├── CreateSection.tsx               # Create/AI main component
  ├── *Shimmer.tsx                    # Loading skeletons
  └── commerce/                       # Commerce sub-components
      ├── CommerceContent.tsx         # Main commerce layout
      ├── HeroBanner.tsx              # Hero section
      ├── CategoryStories.tsx         # Story-style category nav
      ├── ProductCarousel.tsx         # Horizontal product scroll
      ├── ProductCard.tsx             # Product card component
      ├── ComboBundle.tsx             # Bundle card component
      ├── FlashDeals.tsx              # Flash deals section
      ├── PriceRangeCards.tsx         # Price filter cards
      ├── OccasionCards.tsx           # Occasion filter cards
      └── CollectionCard.tsx          # Collection card
  └── community/                      # Community sub-components
      ├── ThyneVerse.tsx              # Main feed
      ├── Spotlight.tsx               # Spotlight tab
      ├── MyProfile.tsx               # Profile tab
      ├── FeedPost.tsx                # Feed post card
      ├── FullScreenPost.tsx          # Full-screen post view
      └── ProductAvatarBadge.tsx      # Product badge component
  └── ui/                             # shadcn/ui components (42 components)
```

### 2.3 Main App Component (App.tsx)

**State Management**
```typescript
// Theme
const [theme, setTheme] = useState<'dark' | 'light'>('dark')

// Navigation
const [selectedTab, setSelectedTab] = useState<'commerce' | 'community' | 'create'>('commerce')
const [selectedCategory, setSelectedCategory] = useState('all')
const [selectedCommunityTab, setSelectedCommunityTab] = useState<'verse' | 'spotlight' | 'profile'>('verse')
const [selectedCreateTab, setSelectedCreateTab] = useState<'chat' | 'creations' | 'history'>('chat')

// UI State
const [isAppBarVisible, setIsAppBarVisible] = useState(true)
const [isBottomToolbarVisible, setIsBottomToolbarVisible] = useState(true)
const [isSearchOpen, setIsSearchOpen] = useState(false)
const [searchQuery, setSearchQuery] = useState('')

// Navigation State
const [activeScreen, setActiveScreen] = useState<'home' | 'productDetail' | 'bundleDetail' | 'wishlist' | 'bag' | 'productList' | 'fullPost'>('home')
const [selectedProduct, setSelectedProduct] = useState<Product | null>(null)
const [selectedBundle, setSelectedBundle] = useState<Bundle | null>(null)
const [selectedPost, setSelectedPost] = useState<Post | null>(null)
const [viewAllCategory, setViewAllCategory] = useState<string>('')

// Shopping State
const [wishlistItems, setWishlistItems] = useState<Product[]>([])
const [bagItems, setBagItems] = useState<Product[]>([])

// Loading State
const [isLoading, setIsLoading] = useState(true)

// Scroll Detection
const scrollContainerRef = useRef<HTMLDivElement>(null)
const lastScrollY = useRef(0)
```

**Scroll Detection Logic**
```typescript
// Hide/show toolbars based on scroll direction
// Scrolling down (> 5px): Hide both app bar and bottom toolbar
// Scrolling up (> 5px): Show both app bar and bottom toolbar
// Search open: Force hide bottom toolbar
// Full-screen post view: Force hide bottom toolbar
```

## 3. Global Navigation Structure

### 3.1 Collapsible App Bar (Top)

**Position**: Fixed at top, z-index 50
**Behavior**: 
- Slides up (-100px) when scrolling down
- Slides down (0px) when scrolling up
- Always visible when at top of page

**Structure**:
```
Row 1 (Always Visible):
  Left: Thyne logo + Avatar (Group2 SVG)
  Right: Theme toggle + User avatar

Row 2 (Collapsible):
  Left: Delivery address ("deliver to Sector 2") with MapPin icon
  Right: Gift icon + Heart icon (wishlist) + ShoppingBag icon (with count badge)
```

**Styling**:
- Background: `backdrop-blur-2xl` with `bg-black/40` (dark) or `bg-white/60` (light)
- Border: `border-b border-white/[0.03]` (dark) or `border-black/[0.03]` (light)
- Height when expanded: ~84px
- Positioned at `top: 0`
- Module top navs positioned at `top: 104px` when app bar visible (20px gap)

### 3.2 Collapsible Bottom Toolbar

**Position**: Fixed at bottom, z-index 40
**Components**: 3-tab navigation bar (compact, icons only)

**Tabs**:
1. **Commerce**: ShoppingBag icon
2. **Community**: Users icon  
3. **Create**: Sparkles icon

**Behavior**:
- Slides down (100px) when scrolling down
- Slides up (0) when scrolling up
- Each tab shows colored background circle when active
- Top indicator bar animates between tabs with `layoutId`
- Reduced padding: `py-3` for compact height

**Styling**:
- No text labels (icons only)
- Active state: Colored background circle + colored icon + top indicator
- Inactive state: 40% opacity, white/black icon
- Background: Same as app bar with backdrop blur

### 3.3 Persistent Search Bar

**Position**: Fixed, floats above bottom nav
- When bottom nav visible: `bottom: 64px`
- When bottom nav hidden: `bottom: 20px`
- Animates smoothly with bottom nav

**Structure**:
```
Left: FAB (Plus icon) - colored based on active tab
Right: Search input field with Search icon + Mic icon
```

**Styling**:
- FAB: 48x48px, full module color (emerald/red/blue)
- Search bar: Rounded-full, backdrop blur, expands on interaction
- Input placeholder: "ask me anything"
- Transitions: 0.4s with custom easing

### 3.4 Search Overlay

**Trigger**: Clicking search bar or input focus
**Coverage**: Full screen with backdrop blur
**Position**: 
- Top: `176px` (below app bar when visible)
- Bottom: `184px` (above search bar)

**Structure**:
```
Header:
  - AI avatar badge
  - "thyne AI" heading
  - Subheading with sparkle icon
  - Quick action chips (4 rounded pills)

Results Panel:
  - Category tabs: Products, Bundles, Posts, Creators
  - Grid layout with cards
  - Each card shows image, title, price/info
  - Module-colored accents

Footer (Fixed):
  - Search input (same as persistent search)
  - Close button
```

**Behavior**:
- Fades in/out with scale animation
- Prevents scroll on main content
- ESC key or backdrop click closes
- Results update based on search query (mock implementation)

## 4. Commerce Module

### 4.1 Commerce Top Navigation

**Position**: Fixed, below app bar
- When app bar visible: `top: 104px`
- When app bar hidden: `top: 0px`
- Z-index: 40

**Categories**: all | women | men | inclusive | kids

**Styling**:
- Emerald/teal themed
- Active tab: Outer glow blur + inner gradient + shadow + border
- Gradient: `from-emerald-600 via-teal-600 to-emerald-600`
- Pills: Rounded-full, horizontal scrollable
- Smooth spring animation with `layoutId`

### 4.2 Commerce Content Sections

**CommerceContent.tsx** - Main layout orchestrator

**Section Order**:

1. **Hero Banner**
   - Full-width image with overlay
   - Heading + description + CTA button
   - Gradient overlay for text readability
   - Height: 400px, object-cover image

2. **Category Stories**
   - Horizontal scroll of circular story buttons
   - Each category has icon + label
   - Active state with emerald ring
   - Categories: New Arrivals, Necklaces, Rings, Bracelets, Earrings, Watches

3. **New Arrivals Carousel**
   - Horizontal scroll of ProductCards
   - Each card: Image, title, price, rating
   - "View All" button at end
   - Gap: 12px between cards

4. **Combo Bundles Carousel**
   - Horizontal scroll of ComboBundle cards
   - Each bundle: Multiple product images, title, original price, bundle price, savings
   - Emerald "Save X%" badge
   - "View All" button at end

5. **Flash Deals**
   - Countdown timer component
   - Grid of 4 deal cards
   - Red accent for urgency
   - Limited time badge

6. **Shop by Price Range**
   - 4 cards: Under ₹5k | ₹5k-₹10k | ₹10k-₹25k | Luxury
   - Each card with icon + price range
   - Border glow on hover

7. **Shop by Occasion**
   - 4 cards: Wedding | Party | Office | Casual
   - Each card with icon + occasion name
   - Module-colored hover state

8. **Premium Collections**
   - Large collection cards
   - Image + overlay + title + description
   - "Explore" button
   - Rounded corners (app-level component)

9. **Trending Products**
   - Horizontal carousel
   - Same as New Arrivals structure

10. **Best Sellers**
    - Grid layout (2 columns)
    - ProductCards with rank badges
    - Different layout from carousels

### 4.3 Product Card Component

**Structure**:
```
Container (rounded-2xl for app-level, sharp for module-internal)
  └─ AspectRatio (1:1)
      ├─ Image with object-cover
      ├─ Wishlist button (top-right, heart icon)
      └─ "New" badge (top-left, if applicable)
  └─ Content area
      ├─ Brand name (opacity-60)
      ├─ Product title (2-line truncate)
      ├─ Price (primary)
      ├─ Original price (line-through, if discounted)
      └─ Rating stars + count
```

**States**:
- Hover: Scale 1.02, shadow increase
- Wishlist active: Filled heart, emerald color
- Click: Navigate to ProductDetail

### 4.4 Combo Bundle Card

**Structure**:
```
Container (rounded-2xl)
  └─ Images section
      ├─ 2-4 product images in grid
      └─ Savings badge (emerald, top-right)
  └─ Content
      ├─ Bundle title
      ├─ Original price (line-through)
      ├─ Bundle price (emerald color, larger)
      └─ "Save ₹X" text
```

**Behavior**: Click opens BundleDetail page

### 4.5 Product Detail Page

**Layout**:
```
Header:
  └─ Back button + "Product Details" + Share button

Hero Section:
  └─ Image carousel (dots pagination)
  └─ Wishlist FAB (bottom-right of image)

Info Section:
  ├─ Brand name
  ├─ Product name
  ├─ Rating + reviews count
  ├─ Price (large, emerald)
  ├─ Original price (line-through)
  └─ Discount percentage (emerald badge)

Features:
  └─ 4 icon cards (Free Shipping, Easy Returns, etc.)

Description:
  └─ Expandable text with "Read more" toggle

Size Selection:
  └─ Radio button pills (Sharp edges - module internal)

Color Selection:
  └─ Color circle buttons with checkmark

Quantity Selector:
  └─ -/+ buttons with number input

Delivery Info:
  └─ Pincode input + Check button
  └─ Expected delivery date

Similar Products:
  └─ Horizontal carousel of ProductCards

Reviews Section:
  ├─ Overall rating + breakdown bars
  ├─ Filter chips (All, With Photos, 5⭐, 4⭐, etc.)
  ├─ Sort dropdown
  └─ Review cards
      ├─ User avatar + name + date
      ├─ Star rating
      ├─ Review text
      ├─ Masonry grid of review images (react-responsive-masonry)
      └─ Helpful button

Bottom Action Bar (Fixed):
  └─ "Add to Bag" button (full-width, emerald)
```

**Scroll Behavior**:
- Hides app bar and bottom nav on scroll
- Back button always accessible
- Smooth transitions

### 4.6 Bundle Detail Page

**Similar to ProductDetail but**:
- Shows multiple products in bundle
- Each product expandable to see details
- Bundle pricing prominently displayed
- "Add Bundle to Bag" action

### 4.7 Wishlist Page

**Layout**:
```
Header:
  └─ Back button + "Wishlist" title + count badge

Content:
  └─ Grid of ProductCards (2 columns)
  └─ Each card has "Remove" button
  └─ Empty state if no items

Actions:
  └─ "Move all to Bag" button (if items exist)
```

**Behavior**:
- Heart icon removes item with animation
- Updates wishlist count in app bar
- Shows shimmer while loading

### 4.8 Shopping Bag Page

**Layout**:
```
Header:
  └─ Back button + "Shopping Bag" title + count

Items List:
  └─ Bag item cards
      ├─ Product image (left)
      ├─ Product info (middle)
      │   ├─ Title
      │   ├─ Size, Color
      │   └─ Quantity selector
      ├─ Price (right)
      └─ Remove button

Price Summary Card:
  ├─ Subtotal
  ├─ Discount
  ├─ Delivery charges
  └─ Total (emerald, large)

Bottom Action:
  └─ "Proceed to Checkout" button (emerald)
```

**Behavior**:
- Quantity changes update total instantly
- Remove shows confirmation
- Updates bag count in app bar

### 4.9 Product List Page

**Trigger**: "View All" buttons from carousels
**Layout**:
```
Header:
  └─ Back button + Category name

Filters Bar:
  └─ Sort dropdown + Filter button

Content:
  └─ Grid of ProductCards (2 columns)
  └─ Infinite scroll capability

Empty State:
  └─ "No products found" message
```

## 5. Community Module

### 5.1 Community Top Navigation

**Position**: Same as Commerce (fixed, animated)
**Tabs**: verse | spotlight | profile

**Styling**:
- Red/rose/pink themed
- Same animation pattern as Commerce
- Gradient: `from-red-600 via-rose-600 to-pink-600`

### 5.2 Thyne Verse Tab

**Layout**: Vertical feed of posts

**Post Types**:
1. Text posts
2. Image posts (single)
3. Multi-image posts (carousel)
4. Video posts
5. Product-tagged posts

**FeedPost Component**:
```
Header:
  ├─ User avatar
  ├─ Username
  ├─ Timestamp
  └─ Menu button (3 dots)

Content:
  ├─ Text content (expandable)
  ├─ Media (if applicable)
  └─ Product badges (if tagged)

Actions Bar:
  ├─ Like button + count
  ├─ Comment button + count
  ├─ Share button
  └─ Bookmark button
```

**Media Handling**:
- Images: AspectRatio maintained, rounded corners
- Multiple images: Carousel with dots
- Videos: Play button overlay
- Click opens FullScreenPost

**Product Tags**:
- ProductAvatarBadge component
- Shows product image + price
- Clickable to ProductDetail
- Positioned overlay on media or below

### 5.3 Full-Screen Post View

**Trigger**: Click on any post
**Layout**: Full viewport takeover

**Behavior**:
- Hides bottom search bar
- Shows post content full-screen
- Swipe down gesture to close (potential)
- Back button to return to feed

**Structure**:
```
Header (Fixed):
  └─ Back button + User info

Media Section:
  └─ Full-screen image/video
  └─ Carousel for multi-image

Actions (Overlay on media):
  └─ Like, Comment, Share, Bookmark

Comments Section:
  └─ Scrollable comments below media
  └─ Comment input (fixed bottom)
```

### 5.4 Spotlight Tab

**Purpose**: Featured/trending posts
**Layout**: 
- Hero featured post at top
- Grid of spotlight posts (2 columns)
- Each post shows engagement metrics prominently
- Red accent for trending indicators

### 5.5 My Profile Tab

**Layout**:
```
Profile Header:
  ├─ Cover photo (gradient)
  ├─ Profile avatar (large, centered)
  ├─ Username
  ├─ Bio
  └─ Stats (Posts, Followers, Following)

Action Buttons:
  ├─ Edit Profile
  └─ Settings

Tabs:
  ├─ My Posts (grid view)
  ├─ Liked Posts
  └─ Saved Posts

Content Grid:
  └─ Masonry grid of user's posts
```

## 6. Create Module

### 6.1 Create Top Navigation

**Position**: Same as other modules
**Tabs**: chat | my creations | history

**Styling**:
- Blue/cyan/sky themed
- Gradient: `from-blue-600 via-cyan-600 to-sky-600`

### 6.2 Chat Tab

**Purpose**: ChatGPT-like AI interface
**Layout**:
```
Chat Container:
  └─ Messages area (scrollable)
      ├─ AI messages (left-aligned)
      │   ├─ AI avatar
      │   ├─ Message bubble (blue accent)
      │   └─ Timestamp
      └─ User messages (right-aligned)
          ├─ Message bubble (glass morphism)
          └─ Timestamp

Suggested Prompts (Empty State):
  └─ Grid of prompt cards
      ├─ "Generate product description"
      ├─ "Create marketing copy"
      ├─ "Design ideas for..."
      └─ "Write a blog post about..."

Input Area (Fixed Bottom):
  ├─ Text input (multiline)
  ├─ Attachment button
  └─ Send button (blue)
```

**Behavior**:
- Auto-scroll to latest message
- Typing indicator when AI responding
- Markdown support in messages
- Code syntax highlighting

**AI Responses**:
- Stream-like appearance (optional)
- Can include images, tables, lists
- Copy button for code blocks
- Regenerate button for responses

### 6.3 My Creations Tab

**Purpose**: Gallery of AI-generated content
**Layout**:
```
Filter Bar:
  └─ All | Images | Text | Code | Other

Content Grid:
  └─ Masonry grid of creation cards
      ├─ Thumbnail/preview
      ├─ Title
      ├─ Date created
      └─ Quick actions (View, Edit, Delete)
```

### 6.4 History Tab

**Purpose**: Chat history and past sessions
**Layout**:
```
List of Sessions:
  └─ Session cards
      ├─ Session title (first message preview)
      ├─ Date
      ├─ Message count
      └─ Last activity time
```

**Behavior**:
- Click opens session in Chat tab
- Swipe to delete session
- Search bar to filter history

## 7. Shimmer Loading States

### 7.1 Shimmer Implementation

**Used Components**:
- `ShimmerCard.tsx`: Base shimmer component
- `CommerceShimmer.tsx`: Commerce section skeleton
- `CommunityShimmer.tsx`: Community feed skeleton
- `CreateShimmer.tsx`: Create chat skeleton
- `WishlistShimmer.tsx`: Wishlist skeleton
- `ShoppingBagShimmer.tsx`: Bag skeleton

**Animation**:
```css
Gradient shimmer animation from left to right
Background: bg-white/[0.02] (dark) or bg-black/[0.02] (light)
Shimmer overlay: white/10 to transparent gradient
Duration: 1.5s infinite
```

**Pattern**:
- Match the layout of actual content
- Use same spacing and dimensions
- Show during data fetching (3s simulated delay)
- Smooth transition to real content

## 8. Data Structure

### 8.1 Product Interface

```typescript
interface Product {
  id: string;
  title: string;
  brand: string;
  price: number;
  originalPrice?: number;
  discount?: number;
  rating: number;
  reviewCount: number;
  image: string;
  images?: string[]; // Multiple images for detail page
  category: string;
  isNew?: boolean;
  description?: string;
  features?: string[];
  sizes?: string[];
  colors?: Array<{ name: string; hex: string }>;
  inStock?: boolean;
  deliveryTime?: string;
}
```

### 8.2 Bundle Interface

```typescript
interface Bundle {
  id: string;
  title: string;
  products: Product[];
  originalPrice: number;
  bundlePrice: number;
  savings: number;
  image: string;
  description?: string;
}
```

### 8.3 Post Interface

```typescript
interface Post {
  id: string;
  author: {
    id: string;
    name: string;
    avatar: string;
    verified?: boolean;
  };
  content: string;
  timestamp: string;
  media?: Array<{
    type: 'image' | 'video';
    url: string;
    thumbnail?: string;
  }>;
  products?: Product[]; // Tagged products
  likes: number;
  comments: number;
  shares: number;
  isLiked: boolean;
  isBookmarked: boolean;
}
```

### 8.4 Review Interface

```typescript
interface Review {
  id: string;
  user: {
    name: string;
    avatar: string;
    verified?: boolean;
  };
  rating: number;
  date: string;
  title?: string;
  content: string;
  images?: string[];
  helpful: number;
  isHelpful: boolean;
}
```

## 9. Key Interactions & Behaviors

### 9.1 Scroll Behavior

**Detection Logic**:
```typescript
// Scroll threshold: 5px
// Direction: down (hide) or up (show)
// Debounced: Only triggers after movement stops
// Special cases: Top of page always shows toolbars
```

**Affected Elements**:
- Collapsible App Bar (top)
- Collapsible Bottom Toolbar (bottom)
- Module Top Navs (adjust position)
- Persistent Search Bar (adjusts position)

### 9.2 Tab Switching

**Behavior**:
- Instant content swap (no page transition)
- Module top nav animates to appropriate position
- Bottom nav indicator slides to active tab
- Search bar FAB color changes to module theme
- Content area re-renders with appropriate padding
- Scroll position resets to top

### 9.3 Navigation Stack

**Screens**:
- `home`: Main module content
- `productDetail`: Product detail page
- `bundleDetail`: Bundle detail page
- `wishlist`: Wishlist page
- `bag`: Shopping bag page
- `productList`: Category product list
- `fullPost`: Full-screen post view

**Back Navigation**:
- Back button returns to previous screen
- State preserved (scroll position, filters)
- Animation: Slide right (back), slide left (forward)

### 9.4 Wishlist & Bag Management

**Wishlist**:
- Heart icon toggle on ProductCard
- Global wishlist state
- Count badge on app bar heart icon
- Persist across navigation
- Add/remove animations

**Shopping Bag**:
- Add from ProductDetail
- Quantity management
- Size/color selection required
- Count badge on app bar bag icon
- Auto-calculate totals

### 9.5 Search Functionality

**Trigger**: Focus or click on search bar
**Overlay**: Full-screen with backdrop
**Search Logic**:
- Debounced input (300ms)
- Search across: Products, Bundles, Posts, Creators
- Filter by category tabs
- Real-time results update (mock)
- Highlight matching terms

**Quick Actions**:
- "Show me trending products"
- "Find jewelry under ₹5000"
- "Latest community posts"
- "Create product description"

### 9.6 Theme Toggle

**Behavior**:
- Icon toggles: Moon (dark) ↔ Sun (light)
- Global theme state
- Smooth color transitions (500ms)
- All components react to theme prop
- Icon scale animation on toggle

## 10. Responsive Considerations

**Primary Target**: Mobile (iPhone-like viewport)
**Breakpoints**: Not extensively used (mobile-first)

**Layout Adjustments**:
- Fixed toolbars always span full width
- Content padding: px-6 (24px) for breathing room
- Cards: Full-width or 2-column grid
- Carousels: Horizontal scroll, no arrows
- Touch interactions: Appropriate tap targets (44x44 minimum)

## 11. Animation Specifications

### 11.1 Motion Components

**Framer Motion Import**:
```typescript
import { motion, AnimatePresence } from 'motion/react';
```

### 11.2 Common Animation Patterns

**Fade In/Out**:
```typescript
initial={{ opacity: 0 }}
animate={{ opacity: 1 }}
exit={{ opacity: 0 }}
transition={{ duration: 0.3 }}
```

**Slide Up/Down**:
```typescript
initial={{ y: 100 }}
animate={{ y: 0 }}
exit={{ y: 100 }}
transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
```

**Scale**:
```typescript
whileHover={{ scale: 1.05 }}
whileTap={{ scale: 0.95 }}
```

**Layout Animation** (Tab Indicators):
```typescript
<motion.div layoutId="activeTab" />
transition={{ type: 'spring', stiffness: 500, damping: 40 }}
```

**Stagger Children**:
```typescript
variants={{
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
}}
```

### 11.3 Neon Glow Effect

**Structure**:
```tsx
<div className="relative">
  {/* Outer glow */}
  <motion.div
    layoutId="categoryGlow"
    className="absolute -inset-1 rounded-full 
               bg-gradient-to-r from-emerald-600/30 via-teal-600/30 to-emerald-600/30 
               blur-lg opacity-70 animate-pulse"
  />
  
  {/* Button */}
  <button className="relative border border-emerald-600/30 
                     shadow-lg shadow-emerald-600/40">
    {/* Inner glow */}
    <motion.div
      layoutId="activeTabGlow"
      className="absolute inset-0 
                 bg-gradient-to-r from-emerald-600/20 via-teal-600/20 to-emerald-600/20 
                 rounded-full"
    />
    <span className="relative z-10">Content</span>
  </button>
</div>
```

## 12. Special Components

### 12.1 Image Handling

**ImageWithFallback Component**:
- Protected system file at `/components/figma/ImageWithFallback.tsx`
- Use for all dynamic images
- Handles loading states and errors gracefully
- Import: `import { ImageWithFallback } from './components/figma/ImageWithFallback'`

**Unsplash Integration**:
- Use unsplash_tool for all photo needs
- Relevant search queries for jewelry, fashion
- No hardcoded image URLs

### 12.2 shadcn/ui Components

**Available Components** (42 total):
- Form controls: Button, Input, Textarea, Checkbox, Radio, Switch, Select, Slider
- Overlays: Dialog, Sheet, Drawer, Popover, Tooltip, Alert Dialog, Context Menu, Dropdown Menu
- Layout: Card, Separator, Accordion, Tabs, Collapsible, Resizable, Scroll Area
- Navigation: Breadcrumb, Pagination, Navigation Menu, Menubar
- Feedback: Alert, Toast (Sonner), Skeleton, Progress
- Data Display: Table, Avatar, Badge, Calendar, Chart, Carousel, Aspect Ratio
- Forms: Form (React Hook Form + Zod)

**Import Pattern**:
```typescript
import { Button } from './components/ui/button';
import { Dialog } from './components/ui/dialog';
```

### 12.3 Icons

**Library**: Lucide React
**Usage**:
```typescript
import { Heart, ShoppingBag, User, Search } from 'lucide-react';
```

**Common Icons**:
- Navigation: ChevronLeft, ChevronRight, Menu, X
- Commerce: ShoppingBag, Heart, Gift, Star
- Social: Heart, MessageCircle, Share2, Bookmark
- UI: Search, Filter, Plus, Minus, Check
- Info: Info, AlertCircle, CheckCircle, XCircle

## 13. Styling Guidelines

### 13.1 Global CSS (styles/globals.css)

**Typography Tokens**: Custom text classes defined
**No Tailwind font classes**: text-2xl, font-bold, leading-none not used
**Exception**: Only use when user explicitly requests

### 13.2 Class Naming Patterns

**Spacing**:
- px-6, py-4: Standard padding
- gap-3, gap-4, gap-6: Consistent gaps
- mb-4, mt-6: Vertical rhythm

**Borders**:
- border, border-2: Standard borders
- border-white/[0.03]: Subtle borders
- border-white/10: Visible borders

**Backgrounds**:
- bg-black/40, bg-white/60: Translucent
- backdrop-blur-2xl: Glass morphism
- bg-gradient-to-r: Directional gradients

**Transitions**:
- transition-all duration-300
- transition-colors duration-500
- Custom easing in motion components

### 13.3 Rounded Corners Logic

**App-Level (Rounded)**:
- Module cards: rounded-2xl or rounded-3xl
- Buttons: rounded-full or rounded-lg
- Bottom nav tabs: rounded-full backgrounds
- Search bar: rounded-full
- Product/Bundle cards shown in main feed: rounded-2xl

**Module-Internal (Sharp)**:
- Product cards within detail pages: sharp
- Size/color selectors: sharp or minimal rounding
- Grid items within a section: sharp
- Internal navigation elements: sharp

## 14. Error Handling & Edge Cases

### 14.1 Empty States

**Wishlist Empty**:
- Icon + message: "Your wishlist is empty"
- CTA: "Explore Products" button

**Bag Empty**:
- Icon + message: "Your bag is empty"
- CTA: "Start Shopping" button

**No Search Results**:
- Icon + message: "No results found"
- Suggestions: Show trending or popular items

**No Posts**:
- Icon + message: "No posts yet"
- CTA: "Refresh" button

### 14.2 Loading States

**Initial Load**: Full shimmer skeleton (3s)
**Subsequent Loads**: Shimmer for specific section
**Transitions**: Smooth fade from shimmer to content
**Failed Loads**: Retry button with error message

### 14.3 Image Errors

**Product Images**: Fallback to placeholder gradient
**User Avatars**: Fallback to initials
**Post Media**: Show error icon with retry option

## 15. Performance Optimizations

### 15.1 Lazy Loading

**Images**: Load on viewport entry
**Carousels**: Render visible + 1 on each side
**Infinite Scroll**: Load next batch on scroll threshold

### 15.2 Scroll Performance

**Virtual Scrolling**: Not implemented (manageable data size)
**Debounced Scroll Events**: 50ms debounce
**CSS transforms**: Use for animations (GPU accelerated)

### 15.3 State Management

**Local State**: useState for component-level
**Prop Drilling**: Acceptable for this app size
**Memoization**: Not extensively used (not needed yet)

## 16. Future Enhancements (Not Implemented)

### 16.1 Potential Features

- Real backend integration
- User authentication
- Payment gateway
- Order tracking
- Push notifications
- Real-time chat
- Video calls for support
- AR try-on for jewelry
- Social sharing
- Deep linking

### 16.2 Technical Debt

- No real routing (client-side only)
- Mock data (no API calls)
- No persistent storage (localStorage potential)
- No testing suite
- No accessibility audit (WCAG)
- No analytics integration

## 17. Development Commands

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 18. Key Dependencies

```json
{
  "react": "^18",
  "motion": "^10", // Framer Motion
  "lucide-react": "^0.x",
  "tailwindcss": "^4.0",
  "react-responsive-masonry": "^2.x",
  "sonner": "^2.0.3",
  "recharts": "^2.x" // For charts if needed
}
```

## 19. File Imports & SVGs

**Import Pattern for Assets**:
```typescript
// SVG components
import Group from '../imports/Group2';

// Image fallback component
import { ImageWithFallback } from './components/figma/ImageWithFallback';
```

**Imports Directory**: Contains exported Figma SVGs
- Group2.tsx: Thyne logo
- Frame1.tsx, IPhone165.tsx, IPhone166.tsx: Other assets
- svg-*.ts: SVG path data

## 20. Critical Implementation Notes

### 20.1 DO's

✅ Use `backdrop-blur-2xl` extensively for glass morphism
✅ Maintain module color theming (emerald/red/blue)
✅ Keep animations smooth with custom easing
✅ Use sharp edges for module-internal components
✅ Maintain consistent spacing (px-6, gap-4)
✅ Use ImageWithFallback for dynamic images
✅ Implement shimmer loading states
✅ Use motion for all animations
✅ Keep bottom nav compact (icons only)
✅ Maintain 20px gap between app bar and module navs

### 20.2 DON'Ts

❌ Don't use Tailwind font classes (text-2xl, font-bold, etc.)
❌ Don't create tailwind.config.js (using v4.0)
❌ Don't modify typography in globals.css unless requested
❌ Don't add rounded corners to module-internal components
❌ Don't use real API endpoints (mock only)
❌ Don't create complex routing (tab-based only)
❌ Don't remove the 20px spacing between toolbars

### 20.3 Spacing Formula

**Top Padding Calculation**:
```
Commerce: 180px = App Bar (84px) + Gap (20px) + Top Nav (~56px) + spacing (20px)
Community: 228px = App Bar (84px) + Gap (20px) + Top Nav (~56px) + spacing (68px for second nav)
Create: 228px = Same as Community
```

**Bottom Padding**: 200px (Search bar + Bottom nav + spacing)

**Search Bar Positioning**:
- Bottom (nav visible): 64px
- Bottom (nav hidden): 20px

**Search Overlay**:
- Top: 176px (below app bar with spacing)
- Bottom: 184px (above search bar)

## 21. Rebuild Instructions

To recreate this exact app:

1. **Setup**: Create React + TypeScript + Tailwind CSS v4.0 project
2. **Install**: motion, lucide-react, shadcn/ui, react-responsive-masonry, sonner
3. **Copy**: styles/globals.css with typography tokens
4. **Create**: All component files as per structure
5. **Implement**: App.tsx with all state management
6. **Add**: Mock data in data/jewelryData.ts
7. **Configure**: Import shadcn/ui components (42 components)
8. **Import**: SVG assets in imports/ directory
9. **Test**: Scroll behavior, tab switching, navigation flows
10. **Verify**: All animations, theming, responsiveness

**Key Starting Point**: App.tsx orchestrates everything
**Critical Components**: CollapsibleAppBar, CollapsibleBottomToolbar, SearchOverlay
**Module Entry Points**: CommerceContent, CommunitySection, CreateSection

---

## Document Version: 1.0
## Last Updated: 2025-10-26
## Completeness: Comprehensive specification for full rebuild

This document serves as a complete blueprint for recreating the Thyne application from scratch. Every major feature, component, interaction, and styling decision has been documented to ensure pixel-perfect reproduction.
