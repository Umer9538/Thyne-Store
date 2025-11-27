import { motion } from 'motion/react';
import { IndianRupee } from 'lucide-react';

interface PriceRange {
  id: string;
  label: string;
  min: number;
  max: number | null;
  count: number;
  popular?: boolean;
}

interface PriceRangeCardsProps {
  ranges: PriceRange[];
  theme?: 'dark' | 'light';
}

export function PriceRangeCards({ ranges, theme = 'dark' }: PriceRangeCardsProps) {
  return (
    <div className="space-y-3">
      <h3 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
        Shop by Budget
      </h3>
      <div className="grid grid-cols-2 gap-2">
        {ranges.map((range, index) => (
          <motion.button
            key={range.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className={`relative p-3 border transition-all duration-300 overflow-hidden rounded-xl ${
              range.popular
                ? theme === 'dark'
                  ? 'bg-gradient-to-br from-emerald-950/50 to-teal-950/50 border-emerald-500/30'
                  : 'bg-gradient-to-br from-emerald-50 to-teal-50 border-emerald-300'
                : theme === 'dark'
                ? 'bg-white/5 border-white/10 hover:border-emerald-500/30'
                : 'bg-white border-gray-200 hover:border-emerald-400'
            }`}
          >
            {range.popular && (
              <div className="absolute top-1.5 right-1.5 px-1.5 py-0.5 text-[8px] bg-emerald-500 text-white rounded">
                Popular
              </div>
            )}
            
            <div className="space-y-1 text-left">
              <div className={`flex items-center gap-1 ${
                theme === 'dark' ? 'text-emerald-400' : 'text-emerald-600'
              }`}>
                <IndianRupee className="w-3 h-3" />
                <span className="text-[16px]">
                  {range.max ? `${range.min / 1000}k-${range.max / 1000}k` : `${range.min / 1000}k+`}
                </span>
              </div>
              <p className={`text-[9px] ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
                {range.count} items
              </p>
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  );
}
