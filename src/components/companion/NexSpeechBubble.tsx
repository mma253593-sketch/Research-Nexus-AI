import { useEffect, useRef } from 'react';
import { X, Volume2 } from 'lucide-react';

interface NexSpeechBubbleProps {
  message: string;
  onDismiss: () => void;
  onSpeak?: (text: string) => void;
  voiceEnabled?: boolean;
  position: { x: number; y: number };
  scale?: number;
  duration?: number; // auto-dismiss in ms
}

export function NexSpeechBubble({
  message,
  onDismiss,
  onSpeak,
  voiceEnabled = false,
  position,
  scale = 1.0,
  duration = 7500
}: NexSpeechBubbleProps) {
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (duration > 0) {
      timerRef.current = setTimeout(() => {
        onDismiss();
      }, duration);
    }
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [message, duration, onDismiss]);

  const handleMouseEnter = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
  };

  const handleMouseLeave = () => {
    if (duration > 0) {
      timerRef.current = setTimeout(() => {
        onDismiss();
      }, 3500);
    }
  };

  // Determine flip orientation based on screen position
  const isNearTop = position.y < 160;
  const isNearRight = typeof window !== 'undefined' && position.x > (window.innerWidth - 280);

  // Offset placement
  const bubbleStyle: React.CSSProperties = {
    position: 'absolute',
    bottom: isNearTop ? 'auto' : `${115 * scale}px`,
    top: isNearTop ? `${115 * scale}px` : 'auto',
    left: isNearRight ? 'auto' : '-40px',
    right: isNearRight ? '-20px' : 'auto',
    maxWidth: '280px',
    minWidth: '180px',
    zIndex: 60
  };

  return (
    <div
      style={bubbleStyle}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className="bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200 p-3.5 rounded-2xl shadow-xl text-xs transition-all animate-in fade-in zoom-in-95 duration-200 pointer-events-auto"
      role="status"
      aria-live="polite"
    >
      {/* Speech Bubble Arrow Indicator */}
      <div
        className={`absolute w-3 h-3 bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 rotate-45 ${
          isNearTop
            ? '-top-1.5 border-t border-l'
            : '-bottom-1.5 border-b border-r'
        } ${isNearRight ? 'right-10' : 'left-14'}`}
      />

      <div className="flex items-start justify-between gap-2 mb-1.5">
        <span className="font-mono text-[10px] text-teal-600 dark:text-teal-400 font-semibold tracking-wider uppercase flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-teal-500 inline-block animate-pulse" />
          NEX Insight
        </span>

        <div className="flex items-center gap-1">
          {voiceEnabled && onSpeak && (
            <button
              onClick={() => onSpeak(message)}
              className="p-1 text-slate-400 hover:text-teal-600 dark:hover:text-teal-400 rounded transition-colors"
              title="Speak message"
              aria-label="Speak message"
            >
              <Volume2 className="w-3 h-3" />
            </button>
          )}
          <button
            onClick={onDismiss}
            className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded transition-colors"
            aria-label="Dismiss speech bubble"
          >
            <X className="w-3 h-3" />
          </button>
        </div>
      </div>

      <p className="text-xs text-slate-700 dark:text-slate-200 leading-relaxed font-sans">
        {message}
      </p>
    </div>
  );
}
