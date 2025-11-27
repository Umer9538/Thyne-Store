import { motion } from 'motion/react';

interface CommunityShimmerProps {
  variant: 'verse' | 'spotlight' | 'profile';
  theme?: 'dark' | 'light';
}

export function CommunityShimmer({ variant, theme = 'dark' }: CommunityShimmerProps) {
  const shimmerAnimation = {
    initial: { backgroundPosition: '-200% 0' },
    animate: { backgroundPosition: '200% 0' },
  };

  const baseShimmer = theme === 'dark'
    ? 'bg-gradient-to-r from-white/5 via-white/10 to-white/5'
    : 'bg-gradient-to-r from-gray-200 via-gray-300 to-gray-200';

  const baseColor = theme === 'dark' ? 'bg-white/5' : 'bg-gray-100';

  if (variant === 'verse') {
    // Instagram-like feed shimmer
    return (
      <div className="space-y-6 pb-8">
        {[...Array(3)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.1 }}
            className="space-y-3 rounded-3xl overflow-hidden bg-gradient-to-br from-rose-950/30 via-pink-950/30 to-rose-950/30 backdrop-blur-xl border border-rose-500/20 shadow-lg shadow-rose-900/10"
          >
            {/* Header - User info */}
            <div className="flex items-center justify-between px-4">
              <div className="flex items-center gap-3">
                {/* Avatar */}
                <motion.div className={`w-10 h-10 rounded-full overflow-hidden ${baseColor}`}>
                  <motion.div
                    className={`w-full h-full ${baseShimmer}`}
                    style={{ backgroundSize: '200% 100%' }}
                    initial={shimmerAnimation.initial}
                    animate={shimmerAnimation.animate}
                    transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                  />
                </motion.div>
                {/* Username & time */}
                <div className="space-y-1.5">
                  <motion.div className={`w-24 h-3 rounded-full overflow-hidden ${baseColor}`}>
                    <motion.div
                      className={`w-full h-full ${baseShimmer}`}
                      style={{ backgroundSize: '200% 100%' }}
                      initial={shimmerAnimation.initial}
                      animate={shimmerAnimation.animate}
                      transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                    />
                  </motion.div>
                  <motion.div className={`w-16 h-2 rounded-full overflow-hidden ${baseColor}`}>
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

            {/* Post Image */}
            <motion.div className={`w-full aspect-[3/4] rounded-2xl overflow-hidden ${baseColor}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>

            {/* Product Avatars */}
            <div className="flex gap-2 px-4">
              {[...Array(3)].map((_, j) => (
                <motion.div key={j} className={`w-12 h-12 rounded-full overflow-hidden ${baseColor}`}>
                  <motion.div
                    className={`w-full h-full ${baseShimmer}`}
                    style={{ backgroundSize: '200% 100%' }}
                    initial={shimmerAnimation.initial}
                    animate={shimmerAnimation.animate}
                    transition={{ duration: 1.5, repeat: Infinity, ease: 'linear', delay: j * 0.1 }}
                  />
                </motion.div>
              ))}
            </div>

            {/* Actions */}
            <div className="flex items-center justify-between px-4">
              <div className="flex gap-3">
                {[...Array(3)].map((_, j) => (
                  <motion.div key={j} className={`w-6 h-6 rounded-full overflow-hidden ${baseColor}`}>
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
              <motion.div className={`w-6 h-6 rounded-full overflow-hidden ${baseColor}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
            </div>

            {/* Caption */}
            <div className="px-4 space-y-2">
              <motion.div className={`w-3/4 h-3 rounded-full overflow-hidden ${baseColor}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>
              <motion.div className={`w-1/2 h-3 rounded-full overflow-hidden ${baseColor}`}>
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

  if (variant === 'spotlight') {
    // Marketing/Leaderboard shimmer
    return (
      <div className="space-y-6 pb-8">
        {/* Featured Banner */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className={`w-full h-40 rounded-3xl overflow-hidden ${baseColor}`}
        >
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
          />
        </motion.div>

        {/* Leaderboard Items */}
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.05 }}
              className={`flex items-center gap-4 p-4 rounded-2xl ${baseColor}`}
            >
              {/* Rank number */}
              <motion.div className={`w-8 h-8 rounded-lg overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>

              {/* Avatar */}
              <motion.div className={`w-12 h-12 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
                <motion.div
                  className={`w-full h-full ${baseShimmer}`}
                  style={{ backgroundSize: '200% 100%' }}
                  initial={shimmerAnimation.initial}
                  animate={shimmerAnimation.animate}
                  transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                />
              </motion.div>

              {/* Info */}
              <div className="flex-1 space-y-2">
                <motion.div className={`w-32 h-3 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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

              {/* Score */}
              <motion.div className={`w-16 h-6 rounded-full overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-gray-200'}`}>
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
      </div>
    );
  }

  // Profile tab shimmer
  return (
    <div className="space-y-6 pb-8">
      {/* Profile Header */}
      <div className="flex items-center gap-4 px-4">
        <motion.div className={`w-20 h-20 rounded-full overflow-hidden ${baseColor}`}>
          <motion.div
            className={`w-full h-full ${baseShimmer}`}
            style={{ backgroundSize: '200% 100%' }}
            initial={shimmerAnimation.initial}
            animate={shimmerAnimation.animate}
            transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
          />
        </motion.div>
        <div className="flex-1 space-y-2">
          <motion.div className={`w-32 h-4 rounded-full overflow-hidden ${baseColor}`}>
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>
          <motion.div className={`w-24 h-3 rounded-full overflow-hidden ${baseColor}`}>
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

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 px-4">
        {[...Array(3)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.05 }}
            className="space-y-1"
          >
            <motion.div className={`w-full h-6 rounded-lg overflow-hidden ${baseColor}`}>
              <motion.div
                className={`w-full h-full ${baseShimmer}`}
                style={{ backgroundSize: '200% 100%' }}
                initial={shimmerAnimation.initial}
                animate={shimmerAnimation.animate}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              />
            </motion.div>
            <motion.div className={`w-12 h-2 mx-auto rounded-full overflow-hidden ${baseColor}`}>
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

      {/* Media Grid */}
      <div className="grid grid-cols-3 gap-2 px-4">
        {[...Array(9)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.05 }}
            className={`aspect-square rounded-xl overflow-hidden ${baseColor}`}
          >
            <motion.div
              className={`w-full h-full ${baseShimmer}`}
              style={{ backgroundSize: '200% 100%' }}
              initial={shimmerAnimation.initial}
              animate={shimmerAnimation.animate}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
            />
          </motion.div>
        ))}
      </div>
    </div>
  );
}
