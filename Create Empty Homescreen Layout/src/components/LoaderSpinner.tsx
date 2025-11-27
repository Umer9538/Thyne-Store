import { motion } from 'motion/react';

interface LoaderSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  theme?: 'dark' | 'light';
  text?: string;
}

export function LoaderSpinner({ size = 'md', theme = 'dark', text }: LoaderSpinnerProps) {
  const sizeClasses = {
    sm: 'w-5 h-5',
    md: 'w-8 h-8',
    lg: 'w-12 h-12',
  };

  return (
    <div className="flex flex-col items-center justify-center gap-3">
      <motion.div
        className={`${sizeClasses[size]} rounded-full border-2`}
        style={{
          borderColor: theme === 'dark' ? 'rgba(9, 64, 16, 0.2)' : 'rgba(9, 64, 16, 0.3)',
          borderTopColor: '#094010'
        }}
        animate={{ rotate: 360 }}
        transition={{
          duration: 1,
          repeat: Infinity,
          ease: 'linear',
        }}
      />
      {text && (
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className={`text-body-sm ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}
        >
          {text}
        </motion.p>
      )}
    </div>
  );
}
