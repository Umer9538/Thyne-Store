import { motion } from 'motion/react';

interface ShoppingBagShimmerProps {
  theme?: 'dark' | 'light';
}

export function ShoppingBagShimmer({ theme = 'dark' }: ShoppingBagShimmerProps) {
  const shimmerAnimation = {
    initial: { backgroundPosition: '-200% 0' },
    animate: { backgroundPosition: '200% 0' },
  };

  const baseShimmer = theme === 'dark'
    ? 'bg-gradient-to-r from-white/5 via-white/10 to-white/5'
    : 'bg-gradient-to-r from-gray-200 via-gray-300 to-gray-200';

  const baseColor = theme === 'dark' ? 'bg-white/5' : 'bg-gray-100';

  return (
    <div className="px-4 py-6 space-y-6 pb-48">
      {/* Trust Badges Shimmer */}
      <div className="grid grid-cols-3 gap-2">
        {[...Array(3)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05 }}
            className={`p-3 rounded-xl overflow-hidden ${baseColor}`}
          >
            {/* Icon */}
            <motion.div className={`w-5 h-5 mx-auto mb-2 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
            
            {/* Text lines */}
            <motion.div className={`w-16 h-2 mx-auto mb-1 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
            <motion.div className={`w-12 h-2 mx-auto rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
          </motion.div>
        ))}
      </div>

      {/* Bag Items Shimmer */}
      <div className="space-y-3">
        {[...Array(3)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.05 }}
            className={`p-4 rounded-2xl ${baseColor}`}
          >
            <div className="flex gap-4">
              {/* Image Shimmer */}
              <motion.div className={`w-20 h-20 rounded-xl overflow-hidden shrink-0 ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>

              {/* Info Shimmer */}
              <div className="flex-1 space-y-3">
                {/* Title & variant */}
                <div className="space-y-1.5">
                  <motion.div className={`w-3/4 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                  <motion.div className={`w-16 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                </div>

                {/* Price and controls */}
                <div className="flex items-center justify-between">
                  <motion.div className={`w-24 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>

                  {/* Quantity controls shimmer */}
                  <div className="flex items-center gap-2">
                    {[...Array(4)].map((_, j) => (
                      <motion.div
                        key={j}
                        className={`${j === 1 ? 'w-5' : 'w-7'} h-7 rounded-lg overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}
                      >
                        <motion.div
                          className={`w-full h-full ${baseShimmer}`}
                          style={{ backgroundSize: '200% 100%' }}
                          initial={shimmerAnimation.initial}
                          animate={shimmerAnimation.animate}
                          transition={{ duration: 1.5, repeat: Infinity, ease: 'linear', delay: j * 0.05 }}
                        />
                      </motion.div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Promo Code Shimmer */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className={`p-4 rounded-2xl ${baseColor}`}
      >
        <div className="flex items-center gap-2 mb-3">
          <motion.div className={`w-4 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>
          <motion.div className={`w-24 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>
        </div>
        
        <div className="flex gap-2">
          <motion.div className={`flex-1 h-10 rounded-xl overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>
          <motion.div className={`w-20 h-10 rounded-xl overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>
        </div>
      </motion.div>
    </div>
  );
}
