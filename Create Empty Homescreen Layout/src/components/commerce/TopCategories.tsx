import { useState } from 'react';
import { ExpandableCategoryCard } from './ExpandableCategoryCard';

interface TopCategoriesProps {
  theme?: 'dark' | 'light';
  onItemClick?: (itemId: string) => void;
}

export function TopCategories({ theme = 'dark', onItemClick }: TopCategoriesProps) {
  const [expandedId, setExpandedId] = useState<string | null>('rings'); // Default to rings expanded
  // Category data with expandable content
  const categories = [
    {
      id: 'rings',
      name: 'Rings',
      image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: 'rings-under-10k', label: 'Under 10K' },
        { id: 'rings-10k-20k', label: '10K - 20K' },
        { id: 'rings-20k-30k', label: '20K - 30K' },
        { id: 'rings-30k-50k', label: '30K - 50K' },
        { id: 'rings-50k-75k', label: '50K - 75K' },
        { id: 'rings-75k-above', label: '75K & Above' },
      ],
      styleItems: [
        {
          id: 'rings-all',
          name: 'All Rings',
          image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=300',
          count: 245,
        },
        {
          id: 'rings-engagement',
          name: 'Engagement',
          image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=300',
          count: 89,
        },
        {
          id: 'rings-solitaire',
          name: 'Solitaire',
          image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=300',
          count: 67,
        },
        {
          id: 'rings-dailywear',
          name: 'Dailywear',
          image: 'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?w=300',
          count: 156,
        },
        {
          id: 'rings-platinum',
          name: 'Platinum Rings',
          image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=300',
          count: 43,
        },
        {
          id: 'rings-bands',
          name: 'Bands',
          image: 'https://images.unsplash.com/photo-1614015270921-161579a36d57?w=300',
          count: 98,
        },
        {
          id: 'rings-cocktail',
          name: 'Cocktail',
          image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=300',
          count: 54,
        },
        {
          id: 'rings-couple',
          name: 'Couple Rings',
          image: 'https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=300',
          count: 76,
        },
      ],
    },
    {
      id: 'earrings',
      name: 'Earrings',
      image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: 'earrings-under-5k', label: 'Under 5K' },
        { id: 'earrings-5k-15k', label: '5K - 15K' },
        { id: 'earrings-15k-25k', label: '15K - 25K' },
        { id: 'earrings-25k-40k', label: '25K - 40K' },
        { id: 'earrings-40k-60k', label: '40K - 60K' },
        { id: 'earrings-60k-above', label: '60K & Above' },
      ],
      styleItems: [
        {
          id: 'earrings-all',
          name: 'All Earrings',
          image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=300',
          count: 298,
        },
        {
          id: 'earrings-studs',
          name: 'Studs',
          image: 'https://images.unsplash.com/photo-1596944924591-4b0e0d5c5c09?w=300',
          count: 134,
        },
        {
          id: 'earrings-hoops',
          name: 'Hoops',
          image: 'https://images.unsplash.com/photo-1622434641406-a158123450f9?w=300',
          count: 87,
        },
        {
          id: 'earrings-drops',
          name: 'Drops & Danglers',
          image: 'https://images.unsplash.com/photo-1610458101708-7e9bd5ec7ae7?w=300',
          count: 112,
        },
      ],
    },
    {
      id: 'bracelets-bangles',
      name: 'Bracelets & Bangles',
      image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: 'bb-under-10k', label: 'Under 10K' },
        { id: 'bb-10k-30k', label: '10K - 30K' },
        { id: 'bb-30k-50k', label: '30K - 50K' },
        { id: 'bb-50k-75k', label: '50K - 75K' },
        { id: 'bb-75k-100k', label: '75K - 100K' },
        { id: 'bb-100k-above', label: '100K & Above' },
      ],
      styleItems: [
        {
          id: 'bb-all',
          name: 'All',
          image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=300',
          count: 187,
        },
        {
          id: 'bb-bracelets',
          name: 'Bracelets',
          image: 'https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=300',
          count: 98,
        },
        {
          id: 'bb-bangles',
          name: 'Bangles',
          image: 'https://images.unsplash.com/photo-1614015270921-161579a36d57?w=300',
          count: 112,
        },
        {
          id: 'bb-kada',
          name: 'Kada',
          image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=300',
          count: 67,
        },
      ],
    },
    {
      id: 'solitaires',
      name: 'Solitaires',
      image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: 'solitaire-under-50k', label: 'Under 50K' },
        { id: 'solitaire-50k-100k', label: '50K - 1L' },
        { id: 'solitaire-1l-2l', label: '1L - 2L' },
        { id: 'solitaire-2l-3l', label: '2L - 3L' },
        { id: 'solitaire-3l-5l', label: '3L - 5L' },
        { id: 'solitaire-5l-above', label: '5L & Above' },
      ],
      styleItems: [
        {
          id: 'solitaire-all',
          name: 'All Solitaires',
          image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=300',
          count: 134,
        },
        {
          id: 'solitaire-rings',
          name: 'Solitaire Rings',
          image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=300',
          count: 89,
        },
        {
          id: 'solitaire-pendants',
          name: 'Solitaire Pendants',
          image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=300',
          count: 45,
        },
      ],
    },
    {
      id: '22kt',
      name: '22KT',
      image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: '22kt-under-20k', label: 'Under 20K' },
        { id: '22kt-20k-40k', label: '20K - 40K' },
        { id: '22kt-40k-60k', label: '40K - 60K' },
        { id: '22kt-60k-80k', label: '60K - 80K' },
        { id: '22kt-80k-100k', label: '80K - 100K' },
        { id: '22kt-100k-above', label: '100K & Above' },
      ],
      styleItems: [
        {
          id: '22kt-all',
          name: 'All 22KT',
          image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=300',
          count: 267,
        },
        {
          id: '22kt-chains',
          name: 'Chains',
          image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=300',
          count: 87,
        },
        {
          id: '22kt-bangles',
          name: 'Bangles',
          image: 'https://images.unsplash.com/photo-1614015270921-161579a36d57?w=300',
          count: 112,
        },
        {
          id: '22kt-coins',
          name: 'Coins',
          image: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?w=300',
          count: 68,
        },
      ],
    },
    {
      id: 'silver-shaya',
      name: 'Silver by Shaya',
      image: 'https://images.unsplash.com/photo-1610458101708-7e9bd5ec7ae7?w=400',
      imageBackgroundColor: '#a0e7e5',
      priceRanges: [
        { id: 'silver-under-2k', label: 'Under 2K' },
        { id: 'silver-2k-5k', label: '2K - 5K' },
        { id: 'silver-5k-10k', label: '5K - 10K' },
        { id: 'silver-10k-15k', label: '10K - 15K' },
        { id: 'silver-15k-20k', label: '15K - 20K' },
        { id: 'silver-20k-above', label: '20K & Above' },
      ],
      styleItems: [
        {
          id: 'silver-all',
          name: 'All Silver',
          image: 'https://images.unsplash.com/photo-1610458101708-7e9bd5ec7ae7?w=300',
          count: 198,
        },
        {
          id: 'silver-earrings',
          name: 'Earrings',
          image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=300',
          count: 76,
        },
        {
          id: 'silver-pendants',
          name: 'Pendants',
          image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=300',
          count: 54,
        },
        {
          id: 'silver-bracelets',
          name: 'Bracelets',
          image: 'https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=300',
          count: 68,
        },
      ],
    },
    {
      id: 'mangalsutra',
      name: 'Mangalsutra',
      image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: 'mangalsutra-under-15k', label: 'Under 15K' },
        { id: 'mangalsutra-15k-30k', label: '15K - 30K' },
        { id: 'mangalsutra-30k-50k', label: '30K - 50K' },
        { id: 'mangalsutra-50k-75k', label: '50K - 75K' },
        { id: 'mangalsutra-75k-100k', label: '75K - 100K' },
        { id: 'mangalsutra-100k-above', label: '100K & Above' },
      ],
      styleItems: [
        {
          id: 'mangalsutra-all',
          name: 'All Designs',
          image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=300',
          count: 145,
        },
        {
          id: 'mangalsutra-traditional',
          name: 'Traditional',
          image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=300',
          count: 67,
        },
        {
          id: 'mangalsutra-modern',
          name: 'Modern',
          image: 'https://images.unsplash.com/photo-1610458101708-7e9bd5ec7ae7?w=300',
          count: 78,
        },
      ],
    },
    {
      id: 'necklaces',
      name: 'Necklaces',
      image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=400',
      imageBackgroundColor: undefined,
      priceRanges: [
        { id: 'necklaces-under-15k', label: 'Under 15K' },
        { id: 'necklaces-15k-40k', label: '15K - 40K' },
        { id: 'necklaces-40k-70k', label: '40K - 70K' },
        { id: 'necklaces-70k-100k', label: '70K - 100K' },
        { id: 'necklaces-100k-150k', label: '100K - 150K' },
        { id: 'necklaces-150k-above', label: '150K & Above' },
      ],
      styleItems: [
        {
          id: 'necklaces-all',
          name: 'All Necklaces',
          image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=300',
          count: 234,
        },
        {
          id: 'necklaces-choker',
          name: 'Choker',
          image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=300',
          count: 87,
        },
        {
          id: 'necklaces-long',
          name: 'Long Necklaces',
          image: 'https://images.unsplash.com/photo-1610458101708-7e9bd5ec7ae7?w=300',
          count: 98,
        },
        {
          id: 'necklaces-layered',
          name: 'Layered',
          image: 'https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=300',
          count: 49,
        },
      ],
    },
  ];

  const expandedCategory = categories.find(c => c.id === expandedId);
  const expandedIndex = categories.findIndex(c => c.id === expandedId);
  
  // Calculate where to insert the expansion panel (after the row containing the expanded item)
  // For a 2-column grid, insert after every 2nd item
  const insertPanelAfterIndex = expandedIndex >= 0 ? Math.floor(expandedIndex / 2) * 2 + 1 : -1;

  return (
    <div className="space-y-3">
      {/* Section Header */}
      <div>
        <h3 className={`text-[15px] ${
          theme === 'dark' ? 'text-white' : 'text-black'
        }`}>
          Top Categories
        </h3>
      </div>

      {/* Categories Grid with inline expansion */}
      <div>
        <div className="grid grid-cols-2 gap-2">
          {categories.map((category, index) => (
            <>
              <ExpandableCategoryCard
                key={category.id}
                id={category.id}
                name={category.name}
                image={category.image}
                imageBackgroundColor={category.imageBackgroundColor}
                theme={theme}
                isExpanded={expandedId === category.id}
                onToggle={() => setExpandedId(expandedId === category.id ? null : category.id)}
                hasContent={(category.styleItems && category.styleItems.length > 0) || (category.priceRanges && category.priceRanges.length > 0)}
              />
              
              {/* Insert expansion panel after this row */}
              {index === insertPanelAfterIndex && expandedCategory && (
                <div key={`panel-${expandedCategory.id}`} className="col-span-2">
                  <ExpandableCategoryCard
                    id={expandedCategory.id}
                    name={expandedCategory.name}
                    image={expandedCategory.image}
                    theme={theme}
                    styleItems={expandedCategory.styleItems}
                    priceRanges={expandedCategory.priceRanges}
                    onItemClick={onItemClick}
                    isExpanded={true}
                    renderPanelOnly={true}
                    expandedCardColumn={expandedIndex % 2}
                  />
                </div>
              )}
            </>
          ))}
        </div>
      </div>
    </div>
  );
}
