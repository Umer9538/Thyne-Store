import { motion } from 'motion/react';

interface WishlistShimmerProps {
  theme?: 'dark' | 'light';
}

export function WishlistShimmer({ theme = 'dark' }: WishlistShimmerProps) {
  const shimmerAnimation = {
    initial: { backgroundPosition: '-200% 0' },
    animate: { backgroundPosition: '200% 0' },
  };

  const baseShimmer = theme === 'dark'
    ? 'bg-gradient-to-r from-white/5 via-white/10 to-white/5'
    : 'bg-gradient-to-r from-gray-200 via-gray-300 to-gray-200';

  const baseColor = theme === 'dark' ? 'bg-white/5' : 'bg-gray-100';

  return (
    <div className="px-4 py-6 space-y-6">
      {/* Stats Card Shimmer */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className={`p-4 rounded-2xl overflow-hidden ${baseColor}`}
      >
        <div className="flex items-center justify-between">
          <div className="space-y-2 flex-1">
            <motion.div className={`w-20 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
            <motion.div className={`w-32 h-6 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
          </div>
          <motion.div className={`w-12 h-12 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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

      {/* Wishlist Items Shimmer */}
      <div className="space-y-4">
        {[...Array(4)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05 }}
            className={`p-4 rounded-2xl ${baseColor}`}
          >
            <div className="flex gap-4">
              {/* Image Shimmer */}
              <motion.div className={`w-24 h-24 rounded-xl overflow-hidden shrink-0 ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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
                {/* Title & date */}
                <div className="space-y-2">
                  <motion.div className={`w-3/4 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                  <motion.div className={`w-24 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                </div>

                {/* Price */}
                <div className="flex items-center gap-2">
                  <motion.div className={`w-20 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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

                {/* Action buttons */}
                <div className="flex gap-2 pt-2">
                  <motion.div className={`flex-1 h-9 rounded-xl overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                  <motion.div className={`w-9 h-9 rounded-xl overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
