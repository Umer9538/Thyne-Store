import React, { useState, useEffect } from 'react';
import { NewThyneVerse } from './community/NewThyneVerse';
import { NewMyProfile } from './community/NewMyProfile';
import { CommunityShimmer } from './CommunityShimmer';
import { CreatorSpotlight } from './community/CreatorSpotlight';

interface CommunitySectionProps {
  activeTab: 'verse' | 'spotlight' | 'profile';
  onProductClick: (productId: string) => void;
  onRemixPrompt: (prompt: string) => void;
  onNavigateToCreate: () => void;
  onFullScreenChange?: (isFullScreen: boolean) => void;
  theme?: 'dark' | 'light';
}

export const CommunitySection: React.FC<CommunitySectionProps> = ({
  activeTab,
  onProductClick,
  onRemixPrompt,
  onNavigateToCreate,
  onFullScreenChange,
  theme = 'light',
}) => {
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading when tab changes
    setIsLoading(true);
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 800);

    return () => clearTimeout(timer);
  }, [activeTab]);

  const handleRemix = (prompt: string) => {
    onRemixPrompt(prompt);
    onNavigateToCreate();
  };

  return (
    <div className="w-full">
      {/* Tab Content */}
      <div className="px-0">
        {isLoading ? (
          <CommunityShimmer variant={activeTab} theme={theme} />
        ) : (
          <>
            {activeTab === 'verse' && (
              <NewThyneVerse 
                onProductClick={onProductClick} 
                onFullScreenChange={onFullScreenChange}
                theme={theme}
              />
            )}
            {activeTab === 'spotlight' && (
              <CreatorSpotlight 
                onProductClick={onProductClick}
                theme={theme}
              />
            )}
            {activeTab === 'profile' && (
              <NewMyProfile
                onMediaClick={(mediaId) => console.log('Media clicked:', mediaId)}
                onUploadClick={() => console.log('Upload clicked')}
                onCameraClick={() => console.log('Camera clicked')}
                theme={theme}
              />
            )}
          </>
        )}
      </div>
    </div>
  );
};
