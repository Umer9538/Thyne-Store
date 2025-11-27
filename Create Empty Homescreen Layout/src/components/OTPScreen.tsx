import { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { X, MessageCircle } from 'lucide-react';
import { Button } from './ui/button';
import { InputOTP, InputOTPGroup, InputOTPSlot } from './ui/input-otp';
import { ThyneLogo } from './ThyneLogo';

interface OTPScreenProps {
  contact: string;
  onVerify: () => void;
  onBack: () => void;
}

export function OTPScreen({ contact, onVerify, onBack }: OTPScreenProps) {
  const [otp, setOtp] = useState('');
  const [timer, setTimer] = useState(60);
  const [canResend, setCanResend] = useState(false);
  const [error, setError] = useState('');
  const [isVerifying, setIsVerifying] = useState(false);
  const [whatsappSent, setWhatsappSent] = useState(false);

  useEffect(() => {
    if (timer > 0) {
      const interval = setInterval(() => {
        setTimer((prev) => {
          if (prev <= 1) {
            setCanResend(true);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [timer]);

  const handleVerify = () => {
    if (otp.length !== 6) {
      setError('Please enter the complete 6-digit OTP');
      return;
    }

    setIsVerifying(true);
    setError('');

    // Simulate verification
    setTimeout(() => {
      // For demo, accept 123456 as valid OTP
      if (otp === '123456') {
        onVerify();
      } else {
        setError('Invalid OTP. Please try again.');
        setIsVerifying(false);
        setOtp('');
      }
    }, 1000);
  };

  const handleResend = () => {
    setTimer(60);
    setCanResend(false);
    setError('');
    setOtp('');
    // Simulate resend
  };

  const handleWhatsApp = () => {
    setWhatsappSent(true);
    setTimeout(() => setWhatsappSent(false), 3000);
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
              <div className="relative">
                <ThyneLogo size="md" color="#094010" showText={false} showTagline={false} />
                <motion.div
                  className="absolute inset-0 rounded-full blur-xl"
                  style={{ background: 'rgba(9, 64, 16, 0.2)' }}
                  animate={{
                    scale: [1, 1.2, 1],
                    opacity: [0.3, 0.6, 0.3],
                  }}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                  }}
                />
              </div>
            </div>

            {/* Title */}
            <h1
              className="text-center mb-2 text-black"
              style={{ fontSize: '1.75rem', fontWeight: 500, letterSpacing: '-0.02em' }}
            >
              Verify Your Number
            </h1>
            <p className="text-center mb-12 text-neutral-600" style={{ fontSize: '0.9375rem' }}>
              We've sent a 6-digit code to{' '}
              <span style={{ color: '#094010' }}>{contact}</span>
            </p>

            {/* OTP Input */}
            <div className="mb-6">
              <div className="flex justify-center mb-2">
                <InputOTP
                  maxLength={6}
                  value={otp}
                  onChange={(value) => {
                    setOtp(value);
                    setError('');
                    if (value.length === 6) {
                      // Auto-verify when all digits are entered
                      setTimeout(() => {
                        if (value.length === 6) {
                          handleVerify();
                        }
                      }, 300);
                    }
                  }}
                >
                  <InputOTPGroup className="gap-3">
                    {[0, 1, 2, 3, 4, 5].map((index) => (
                      <InputOTPSlot
                        key={index}
                        index={index}
                        className="w-12 h-14 rounded-xl border text-center text-xl transition-all text-black"
                        style={{
                          background: otp[index] ? 'rgba(9, 64, 16, 0.1)' : 'rgba(0, 0, 0, 0.05)',
                          borderColor: error 
                            ? 'rgba(239, 68, 68, 0.5)'
                            : otp[index]
                              ? 'rgba(9, 64, 16, 0.5)'
                              : 'rgba(0, 0, 0, 0.1)'
                        }}
                      />
                    ))}
                  </InputOTPGroup>
                </InputOTP>
              </div>
              {error && (
                <motion.p
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-red-500 text-center mt-4"
                  style={{ fontSize: '0.8125rem' }}
                >
                  {error}
                </motion.p>
              )}
              {isVerifying && !error && (
                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-center mt-4"
                  style={{ fontSize: '0.8125rem', color: '#094010' }}
                >
                  Verifying...
                </motion.p>
              )}
            </div>

            {/* Timer and resend */}
            <div className="flex items-center justify-center gap-2 mb-8">
              {timer > 0 ? (
                <div className="text-neutral-500" style={{ fontSize: '0.8125rem' }}>
                  Resend code in{' '}
                  <span style={{ fontWeight: 500, color: '#094010' }}>
                    {timer}s
                  </span>
                </div>
              ) : (
                <button
                  onClick={handleResend}
                  className="hover:underline"
                  style={{ fontSize: '0.8125rem', fontWeight: 500, color: '#094010' }}
                >
                  Didn't receive the code? Resend
                </button>
              )}
            </div>

            {/* Verify button */}
            <Button
              onClick={handleVerify}
              disabled={otp.length !== 6 || isVerifying}
              className="w-full h-14 text-white rounded-xl mb-4 transition-all disabled:opacity-50 disabled:cursor-not-allowed hover:opacity-90"
              style={{ 
                fontSize: '0.8125rem', 
                fontWeight: 500, 
                letterSpacing: '0.1em',
                background: 'linear-gradient(to right, #094010, #094010)',
                boxShadow: '0 4px 20px rgba(9, 64, 16, 0.3)'
              }}
            >
              {isVerifying ? 'VERIFYING...' : 'VERIFY OTP'}
            </Button>

            {/* WhatsApp option */}
            <Button
              variant="outline"
              onClick={handleWhatsApp}
              className="w-full h-14 rounded-xl mb-8 transition-all bg-black/5 border-black/10 hover:bg-black/10 text-black"
              style={{ 
                fontSize: '0.8125rem', 
                fontWeight: 500, 
                letterSpacing: '0.05em',
                borderColor: 'rgba(0, 0, 0, 0.1)'
              }}
              onMouseEnter={(e) => e.currentTarget.style.borderColor = 'rgba(9, 64, 16, 0.5)'}
              onMouseLeave={(e) => e.currentTarget.style.borderColor = 'rgba(0, 0, 0, 0.1)'}
            >
              <MessageCircle className="w-5 h-5 mr-2" />
              {whatsappSent ? 'SENT TO WHATSAPP' : 'GET OTP ON WHATSAPP'}
            </Button>

            {/* Help text */}
            <div className="rounded-xl p-4 bg-black/5 border border-black/10">
              <p className="text-center text-neutral-600" style={{ fontSize: '0.8125rem' }}>
                For demo purposes, use OTP:{' '}
                <span style={{ fontWeight: 500, color: '#094010' }}>
                  123456
                </span>
              </p>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
