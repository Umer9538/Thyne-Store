import { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { MessageSquare, Image as ImageIcon, Send, Sparkles, Download, Share2, Copy } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { CreateShimmer } from './CreateShimmer';

interface CreateSectionProps {
  activeTab: 'chat' | 'creations' | 'history';
  theme?: 'dark' | 'light';
  initialPrompt?: string;
}

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  image?: string;
}

interface Creation {
  id: string;
  prompt: string;
  image: string;
  timestamp: Date;
}

interface ChatHistory {
  id: string;
  title: string;
  lastMessage: string;
  timestamp: Date;
  messageCount: number;
}

export function CreateSection({ activeTab, theme = 'light', initialPrompt = '' }: CreateSectionProps) {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      role: 'assistant',
      content: 'Hello! I\'m your AI jewelry design assistant. I can help you create custom jewelry designs, suggest combinations, or answer any questions about jewelry. What would you like to create today?',
      timestamp: new Date(),
    },
  ]);
  const [input, setInput] = useState(initialPrompt);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading when tab changes
    setIsLoading(true);
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1200);

    return () => clearTimeout(timer);
  }, [activeTab]);

  // Mock data
  const creations: Creation[] = [
    {
      id: 'c1',
      prompt: 'Rose gold heart necklace with diamonds',
      image: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600',
      timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
    },
    {
      id: 'c2',
      prompt: 'Vintage forest green ring with floral pattern',
      image: 'https://images.unsplash.com/photo-1620360094127-854a67f8c959?w=600',
      timestamp: new Date(Date.now() - 5 * 60 * 60 * 1000),
    },
    {
      id: 'c3',
      prompt: 'Modern minimalist silver bracelet',
      image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=600',
      timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000),
    },
    {
      id: 'c4',
      prompt: 'Pearl drop earrings with gold accents',
      image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600',
      timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c5',
      prompt: 'Sapphire and diamond engagement ring',
      image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600',
      timestamp: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c6',
      prompt: 'Art deco style ruby pendant necklace',
      image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600',
      timestamp: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c7',
      prompt: 'Delicate gold chain with turquoise stone',
      image: 'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0?w=600',
      timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c8',
      prompt: 'Statement cocktail ring with amethyst',
      image: 'https://images.unsplash.com/photo-1588444650700-95e1d5673477?w=600',
      timestamp: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c9',
      prompt: 'Layered gold necklace set with pendants',
      image: 'https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?w=600',
      timestamp: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c10',
      prompt: 'Elegant tennis bracelet with cubic zirconia',
      image: 'https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=600',
      timestamp: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c11',
      prompt: 'Bohemian style feather earrings',
      image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600',
      timestamp: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c12',
      prompt: 'Infinity symbol bracelet with rose gold',
      image: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=600',
      timestamp: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c13',
      prompt: 'Classic pearl necklace with gold clasp',
      image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600',
      timestamp: new Date(Date.now() - 11 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c14',
      prompt: 'Geometric sterling silver earrings',
      image: 'https://images.unsplash.com/photo-1610694955814-1e3c6f7821e4?w=600',
      timestamp: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c15',
      prompt: 'Opal ring with vintage gold setting',
      image: 'https://images.unsplash.com/photo-1620360094127-854a67f8c959?w=600',
      timestamp: new Date(Date.now() - 13 * 24 * 60 * 60 * 1000),
    },
    {
      id: 'c16',
      prompt: 'Charm bracelet with personalized pendants',
      image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343a?w=600',
      timestamp: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
    },
  ];

  const chatHistory: ChatHistory[] = [
    {
      id: 'h1',
      title: 'Wedding Ring Design',
      lastMessage: 'Can you show me platinum wedding bands?',
      timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000),
      messageCount: 8,
    },
    {
      id: 'h2',
      title: 'Engagement Jewelry',
      lastMessage: 'I need a unique engagement ring design',
      timestamp: new Date(Date.now() - 3 * 60 * 60 * 1000),
      messageCount: 12,
    },
    {
      id: 'h3',
      title: 'Gift Ideas',
      lastMessage: 'What would be a good anniversary gift?',
      timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000),
      messageCount: 6,
    },
  ];

  const handleSend = () => {
    if (!input.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsGenerating(true);

    // Simulate AI response
    setTimeout(() => {
      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'I understand you\'re looking for elegant jewelry. Let me create some design options for you. Based on your preferences, I\'d recommend considering rose gold with heart motifs, which are both romantic and timeless.',
        timestamp: new Date(),
        image: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600',
      };
      setMessages((prev) => [...prev, aiMessage]);
      setIsGenerating(false);
    }, 2000);
  };

  const formatTime = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (hours < 1) return 'Just now';
    if (hours < 24) return `${hours}h ago`;
    if (days === 1) return 'Yesterday';
    return `${days}d ago`;
  };

  if (isLoading) {
    return <CreateShimmer variant={activeTab} theme={theme} />;
  }

  return (
    <div className="h-full flex flex-col">
      {/* Chat Tab */}
      {activeTab === 'chat' && (
        <div className="flex-1 flex flex-col">
          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.map((message) => (
              <motion.div
                key={message.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[80%] p-4 rounded-2xl ${
                    message.role === 'user'
                      ? theme === 'dark'
                        ? 'bg-gradient-to-r from-blue-500 to-cyan-500 text-white'
                        : 'bg-gradient-to-r from-blue-600 to-cyan-600 text-white'
                      : theme === 'dark'
                      ? 'bg-white/10 text-white'
                      : 'bg-black/5 text-black'
                  }`}
                >
                  {message.role === 'assistant' && (
                    <div className="flex items-center gap-2 mb-2">
                      <div className="w-6 h-6 rounded-full bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center">
                        <Sparkles className="w-3 h-3 text-white" />
                      </div>
                      <span className="text-footnote opacity-60">AI Assistant</span>
                    </div>
                  )}
                  <p className="text-body-sm">{message.content}</p>
                  {message.image && (
                    <div className="mt-3 overflow-hidden rounded-xl">
                      <ImageWithFallback
                        src={message.image}
                        alt="Generated design"
                        className="w-full h-48 object-cover"
                      />
                      <div className="flex gap-2 p-2 bg-black/20">
                        <motion.button
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          className="flex-1 px-3 py-1.5 bg-white/10 hover:bg-white/20 flex items-center justify-center gap-1 text-footnote rounded-lg"
                        >
                          <Download className="w-3 h-3" />
                          Save
                        </motion.button>
                        <motion.button
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          className="flex-1 px-3 py-1.5 bg-white/10 hover:bg-white/20 flex items-center justify-center gap-1 text-footnote rounded-lg"
                        >
                          <Copy className="w-3 h-3" />
                          Remix
                        </motion.button>
                      </div>
                    </div>
                  )}
                  <p className={`text-footnote mt-2 ${message.role === 'user' ? 'opacity-80' : 'opacity-40'}`}>
                    {formatTime(message.timestamp)}
                  </p>
                </div>
              </motion.div>
            ))}

            {isGenerating && (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex justify-start"
              >
                <div
                  className={`p-4 rounded-2xl ${
                    theme === 'dark' ? 'bg-white/10 text-white' : 'bg-black/5 text-black'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center">
                      <Sparkles className="w-3 h-3 text-white animate-pulse" />
                    </div>
                    <div className="flex gap-1">
                      <motion.div
                        animate={{ y: [0, -5, 0] }}
                        transition={{ duration: 0.6, repeat: Infinity, delay: 0 }}
                        className="w-2 h-2 rounded-full bg-current opacity-60"
                      />
                      <motion.div
                        animate={{ y: [0, -5, 0] }}
                        transition={{ duration: 0.6, repeat: Infinity, delay: 0.2 }}
                        className="w-2 h-2 rounded-full bg-current opacity-60"
                      />
                      <motion.div
                        animate={{ y: [0, -5, 0] }}
                        transition={{ duration: 0.6, repeat: Infinity, delay: 0.4 }}
                        className="w-2 h-2 rounded-full bg-current opacity-60"
                      />
                    </div>
                  </div>
                </div>
              </motion.div>
            )}
          </div>
        </div>
      )}

      {/* Creations Tab */}
      {activeTab === 'creations' && (
        <div className="flex-1 overflow-y-auto p-4">
          <div className="grid grid-cols-2 gap-3">
            {creations.map((creation, index) => (
              <motion.div
                key={creation.id}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: index * 0.05 }}
                className={`overflow-hidden border ${
                  theme === 'dark'
                    ? 'bg-white/5 border-white/10'
                    : 'bg-white border-gray-200'
                }`}
              >
                <div className="relative aspect-square">
                  <ImageWithFallback
                    src={creation.image}
                    alt={creation.prompt}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                  <div className="absolute bottom-2 left-2 right-2">
                    <p className="text-footnote text-white line-clamp-2 mb-2">{creation.prompt}</p>
                    <div className="flex gap-1">
                      <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        className="flex-1 px-2 py-1 bg-white/20 backdrop-blur-sm text-footnote text-white flex items-center justify-center gap-1 rounded-lg"
                      >
                        <Copy className="w-3 h-3" />
                        Remix
                      </motion.button>
                      <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        className="px-2 py-1 bg-white/20 backdrop-blur-sm rounded-lg"
                      >
                        <Share2 className="w-3 h-3 text-white" />
                      </motion.button>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {creations.length === 0 && (
            <div className="flex flex-col items-center justify-center h-full text-center py-16">
              <ImageIcon className={`w-16 h-16 mb-4 ${theme === 'dark' ? 'text-white/20' : 'text-black/20'}`} />
              <h3 className={`text-heading-sm mb-2 ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
                No creations yet
              </h3>
              <p className={`text-body-sm ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
                Start chatting with AI to create jewelry designs
              </p>
            </div>
          )}
        </div>
      )}

      {/* History Tab */}
      {activeTab === 'history' && (
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {chatHistory.map((chat, index) => (
            <motion.button
              key={chat.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              className={`w-full p-4 border text-left transition-all duration-300 rounded-2xl ${
                theme === 'dark'
                  ? 'bg-white/5 border-white/10 hover:border-blue-500/30'
                  : 'bg-white border-gray-200 hover:border-blue-400'
              }`}
            >
              <div className="flex items-start justify-between mb-2">
                <h3 className={`text-body ${theme === 'dark' ? 'text-white' : 'text-black'}`}>
                  {chat.title}
                </h3>
                <span className={`text-footnote ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                  {formatTime(chat.timestamp)}
                </span>
              </div>
              <p className={`text-body-sm mb-2 ${theme === 'dark' ? 'text-white/60' : 'text-black/60'}`}>
                {chat.lastMessage}
              </p>
              <div className="flex items-center gap-2">
                <MessageSquare className={`w-3 h-3 ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`} />
                <span className={`text-footnote ${theme === 'dark' ? 'text-white/40' : 'text-black/40'}`}>
                  {chat.messageCount} messages
                </span>
              </div>
            </motion.button>
          ))}
        </div>
      )}
    </div>
  );
}
