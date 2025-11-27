import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { Trophy, Medal, Award, TrendingUp, Heart, MessageCircle, Star, Crown, Sparkles, Calendar } from 'lucide-react';

interface LeaderboardUser {
  id: string;
  username: string;
  displayName: string;
  avatar: string;
  score: number;
  badge?: string;
  rank: number;
}

interface EventWinner {
  id: string;
  eventName: string;
  eventDate: string;
  eventCategory: string;
  winner: {
    username: string;
    displayName: string;
    avatar: string;
  };
  runnerUp1?: {
    username: string;
    displayName: string;
    avatar: string;
  };
  runnerUp2?: {
    username: string;
    displayName: string;
    avatar: string;
  };
  winningImage: string;
  prize: string;
}

interface CreatorSpotlightProps {
  onProductClick?: (productId: string) => void;
  theme?: 'dark' | 'light';
}

const LEADERBOARD_SECTIONS = [
  {
    id: 'likes',
    title: 'Most Liked',
    icon: Heart,
    color: '#401010',
    users: [
      { id: '1', username: 'luxe.fashion', displayName: 'Luxe Fashion', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', score: 1245000, badge: 'Trendsetter', rank: 1 },
      { id: '2', username: 'style.icon', displayName: 'Style Icon', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200', score: 987000, badge: 'Influencer', rank: 2 },
      { id: '3', username: 'glam.guru', displayName: 'Glam Guru', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200', score: 876000, rank: 3 },
      { id: '4', username: 'haute.couture', displayName: 'Haute Couture', avatar: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200', score: 654000, rank: 4 },
      { id: '5', username: 'trendsetter', displayName: 'Trend Setter', avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200', score: 543000, rank: 5 },
    ]
  },
  {
    id: 'engagement',
    title: 'Top Engagement',
    icon: MessageCircle,
    color: '#401010',
    users: [
      { id: '1', username: 'minimal.vibes', displayName: 'Minimal Vibes', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200', score: 45800, badge: 'Community Star', rank: 1 },
      { id: '2', username: 'chic.styles', displayName: 'Chic Styles', avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200', score: 38900, rank: 2 },
      { id: '3', username: 'luxury.lane', displayName: 'Luxury Lane', avatar: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200', score: 32100, rank: 3 },
      { id: '4', username: 'glam.diary', displayName: 'Glam Diary', avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200', score: 28700, rank: 4 },
      { id: '5', username: 'style.insider', displayName: 'Style Insider', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200', score: 24500, rank: 5 },
    ]
  },
];

const EVENT_WINNERS: EventWinner[] = [
  {
    id: 'e1',
    eventName: 'Summer Style Challenge',
    eventDate: 'October 2024',
    eventCategory: 'Fashion',
    winner: {
      username: 'luxe.fashion',
      displayName: 'Luxe Fashion',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    },
    runnerUp1: {
      username: 'style.icon',
      displayName: 'Style Icon',
      avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    },
    runnerUp2: {
      username: 'glam.guru',
      displayName: 'Glam Guru',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    },
    winningImage: 'https://images.unsplash.com/photo-1719518411339-5158cea86caf?w=1080',
    prize: '₹50,000 + Feature',
  },
  {
    id: 'e2',
    eventName: 'Jewelry Photography Contest',
    eventDate: 'September 2024',
    eventCategory: 'Photography',
    winner: {
      username: 'minimal.vibes',
      displayName: 'Minimal Vibes',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    },
    runnerUp1: {
      username: 'luxury.lane',
      displayName: 'Luxury Lane',
      avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
    },
    runnerUp2: {
      username: 'chic.styles',
      displayName: 'Chic Styles',
      avatar: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
    },
    winningImage: 'https://images.unsplash.com/photo-1655255114527-d0a834d9a774?w=1080',
    prize: '₹30,000 + Feature',
  },
  {
    id: 'e3',
    eventName: 'Best Designer Look',
    eventDate: 'August 2024',
    eventCategory: 'Styling',
    winner: {
      username: 'haute.couture',
      displayName: 'Haute Couture',
      avatar: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
    },
    runnerUp1: {
      username: 'trendsetter',
      displayName: 'Trend Setter',
      avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200',
    },
    winnerUp2: {
      username: 'style.insider',
      displayName: 'Style Insider',
      avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    },
    winningImage: 'https://images.unsplash.com/photo-1563418754681-55ab8367b1c0?w=1080',
    prize: '₹40,000 + Feature',
  },
];

export function CreatorSpotlight({ onProductClick, theme = 'light' }: CreatorSpotlightProps) {
  const [selectedLeaderboard, setSelectedLeaderboard] = useState('likes');

  const formatCount = (count: number): string => {
    if (count >= 1000000) {
      return (count / 1000000).toFixed(1) + 'M';
    }
    if (count >= 1000) {
      return (count / 1000).toFixed(1) + 'K';
    }
    return count.toString();
  };

  const getRankIcon = (rank: number) => {
    switch (rank) {
      case 1:
        return <Trophy className="w-5 h-5 text-[#FFD700]" />;
      case 2:
        return <Medal className="w-5 h-5 text-[#C0C0C0]" />;
      case 3:
        return <Award className="w-5 h-5 text-[#CD7F32]" />;
      default:
        return null;
    }
  };

  const currentLeaderboard = LEADERBOARD_SECTIONS.find(lb => lb.id === selectedLeaderboard);

  return (
    <div className="bg-[#fffff0] min-h-screen pb-32">
      {/* Header */}
      <div className="px-4 pt-6 pb-4">
        <div className="flex items-center gap-2 mb-1">
          <Sparkles className="w-5 h-5 text-[#401010]" />
          <h2 className="text-black/90 tracking-wide">spotlight</h2>
        </div>
        <p className="text-xs text-black/40">leaderboards & event champions</p>
      </div>

      {/* Leaderboard Section */}
      <div className="mb-8">
        {/* Leaderboard Tabs */}
        <div className="px-4 mb-4">
          <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
            {LEADERBOARD_SECTIONS.map((lb) => {
              const Icon = lb.icon;
              return (
                <motion.button
                  key={lb.id}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => setSelectedLeaderboard(lb.id)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs tracking-wide uppercase whitespace-nowrap transition-all duration-300 ${
                    selectedLeaderboard === lb.id
                      ? 'bg-[#401010] text-white shadow-lg shadow-[#401010]/20'
                      : 'bg-black/5 text-black/60 border border-black/10'
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  {lb.title}
                </motion.button>
              );
            })}
          </div>
        </div>

        {/* Top 3 Podium */}
        {currentLeaderboard && (
          <div className="px-4 mb-6">
            <div className="flex items-end justify-center gap-3 mb-6">
              {/* 2nd Place */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="flex flex-col items-center"
              >
                <div className="relative mb-3">
                  <div className="w-16 h-16 rounded-full overflow-hidden ring-2 ring-[#C0C0C0]/50 p-0.5 bg-gradient-to-br from-[#C0C0C0]/20 to-[#C0C0C0]/40">
                    <ImageWithFallback
                      src={currentLeaderboard.users[1].avatar}
                      alt={currentLeaderboard.users[1].displayName}
                      className="w-full h-full rounded-full object-cover"
                    />
                  </div>
                  <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-[#fffff0] flex items-center justify-center shadow-lg">
                    <Medal className="w-5 h-5 text-[#C0C0C0]" />
                  </div>
                </div>
                <div className="bg-[#C0C0C0]/10 rounded-2xl p-3 w-24 text-center">
                  <p className="text-[10px] text-black/90 truncate mb-1">{currentLeaderboard.users[1].displayName}</p>
                  <p className="text-xs text-black">{formatCount(currentLeaderboard.users[1].score)}</p>
                </div>
              </motion.div>

              {/* 1st Place */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex flex-col items-center -mt-6"
              >
                <div className="relative mb-3">
                  <div className="w-20 h-20 rounded-full overflow-hidden ring-2 ring-[#FFD700] p-0.5 bg-gradient-to-br from-[#FFD700]/30 to-[#FFD700]/50">
                    <ImageWithFallback
                      src={currentLeaderboard.users[0].avatar}
                      alt={currentLeaderboard.users[0].displayName}
                      className="w-full h-full rounded-full object-cover"
                    />
                  </div>
                  <div className="absolute -top-3 -right-2 w-10 h-10 rounded-full bg-[#fffff0] flex items-center justify-center shadow-lg">
                    <Crown className="w-6 h-6 text-[#FFD700]" />
                  </div>
                </div>
                <div className="bg-[#FFD700]/10 rounded-2xl p-3 w-28 text-center">
                  <p className="text-[10px] text-black/90 truncate mb-1">{currentLeaderboard.users[0].displayName}</p>
                  <p className="text-xs text-black">{formatCount(currentLeaderboard.users[0].score)}</p>
                  {currentLeaderboard.users[0].badge && (
                    <p className="text-[9px] text-[#401010] mt-1">{currentLeaderboard.users[0].badge}</p>
                  )}
                </div>
              </motion.div>

              {/* 3rd Place */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="flex flex-col items-center"
              >
                <div className="relative mb-3">
                  <div className="w-16 h-16 rounded-full overflow-hidden ring-2 ring-[#CD7F32]/50 p-0.5 bg-gradient-to-br from-[#CD7F32]/20 to-[#CD7F32]/40">
                    <ImageWithFallback
                      src={currentLeaderboard.users[2].avatar}
                      alt={currentLeaderboard.users[2].displayName}
                      className="w-full h-full rounded-full object-cover"
                    />
                  </div>
                  <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-[#fffff0] flex items-center justify-center shadow-lg">
                    <Award className="w-5 h-5 text-[#CD7F32]" />
                  </div>
                </div>
                <div className="bg-[#CD7F32]/10 rounded-2xl p-3 w-24 text-center">
                  <p className="text-[10px] text-black/90 truncate mb-1">{currentLeaderboard.users[2].displayName}</p>
                  <p className="text-xs text-black">{formatCount(currentLeaderboard.users[2].score)}</p>
                </div>
              </motion.div>
            </div>

            {/* Rest of Leaderboard */}
            <div className="space-y-2">
              {currentLeaderboard.users.slice(3).map((user, index) => (
                <motion.div
                  key={user.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.3 + index * 0.05 }}
                  className="bg-[#fffff0] rounded-2xl p-3 border border-black/5 flex items-center gap-3"
                >
                  <div className="w-8 h-8 rounded-full bg-black/5 flex items-center justify-center flex-shrink-0">
                    <span className="text-xs text-black/60">#{user.rank}</span>
                  </div>
                  <div className="w-10 h-10 rounded-full overflow-hidden ring-1 ring-black/10 flex-shrink-0">
                    <ImageWithFallback
                      src={user.avatar}
                      alt={user.displayName}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs text-black/90 truncate">{user.displayName}</p>
                    <p className="text-[10px] text-black/40 truncate">@{user.username}</p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="text-xs text-black">{formatCount(user.score)}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Event Winners Section */}
      <div className="px-4">
        <div className="flex items-center gap-2 mb-4">
          <Trophy className="w-5 h-5 text-[#401010]" />
          <h3 className="text-black/90 tracking-wide">recent winners</h3>
        </div>

        <div className="space-y-6">
          {EVENT_WINNERS.map((event, index) => (
            <motion.div
              key={event.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-[#fffff0] rounded-3xl border border-black/5 overflow-hidden"
            >
              {/* Event Image */}
              <div className="relative h-48 overflow-hidden">
                <ImageWithFallback
                  src={event.winningImage}
                  alt={event.eventName}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                
                {/* Event Category Badge */}
                <div className="absolute top-3 right-3">
                  <div className="px-3 py-1 rounded-full bg-[#fffff0]/90 backdrop-blur-sm border border-black/10">
                    <span className="text-[10px] text-black/70 tracking-wide uppercase">
                      {event.eventCategory}
                    </span>
                  </div>
                </div>

                {/* Prize */}
                <div className="absolute bottom-3 left-3">
                  <div className="px-3 py-1 rounded-full bg-[#401010]/90 backdrop-blur-sm">
                    <span className="text-[10px] text-white tracking-wide">
                      {event.prize}
                    </span>
                  </div>
                </div>
              </div>

              {/* Event Details */}
              <div className="p-5">
                <div className="flex items-center gap-2 mb-3">
                  <Calendar className="w-3.5 h-3.5 text-black/40" />
                  <p className="text-[10px] text-black/40 uppercase tracking-wide">{event.eventDate}</p>
                </div>
                <h4 className="text-black/90 mb-4">{event.eventName}</h4>

                {/* Podium */}
                <div className="flex items-center justify-between gap-2">
                  {/* Runner Up 2 */}
                  {event.runnerUp2 && (
                    <div className="flex flex-col items-center flex-1">
                      <div className="w-10 h-10 rounded-full overflow-hidden ring-1 ring-[#CD7F32]/50 mb-2">
                        <ImageWithFallback
                          src={event.runnerUp2.avatar}
                          alt={event.runnerUp2.displayName}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <p className="text-[9px] text-black/60 text-center truncate w-full">3rd</p>
                      <p className="text-[10px] text-black/90 text-center truncate w-full">{event.runnerUp2.displayName}</p>
                    </div>
                  )}

                  {/* Winner */}
                  <div className="flex flex-col items-center flex-1">
                    <div className="relative mb-2">
                      <div className="w-14 h-14 rounded-full overflow-hidden ring-2 ring-[#FFD700] p-0.5 bg-gradient-to-br from-[#FFD700]/30 to-[#FFD700]/50">
                        <ImageWithFallback
                          src={event.winner.avatar}
                          alt={event.winner.displayName}
                          className="w-full h-full rounded-full object-cover"
                        />
                      </div>
                      <div className="absolute -top-1 -right-1 w-6 h-6 rounded-full bg-[#fffff0] flex items-center justify-center shadow-lg">
                        <Crown className="w-4 h-4 text-[#FFD700]" />
                      </div>
                    </div>
                    <p className="text-[9px] text-black/60 text-center truncate w-full">Winner</p>
                    <p className="text-[10px] text-black/90 text-center truncate w-full">{event.winner.displayName}</p>
                  </div>

                  {/* Runner Up 1 */}
                  {event.runnerUp1 && (
                    <div className="flex flex-col items-center flex-1">
                      <div className="w-10 h-10 rounded-full overflow-hidden ring-1 ring-[#C0C0C0]/50 mb-2">
                        <ImageWithFallback
                          src={event.runnerUp1.avatar}
                          alt={event.runnerUp1.displayName}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <p className="text-[9px] text-black/60 text-center truncate w-full">2nd</p>
                      <p className="text-[10px] text-black/90 text-center truncate w-full">{event.runnerUp1.displayName}</p>
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
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
    </div>
  );
}
