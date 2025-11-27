import React from 'react';
import { Heart, Share2, Bookmark, Sparkles } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { ProductAvatarBadge } from './ProductAvatarBadge';

export interface Product {
  id: string;
  name: string;
  image: string;
  price?: number;
}

export interface FeedPostData {
  id: string;
  username: string;
  userAvatar: string;
  timeAgo: string;
  mediaUrl: string;
  likes: number;
  comments: number;
  caption?: string;
  products: Product[];
  isLiked?: boolean;
  isSaved?: boolean;
  // AI-generated post properties
  isAiGenerated?: boolean;
  prompt?: string;
}

interface FeedPostProps {
  post: FeedPostData;
  onMediaClick: () => void;
  onProductClick: (productId: string) => void;
  onRemix?: (prompt: string) => void;
  onLike?: () => void;
  onSave?: () => void;
  theme?: 'dark' | 'light';
}

export const FeedPost: React.FC<FeedPostProps> = ({
  post,
  onMediaClick,
  onProductClick,
  onRemix,
  onLike,
  onSave,
  theme = 'dark',
}) => {
  return (
    <div className="bg-gradient-to-br from-rose-950/30 via-pink-950/30 to-rose-950/30 backdrop-blur-xl border border-rose-500/20 overflow-hidden shadow-lg shadow-rose-900/10 rounded-2xl">
      {/* Post Header */}
      <div className="flex items-center justify-between px-3 py-2.5">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-rose-500 to-pink-600 p-0.5">
            <ImageWithFallback
              src={post.userAvatar}
              alt={post.username}
              className="w-full h-full rounded-full object-cover"
            />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <p className="text-sm text-zinc-100">{post.username}</p>
              {post.isAiGenerated && (
                <div className="flex items-center gap-1 px-1.5 py-0.5 rounded-full bg-gradient-to-r from-rose-500/20 to-pink-500/20 border border-rose-400/30">
                  <Sparkles className="w-3 h-3 text-rose-400" />
                  <span className="text-xs text-rose-400">AI</span>
                </div>
              )}
            </div>
            <p className="text-xs text-zinc-500">{post.timeAgo}</p>
          </div>
        </div>
      </div>

      {/* Post Media with Product Badges */}
      <div className="relative aspect-[4/5] overflow-hidden">
        <button onClick={onMediaClick} className="w-full h-full">
          <ImageWithFallback
            src={post.mediaUrl}
            alt="Post media"
            className="w-full h-full object-cover"
          />
        </button>
        
        {/* Product Avatar Badges */}
        {post.products.length > 0 && (
          <div className="absolute bottom-3 right-3 flex gap-1.5">
            {post.products.map((product) => (
              <ProductAvatarBadge
                key={product.id}
                productImage={product.image}
                productName={product.name}
                onClick={() => onProductClick(product.id)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Post Actions */}
      <div className="px-3 py-2.5 space-y-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              onClick={onLike}
              className="group flex items-center gap-1.5 transition-transform duration-200 active:scale-90"
            >
              <Heart
                className={`w-5 h-5 transition-colors duration-200 ${
                  post.isLiked
                    ? 'fill-rose-500 text-rose-500'
                    : theme === 'dark'
                    ? 'text-zinc-400 group-hover:text-zinc-200'
                    : 'text-zinc-600 group-hover:text-zinc-800'
                }`}
              />
              <span className={`text-sm ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{post.likes}</span>
            </button>
            <button className="group transition-transform duration-200 active:scale-90">
              <Share2 className={`w-5 h-5 transition-colors duration-200 ${
                theme === 'dark'
                  ? 'text-zinc-400 group-hover:text-zinc-200'
                  : 'text-zinc-600 group-hover:text-zinc-800'
              }`} />
            </button>
          </div>
          <button onClick={onSave} className="transition-transform duration-200 active:scale-90">
            <Bookmark
              className={`w-5 h-5 transition-colors duration-200 ${
                post.isSaved
                  ? 'fill-rose-400 text-rose-400'
                  : theme === 'dark'
                  ? 'text-zinc-400 hover:text-zinc-200'
                  : 'text-zinc-600 hover:text-zinc-800'
              }`}
            />
          </button>
        </div>

        {/* Caption */}
        {post.caption && (
          <p className="text-sm text-zinc-300">
            <span className="text-zinc-100 mr-1.5">{post.username}</span>
            {post.caption}
          </p>
        )}

        {/* AI Prompt & Remix */}
        {post.isAiGenerated && post.prompt && (
          <div className="mt-2 p-2.5 bg-gradient-to-br from-rose-950/40 to-pink-950/40 border border-rose-800/30 rounded-xl">
            <p className="text-xs text-rose-400/70 mb-1">Prompt</p>
            <p className="text-sm text-zinc-300 mb-2">"{post.prompt}"</p>
            <button
              onClick={() => onRemix?.(post.prompt!)}
              className="w-full py-1.5 px-3 rounded-lg bg-gradient-to-r from-rose-600 to-pink-600 hover:from-rose-500 hover:to-pink-500 text-white text-sm transition-all duration-300 flex items-center justify-center gap-2"
            >
              <Sparkles className="w-3.5 h-3.5" />
              Remix this creation
            </button>
          </div>
        )}
      </div>
    </div>
  );
};