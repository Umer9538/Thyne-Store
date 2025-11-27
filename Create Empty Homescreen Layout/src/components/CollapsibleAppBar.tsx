import { motion, AnimatePresence } from 'motion/react';
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar';
import { Gift, Heart, ShoppingBag, MapPin } from 'lucide-react';
import Group from '../imports/Group2';

interface CollapsibleAppBarProps {
  isVisible: boolean;
  onWishlistClick: () => void;
  onBagClick: () => void;
  bagItemCount?: number;
}

export function CollapsibleAppBar({ isVisible, onWishlistClick, onBagClick, bagItemCount = 0 }: CollapsibleAppBarProps) {
  return (
    <div className="fixed top-0 left-0 right-0 z-50">
      {/* Row 1 - Always visible */}
      <motion.div
        initial={{ y: 0 }}
        animate={{ y: isVisible ? 0 : -64 }}
        transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
        className="backdrop-blur-2xl transition-colors duration-500 bg-[#fffff0]/80 border-b border-black/[0.03]"
      >
        <div className="flex items-center justify-between px-6 pt-4 pb-3">
          <div className="flex items-center gap-3">
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.98 }}
            >
              <Avatar className="h-8 w-8 ring-1 transition-all duration-300 ring-black/10">
                <AvatarFallback className="text-[10px] tracking-wider uppercase transition-colors bg-black/5 text-black/90">
                  <div className="w-4 h-4">
                    <Group />
                  </div>
                </AvatarFallback>
              </Avatar>
            </motion.div>
            <span className="text-sm tracking-[0.08em] uppercase transition-colors duration-500 text-black/90">thyne</span>
          </div>
          
          <div className="flex items-center gap-4">
            {/* Profile Avatar */}
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.98 }}
            >
              <Avatar className="h-8 w-8 ring-1 transition-all duration-300 ring-black/10">
                <AvatarImage src="" />
                <AvatarFallback className="text-xs tracking-wider uppercase bg-black/5 text-black/90">
                  U
                </AvatarFallback>
              </Avatar>
            </motion.div>
          </div>
        </div>
      </motion.div>

      {/* Row 2 - Collapsible */}
      <motion.div
        initial={{ y: 0 }}
        animate={{ y: isVisible ? 0 : -64 }}
        transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
        className="backdrop-blur-2xl transition-colors duration-500 bg-[#fffff0]/80 border-b border-black/[0.03]"
      >
        <motion.div
          initial={{ opacity: 1, height: 'auto' }}
          animate={{ 
            opacity: isVisible ? 1 : 0,
            height: isVisible ? 'auto' : 0
          }}
          transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
          className="overflow-hidden"
        >
            <div className="flex items-center justify-between px-6 pb-3 gap-4">
              <div className="flex-1 min-w-0 max-w-[65%] flex items-center gap-2">
                <MapPin className="w-3.5 h-3.5 flex-shrink-0 transition-colors duration-500 text-black/40" />
                <span className="text-xs truncate block transition-colors duration-500 text-black/60">
                  <span className="opacity-70">deliver to </span>
                  <span className="text-black/90">Sector 2</span>
                </span>
              </div>
              
              <div className="flex items-center gap-3 flex-shrink-0">
                <motion.button 
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  className="p-2 rounded-full transition-all duration-300 hover:bg-black/5"
                >
                  <Gift className="w-4 h-4 transition-colors text-black/50 hover:text-black/90" />
                </motion.button>
                
                <motion.button 
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={onWishlistClick}
                  className="p-2 rounded-full transition-all duration-300 hover:bg-black/5"
                >
                  <Heart className="w-4 h-4 transition-colors text-black/50 hover:text-black/90" />
                </motion.button>
                
                <motion.button 
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={onBagClick}
                  className="relative"
                >
                  <div className="p-2 rounded-full transition-all duration-300 hover:bg-black/5">
                    <ShoppingBag className="w-4 h-4 transition-colors text-black/50 hover:text-black/90" />
                  </div>
                  {bagItemCount > 0 && (
                    <div className="absolute top-0 right-0 min-w-[14px] h-[14px] px-0.5 rounded-full flex items-center justify-center text-[9px] bg-black text-white">
                      {bagItemCount}
                    </div>
                  )}
                </motion.button>
              </div>
            </div>
          </motion.div>
      </motion.div>
    </div>
  );
}
