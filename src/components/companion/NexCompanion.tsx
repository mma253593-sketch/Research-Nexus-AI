import React, { useState, useEffect, useRef, useCallback } from 'react';
import { 
  NexState, NexPosition, NexPreferences, 
  NexContextInfo, NexLanguage 
} from './types';
import { getLocalized } from './nexLocalization';
import { useLanguage } from '../../context/LanguageContext';
import { NexCharacter } from './NexCharacter';
import { NexSpeechBubble } from './NexSpeechBubble';
import { NexChatPanel } from './NexChatPanel';
import { NexSettingsModal } from './NexSettingsModal';
import { Bot, MessageSquare, Settings, Sparkles, X } from 'lucide-react';

interface NexCompanionProps {
  context: NexContextInfo;
  onNavigateView?: (view: string) => void;
  appEvent?: {
    type: 'nav' | 'hypothesis_saved' | 'experiment_saved' | 'concept_selected';
    payload?: string;
  } | null;
}

const PREF_STORAGE_KEY = 'nex_companion_prefs_v1';
const POS_STORAGE_KEY = 'nex_companion_position_v1';

export function NexCompanion({
  context,
  onNavigateView,
  appEvent
}: NexCompanionProps) {
  const { language: globalLanguage, setLanguage: setGlobalLanguage } = useLanguage();

  // Preferences State
  const [preferences, setPreferences] = useState<NexPreferences>(() => {
    try {
      const raw = localStorage.getItem(PREF_STORAGE_KEY);
      if (raw) return JSON.parse(raw);
    } catch {}
    return {
      visible: true,
      walkingEnabled: true,
      voiceEnabled: false,
      autoGreetings: true,
      scale: 1.0,
      language: (globalLanguage as NexLanguage) || 'en',
      savedPosition: null
    };
  });

  // Keep Nex language in sync when user changes language via Navbar
  useEffect(() => {
    if (preferences.language !== globalLanguage) {
      setPreferences(prev => ({ ...prev, language: globalLanguage as NexLanguage }));
    }
  }, [globalLanguage]);

  // Position State
  const [position, setPosition] = useState<NexPosition>(() => {
    try {
      const raw = localStorage.getItem(POS_STORAGE_KEY);
      if (raw) return JSON.parse(raw);
    } catch {}
    return {
      x: typeof window !== 'undefined' ? Math.max(20, window.innerWidth - 120) : 1000,
      y: typeof window !== 'undefined' ? Math.max(100, window.innerHeight - 150) : 600
    };
  });

  // Character Animation State
  const [characterState, setCharacterState] = useState<NexState>('idle');
  const [facingDirection, setFacingDirection] = useState<'left' | 'right'>('right');

  // Interactive UI Panes
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [speechBubbleText, setSpeechBubbleText] = useState<string | null>(null);

  // Dragging Internals
  const [isDragging, setIsDragging] = useState(false);
  const dragStartRef = useRef<{ startX: number; startY: number; initPosX: number; initPosY: number }>({
    startX: 0,
    startY: 0,
    initPosX: 0,
    initPosY: 0
  });
  const hasMovedRef = useRef<boolean>(false);

  // Autonomous Walk & Idle Timers
  const walkIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const blinkIntervalRef = useRef<NodeJS.Timeout | null>(null);

  const t = getLocalized(preferences.language);

  // Persist preferences
  const updatePreferences = (updates: Partial<NexPreferences>) => {
    setPreferences((prev) => {
      const next = { ...prev, ...updates };
      try {
        localStorage.setItem(PREF_STORAGE_KEY, JSON.stringify(next));
      } catch {}
      return next;
    });
  };

  // Reset to default dock position
  const handleResetPosition = () => {
    const defaultPos: NexPosition = {
      x: Math.max(20, window.innerWidth - 130),
      y: Math.max(100, window.innerHeight - 160)
    };
    setPosition(defaultPos);
    try {
      localStorage.setItem(POS_STORAGE_KEY, JSON.stringify(defaultPos));
    } catch {}
    setCharacterState('happy');
    setTimeout(() => setCharacterState('idle'), 1500);
  };

  // Clamp position to viewport bounds with safe margins
  const clampPosition = useCallback((pos: NexPosition, scale: number): NexPosition => {
    if (typeof window === 'undefined') return pos;
    const charWidth = 84 * scale;
    const charHeight = 110 * scale;
    const margin = 16;
    const topMargin = 70; // Avoid top navbar
    const minX = margin;
    const maxX = Math.max(minX, window.innerWidth - charWidth - margin);
    const minY = topMargin;
    const maxY = Math.max(minY, window.innerHeight - charHeight - margin);

    return {
      x: Math.min(Math.max(pos.x, minX), maxX),
      y: Math.min(Math.max(pos.y, minY), maxY)
    };
  }, []);

  // Update position on window resize
  useEffect(() => {
    const handleResize = () => {
      setPosition((prev) => clampPosition(prev, preferences.scale));
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [clampPosition, preferences.scale]);

  // Periodic blinking state
  useEffect(() => {
    blinkIntervalRef.current = setInterval(() => {
      if (characterState === 'idle' || characterState === 'looking_at_user') {
        setCharacterState('blinking');
        setTimeout(() => {
          setCharacterState((prev) => (prev === 'blinking' ? 'idle' : prev));
        }, 180);
      }
    }, 4500);

    return () => {
      if (blinkIntervalRef.current) clearInterval(blinkIntervalRef.current);
    };
  }, [characterState]);

  // Autonomous walking loop
  useEffect(() => {
    if (!preferences.walkingEnabled || isDragging || isChatOpen || isSettingsOpen) {
      if (walkIntervalRef.current) clearInterval(walkIntervalRef.current);
      return;
    }

    const triggerAutonomousStroll = () => {
      // Do not walk if user is typing or modals are active
      const activeEl = document.activeElement;
      if (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA')) {
        return;
      }

      // Check prefers-reduced-motion
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        return;
      }

      // Decide stroll distance: 40px to 80px
      const deltaX = (Math.random() > 0.5 ? 1 : -1) * (40 + Math.random() * 45);
      const newFacing = deltaX > 0 ? 'right' : 'left';
      setFacingDirection(newFacing);
      setCharacterState('walking');

      const startPos = position;
      const targetX = clampPosition({ x: startPos.x + deltaX, y: startPos.y }, preferences.scale).x;
      const duration = 1200;
      const startTime = performance.now();

      const animateStep = (now: number) => {
        const elapsed = now - startTime;
        const progress = Math.min(1, elapsed / duration);
        const currentX = startPos.x + (targetX - startPos.x) * progress;

        setPosition((prev) => ({ ...prev, x: currentX }));

        if (progress < 1) {
          requestAnimationFrame(animateStep);
        } else {
          setCharacterState('idle');
          try {
            localStorage.setItem(POS_STORAGE_KEY, JSON.stringify({ x: targetX, y: startPos.y }));
          } catch {}
        }
      };

      requestAnimationFrame(animateStep);
    };

    walkIntervalRef.current = setInterval(triggerAutonomousStroll, 22000);

    return () => {
      if (walkIntervalRef.current) clearInterval(walkIntervalRef.current);
    };
  }, [preferences.walkingEnabled, isDragging, isChatOpen, isSettingsOpen, position, clampPosition, preferences.scale]);

  // Handle Application Events Reactions
  useEffect(() => {
    if (!appEvent || !preferences.autoGreetings) return;

    if (appEvent.type === 'nav') {
      let msg = t.greetingDefault;
      if (context.currentView === 'workspace') msg = t.greetingWorkspace;
      else if (context.currentView === 'graph') msg = t.greetingGraph;
      else if (context.currentView === 'hypotheses') msg = t.greetingHypothesis;
      else if (context.currentView === 'experiments') msg = t.greetingExperiment;
      else if (context.currentView === 'paper-analysis') msg = t.greetingPaper;

      setSpeechBubbleText(msg);
      setCharacterState('waving');
      setTimeout(() => setCharacterState('idle'), 2200);
    } else if (appEvent.type === 'hypothesis_saved') {
      setSpeechBubbleText(t.celebrateHypothesis);
      setCharacterState('happy');
      setTimeout(() => setCharacterState('idle'), 2500);
    } else if (appEvent.type === 'experiment_saved') {
      setSpeechBubbleText(t.celebrateExperiment);
      setCharacterState('explaining');
      setTimeout(() => setCharacterState('idle'), 2500);
    } else if (appEvent.type === 'concept_selected') {
      setSpeechBubbleText(`Concept activated: "${appEvent.payload}". Let's formulate a hypothesis!`);
      setCharacterState('thinking');
      setTimeout(() => setCharacterState('idle'), 2500);
    }
  }, [appEvent, context.currentView, preferences.autoGreetings, t]);

  // Initial welcome greeting on first load
  useEffect(() => {
    if (preferences.autoGreetings && preferences.visible) {
      const welcomeTimer = setTimeout(() => {
        setSpeechBubbleText(t.greetingDefault);
        setCharacterState('waving');
        setTimeout(() => setCharacterState('idle'), 2500);
      }, 1500);
      return () => clearTimeout(welcomeTimer);
    }
  }, []);

  // Pointer Drag Handlers (Unified Mouse and Touch)
  const handlePointerDown = (e: React.PointerEvent) => {
    if (e.button !== 0 && e.pointerType === 'mouse') return;

    e.preventDefault();
    (e.target as HTMLElement).setPointerCapture(e.pointerId);

    setIsDragging(true);
    hasMovedRef.current = false;
    dragStartRef.current = {
      startX: e.clientX,
      startY: e.clientY,
      initPosX: position.x,
      initPosY: position.y
    };

    setCharacterState('looking_at_user');
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!isDragging) return;

    const deltaX = e.clientX - dragStartRef.current.startX;
    const deltaY = e.clientY - dragStartRef.current.startY;
    const dist = Math.hypot(deltaX, deltaY);

    if (dist > 5) {
      hasMovedRef.current = true;
      if (deltaX !== 0) {
        setFacingDirection(deltaX > 0 ? 'right' : 'left');
      }
      setCharacterState('surprised');

      const rawX = dragStartRef.current.initPosX + deltaX;
      const rawY = dragStartRef.current.initPosY + deltaY;
      const clamped = clampPosition({ x: rawX, y: rawY }, preferences.scale);
      setPosition(clamped);
    }
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    if (!isDragging) return;
    setIsDragging(false);

    try {
      (e.target as HTMLElement).releasePointerCapture(e.pointerId);
    } catch {}

    if (!hasMovedRef.current) {
      // Tap detected without dragging! Toggle chat panel & react
      setCharacterState('happy');
      setIsChatOpen((prev) => !prev);
      setSpeechBubbleText(null);
      setTimeout(() => setCharacterState('idle'), 1500);
    } else {
      // Drag completed: persist position
      try {
        localStorage.setItem(POS_STORAGE_KEY, JSON.stringify(position));
      } catch {}
      setCharacterState('idle');
    }
  };

  const handlePointerCancel = () => {
    setIsDragging(false);
    setCharacterState('idle');
  };

  // Text to speech voice playback
  const handleSpeak = (text: string) => {
    if (typeof window === 'undefined' || !('speechSynthesis' in window)) return;
    window.speechSynthesis.cancel();
    const cleanText = text.replace(/\[.*?\]/g, '').replace(/[*_#]/g, '');
    const utterance = new SpeechSynthesisUtterance(cleanText);
    utterance.lang = preferences.language === 'th' ? 'th-TH' : 'en-US';
    window.speechSynthesis.speak(utterance);
  };

  // If hidden, show small unobtrusive dock button to summon NEX
  if (!preferences.visible) {
    return (
      <div className="fixed bottom-5 right-5 z-40">
        <button
          onClick={() => {
            updatePreferences({ visible: true });
            setCharacterState('waving');
            setSpeechBubbleText(t.greetingDefault);
            setTimeout(() => setCharacterState('idle'), 2500);
          }}
          className="flex items-center gap-2 px-3 py-2 bg-slate-900/90 dark:bg-slate-800/90 backdrop-blur-md text-white border border-slate-700 rounded-full shadow-lg hover:border-teal-500 hover:text-teal-300 transition-all text-xs font-medium cursor-pointer group"
          title={t.summonNex}
          aria-label={t.summonNex}
        >
          <Bot className="w-4 h-4 text-teal-400 group-hover:scale-110 transition-transform" />
          <span>{t.summonNex}</span>
        </button>
      </div>
    );
  }

  return (
    <>
      {/* Draggable Character Container */}
      <div
        style={{
          position: 'fixed',
          left: `${position.x}px`,
          top: `${position.y}px`,
          touchAction: 'none',
          zIndex: 45,
          cursor: isDragging ? 'grabbing' : 'grab'
        }}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerCancel={handlePointerCancel}
        className="group focus:outline-none transition-shadow"
      >
        {/* Character Visual Model */}
        <NexCharacter
          state={characterState}
          scale={preferences.scale}
          direction={facingDirection}
          isInteracting={isDragging || isChatOpen}
        />

        {/* Floating Speech Bubble */}
        {speechBubbleText && !isChatOpen && (
          <NexSpeechBubble
            message={speechBubbleText}
            onDismiss={() => setSpeechBubbleText(null)}
            onSpeak={handleSpeak}
            voiceEnabled={preferences.voiceEnabled}
            position={position}
            scale={preferences.scale}
          />
        )}

        {/* Hover Quick Action Pill (Desktop affordance) */}
        <div className="absolute -bottom-6 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity bg-slate-900/90 text-white text-[9.5px] font-mono px-2 py-0.5 rounded-full whitespace-nowrap pointer-events-none shadow-md">
          Tap to Chat · Drag to Move
        </div>
      </div>

      {/* Floating Chat Panel */}
      <NexChatPanel
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
        context={context}
        preferences={preferences}
        onOpenSettings={() => setIsSettingsOpen(true)}
        onNavigateView={onNavigateView}
      />

      {/* Companion Settings Modal */}
      <NexSettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
        preferences={preferences}
        onUpdatePreferences={updatePreferences}
        onResetPosition={handleResetPosition}
      />
    </>
  );
}
