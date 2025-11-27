import { motion, AnimatePresence } from 'motion/react';
import { Plus, Mic, Search } from 'lucide-react';

interface CollapsibleBottomToolbarProps {
  isVisible: boolean;
  selectedTab: 'commerce' | 'community' | 'create';
  onTabChange: (tab: 'commerce' | 'community' | 'create') => void;
  theme: 'dark' | 'light';
  onSearchClick: () => void;
  searchQuery: string;
  onSearchQueryChange: (query: string) => void;
  isSearchOpen: boolean;
}

export function CollapsibleBottomToolbar({ isVisible, selectedTab, onTabChange, theme, onSearchClick, searchQuery, onSearchQueryChange, isSearchOpen }: CollapsibleBottomToolbarProps) {
  const getTabColor = (tab: 'commerce' | 'community' | 'create') => {
    if (tab === 'commerce') return '';
    if (tab === 'community') return '#401010';
    return '#0a1a40';
  };

  const getTabColorStyle = (tab: 'commerce' | 'community' | 'create') => {
    if (tab === 'commerce') return { color: '#094010' };
    return {};
  };

  const getAccentColor = (tab: 'commerce' | 'community' | 'create') => {
    if (tab === 'commerce') return 'bg-[#094010]/10';
    if (tab === 'community') return 'rgba(64, 16, 16, 0.1)';
    return 'rgba(10, 26, 64, 0.1)';
  };

  const getGlowColor = (tab: 'commerce' | 'community' | 'create') => {
    if (tab === 'commerce') return 'rgba(9, 64, 16, 0.3)';
    if (tab === 'community') return 'rgba(64, 16, 16, 0.3)';
    return 'rgba(10, 26, 64, 0.3)';
  };

  const getShadowColor = (tab: 'commerce' | 'community' | 'create') => {
    if (tab === 'commerce') return '0 4px 20px rgba(9, 64, 16, 0.4)';
    if (tab === 'community') return '0 4px 20px rgba(64, 16, 16, 0.4)';
    return '0 4px 20px rgba(10, 26, 64, 0.4)';
  };

  const getBorderColor = (tab: 'commerce' | 'community' | 'create') => {
    if (tab === 'commerce') return 'rgba(9, 64, 16, 0.3)';
    if (tab === 'community') return 'rgba(64, 16, 16, 0.3)';
    return 'rgba(10, 26, 64, 0.3)';
  };

  return (
    <>
      {/* Collapsible Toolbar - 3 sections */}
      <motion.div
        initial={{ y: 0 }}
        animate={{ y: isVisible ? 0 : 100 }}
        transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
        className="fixed bottom-0 left-0 right-0 z-40"
      >
            <div className={`backdrop-blur-2xl border-t transition-all duration-500 ${
              theme === 'dark'
                ? 'bg-black/40 border-white/[0.03]'
                : 'bg-[#fffff0]/80 border-black/[0.03]'
            }`}>
              <div className="grid grid-cols-3 px-6">
                {/* Commerce */}
                <button 
                  onClick={() => onTabChange('commerce')}
                  className={`py-3 flex items-center justify-center relative transition-all duration-300 ${
                    selectedTab === 'commerce' 
                      ? ''
                      : theme === 'dark' ? 'opacity-40 hover:opacity-70' : 'opacity-40 hover:opacity-70'
                  }`}
                >
                  <div className="relative">
                    {/* Outer glow effect for active tab */}
                    {selectedTab === 'commerce' && (
                      <motion.div
                        layoutId="bottomNavGlow"
                        className="absolute -inset-2 rounded-full blur-lg opacity-70 animate-pulse"
                        style={{ background: `radial-gradient(circle, ${getGlowColor('commerce')}, transparent)` }}
                        transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                      />
                    )}
                    
                    <motion.div 
                      className={`p-2 rounded-full transition-all duration-500 relative overflow-hidden ${
                        selectedTab === 'commerce' 
                          ? `shadow-lg border ${theme === 'dark' ? 'bg-white/10' : 'bg-black/10'}`
                          : ''
                      }`}
                      style={selectedTab === 'commerce' ? {
                        borderColor: getBorderColor('commerce'),
                        boxShadow: getShadowColor('commerce')
                      } : {}}
                    >
                      {/* Inner background glow for active tab */}
                      {selectedTab === 'commerce' && (
                        <motion.div
                          layoutId="bottomNavInnerGlow"
                          className="absolute inset-0 rounded-full"
                          style={{ background: getGlowColor('commerce').replace('0.3', '0.2') }}
                          transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                        />
                      )}
                      
                      <ShoppingBag 
                        className={`w-5 h-5 transition-colors duration-300 relative z-10 ${
                          selectedTab === 'commerce' 
                            ? getTabColor('commerce')
                            : theme === 'dark' ? 'text-white' : 'text-black'
                        }`}
                        style={selectedTab === 'commerce' ? getTabColorStyle('commerce') : {}}
                      />
                    </motion.div>
                  </div>
                  {selectedTab === 'commerce' && (
                    <motion.div
                      layoutId="activeTab"
                      className="absolute top-0 left-0 right-0 h-[2px]"
                      style={{
                        background: 'linear-gradient(to right, #094010, #094010)'
                      }}
                      transition={{ type: 'spring', stiffness: 500, damping: 40 }}
                    />
                  )}
                </button>
                
                {/* Community */}
                <button 
                  onClick={() => onTabChange('community')}
                  className={`py-3 flex items-center justify-center relative transition-all duration-300 ${
                    selectedTab === 'community' 
                      ? ''
                      : theme === 'dark' ? 'opacity-40 hover:opacity-70' : 'opacity-40 hover:opacity-70'
                  }`}
                >
                  <div className="relative">
                    {/* Outer glow effect for active tab */}
                    {selectedTab === 'community' && (
                      <motion.div
                        layoutId="bottomNavGlow"
                        className="absolute -inset-2 rounded-full blur-lg opacity-70 animate-pulse"
                        style={{ background: `radial-gradient(circle, ${getGlowColor('community')}, transparent)` }}
                        transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                      />
                    )}
                    
                    <motion.div 
                      className={`p-2 rounded-full transition-all duration-500 relative overflow-hidden ${
                        selectedTab === 'community' 
                          ? `shadow-lg border ${theme === 'dark' ? 'bg-white/10' : 'bg-black/10'}`
                          : ''
                      }`}
                      style={selectedTab === 'community' ? {
                        borderColor: getBorderColor('community'),
                        boxShadow: getShadowColor('community')
                      } : {}}
                    >
                      {/* Inner background glow for active tab */}
                      {selectedTab === 'community' && (
                        <motion.div
                          layoutId="bottomNavInnerGlow"
                          className="absolute inset-0 rounded-full"
                          style={{ background: getGlowColor('community').replace('0.3', '0.2') }}
                          transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                        />
                      )}
                      
                      <Users 
                        className={`w-5 h-5 transition-colors duration-300 relative z-10 ${
                          selectedTab === 'community' 
                            ? ''
                            : theme === 'dark' ? 'text-white' : 'text-black'
                        }`}
                        style={selectedTab === 'community' ? { color: getTabColor('community') } : {}}
                      />
                    </motion.div>
                  </div>
                  {selectedTab === 'community' && (
                    <motion.div
                      layoutId="activeTab"
                      className="absolute top-0 left-0 right-0 h-[2px]"
                      style={{ background: 'linear-gradient(to right, #401010, #401010)' }}
                      transition={{ type: 'spring', stiffness: 500, damping: 40 }}
                    />
                  )}
                </button>

                {/* Create */}
                <button 
                  onClick={() => onTabChange('create')}
                  className={`py-3 flex items-center justify-center relative transition-all duration-300 ${
                    selectedTab === 'create' 
                      ? ''
                      : theme === 'dark' ? 'opacity-40 hover:opacity-70' : 'opacity-40 hover:opacity-70'
                  }`}
                >
                  <div className="relative">
                    {/* Outer glow effect for active tab */}
                    {selectedTab === 'create' && (
                      <motion.div
                        layoutId="bottomNavGlow"
                        className="absolute -inset-2 rounded-full blur-lg opacity-70 animate-pulse"
                        style={{ background: `radial-gradient(circle, ${getGlowColor('create')}, transparent)` }}
                        transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                      />
                    )}
                    
                    <motion.div 
                      className={`p-2 rounded-full transition-all duration-500 relative overflow-hidden ${
                        selectedTab === 'create' 
                          ? `shadow-lg border ${theme === 'dark' ? 'bg-white/10' : 'bg-black/10'}`
                          : ''
                      }`}
                      style={selectedTab === 'create' ? {
                        borderColor: getBorderColor('create'),
                        boxShadow: getShadowColor('create')
                      } : {}}
                    >
                      {/* Inner background glow for active tab */}
                      {selectedTab === 'create' && (
                        <motion.div
                          layoutId="bottomNavInnerGlow"
                          className="absolute inset-0 rounded-full"
                          style={{ background: getGlowColor('create').replace('0.3', '0.2') }}
                          transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                        />
                      )}
                      
                      <Sparkles 
                        className={`w-5 h-5 transition-colors duration-300 relative z-10 ${
                          selectedTab === 'create' 
                            ? ''
                            : theme === 'dark' ? 'text-white' : 'text-black'
                        }`}
                        style={selectedTab === 'create' ? { color: getTabColor('create') } : {}}
                      />
                    </motion.div>
                  </div>
                  {selectedTab === 'create' && (
                    <motion.div
                      layoutId="activeTab"
                      className="absolute top-0 left-0 right-0 h-[2px]"
                      style={{ background: 'linear-gradient(to right, #0a1a40, #0a1a40)' }}
                      transition={{ type: 'spring', stiffness: 500, damping: 40 }}
                    />
                  )}
                </button>
              </div>
            </div>
      </motion.div>

      {/* Persistent Search Bar */}
      <motion.div
        initial={{ bottom: 64 }}
        animate={{ bottom: isVisible ? 64 : 20 }}
        transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
        className="fixed left-6 right-6 z-50 flex items-center justify-between gap-3"
      >
        {/* Left - FAB with + */}
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-300 ${
            selectedTab === 'commerce'
              ? 'hover:opacity-90'
              : selectedTab === 'community'
              ? 'hover:opacity-90'
              : 'hover:opacity-90'
          }`}
          style={
            selectedTab === 'commerce' ? {
              background: '#094010',
              boxShadow: '0 4px 20px rgba(9, 64, 16, 0.4)'
            } : selectedTab === 'community' ? {
              background: '#401010',
              boxShadow: '0 4px 20px rgba(64, 16, 16, 0.4)'
            } : {
              background: '#0a1a40',
              boxShadow: '0 4px 20px rgba(10, 26, 64, 0.4)'
            }
          }
        >
          <Plus className={`w-5 h-5 ${
            theme === 'dark' ? 'text-black' : 'text-white'
          }`} />
        </motion.button>

        {/* Right - Search bar */}
        <div className="relative flex-1">
          <div className={`rounded-full px-5 py-3.5 flex items-center gap-3 backdrop-blur-2xl border shadow-lg transition-all duration-300 ${
            theme === 'dark'
              ? 'bg-black/60 border-white/10 hover:border-white/20 shadow-black/20'
              : 'bg-white/70 border-black/10 hover:border-black/20 shadow-black/10'
          }`}>
            <Search 
              className="w-4 h-4 transition-colors"
              style={{
                color: selectedTab === 'commerce' ? '#094010' 
                  : selectedTab === 'community' ? '#401010'
                  : '#0a1a40'
              }}
            />
            <input
              type="text"
              placeholder="ask me anything"
              value={searchQuery}
              onChange={(e) => onSearchQueryChange(e.target.value)}
              onFocus={onSearchClick}
              className={`flex-1 bg-transparent outline-none text-sm transition-colors duration-300 ${
                theme === 'dark'
                  ? 'text-white placeholder:text-white/40'
                  : 'text-black placeholder:text-black/40'
              }`}
            />
            <button 
              className={`p-1.5 rounded-full transition-all duration-300 ${
                theme === 'dark' ? 'hover:bg-white/10' : 'hover:bg-black/10'
              }`}
              onClick={onSearchClick}
            >
              <Mic className={`w-4 h-4 transition-colors ${
                theme === 'dark' ? 'text-white/50' : 'text-black/50'
              }`} />
            </button>
          </div>
        </div>
      </motion.div>
    </>
  );
}

// Icon components
function ShoppingBag({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
      <line x1="3" y1="6" x2="21" y2="6" />
      <path d="M16 10a4 4 0 0 1-8 0" />
    </svg>
  );
}

function Users({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}

function Sparkles({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3l2 7h7l-5.5 4.5L18 22l-6-4.5L6 22l2.5-7.5L3 10h7l2-7z" />
    </svg>
  );
}