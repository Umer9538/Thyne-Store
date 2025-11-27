import { useState } from 'react';
import { motion } from 'motion/react';
import { X, ChevronRight } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Checkbox } from './ui/checkbox';
import { ThyneLogo } from './ThyneLogo';

interface SignUpLoginScreenProps {
  onContinue: (contact: string) => void;
  onSkip: () => void;
  onBack: () => void;
}

export function SignUpLoginScreen({ onContinue, onSkip, onBack }: SignUpLoginScreenProps) {
  const [contact, setContact] = useState('');
  const [notifyMe, setNotifyMe] = useState(true);
  const [emailSubscription, setEmailSubscription] = useState(false);
  const [error, setError] = useState('');

  const handleContinue = () => {
    if (!contact.trim()) {
      setError('Please enter your phone number or email address');
      return;
    }

    // Check if it's a phone number (contains only digits) or email
    const isPhone = /^[0-9\s\-\+\(\)]+$/.test(contact);
    
    if (isPhone) {
      // Basic phone validation (10 digits)
      const phoneRegex = /^[0-9]{10}$/;
      if (!phoneRegex.test(contact.replace(/[\s\-\+\(\)]/g, ''))) {
        setError('Please enter a valid 10-digit phone number');
        return;
      }
    } else {
      // Basic email validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(contact)) {
        setError('Please enter a valid email address');
        return;
      }
    }

    setError('');
    onContinue(contact);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto transition-colors duration-500 bg-[#fffff0]">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#094010]/10 via-[#fffff0] to-[#fffff0]" />

      <div className="relative min-h-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6">
          <Button
            variant="ghost"
            size="icon"
            onClick={onBack}
            className="rounded-full w-10 h-10 hover:bg-black/5 text-black"
          >
            <X className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              onClick={onSkip}
              className="rounded-full px-6 hover:bg-black/5"
              style={{ 
                fontSize: '0.8125rem', 
                letterSpacing: '0.05em',
                color: '#094010'
              }}
            >
              SKIP
            </Button>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 flex flex-col items-center justify-center px-6 pb-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="w-full max-w-md"
          >
            {/* Logo */}
            <div className="flex justify-center mb-8">
              <ThyneLogo size="md" color="#094010" showText={false} showTagline={false} />
            </div>

            {/* Title */}
            <h1
              className="text-center mb-2 text-black"
              style={{ fontSize: '1.75rem', fontWeight: 500, letterSpacing: '-0.02em' }}
            >
              Welcome to Thyne
            </h1>
            <p className="text-center mb-12 text-neutral-600" style={{ fontSize: '0.9375rem' }}>
              Sign up or log in to continue
            </p>

            {/* Input */}
            <div className="mb-6">
              <Input
                type="text"
                placeholder="Phone or Email"
                value={contact}
                onChange={(e) => {
                  setContact(e.target.value);
                  setError('');
                }}
                className={`h-14 rounded-xl px-4 bg-black/5 border-black/10 text-black placeholder:text-neutral-400 ${
                  error ? 'border-red-500/50' : 'focus:border-[#094010]/50'
                }`}
                style={{ fontSize: '0.9375rem' }}
              />
              {error && (
                <motion.p
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-red-500 mt-2"
                  style={{ fontSize: '0.8125rem' }}
                >
                  {error}
                </motion.p>
              )}
            </div>

            {/* Checkboxes */}
            <div className="space-y-4 mb-8">
              <div className="flex items-start gap-3">
                <Checkbox
                  id="notify"
                  checked={notifyMe}
                  onCheckedChange={(checked) => setNotifyMe(checked as boolean)}
                  className="mt-0.5 border-black/20 data-[state=checked]:bg-[#094010] data-[state=checked]:border-[#094010]"
                />
                <label
                  htmlFor="notify"
                  className="leading-tight cursor-pointer text-neutral-700"
                  style={{ fontSize: '0.8125rem', fontWeight: 400, textTransform: 'none', letterSpacing: 'normal' }}
                >
                  Notify me of orders, updates and offers
                </label>
              </div>
              <div className="flex items-start gap-3">
                <Checkbox
                  id="email"
                  checked={emailSubscription}
                  onCheckedChange={(checked) => setEmailSubscription(checked as boolean)}
                  className="mt-0.5 border-black/20 data-[state=checked]:bg-[#094010] data-[state=checked]:border-[#094010]"
                />
                <label
                  htmlFor="email"
                  className="leading-tight cursor-pointer text-neutral-700"
                  style={{ fontSize: '0.8125rem', fontWeight: 400, textTransform: 'none', letterSpacing: 'normal' }}
                >
                  Subscribe to email newsletter
                </label>
              </div>
            </div>

            {/* Continue button */}
            <Button
              onClick={handleContinue}
              className="w-full h-14 text-white rounded-xl mb-6 transition-all hover:opacity-90"
              style={{ 
                fontSize: '0.8125rem', 
                fontWeight: 500, 
                letterSpacing: '0.1em',
                background: `linear-gradient(to right, #094010, #094010)`,
                boxShadow: '0 4px 20px rgba(9, 64, 16, 0.3)'
              }}
            >
              CONTINUE
              <ChevronRight className="w-5 h-5 ml-2" />
            </Button>

            {/* Divider */}
            <div className="flex items-center gap-4 mb-6">
              <div className="flex-1 h-px bg-black/10" />
              <span className="text-neutral-400" style={{ fontSize: '0.8125rem' }}>
                or continue with
              </span>
              <div className="flex-1 h-px bg-black/10" />
            </div>

            {/* Social login buttons */}
            <div className="grid grid-cols-3 gap-3 mb-8">
              <Button
                variant="outline"
                className="h-12 rounded-xl bg-black/5 border-black/10 hover:bg-black/10 hover:border-black/20 text-black"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  />
                </svg>
              </Button>
              <Button
                variant="outline"
                className="h-12 rounded-xl bg-black/5 border-black/10 hover:bg-black/10 hover:border-black/20"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path fill="#1877F2" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                </svg>
              </Button>
              <Button
                variant="outline"
                className="h-12 rounded-xl bg-black/5 border-black/10 hover:bg-black/10 hover:border-black/20"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="black">
                  <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
                </svg>
              </Button>
            </div>

            {/* Terms and privacy */}
            <p className="text-center leading-relaxed text-neutral-400" style={{ fontSize: '0.6875rem' }}>
              By continuing, you agree to our{' '}
              <button className="hover:underline" style={{ color: '#094010' }}>Terms & Conditions</button>,{' '}
              <button className="hover:underline" style={{ color: '#094010' }}>Privacy Policy</button>,{' '}
              <button className="hover:underline" style={{ color: '#094010' }}>Wallet Policy</button>, and{' '}
              <button className="hover:underline" style={{ color: '#094010' }}>Data Policy</button>
            </p>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
