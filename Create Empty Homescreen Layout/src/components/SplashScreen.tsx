import { useEffect, useState } from 'react';
import { motion } from 'motion/react';
import { Sparkles, Users, Palette } from 'lucide-react';
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  type CarouselApi,
} from './ui/carousel';
import { ThyneLogo } from './ThyneLogo';

interface SplashScreenProps {
  onComplete: () => void;
}

export function SplashScreen({ onComplete }: SplashScreenProps) {
  const [api, setApi] = useState<CarouselApi>();
  const [currentSlide, setCurrentSlide] = useState(0);

  const features = [
    {
      icon: Sparkles,
      title: 'Commerce',
      description: 'Premium jewelry & accessories',
      color: '#094010',
      gradient: 'from-[#094010]/20 to-[#094010]/10',
      bgGradient: 'from-[#094010]/20 via-[#fffff0] to-[#fffff0]',
    },
    {
      icon: Users,
      title: 'Community',
      description: 'Connect with style enthusiasts',
      color: '#401010',
      gradient: 'from-[#401010]/20 to-[#401010]/10',
      bgGradient: 'from-[#401010]/20 via-[#fffff0] to-[#fffff0]',
    },
    {
      icon: Palette,
      title: 'Create',
      description: 'Design your unique pieces',
      color: '#0a1a40',
      gradient: 'from-[#0a1a40]/20 to-[#0a1a40]/10',
      bgGradient: 'from-[#0a1a40]/20 via-[#fffff0] to-[#fffff0]',
    },
  ];

  useEffect(() => {
    if (!api) return;

    // Track current slide
    api.on('select', () => {
      setCurrentSlide(api.selectedScrollSnap());
    });
  }, [api]);

  useEffect(() => {
    if (!api) return;

    const interval = setInterval(() => {
      if (currentSlide >= features.length - 1) {
        clearInterval(interval);
        setTimeout(onComplete, 1000);
      } else {
        api.scrollNext();
      }
    }, 2000);

    return () => clearInterval(interval);
  }, [api, currentSlide, onComplete, features.length]);

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center overflow-hidden transition-colors duration-500 bg-[#fffff0]">
      {/* Animated background gradient - changes with slides */}
      <motion.div
        key={currentSlide}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.8 }}
        className={`absolute inset-0 bg-gradient-to-br ${features[currentSlide].bgGradient}`}
      />
      
      {/* Animated particles */}
      <div className="absolute inset-0 overflow-hidden">
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 rounded-full"
            style={{ 
              backgroundColor: `${features[currentSlide].color}50`,
            }}
            initial={{
              x: Math.random() * (typeof window !== 'undefined' ? window.innerWidth : 1000),
              y: Math.random() * (typeof window !== 'undefined' ? window.innerHeight : 1000),
              scale: 0,
            }}
            animate={{
              y: [null, -100],
              scale: [0, 1, 0],
            }}
            transition={{
              duration: 3 + Math.random() * 2,
              repeat: Infinity,
              delay: Math.random() * 2,
            }}
          />
        ))}
      </div>

      {/* Logo - color not changed as per user request */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, ease: [0.34, 1.56, 0.64, 1] }}
        className="mb-16 relative z-10"
      >
        <ThyneLogo size="lg" color={features[currentSlide].color} showText={true} showTagline={true} />
        <motion.div
          className="absolute -inset-8 rounded-full blur-3xl"
          style={{
            background: `radial-gradient(circle, ${features[currentSlide].color}40, transparent 70%)`,
          }}
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.3, 0.6, 0.3],
          }}
          transition={{
            duration: 3,
            repeat: Infinity,
          }}
        />
      </motion.div>

      {/* Feature carousel */}
      <div className="w-full max-w-md px-6 z-10">
        <Carousel
          setApi={setApi}
          opts={{
            loop: false,
            align: 'center',
          }}
          className="w-full"
        >
          <CarouselContent>
            {features.map((feature) => {
              const Icon = feature.icon;
              
              return (
                <CarouselItem key={feature.title}>
                  <motion.div
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.5 }}
                    className={`relative rounded-3xl p-8 backdrop-blur-xl border bg-gradient-to-br ${feature.gradient} border-black/10`}
                  >
                    {/* Icon */}
                    <motion.div
                      className="w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-6"
                      style={{
                        background: `linear-gradient(135deg, ${feature.color}40, ${feature.color}20)`,
                      }}
                      animate={{
                        scale: [1, 1.05, 1],
                      }}
                      transition={{
                        duration: 2,
                        repeat: Infinity,
                        ease: 'easeInOut',
                      }}
                    >
                      <Icon
                        className="w-10 h-10"
                        style={{ color: feature.color }}
                      />
                    </motion.div>

                    {/* Title */}
                    <h3
                      className="text-center mb-3"
                      style={{
                        fontSize: '1.75rem',
                        fontWeight: 500,
                        color: '#0a0a0a',
                        letterSpacing: '-0.02em',
                      }}
                    >
                      {feature.title}
                    </h3>

                    {/* Description */}
                    <p
                      className="text-center"
                      style={{
                        fontSize: '0.9375rem',
                        color: '#737373',
                      }}
                    >
                      {feature.description}
                    </p>

                    {/* Decorative glow */}
                    <motion.div
                      className="absolute inset-0 rounded-3xl blur-2xl opacity-20"
                      style={{
                        background: `radial-gradient(circle at center, ${feature.color}, transparent 70%)`,
                      }}
                      animate={{
                        scale: [1, 1.1, 1],
                        opacity: [0.1, 0.3, 0.1],
                      }}
                      transition={{
                        duration: 3,
                        repeat: Infinity,
                      }}
                    />
                  </motion.div>
                </CarouselItem>
              );
            })}</CarouselContent>
        </Carousel>

        {/* Custom pagination dots */}
        <div className="flex justify-center gap-3 mt-8">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              className="w-2 h-2 rounded-full transition-all duration-300"
              style={{
                backgroundColor: index === currentSlide ? feature.color : 'rgba(0, 0, 0, 0.3)',
              }}
              animate={{
                scale: index === currentSlide ? 1.25 : 1,
              }}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
