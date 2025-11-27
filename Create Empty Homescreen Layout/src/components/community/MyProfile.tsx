import React, { useState } from 'react';
import { Camera, Upload, Plus, Sparkles, Heart, MessageCircle, Bookmark } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '../ui/dropdown-menu';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';

interface MediaItem {
  id: string;
  imageUrl: string;
  likes: number;
  comments: number;
  isAiGenerated?: boolean;
}

interface MyProfileProps {
  onMediaClick?: (mediaId: string) => void;
  onUploadClick?: () => void;
  onCameraClick?: () => void;
  theme?: 'dark' | 'light';
}

const MOCK_UPLOADS: MediaItem[] = [
  {
    id: '1',
    imageUrl: 'https://images.unsplash.com/photo-1559878541-926091e4c31b?w=600',
    likes: 1243,
    comments: 87,
  },
  {
    id: '2',
    imageUrl: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=600',
    likes: 2134,
    comments: 142,
  },
  {
    id: '3',
    imageUrl: 'https://images.unsplash.com/photo-1668718003259-650efe62fbca?w=600',
    likes: 1567,
    comments: 93,
  },
  {
    id: '4',
    imageUrl: 'https://images.unsplash.com/photo-1680503504076-e5c61901c36d?w=600',
    likes: 892,
    comments: 54,
  },
  {
    id: '5',
    imageUrl: 'https://images.unsplash.com/photo-1519217651866-847339e674d4?w=600',
    likes: 743,
    comments: 38,
  },
  {
    id: '6',
    imageUrl: 'https://images.unsplash.com/photo-1559878541-926091e4c31b?w=600',
    likes: 654,
    comments: 29,
  },
];

const MOCK_CREATIONS: MediaItem[] = [
  {
    id: 'ai1',
    imageUrl: 'https://images.unsplash.com/photo-1680503504076-e5c61901c36d?w=600',
    likes: 892,
    comments: 54,
    isAiGenerated: true,
  },
  {
    id: 'ai2',
    imageUrl: 'https://images.unsplash.com/photo-1519217651866-847339e674d4?w=600',
    likes: 743,
    comments: 38,
    isAiGenerated: true,
  },
  {
    id: 'ai3',
    imageUrl: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=600',
    likes: 1089,
    comments: 67,
    isAiGenerated: true,
  },
  {
    id: 'ai4',
    imageUrl: 'https://images.unsplash.com/photo-1668718003259-650efe62fbca?w=600',
    likes: 923,
    comments: 45,
    isAiGenerated: true,
  },
];

const MOCK_SAVED: MediaItem[] = [
  {
    id: 'saved1',
    imageUrl: 'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?w=600',
    likes: 2134,
    comments: 142,
  },
  {
    id: 'saved2',
    imageUrl: 'https://images.unsplash.com/photo-1519217651866-847339e674d4?w=600',
    likes: 743,
    comments: 38,
    isAiGenerated: true,
  },
  {
    id: 'saved3',
    imageUrl: 'https://images.unsplash.com/photo-1680503504076-e5c61901c36d?w=600',
    likes: 1342,
    comments: 89,
  },
  {
    id: 'saved4',
    imageUrl: 'https://images.unsplash.com/photo-1668718003259-650efe62fbca?w=600',
    likes: 1876,
    comments: 124,
  },
  {
    id: 'saved5',
    imageUrl: 'https://images.unsplash.com/photo-1559878541-926091e4c31b?w=600',
    likes: 1543,
    comments: 96,
  },
];

export const MyProfile: React.FC<MyProfileProps> = ({
  onMediaClick,
  onUploadClick,
  onCameraClick,
  theme = 'dark',
}) => {
  const [activeTab, setActiveTab] = useState('uploads');

  const totalPosts = MOCK_UPLOADS.length + MOCK_CREATIONS.length;
  const totalLikes = [...MOCK_UPLOADS, ...MOCK_CREATIONS].reduce(
    (sum, item) => sum + item.likes,
    0
  );

  return (
    <div className="space-y-6 pb-6">
      {/* Profile Header */}
      <div className={`backdrop-blur-xl p-6 ${
        theme === 'dark'
          ? 'bg-zinc-900/40 border border-red-900/20'
          : 'bg-white/60 border border-red-200/40'
      }`}>
        <div className="flex items-start gap-6 mb-6">
          {/* Profile Picture */}
          <div className="relative flex-shrink-0">
            <div className="w-24 h-24 rounded-full bg-gradient-to-br from-red-500 to-rose-600 p-1">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1614283233556-f35b0c801ef1?w=200"
                alt="Profile"
                className="w-full h-full rounded-full object-cover"
              />
            </div>
            <button className={`absolute bottom-0 right-0 w-8 h-8 rounded-full bg-gradient-to-br from-red-500 to-rose-600 border-2 flex items-center justify-center hover:scale-110 transition-transform duration-200 ${
              theme === 'dark' ? 'border-zinc-900' : 'border-white'
            }`}>
              <Camera className="w-4 h-4 text-white" />
            </button>
          </div>

          {/* Profile Info */}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-4 mb-4">
              <div className="min-w-0">
                <h2 className={`text-xl mb-1 ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>Alex Morgan</h2>
                <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>@alexmorgan</p>
              </div>

              {/* Add Post Button */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <button className="px-4 py-2 rounded-xl bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-500 hover:to-rose-500 text-white transition-all duration-300 flex items-center gap-2 flex-shrink-0">
                    <Plus className="w-4 h-4" />
                    Add Post
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent
                  align="end"
                  className={`backdrop-blur-xl ${
                    theme === 'dark'
                      ? 'bg-zinc-900/95 border-red-900/30 text-zinc-100'
                      : 'bg-white/95 border-red-200/40 text-zinc-900'
                  }`}
                >
                  <DropdownMenuItem
                    onClick={onUploadClick}
                    className="flex items-center gap-3 cursor-pointer focus:bg-red-900/20 focus:text-red-400"
                  >
                    <Upload className="w-4 h-4" />
                    Upload from device
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    onClick={onCameraClick}
                    className="flex items-center gap-3 cursor-pointer focus:bg-red-900/20 focus:text-red-400"
                  >
                    <Camera className="w-4 h-4" />
                    Take photo
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            {/* Stats */}
            <div className="flex gap-8">
              <div>
                <p className={`text-xl ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>{totalPosts}</p>
                <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>Posts</p>
              </div>
              <div>
                <p className={`text-xl ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>{totalLikes.toLocaleString()}</p>
                <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>Likes</p>
              </div>
              <div>
                <p className={`text-xl ${theme === 'dark' ? 'text-zinc-100' : 'text-zinc-900'}`}>98.2K</p>
                <p className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-600'}`}>Followers</p>
              </div>
            </div>
          </div>
        </div>

        {/* Bio */}
        <div className={`p-4 ${
          theme === 'dark'
            ? 'bg-zinc-900/60 border border-red-900/20'
            : 'bg-white/40 border border-red-200/30'
        }`}>
          <p className={`text-sm ${theme === 'dark' ? 'text-zinc-300' : 'text-zinc-700'}`}>
            Creative designer & AI enthusiast ✨ Sharing my journey through design, fashion, and technology
          </p>
        </div>
      </div>

      {/* Content Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className={`w-full backdrop-blur-xl p-1 ${
          theme === 'dark'
            ? 'bg-zinc-900/40 border border-red-900/20'
            : 'bg-white/60 border border-red-200/40'
        }`}>
          <TabsTrigger
            value="uploads"
            className={`flex-1 data-[state=active]:bg-gradient-to-r data-[state=active]:from-red-600 data-[state=active]:to-rose-600 data-[state=active]:text-white data-[state=active]:border-transparent ${
              theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'
            }`}
          >
            <Upload className="w-4 h-4 mr-2" />
            Uploads
          </TabsTrigger>
          <TabsTrigger
            value="creations"
            className={`flex-1 data-[state=active]:bg-gradient-to-r data-[state=active]:from-red-600 data-[state=active]:to-rose-600 data-[state=active]:text-white data-[state=active]:border-transparent ${
              theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'
            }`}
          >
            <Sparkles className="w-4 h-4 mr-2" />
            Creations
          </TabsTrigger>
          <TabsTrigger
            value="saved"
            className={`flex-1 data-[state=active]:bg-gradient-to-r data-[state=active]:from-red-600 data-[state=active]:to-rose-600 data-[state=active]:text-white data-[state=active]:border-transparent ${
              theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'
            }`}
          >
            <Bookmark className="w-4 h-4 mr-2" />
            Saved
          </TabsTrigger>
        </TabsList>

        {/* My Uploads */}
        <TabsContent value="uploads" className="mt-6">
          {MOCK_UPLOADS.length === 0 ? (
            <div className={`backdrop-blur-xl p-12 text-center ${
              theme === 'dark'
                ? 'bg-zinc-900/40 border border-emerald-900/20'
                : 'bg-white/60 border border-emerald-200/40'
            }`}>
              <Upload className={`w-16 h-16 mx-auto mb-4 ${theme === 'dark' ? 'text-zinc-700' : 'text-zinc-400'}`} />
              <p className={`mb-2 ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>No uploads yet</p>
              <p className={`text-sm ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-500'}`}>
                Start sharing your content with the community
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              {MOCK_UPLOADS.map((item) => (
                <button
                  key={item.id}
                  onClick={() => onMediaClick?.(item.id)}
                  className={`group relative aspect-square overflow-hidden ${
                    theme === 'dark' ? 'bg-zinc-950' : 'bg-zinc-200'
                  }`}
                >
                  <ImageWithFallback
                    src={item.imageUrl}
                    alt="Upload"
                    className="w-full h-full object-cover"
                  />
                  
                  {/* Hover Overlay */}
                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center gap-4">
                    <div className="flex items-center gap-1 text-white">
                      <Heart className="w-5 h-5 fill-white" />
                      <span className="text-sm">{item.likes}</span>
                    </div>
                    <div className="flex items-center gap-1 text-white">
                      <MessageCircle className="w-5 h-5 fill-white" />
                      <span className="text-sm">{item.comments}</span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </TabsContent>

        {/* My Creations */}
        <TabsContent value="creations" className="mt-6">
          {MOCK_CREATIONS.length === 0 ? (
            <div className={`backdrop-blur-xl p-12 text-center ${
              theme === 'dark'
                ? 'bg-zinc-900/40 border border-emerald-900/20'
                : 'bg-white/60 border border-emerald-200/40'
            }`}>
              <Sparkles className={`w-16 h-16 mx-auto mb-4 ${theme === 'dark' ? 'text-zinc-700' : 'text-zinc-400'}`} />
              <p className={`mb-2 ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>No AI creations yet</p>
              <p className={`text-sm ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-500'}`}>
                Create stunning visuals with AI in the Create section
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              {MOCK_CREATIONS.map((item) => (
                <button
                  key={item.id}
                  onClick={() => onMediaClick?.(item.id)}
                  className={`group relative aspect-square overflow-hidden ${
                    theme === 'dark' ? 'bg-zinc-950' : 'bg-zinc-200'
                  }`}
                >
                  <ImageWithFallback
                    src={item.imageUrl}
                    alt="AI Creation"
                    className="w-full h-full object-cover"
                  />

                  {/* AI Badge */}
                  <div className="absolute top-2 right-2 flex items-center gap-1 px-2 py-1 rounded-lg bg-gradient-to-r from-emerald-500/80 to-teal-500/80 backdrop-blur-xl">
                    <Sparkles className="w-3 h-3 text-white" />
                    <span className="text-xs text-white">AI</span>
                  </div>
                  
                  {/* Hover Overlay */}
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end justify-center pb-4 gap-4">
                    <div className="flex items-center gap-1 text-white">
                      <Heart className="w-5 h-5 fill-white" />
                      <span className="text-sm">{item.likes}</span>
                    </div>
                    <div className="flex items-center gap-1 text-white">
                      <MessageCircle className="w-5 h-5 fill-white" />
                      <span className="text-sm">{item.comments}</span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Saved Media */}
        <TabsContent value="saved" className="mt-6">
          {MOCK_SAVED.length === 0 ? (
            <div className={`backdrop-blur-xl p-12 text-center ${
              theme === 'dark'
                ? 'bg-zinc-900/40 border border-emerald-900/20'
                : 'bg-white/60 border border-emerald-200/40'
            }`}>
              <Bookmark className={`w-16 h-16 mx-auto mb-4 ${theme === 'dark' ? 'text-zinc-700' : 'text-zinc-400'}`} />
              <p className={`mb-2 ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>No saved posts yet</p>
              <p className={`text-sm ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-500'}`}>
                Save posts from the community to view them later
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              {MOCK_SAVED.map((item) => (
                <button
                  key={item.id}
                  onClick={() => onMediaClick?.(item.id)}
                  className={`group relative aspect-square overflow-hidden ${
                    theme === 'dark' ? 'bg-zinc-950' : 'bg-zinc-200'
                  }`}
                >
                  <ImageWithFallback
                    src={item.imageUrl}
                    alt="Saved media"
                    className="w-full h-full object-cover"
                  />

                  {/* AI Badge if applicable */}
                  {item.isAiGenerated && (
                    <div className="absolute top-2 right-2 flex items-center gap-1 px-2 py-1 rounded-lg bg-gradient-to-r from-emerald-500/80 to-teal-500/80 backdrop-blur-xl">
                      <Sparkles className="w-3 h-3 text-white" />
                      <span className="text-xs text-white">AI</span>
                    </div>
                  )}
                  
                  {/* Hover Overlay */}
                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center gap-4">
                    <div className="flex items-center gap-1 text-white">
                      <Heart className="w-5 h-5 fill-white" />
                      <span className="text-sm">{item.likes}</span>
                    </div>
                    <div className="flex items-center gap-1 text-white">
                      <MessageCircle className="w-5 h-5 fill-white" />
                      <span className="text-sm">{item.comments}</span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
};
