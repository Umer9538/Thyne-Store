import { motion } from 'motion/react';

interface Occasion {
  id: string;
  name: string;
  icon: string;
  gradient: string;
  count?: number;
}

interface OccasionCardsProps {
  occasions: Occasion[];
  theme?: 'dark' | 'light';
}

export function OccasionCards({ occasions, theme = 'light' }: OccasionCardsProps) {
  return (
    <div className="space-y-3">
      <h3 className={`text-[15px] ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
        Shop by Occasion
      </h3>
      <div className="grid grid-cols-2 gap-2">
        {occasions.map((occasion, index) => (
          <motion.button
            key={occasion.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className={`relative p-4 overflow-hidden border transition-all duration-300 rounded-2xl ${
              theme === 'dark'
                ? 'bg-white/[0.02] border-white/[0.08] hover:border-[#094010]/30 hover:bg-white/[0.04]'
                : 'bg-white border-black/5 hover:border-[#094010]/30 hover:bg-black/[0.01]'
            }`}
          >
            {/* Content */}
            <div className="relative space-y-2">
              <div className="text-2xl">{occasion.icon}</div>
              <div className="text-left">
                <h4 className={`text-xs ${theme === 'dark' ? 'text-white/90' : 'text-black/90'}`}>
                  {occasion.name}
                </h4>
                {occasion.count && (
                  <p className={`text-[10px] ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                    {occasion.count} items
                  </p>
                )}
              </div>
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  );
}
