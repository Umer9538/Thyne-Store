import { motion } from 'motion/react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface Category {
  id: string;
  name: string;
  image: string;
}

interface CategoryStoriesProps {
  categories: Category[];
  theme?: 'dark' | 'light';
}

export function CategoryStories({ categories, theme = 'light' }: CategoryStoriesProps) {
  return (
    <div className="space-y-3">
      <h3 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
        Shop by Category
      </h3>
      <div className="flex gap-2 overflow-x-auto no-scrollbar pb-2">
        {categories.map((cat, index) => (
          <motion.button
            key={cat.id}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.05 }}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className={`flex-shrink-0 w-[90px] transition-all duration-300 rounded-2xl overflow-hidden border ${
              theme === 'dark'
                ? 'bg-white border-white/[0.08] hover:border-white/[0.15]'
                : 'bg-white border-black/[0.08] hover:border-black/[0.15]'
            }`}
          >
            {/* Image Container */}
            <div className="relative w-full aspect-square bg-white">
              <ImageWithFallback
                src={cat.image}
                alt={cat.name}
                className="w-full h-full object-cover"
              />
            </div>
            
            {/* Label */}
            <div className={`py-2 px-1.5 ${
              theme === 'dark' ? 'bg-white/[0.02]' : 'bg-black/[0.01]'
            }`}>
              <span className={`text-[10px] block text-center ${
                theme === 'dark' ? 'text-white/80' : 'text-black/80'
              }`}>
                {cat.name}
              </span>
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  );
}
