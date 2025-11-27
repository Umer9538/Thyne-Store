# Color Replacement Guide

## Old Color: #10b981 (Emerald-500)
## New Color: #094010

## Replacement Patterns:

### Hex Colors:
- `#10b981` → `#094010`

### Tailwind Classes - Text:
- `text-emerald-400` → `style={{ color: '#094010' }}` or custom class
- `text-emerald-500` → `style={{ color: '#094010' }}`
- `text-emerald-600` → `style={{ color: '#094010' }}`

### Tailwind Classes - Background:
- `bg-emerald-400` → `bg-[#094010]` or `style={{ background: '#094010' }}`
- `bg-emerald-500` → `bg-[#094010]`
- `bg-emerald-600` → `bg-[#094010]`
- `bg-emerald-500/20` → `bg-[#094010]/20` or `style={{ background: 'rgba(9, 64, 16, 0.2)' }}`
- `bg-emerald-950/20` → `bg-[#094010]/20`
- `bg-emerald-50` → `bg-[#094010]/10`

### Tailwind Classes - Border:
- `border-emerald-400` → `border-[#094010]`
- `border-emerald-500` → `border-[#094010]`
- `border-emerald-600` → `border-[#094010]`
- `border-emerald-500/30` → `border-[#094010]/30` or inline style
- `border-emerald-900/20` → `border-[#094010]/20`

### Tailwind Classes - Gradients:
- `from-emerald-500` → `from-[#094010]`
- `to-emerald-600` → `to-[#094010]`
- `from-emerald-600/30` → `from-[#094010]/30`
- `via-emerald-600` → `via-[#094010]`

## Inline Style Approach for Complex Cases:
For dynamic hover states and complex scenarios, use inline styles:
```tsx
style={{
  color: '#094010',
  background: 'linear-gradient(to right, #094010, #094010)',
  borderColor: 'rgba(9, 64, 16, 0.3)',
  boxShadow: '0 4px 20px rgba(9, 64, 16, 0.3)'
}}
```

## Files to Update:
- ✅ SplashScreen.tsx
- ✅ SignUpLoginScreen.tsx
- ✅ OTPScreen.tsx
- ✅ App.tsx (mock data color)
- 🔄 CollapsibleBottomToolbar.tsx
- 🔄 CommerceTopNav.tsx
- 🔄 LoaderSpinner.tsx
- 🔄 All commerce/* components
- 🔄 ProductDetail.tsx
- 🔄 BundleDetail.tsx
- 🔄 ShoppingBag.tsx
- 🔄 Wishlist.tsx
- 🔄 SearchOverlay.tsx
