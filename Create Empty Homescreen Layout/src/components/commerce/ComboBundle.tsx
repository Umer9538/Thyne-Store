import { motion } from 'motion/react';
import { Plus, ShoppingBag } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface ComboProduct {
  id: string;
  name: string;
  price: number;
  image: string;
}

interface Combo {
  id: string;
  name: string;
  products: ComboProduct[];
  totalPrice: number;
  discountedPrice: number;
  savings: number;
  savingsPercent: number;
}

interface ComboBundleProps {
  combo: Combo;
  theme?: 'dark' | 'light';
  onClick?: (bundleId: string) => void;
}

export function ComboBundle({ combo, theme = 'dark', onClick }: ComboBundleProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      onClick={() => onClick?.(combo.id)}
      className={`p-4 border transition-all duration-300 cursor-pointer rounded-2xl ${
        theme === 'dark'
          ? 'bg-gradient-to-br from-emerald-950/30 to-teal-950/30 border-emerald-500/20 hover:border-emerald-500/40'
          : 'bg-gradient-to-br from-emerald-50 to-teal-50 border-emerald-200 hover:border-emerald-300'
      }`}
    >
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div>
            <h4 className={`text-body ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
              {combo.name}
            </h4>
            <p className={`text-footnote ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
              Save ₹{combo.savings} ({combo.savingsPercent}% off)
            </p>
          </div>
          <div className="px-3 py-1 text-footnote bg-emerald-500 text-white rounded-lg">
            Bundle Deal
          </div>
        </div>

        {/* Products */}
        <div className="flex items-center gap-2">
          {combo.products.map((product, index) => (
            <div key={product.id} className="flex items-center gap-2">
              <div className={`relative w-16 h-16 overflow-hidden border rounded-lg ${
                theme === 'dark' ? 'border-white/10' : 'border-gray-200'
              }`}>
                <ImageWithFallback
                  src={product.image}
                  alt={product.name}
                  className="w-full h-full object-cover"
                />
              </div>
              {index < combo.products.length - 1 && (
                <Plus className={`w-3 h-3 ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`} />
              )}
            </div>
          ))}
        </div>

        {/* Price & CTA */}
        <div className="flex items-center justify-between pt-2">
          <div>
            <div className="flex items-center gap-2">
              <span className={`text-body ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
                ₹{combo.discountedPrice.toLocaleString()}
              </span>
              <span className={`text-footnote line-through ${
                theme === 'dark' ? 'text-white/40' : 'text-black/40'
              }`}>
                ₹{combo.totalPrice.toLocaleString()}
              </span>
            </div>
          </div>
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className={`px-4 py-2 flex items-center gap-2 transition-all duration-300 rounded-lg ${
              theme === 'dark'
                ? 'bg-emerald-500 hover:bg-emerald-600 text-white'
                : 'bg-emerald-600 hover:bg-emerald-700 text-white'
            }`}
          >
            <ShoppingBag className="w-4 h-4" />
            <span className="text-body-sm">Add Bundle</span>
          </motion.button>
        </div>
      </div>
    </motion.div>
  );
}
