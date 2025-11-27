import { motion, AnimatePresence } from 'motion/react';

interface CommerceTopNavProps {
  isVisible: boolean;
  selectedCategory: string;
  onCategoryChange: (category: string) => void;
  theme: 'dark' | 'light';
}

export function CommerceTopNav({ isVisible, selectedCategory, onCategoryChange, theme }: CommerceTopNavProps) {
  const categories = [
    { id: 'all', label: 'all' },
    { id: 'women', label: 'women' },
    { id: 'men', label: 'men' },
    { id: 'inclusive', label: 'inclusive' },
    { id: 'kids', label: 'kids' },
  ];

  return (
    <motion.div
      initial={false}
      animate={{ top: isVisible ? '104px' : '0px' }}
      transition={{ duration: 0.3, ease: [0.4, 0, 0.2, 1] }}
      className={`fixed left-0 right-0 z-40 backdrop-blur-2xl border-b transition-colors duration-500 ${
        theme === 'dark'
          ? 'bg-black/40 border-white/[0.03]'
          : 'bg-[#fffff0]/80 border-black/[0.03]'
      }`}
    >
          <div className="flex items-center gap-3 px-5 py-4 overflow-x-auto scrollbar-hide">
            {categories.map((category) => (
              <div key={category.id} className="relative">
                {/* Outer glow effect for active tab */}
                {selectedCategory === category.id && (
                  <motion.div
                    layoutId="categoryGlow"
                    className="absolute -inset-1 rounded-full blur-lg opacity-70 animate-pulse"
                    style={{ background: 'radial-gradient(circle, rgba(9, 64, 16, 0.3), transparent)' }}
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
                
                <motion.button
                  onClick={() => onCategoryChange(category.id)}
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                  className={`relative px-6 py-2.5 rounded-full transition-all duration-500 whitespace-nowrap flex-shrink-0 overflow-hidden ${
                    selectedCategory === category.id
                      ? `shadow-lg border ${
                          theme === 'dark' ? 'bg-white/10' : 'bg-black/10'
                        }`
                      : `border border-transparent ${
                          theme === 'dark' 
                            ? 'bg-white/[0.03] hover:bg-white/[0.06]' 
                            : 'bg-black/[0.03] hover:bg-black/[0.06]'
                        }`
                  }`}
                  style={selectedCategory === category.id ? {
                    borderColor: 'rgba(9, 64, 16, 0.3)',
                    boxShadow: '0 4px 20px rgba(9, 64, 16, 0.4)'
                  } : {}}
                >
                  {/* Inner background glow for active tab */}
                  {selectedCategory === category.id && (
                    <motion.div
                      layoutId="activeTabGlow"
                      className="absolute inset-0 rounded-full"
                      style={{ background: 'rgba(9, 64, 16, 0.2)' }}
                      transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                    />
                  )}
                  
                  <span
                    className={`relative z-10 text-body-sm tracking-wide transition-all duration-500 ${
                      selectedCategory === category.id 
                        ? theme === 'dark' ? 'text-white' : 'text-black'
                        : theme === 'dark' ? 'text-white/50' : 'text-black/50'
                    }`}
                  >
                    {category.label}
                  </span>
                </motion.button>
              </div>
            ))}
          </div>

          <style>{`
            .scrollbar-hide::-webkit-scrollbar {
              display: none;
            }
            .scrollbar-hide {
              -ms-overflow-style: none;
              scrollbar-width: none;
            }
          `}</style>
    </motion.div>
  );
}
