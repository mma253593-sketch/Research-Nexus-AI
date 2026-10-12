import { useState } from 'react';
import { resolveProjectImageUrl } from '../../assets/images';
import { Microscope, FlaskConical, Atom, Dna } from 'lucide-react';

interface ScientificImageProps {
  src: string;
  fallbackSrc?: string;
  alt: string;
  className?: string;
  aspectRatioClass?: string;
  category?: 'oncology' | 'materials' | 'neuro' | 'general';
}

export function ScientificImage({
  src,
  fallbackSrc,
  alt,
  className = 'w-full h-full object-cover',
  aspectRatioClass = 'aspect-16/9',
  category = 'general'
}: ScientificImageProps) {
  const resolvedSrc = resolveProjectImageUrl(src);
  const [currentSrc, setCurrentSrc] = useState<string>(resolvedSrc);
  const [hasError, setHasError] = useState(false);

  const handleError = () => {
    if (fallbackSrc && currentSrc !== fallbackSrc) {
      setCurrentSrc(fallbackSrc);
    } else {
      setHasError(true);
    }
  };

  if (hasError) {
    const Icon = category === 'neuro' ? Dna : category === 'materials' ? Atom : category === 'oncology' ? FlaskConical : Microscope;
    return (
      <div className={`w-full ${aspectRatioClass} bg-[#F4EFEA] dark:bg-[#1A222B] border border-stone-200 dark:border-stone-800 flex flex-col items-center justify-center p-4 text-center select-none`}>
        <div className="w-10 h-10 rounded-full bg-stone-200/70 dark:bg-stone-800 flex items-center justify-center text-[#1B4332] dark:text-[#52B788] mb-2">
          <Icon className="w-5 h-5 stroke-[1.5]" />
        </div>
        <span className="text-[11px] font-mono uppercase tracking-wider text-stone-500 dark:text-stone-400">
          Scientific Archive Record
        </span>
        <span className="text-xs font-serif text-stone-700 dark:text-stone-300 line-clamp-1 mt-0.5">
          {alt}
        </span>
      </div>
    );
  }

  return (
    <div className={`relative overflow-hidden ${aspectRatioClass} bg-[#F4EFEA] dark:bg-[#1A222B]`}>
      <img
        src={currentSrc}
        alt={alt}
        onError={handleError}
        loading="lazy"
        decoding="async"
        referrerPolicy="no-referrer"
        className={className}
      />
    </div>
  );
}
