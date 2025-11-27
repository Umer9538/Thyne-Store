import React from 'react';
import { Trophy, TrendingUp, Star, Crown, Zap, Award, Users, Heart } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface Creator {
  id: string;
  name: string;
  avatar: string;
  followers: string;
  posts: number;
  rank: number;
}

interface LeaderboardEntry {
  id: string;
  name: string;
  avatar: string;
  points: number;
  change: number;
}

interface SpotlightProps {
  onProductClick?: (productId: string) => void;
  onCreatorClick?: (creatorId: string) => void;
  theme?: 'dark' | 'light';
}

const TOP_CREATORS: Creator[] = [
  {
    id: '1',
    name: 'Sarah Chen',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    followers: '124K',
    posts: 342,
    rank: 1,
  },
  {
    id: '2',
    name: 'Alex Morgan',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    followers: '98K',
    posts: 287,
    rank: 2,
  },
  {
    id: '3',
    name: 'Maya Patel',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    followers: '87K',
    posts: 215,
    rank: 3,
  },
];

const LEADERBOARD: LeaderboardEntry[] = [
  {
    id: '1',
    name: 'DesignMaster',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    points: 15420,
    change: 12,
  },
  {
    id: '2',
    name: 'CreativeFlow',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    points: 14830,
    change: -3,
  },
  {
    id: '3',
    name: 'ArtisticSoul',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    points: 13965,
    change: 5,
  },
  {
    id: '4',
    name: 'VisualVerse',
    avatar: 'https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200',
    points: 12740,
    change: 8,
  },
];

export const Spotlight: React.FC<SpotlightProps> = ({ onProductClick, onCreatorClick, theme = 'dark' }) => {
  return (
    <div className="space-y-6 pb-6">
      {/* Featured Banner */}
      <div className="relative h-48 rounded-2xl overflow-hidden bg-gradient-to-br from-red-600 to-rose-700">
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48cGF0dGVybiBpZD0iZ3JpZCIgd2lkdGg9IjQwIiBoZWlnaHQ9IjQwIiBwYXR0ZXJuVW5pdHM9InVzZXJTcGFjZU9uVXNlIj48cGF0aCBkPSJNIDQwIDAgTCAwIDAgMCA0MCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLW9wYWNpdHk9IjAuMSIgc3Ryb2tlLXdpZHRoPSIxIi8+PC9wYXR0ZXJuPjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2dyaWQpIi8+PC9zdmc+')] opacity-20" />
        <div className="relative h-full flex items-center justify-between px-8">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Star className="w-6 h-6 text-yellow-400 fill-yellow-400" />
              <span className="text-sm text-red-100">This Week's Highlight</span>
            </div>
            <h2 className="text-2xl text-white mb-1">Community Spotlight</h2>
            <p className="text-red-100">Discover trending creators and top posts</p>
          </div>
          <Trophy className="w-24 h-24 text-white/20" />
        </div>
      </div>

      {/* Top Creators */}
      <div className={`rounded-2xl backdrop-blur-xl p-6 ${
        theme === 'dark'
          ? 'bg-zinc-900/40 border border-red-900/20'
          : 'bg-white/60 border border-red-200/40'
      }`}>
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-red-500 to-rose-600 flex items-center justify-center">
              <Crown className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className={`text-lg ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>Top Creators</h3>
              <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>Most influential this month</p>
            </div>
          </div>
          <button className="text-sm text-rose-400 hover:text-rose-300 transition-colors px-3 py-1.5 rounded-full hover:bg-rose-500/10 transition-all">
            View All
          </button>
        </div>

        <div className="grid grid-cols-3 gap-4">
          {TOP_CREATORS.map((creator) => (
            <button
              key={creator.id}
              onClick={() => onCreatorClick?.(creator.id)}
              className={`group relative p-4 transition-all duration-300 rounded-2xl ${
                theme === 'dark'
                  ? 'bg-zinc-900/60 border border-rose-900/20 hover:border-rose-500/40 hover:bg-zinc-900'
                  : 'bg-white/50 border border-rose-200/30 hover:border-rose-500/50 hover:bg-white/80'
              }`}
            >
              {/* Rank Badge */}
              <div className={`absolute -top-2 -right-2 w-8 h-8 rounded-full bg-gradient-to-br from-rose-500 to-pink-600 border-2 flex items-center justify-center ${
                theme === 'dark' ? 'border-zinc-900' : 'border-white'
              }`}>
                <span className="text-xs text-white">#{creator.rank}</span>
              </div>

              <div className="flex flex-col items-center">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-rose-500 to-pink-600 p-0.5 mb-3">
                  <ImageWithFallback
                    src={creator.avatar}
                    alt={creator.name}
                    className="w-full h-full rounded-full object-cover"
                  />
                </div>
                <p className={`text-sm mb-1 ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>{creator.name}</p>
                <p className="text-xs text-rose-400 mb-2">{creator.followers} followers</p>
                <p className={`text-xs ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>{creator.posts} posts</p>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Leaderboard */}
      <div className={`rounded-2xl backdrop-blur-xl p-6 ${
        theme === 'dark'
          ? 'bg-zinc-900/40 border border-emerald-900/20'
          : 'bg-white/60 border border-emerald-200/40'
      }`}>
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className={`text-lg ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>Leaderboard</h3>
              <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>Top performers this week</p>
            </div>
          </div>
        </div>

        <div className="space-y-3">
          {LEADERBOARD.map((entry, index) => (
            <div
              key={entry.id}
              className={`flex items-center gap-4 p-4 rounded-xl transition-all duration-300 ${
                theme === 'dark'
                  ? 'bg-zinc-900/60 border border-emerald-900/20 hover:border-emerald-500/40'
                  : 'bg-white/50 border border-emerald-200/30 hover:border-emerald-500/50'
              }`}
            >
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-600/20 to-teal-600/20 border border-emerald-500/30">
                <span className="text-sm text-emerald-400">#{index + 1}</span>
              </div>
              
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 p-0.5">
                <ImageWithFallback
                  src={entry.avatar}
                  alt={entry.name}
                  className="w-full h-full rounded-full object-cover"
                />
              </div>

              <div className="flex-1">
                <p className={`text-sm ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>{entry.name}</p>
                <p className={`text-xs ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>{entry.points.toLocaleString()} points</p>
              </div>

              <div
                className={`flex items-center gap-1 px-2 py-1 rounded-lg ${
                  entry.change > 0
                    ? 'bg-emerald-500/20 text-emerald-400'
                    : 'bg-red-500/20 text-red-400'
                }`}
              >
                <TrendingUp
                  className={`w-4 h-4 ${entry.change < 0 ? 'rotate-180' : ''}`}
                />
                <span className="text-xs">{Math.abs(entry.change)}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Your Stats */}
      <div className={`backdrop-blur-xl rounded-2xl p-6 ${
        theme === 'dark'
          ? 'bg-zinc-900/40 border border-emerald-900/20'
          : 'bg-white/60 border border-emerald-200/40'
      }`}>
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Award className="w-6 h-6 text-white" />
          </div>
          <div>
            <h3 className={`text-lg ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>Your Top Post</h3>
            <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>Most engagement this week</p>
          </div>
        </div>

        <div className="flex gap-4">
          <div className={`w-32 h-32 rounded-xl overflow-hidden ${
            theme === 'dark' ? 'bg-zinc-950' : 'bg-zinc-200'
          }`}>
            <ImageWithFallback
              src="https://images.unsplash.com/photo-1559878541-926091e4c31b?w=400"
              alt="Your top post"
              className="w-full h-full object-cover"
            />
          </div>
          <div className="flex-1 flex flex-col justify-between">
            <div>
              <p className={`text-sm mb-2 ${theme === 'dark' ? 'text-zinc-300' : 'text-zinc-700'}`}>
                "Elevate your style with timeless elegance ✨"
              </p>
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div className="flex items-center gap-2">
                <Heart className="w-4 h-4 text-red-400" />
                <span className={`text-sm ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>1.2K</span>
              </div>
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-emerald-400" />
                <span className={`text-sm ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>342</span>
              </div>
              <div className="flex items-center gap-2">
                <Zap className="w-4 h-4 text-yellow-400" />
                <span className={`text-sm ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>89%</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Product Highlight */}
      <div className={`relative h-64 rounded-2xl overflow-hidden bg-gradient-to-br ${
        theme === 'dark'
          ? 'from-zinc-900 to-zinc-950 border border-emerald-900/20'
          : 'from-zinc-100 to-zinc-200 border border-emerald-200/40'
      }`}>
        <ImageWithFallback
          src="https://images.unsplash.com/photo-1680503504076-e5c61901c36d?w=1080"
          alt="Featured product"
          className="absolute inset-0 w-full h-full object-cover opacity-40"
        />
        <div className={`absolute inset-0 bg-gradient-to-t ${
          theme === 'dark'
            ? 'from-black via-black/60 to-transparent'
            : 'from-white via-white/60 to-transparent'
        }`} />
        <div className="relative h-full flex flex-col justify-end p-6">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 border border-emerald-400/30 w-fit mb-3">
            <Zap className="w-4 h-4 text-emerald-400" />
            <span className="text-xs text-emerald-400">Featured Product</span>
          </div>
          <h3 className={`text-xl mb-2 ${theme === 'dark' ? 'text-white' : 'text-zinc-900'}`}>Luxury Timepiece Collection</h3>
          <p className={`text-sm mb-4 ${theme === 'dark' ? 'text-zinc-300' : 'text-zinc-700'}`}>
            Discover our exclusive selection of premium watches
          </p>
          <button
            onClick={() => onProductClick?.('featured-1')}
            className="px-6 py-3 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white transition-all duration-300 w-fit"
          >
            Explore Collection
          </button>
        </div>
      </div>
    </div>
  );
};