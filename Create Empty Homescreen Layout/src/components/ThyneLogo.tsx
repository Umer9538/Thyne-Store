import svgPaths from '../imports/svg-wa28anf4ml';

interface ThyneLogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  color?: string;
  showText?: boolean;
  showTagline?: boolean;
  className?: string;
}

export function ThyneLogo({
  size = 'md',
  color = '#094010',
  showText = true,
  showTagline = true,
  className = '',
}: ThyneLogoProps) {
  const sizeMap = {
    sm: { logo: 60, text: 32, tagline: 12 },
    md: { logo: 100, text: 56, tagline: 18 },
    lg: { logo: 140, text: 88, tagline: 28 },
    xl: { logo: 180, text: 110, tagline: 36 },
  };

  const dimensions = sizeMap[size];

  return (
    <div className={`flex flex-col items-center ${className}`}>
      {/* Logo SVG */}
      <div
        className="relative shrink-0"
        style={{
          width: `${dimensions.logo}px`,
          height: `${dimensions.logo}px`,
        }}
      >
        <svg
          className="block w-full h-full"
          fill="none"
          preserveAspectRatio="none"
          viewBox="0 0 140 140"
        >
          <path d={svgPaths.p3a3abcc0} fill={color} id="Intersect" />
        </svg>
      </div>

      {/* Text */}
      {showText && (
        <div
          className="flex flex-col justify-center not-italic relative shrink-0 text-center whitespace-nowrap"
          style={{
            fontSize: `${dimensions.text}px`,
            color: color,
            lineHeight: 'normal',
            fontFamily: 'Sirenik, serif',
            fontWeight: 400,
            marginTop: size === 'sm' ? '8px' : size === 'md' ? '12px' : '16px',
          }}
        >
          <p>thyne</p>
        </div>
      )}

      {/* Tagline */}
      {showTagline && (
        <div
          className="flex flex-col justify-center not-italic relative shrink-0 text-center"
          style={{
            fontSize: `${dimensions.tagline}px`,
            color: color,
            lineHeight: 'normal',
            fontFamily: 'Inter, sans-serif',
            fontWeight: 200,
            marginTop: size === 'sm' ? '4px' : size === 'md' ? '6px' : '8px',
            opacity: 0.8,
          }}
        >
          <p>etched by you</p>
        </div>
      )}
    </div>
  );
}
