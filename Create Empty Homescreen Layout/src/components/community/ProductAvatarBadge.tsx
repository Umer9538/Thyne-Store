import React from 'react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface ProductAvatarBadgeProps {
  productImage: string;
  productName: string;
  onClick?: () => void;
}

export const ProductAvatarBadge: React.FC<ProductAvatarBadgeProps> = ({
  productImage,
  productName,
  onClick,
}) => {
  return (
    <button
      onClick={onClick}
      className="group relative w-9 h-9 rounded-full border-2 border-emerald-400/80 bg-zinc-900/90 backdrop-blur-xl overflow-hidden transition-all duration-300 hover:scale-110 hover:border-emerald-300 hover:shadow-lg hover:shadow-emerald-500/50"
    >
      <ImageWithFallback
        src={productImage}
        alt={productName}
        className="w-full h-full object-cover"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-emerald-950/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
    </button>
  );
};