# Emerald to #094010 Replacement Script

## Files to Update (21 files total):

### Priority 1 - Critical Commerce UI (User-facing):
1. ✅ App.tsx
2. ✅ SplashScreen.tsx  
3. ✅ SignUpLoginScreen.tsx
4. ✅ OTPScreen.tsx
5. ✅ CommerceTopNav.tsx
6. ✅ CollapsibleBottomToolbar.tsx
7. ✅ LoaderSpinner.tsx
8. ✅ ProductDetail.tsx
9. ✅ ProductList.tsx
10. 🔄 BundleDetail.tsx (35+ replacements needed)
11. 🔄 ShoppingBag.tsx (20+ replacements needed)
12. 🔄 Wishlist.tsx (8 replacements needed)
13. 🔄 SearchOverlay.tsx (7 replacements needed)

### Priority 2 - Commerce Components:
14. 🔄 CollectionCard.tsx
15. 🔄 ComboBundle.tsx  
16. 🔄 ProductCard.tsx
17. 🔄 HeroBanner.tsx
18. 🔄 OccasionCards.tsx
19. 🔄 PriceRangeCards.tsx
20. 🔄 ProductCarousel.tsx
21. 🔄 ExpandableCategoryCard.tsx
22. 🔄 CommerceContent.tsx
23. 🔄 CommerceContent_new.tsx

### Priority 3 - Community Components:
24. 🔄 MyProfile.tsx
25. 🔄 ProductAvatarBadge.tsx
26. 🔄 Spotlight.tsx

### Priority 4 - Other:
27. 🔄 ThyneLogo.tsx (default color)
28. 🔄 CreateSection.tsx (text content)

## Replacement Strategy:

### For solid backgrounds:
- `bg-emerald-500` → inline style `background: '#094010'`
- `bg-emerald-600` → inline style `background: '#094010'`

### For background with opacity:
- `bg-emerald-500/20` → inline style `background: 'rgba(9, 64, 16, 0.2)'`
- `bg-emerald-950/30` → inline style `background: 'rgba(9, 64, 16, 0.3)'`

### For text:
- `text-emerald-400` → inline style `color: '#094010'`
- `text-emerald-600` → inline style `color: '#094010'`

### For borders:
- `border-emerald-500` → inline style `borderColor: '#094010'`
- `border-emerald-500/30` → inline style `borderColor: 'rgba(9, 64, 16, 0.3)'`

### For gradients:
- `from-emerald-600 to-teal-600` → inline style `background: 'linear-gradient(to right, #094010, #0d9488)'`
- Keep teal as is for gradient effects

### For shadows:
- `shadow-emerald-500/30` → inline style `boxShadow: '0 4px 20px rgba(9, 64, 16, 0.3)'`
