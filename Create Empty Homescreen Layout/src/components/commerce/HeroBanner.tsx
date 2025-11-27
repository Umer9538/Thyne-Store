import { motion, AnimatePresence } from 'motion/react';
import { ArrowRight, ChevronLeft, ChevronRight } from 'lucide-react';
import { useState, useEffect } from 'react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

// Import hero banner images
import heroBanner1 from 'figma:asset/f0546384a5629c9a9976cee79aa60e239f03b24b.png';
import heroBanner2 from 'figma:asset/121178e79d69317cf47500ee9e93b768c91da73c.png';

interface HeroBannerProps {
  title?: string;
  subtitle?: string;
  cta?: string;
  theme?: 'dark' | 'light';
}

interface BannerSlide {
  image: string;
  title: string;
  subtitle: string;
  cta: string;
}

const bannerSlides: BannerSlide[] = [
  {
    image: heroBanner1,
    title: 'Begin Your Bridal Journey',
    subtitle: 'Exquisite bridal jewelry with Khazana • Across India & Middle East',
    cta: 'Explore Bridal',
  },
  {
    image: heroBanner2,
    title: 'Tiffany & Co.',
    subtitle: 'Iconic luxury jewelry & timeless elegance',
    cta: 'Explore Collection',
  },
  {
    image: 'https://images.unsplash.com/photo-1602177719868-98d27643bf99?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjBqZXdlbHJ5JTIwZGVsaXZlcnklMjBzaGlwcGluZ3xlbnwxfHx8fDE3NjMxMzE4Mjd8MA&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Free Shipping',
    subtitle: 'For orders above ₹120 • Limited time offer',
    cta: 'Shop Now',
  },
];

export function HeroBanner({ theme = 'light' }: HeroBannerProps) {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [direction, setDirection] = useState(0);

  // Auto-advance slides
  useEffect(() => {
    const timer = setInterval(() => {
      setDirection(1);
      setCurrentSlide((prev) => (prev + 1) % bannerSlides.length);
    }, 5000); // Change slide every 5 seconds

    return () => clearInterval(timer);
  }, []);

  const goToSlide = (index: number) => {
    setDirection(index > currentSlide ? 1 : -1);
    setCurrentSlide(index);
  };

  const nextSlide = () => {
    setDirection(1);
    setCurrentSlide((prev) => (prev + 1) % bannerSlides.length);
  };

  const prevSlide = () => {
    setDirection(-1);
    setCurrentSlide((prev) => (prev - 1 + bannerSlides.length) % bannerSlides.length);
  };

  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? '100%' : '-100%',
      opacity: 0,
    }),
    center: {
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      x: direction > 0 ? '-100%' : '100%',
      opacity: 0,
    }),
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.32, 0.72, 0, 1] }}
      className="relative h-[400px] overflow-hidden bg-black"
    >
      {/* Magazine cover carousel */}
      <div className="relative w-full h-full">
        <AnimatePresence initial={false} custom={direction}>
          <motion.div
            key={currentSlide}
            custom={direction}
            variants={slideVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{
              x: { type: 'spring', stiffness: 300, damping: 30 },
              opacity: { duration: 0.3 },
            }}
            className="absolute inset-0 w-full h-full"
            style={{ zIndex: 1 }}
          >
            {/* Background image */}
            <div className="absolute inset-0 w-full h-full">
              <ImageWithFallback
                src={bannerSlides[currentSlide].image}
                alt={bannerSlides[currentSlide].title}
                className="w-full h-full object-cover object-center"
              />
              {/* Dark overlay for better text readability */}
              <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/50 to-black/30" />
            </div>

            {/* Content overlay */}
            <div className="absolute inset-0 flex flex-col justify-end p-8">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2, duration: 0.6 }}
                className="space-y-4"
              >
                <div className="space-y-2">
                  <h2 className={`text-3xl tracking-tight leading-tight ${
                    theme === 'dark' ? 'text-white' : 'text-white'
                  }`}>
                    {bannerSlides[currentSlide].title}
                  </h2>
                  <p className={`text-sm max-w-md ${
                    theme === 'dark' ? 'text-white/80' : 'text-white/90'
                  }`}>
                    {bannerSlides[currentSlide].subtitle}
                  </p>
                </div>

                <motion.button
                  whileHover={{ x: 4 }}
                  whileTap={{ scale: 0.98 }}
                  className={`inline-flex items-center gap-2 px-5 py-2.5 text-xs tracking-wider uppercase transition-all duration-300 backdrop-blur-xl ${
                    theme === 'dark'
                      ? 'bg-emerald-500/90 hover:bg-emerald-500 text-white'
                      : 'bg-[#094010] hover:bg-[#0a5015] text-white'
                  }`}
                >
                  {bannerSlides[currentSlide].cta}
                  <ArrowRight className="w-3.5 h-3.5" />
                </motion.button>
              </motion.div>
            </div>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Navigation arrows */}
      <button
        onClick={prevSlide}
        className={`absolute left-4 top-1/2 -translate-y-1/2 z-20 w-10 h-10 flex items-center justify-center bg-white/10 hover:bg-white/20 backdrop-blur-xl transition-all duration-300 ${
          theme === 'dark' ? 'text-white' : 'text-white'
        }`}
        aria-label="Previous slide"
      >
        <ChevronLeft className="w-5 h-5" />
      </button>
      <button
        onClick={nextSlide}
        className={`absolute right-4 top-1/2 -translate-y-1/2 z-20 w-10 h-10 flex items-center justify-center bg-white/10 hover:bg-white/20 backdrop-blur-xl transition-all duration-300 ${
          theme === 'dark' ? 'text-white' : 'text-white'
        }`}
        aria-label="Next slide"
      >
        <ChevronRight className="w-5 h-5" />
      </button>

      {/* Slide indicators */}
      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-20 flex items-center gap-2">
        {bannerSlides.map((_, index) => (
          <button
            key={index}
            onClick={() => goToSlide(index)}
            className={`h-1.5 transition-all duration-300 ${
              index === currentSlide
                ? 'w-8 bg-emerald-400'
                : 'w-1.5 bg-white/40 hover:bg-white/60'
            }`}
            aria-label={`Go to slide ${index + 1}`}
          />
        ))}
      </div>

      {/* Slide number indicator */}
      <div className={`absolute top-4 right-4 z-20 px-3 py-1.5 bg-black/40 backdrop-blur-xl text-xs ${
        theme === 'dark' ? 'text-white/90' : 'text-white/90'
      }`}>
        {currentSlide + 1} / {bannerSlides.length}
      </div>
    </motion.div>
  );
}