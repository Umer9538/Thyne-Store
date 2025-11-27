import { motion } from 'motion/react';

interface ShimmerCardProps {
  variant?: 'product' | 'banner' | 'category' | 'list';
  theme?: 'dark' | 'light';
  index?: number;
}

export function ShimmerCard({ variant = 'product', theme = 'dark', index = 0 }: ShimmerCardProps) {
  const shimmerAnimation = {
    initial: { backgroundPosition: '-200% 0' },
    animate: { backgroundPosition: '200% 0' },
  };

  const baseShimmer = theme === 'dark'
    ? 'bg-gradient-to-r from-white/5 via-white/10 to-white/5'
    : 'bg-gradient-to-r from-gray-200 via-gray-300 to-gray-200';

  if (variant === 'banner') {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: index * 0.05 }}
        className={`w-full h-48 rounded-3xl overflow-hidden ${
          theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
        }`}
      >
        <motion.div
          className={`w-full h-full ${baseShimmer}`}
          style={{ backgroundSize: '200% 100%' }}
          initial={shimmerAnimation.initial}
          animate={shimmerAnimation.animate}
          transition={{
            duration: 1.5,
            repeat: Infinity,
            ease: 'linear',
          }}
        />
      </motion.div>
    );
  }

  if (variant === 'category') {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: index * 0.05 }}
        className="flex flex-col items-center gap-2 min-w-[80px]"
      >
        <motion.div
          className={`w-16 h-16 rounded-full overflow-hidden ${
            theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
          }`}
        >
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        </motion.div>
        <motion.div
          className={`w-12 h-3 rounded-full overflow-hidden ${
            theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
          }`}
        >
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        </motion.div>
      </motion.div>
    );
  }

  if (variant === 'list') {
    return (
      <motion.div
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: index * 0.05 }}
        className={`flex gap-4 p-4 rounded-2xl ${
          theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
        }`}
      >
        <motion.div
          className={`w-20 h-20 rounded-xl overflow-hidden shrink-0 ${
            theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'
          }`}
        >
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        </motion.div>
        <div className="flex-1 space-y-2">
          <motion.div
            className={`w-3/4 h-4 rounded-full overflow-hidden ${
              theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'
            }`}
          >
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                ease: 'linear',
              }}
            />
          </motion.div>
          <motion.div
            className={`w-1/2 h-3 rounded-full overflow-hidden ${
              theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'
            }`}
          >
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                ease: 'linear',
              }}
            />
          </motion.div>
          <motion.div
            className={`w-1/3 h-4 rounded-full overflow-hidden ${
              theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'
            }`}
          >
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                ease: 'linear',
              }}
            />
          </motion.div>
        </div>
      </motion.div>
    );
  }

  // Default: product card
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05 }}
      className="space-y-3"
    >
      <motion.div
        className={`w-full aspect-square rounded-2xl overflow-hidden ${
          theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
        }`}
      >
        <motion.div
          className={`w-full h-full ${baseShimmer}`}
          style={{ backgroundSize: '200% 100%' }}
          initial={shimmerAnimation.initial}
          animate={shimmerAnimation.animate}
          transition={{
            duration: 1.5,
            repeat: Infinity,
            ease: 'linear',
          }}
        />
      </motion.div>
      <div className="space-y-2">
        <motion.div
          className={`w-3/4 h-4 rounded-full overflow-hidden ${
            theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
          }`}
        >
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        </motion.div>
        <motion.div
          className={`w-1/2 h-3 rounded-full overflow-hidden ${
            theme === 'dark' ? 'bg-white/5' : 'bg-gray-100'
          }`}
        >
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        </motion.div>
      </div>
    </motion.div>
  );
}
