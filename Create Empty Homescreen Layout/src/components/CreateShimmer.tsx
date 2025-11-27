import { motion } from 'motion/react';

interface CreateShimmerProps {
  variant: 'chat' | 'creations' | 'history';
  theme?: 'dark' | 'light';
}

export function CreateShimmer({ variant, theme = 'dark' }: CreateShimmerProps) {
  const shimmerAnimation = {
    initial: { backgroundPosition: '-200% 0' },
    animate: { backgroundPosition: '200% 0' },
  };

  const baseShimmer = theme === 'dark'
    ? 'bg-gradient-to-r from-white/5 via-white/10 to-white/5'
    : 'bg-gradient-to-r from-gray-200 via-gray-300 to-gray-200';

  const baseColor = theme === 'dark' ? 'bg-white/5' : 'bg-gray-100';

  if (variant === 'chat') {
    // Chat messages shimmer
    return (
      <div className="flex-1 p-4 space-y-4">
        {/* Assistant message */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex justify-start"
        >
          <div className={`max-w-[80%] rounded-2xl p-4 space-y-3 ${baseColor}`}>
            {/* Avatar + label */}
            <div className="flex items-center gap-2">
              <motion.div className={`w-6 h-6 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
              <motion.div className={`w-20 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
            </div>

            {/* Message lines */}
            <div className="space-y-2">
              <motion.div className={`w-full h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
              <motion.div className={`w-5/6 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
              <motion.div className={`w-3/4 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
            </div>

            {/* Timestamp */}
            <motion.div className={`w-16 h-2 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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

        {/* User message */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="flex justify-end"
        >
          <div className={`max-w-[80%] rounded-2xl p-4 space-y-3 ${baseColor}`}>
            <div className="space-y-2">
              <motion.div className={`w-48 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
              <motion.div className={`w-32 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
            </div>
            <motion.div className={`w-16 h-2 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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

        {/* Assistant with image */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="flex justify-start"
        >
          <div className={`max-w-[80%] rounded-2xl p-4 space-y-3 ${baseColor}`}>
            {/* Avatar + label */}
            <div className="flex items-center gap-2">
              <motion.div className={`w-6 h-6 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
              <motion.div className={`w-20 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
            </div>

            {/* Message */}
            <div className="space-y-2">
              <motion.div className={`w-full h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
            </div>

            {/* Image */}
            <motion.div className={`w-full h-48 rounded-xl overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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

  if (variant === 'creations') {
    // Creation grid shimmer
    return (
      <div className="flex-1 overflow-y-auto p-4">
        <div className="grid grid-cols-2 gap-3">
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: i * 0.05 }}
              className={`rounded-2xl overflow-hidden ${baseColor}`}
            >
              <div className="relative aspect-square">
                <motion.div className={`w-full h-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                  <motion.div
                    className={`w-full h-full ${baseShimmer}`}
                    style={{ backgroundSize: '200% 100%' }}
                    initial={shimmerAnimation.initial}
                    animate={shimmerAnimation.animate}
                    transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                  />
                </motion.div>
                
                {/* Overlay info */}
                <div className="absolute bottom-2 left-2 right-2 space-y-2">
                  <motion.div className={`w-3/4 h-2 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-black/40' : 'bg-white/60'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                  <motion.div className={`w-1/2 h-2 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-black/40' : 'bg-white/60'}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                  <div className="flex gap-1">
                    <motion.div className={`flex-1 h-6 rounded-lg overflow-hidden ${theme === 'dark' ? 'bg-black/40' : 'bg-white/60'}`}>
                      <motion.div
                        className={`w-full h-full ${baseShimmer}`}
                        style={{ backgroundSize: '200% 100%' }}
                        initial={shimmerAnimation.initial}
                        animate={shimmerAnimation.animate}
                        transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                      />
                    </motion.div>
                    <motion.div className={`w-8 h-6 rounded-lg overflow-hidden ${theme === 'dark' ? 'bg-black/40' : 'bg-white/60'}`}>
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

  // History tab shimmer
  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-3">
      {[...Array(5)].map((_, i) => (
        <motion.div
          key={i}
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: i * 0.05 }}
          className={`p-4 rounded-2xl space-y-3 ${baseColor}`}
        >
          {/* Title & timestamp */}
          <div className="flex items-start justify-between">
            <motion.div className={`w-32 h-4 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
            <motion.div className={`w-12 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
          </div>

          {/* Last message */}
          <motion.div className={`w-2/3 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>

          {/* Message count */}
          <div className="flex items-center gap-2">
            <motion.div className={`w-3 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
            <motion.div className={`w-20 h-2 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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
      ))}
    </div>
  );
}
