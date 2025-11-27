# Complete Color Transformation Guide

## Color Shift Analysis

### Original → New Color Mappings:

#### GREEN (Commerce Module):
- **Old**: `#10b981` (emerald-500) = RGB(16, 185, 129)
- **New**: `#094010` (dark forest green) = RGB(9, 64, 16)
- **Transformation ratio**: (0.56, 0.35, 0.12) - Average: 0.27

#### RED (Community Module):
- **Old**: `#ef4444` (red-500) = RGB(239, 68, 68)
- **New**: `#401010` (dark burgundy) = RGB(64, 16, 16)
- **Calculation**: (239×0.27, 68×0.27, 68×0.27) = (65, 18, 18) ≈ **#401010**

#### BLUE (Create Module):
- **Old**: `#3b82f6` (blue-500) = RGB(59, 130, 246)
- **New**: `#0a1a40` (dark navy) = RGB(10, 26, 64)
- **Calculation**: (59×0.17, 130×0.20, 246×0.26) = (10, 26, 64) = **#0a1a40**

## Replacement Patterns:

### Commerce (Green):
```
emerald-400/500/600 → #094010
emerald-950 → #094010 (dark shade)
emerald-50 → rgba(9, 64, 16, 0.1) (light shade)
emerald-500/20 → rgba(9, 64, 16, 0.2)
emerald-500/30 → rgba(9, 64, 16, 0.3)
```

### Community (Red):
```
red-400/500/600 → #401010
red-950 → #401010 (dark shade)  
red-50/100 → rgba(64, 16, 16, 0.1-0.2) (light shade)
red-500/20 → rgba(64, 16, 16, 0.2)
red-900/20 → rgba(64, 16, 16, 0.2)
rose-400/500/600 → #4a1520 (slightly pinker dark burgundy)
```

### Create (Blue):
```
blue-400/500/600 → #0a1a40
blue-950 → #0a1a40 (dark shade)
blue-50 → rgba(10, 26, 64, 0.1) (light shade)
blue-500/20 → rgba(10, 26, 64, 0.2)
blue-500/30 → rgba(10, 26, 64, 0.3)
cyan-400/500/600 → #0a3040 (slightly more cyan)
```

## Files to Update:

### Priority 1 - Navigation & Core (10 files):
1. ✅ CollapsibleBottomToolbar.tsx - FAB buttons (red, blue)
2. ✅ CommunityTopNav.tsx - Red glows and borders
3. ✅ CreateTopNav.tsx - Blue glows and borders
4. ⏳ ProductDetail.tsx - Red wishlist heart, blue "New" badge
5. ⏳ BundleDetail.tsx - Red out of stock, wishlist
6. ⏳ ShoppingBag.tsx - Red remove button
7. ⏳ Wishlist.tsx - Red remove button
8. ⏳ SignUpLoginScreen.tsx - Red error states
9. ⏳ OTPScreen.tsx - Red error states

### Priority 2 - Commerce Components (4 files):
10. ⏳ ProductCard.tsx - Blue "New" badge
11. ⏳ FlashDeals.tsx - Red gradient backgrounds
12. ⏳ CommerceContent.tsx - Blue/red gradients in data
13. ⏳ CommerceContent_new.tsx - Blue/red gradients in data

### Priority 3 - Community Components (5 files):
14. ⏳ FullScreenPost.tsx - Red gradients, AI badges
15. ⏳ MyProfile.tsx - Red gradients, borders, buttons
16. ⏳ Spotlight.tsx - Red gradients and highlights
17. ⏳ ProductAvatarBadge.tsx - emerald border (if red)
18. ⏳ FeedPost.tsx - potential red elements

### Priority 4 - Create Components (1 file):
19. ⏳ CreateSection.tsx - Blue gradients and highlights

## Testing Checklist:
- [ ] Commerce tab: Green colors are all dark forest green
- [ ] Community tab: Red colors are all dark burgundy
- [ ] Create tab: Blue colors are all dark navy
- [ ] FAB buttons match module colors
- [ ] Search icon matches module colors
- [ ] Error states use new red
- [ ] Wishlist hearts use new red
- [ ] New badges use new blue
- [ ] AI badges use appropriate module color
