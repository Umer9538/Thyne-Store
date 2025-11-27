import { motion } from 'motion/react';
import { ArrowRight } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface Collection {
  id: string;
  name: string;
  description: string;
  images: string[];
  itemCount: number;
}

interface CollectionCardProps {
  collection: Collection;
  theme?: 'dark' | 'light';
  index?: number;
  onClick?: (category: string, title: string) => void;
}

export function CollectionCard({ collection, theme = 'light', index = 0, onClick }: CollectionCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
      onClick={() => onClick?.(collection.id, collection.name)}
      className={`group overflow-hidden border transition-all duration-300 cursor-pointer rounded-2xl ${
        theme === 'dark'
          ? 'bg-white/5 border-white/10 hover:border-emerald-500/30'
          : 'bg-white border-gray-200 hover:border-emerald-400'
      }`}
    >
      {/* Images Grid */}
      <div className="relative h-40 overflow-hidden rounded-t-2xl">
        {collection.images.length === 1 ? (
          <ImageWithFallback
            src={collection.images[0]}
            alt={collection.name}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
          />
        ) : (
          <div className="grid grid-cols-2 gap-1 h-full">
            {collection.images.slice(0, 4).map((image, i) => (
              <div key={i} className="relative overflow-hidden">
                <ImageWithFallback
                  src={image}
                  alt={`${collection.name} ${i + 1}`}
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                />
              </div>
            ))}
          </div>
        )}
        
        {/* Gradient overlay */}
        <div className={`absolute inset-0 ${
          theme === 'dark'
            ? 'bg-gradient-to-t from-black/80 via-black/20 to-transparent'
            : 'bg-gradient-to-t from-white/80 via-white/20 to-transparent'
        }`} />

        {/* Item count badge */}
        <div className="absolute top-2 right-2 px-2 py-0.5 text-[9px] backdrop-blur-md bg-black/60 text-white rounded">
          {collection.itemCount} items
        </div>
      </div>

      {/* Content */}
      <div className="p-3 space-y-1.5">
        <h4 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
          {collection.name}
        </h4>
        <p className={`text-[11px] ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
          {collection.description}
        </p>
        
        <motion.button
          whileHover={{ x: 5 }}
          className={`flex items-center gap-1.5 text-[11px] transition-colors duration-300 ${
            theme === 'dark'
              ? 'text-emerald-400 hover:text-emerald-300'
              : 'text-emerald-600 hover:text-emerald-700'
          }`}
        >
          <span>Explore Collection</span>
          <ArrowRight className="w-3 h-3" />
        </motion.button>
      </div>
    </motion.div>
  );
}
