import { motion } from 'motion/react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { ChevronRight } from 'lucide-react';

interface FeatureCard {
  id: string;
  title: string;
  subtitle: string;
  image: string;
  gradient: string;
  cta?: string;
}

interface FeatureCarouselProps {
  title: string;
  features: FeatureCard[];
  theme?: 'dark' | 'light';
  onCardClick?: (id: string) => void;
}

export function FeatureCarousel({ title, features, theme = 'light', onCardClick }: FeatureCarouselProps) {
  return (
    <div>
      {/* Horizontal Scrolling Full-Width Cards */}
      <div className="flex gap-3 overflow-x-auto no-scrollbar snap-x snap-mandatory -mx-4 px-4" style={{ scrollPaddingLeft: '1rem' }}>
        {features.map((feature, index) => (
          <motion.button
            key={feature.id}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.08, duration: 0.4 }}
            onClick={() => onCardClick?.(feature.id)}
            whileTap={{ scale: 0.98 }}
            className="relative flex-shrink-0 w-[calc(100vw-2rem)] h-[115px] overflow-hidden snap-center rounded-2xl"
          >
            {/* Background Image */}
            <div className="absolute inset-0">
              <ImageWithFallback
                src={feature.image}
                alt={feature.title}
                className="w-full h-full object-cover"
              />
              {/* Gradient Overlay */}
              <div 
                className={`absolute inset-0 bg-gradient-to-b ${feature.gradient}`}
              />
            </div>

            {/* Content */}
            <div className="relative h-full flex flex-col justify-end p-4">
              <div className="space-y-1">
                <h4 className="text-white text-[15px] leading-tight">
                  {feature.title}
                </h4>
                <p className="text-white/80 text-[11px] leading-tight max-w-[85%]">
                  {feature.subtitle}
                </p>
              </div>

              {/* CTA Badge */}
              {feature.cta && (
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.08 + 0.2 }}
                  className="mt-2 inline-flex items-center gap-1.5 px-3 py-1 bg-white/20 backdrop-blur-md border border-white/30"
                  style={{ borderRadius: '6px', width: 'fit-content' }}
                >
                  <span className="text-white text-[10px]">{feature.cta}</span>
                  <ChevronRight className="w-3 h-3 text-white" />
                </motion.div>
              )}
            </div>

            {/* Subtle Glow Effect on Hover */}
            <motion.div
              className="absolute inset-0 opacity-0 hover:opacity-100 transition-opacity duration-300 pointer-events-none"
              style={{
                background: `radial-gradient(circle at 50% 50%, rgba(16, 185, 129, 0.1) 0%, transparent 70%)`,
              }}
            />
          </motion.button>
        ))}
      </div>
    </div>
  );
}
