import { motion } from 'motion/react';
import { useState, useEffect } from 'react';
import { Zap } from 'lucide-react';
import { ProductCard } from './ProductCard';

interface Product {
  id: string;
  name: string;
  price: string;
  originalPrice?: string;
  image: string;
  rating?: number;
  badge?: string;
}

interface FlashDealsProps {
  products: Product[];
  endTime: Date;
  theme?: 'dark' | 'light';
  onProductClick?: (productId: string) => void;
}

export function FlashDeals({ products, endTime, theme = 'dark', onProductClick }: FlashDealsProps) {
  const [timeLeft, setTimeLeft] = useState({ hours: 0, minutes: 0, seconds: 0 });

  useEffect(() => {
    const timer = setInterval(() => {
      const now = new Date().getTime();
      const distance = endTime.getTime() - now;

      if (distance < 0) {
        clearInterval(timer);
        return;
      }

      const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((distance % (1000 * 60)) / 1000);

      setTimeLeft({ hours, minutes, seconds });
    }, 1000);

    return () => clearInterval(timer);
  }, [endTime]);

  return (
    <div className="space-y-4">
      {/* Header with Timer */}
      <div className={`p-4 border rounded-2xl ${
        theme === 'dark'
          ? 'bg-gradient-to-r from-orange-950/30 to-red-950/30 border-orange-500/20'
          : 'bg-gradient-to-r from-orange-50 to-red-50 border-orange-200'
      }`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <motion.div
              animate={{ rotate: [0, 15, -15, 0] }}
              transition={{ duration: 0.5, repeat: Infinity, repeatDelay: 2 }}
            >
              <Zap className={`w-5 h-5 ${theme === 'dark' ? 'text-orange-400' : 'text-orange-600'}`} />
            </motion.div>
            <h3 className={`text-heading-sm ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
              Flash Deals
            </h3>
          </div>
          
          {/* Countdown Timer */}
          <div className="flex items-center gap-2">
            <span className={`text-footnote ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
              Ends in
            </span>
            <div className="flex gap-1">
              {[
                { value: timeLeft.hours, label: 'h' },
                { value: timeLeft.minutes, label: 'm' },
                { value: timeLeft.seconds, label: 's' },
              ].map((unit, index) => (
                <div key={index} className="flex items-center gap-0.5">
                  <div className={`px-2 py-1 min-w-[28px] text-center rounded ${
                    theme === 'dark' ? 'bg-black/40' : 'bg-white/80'
                  }`}>
                    <span className={`text-body-sm ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
                      {String(unit.value).padStart(2, '0')}
                    </span>
                  </div>
                  {index < 2 && (
                    <span className={`text-body-sm ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                      :
                    </span>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Products */}
      <div className="flex gap-4 overflow-x-auto no-scrollbar pb-2">
        {products.map((product, index) => (
          <div key={product.id} className="min-w-[160px]">
            <ProductCard product={product} theme={theme} index={index} onClick={onProductClick} />
          </div>
        ))}
      </div>
    </div>
  );
}
