import { NexPreferences, NexLanguage } from './types';
import { getLocalized } from './nexLocalization';
import { 
  X, Volume2, VolumeX, Eye, EyeOff, Footprints, 
  RotateCcw, Sliders, Globe, Bot
} from 'lucide-react';

interface NexSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  preferences: NexPreferences;
  onUpdatePreferences: (updates: Partial<NexPreferences>) => void;
  onResetPosition: () => void;
}

export function NexSettingsModal({
  isOpen,
  onClose,
  preferences,
  onUpdatePreferences,
  onResetPosition
}: NexSettingsModalProps) {
  if (!isOpen) return null;

  const t = getLocalized(preferences.language);

  return (
    <div
      className="fixed inset-0 z-70 bg-slate-950/50 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-label="NEX Companion Settings"
    >
      <div
        className="w-full max-w-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-2xl overflow-hidden p-5 space-y-4"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded-md bg-teal-50 dark:bg-teal-950/50 text-teal-600 dark:text-teal-400">
              <Bot className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-xs font-bold text-slate-900 dark:text-slate-100">
                {t.settingsTitle}
              </h3>
              <p className="text-[10px] text-slate-400 font-mono">NEX v1.2 Assistant Core</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded"
            aria-label="Close settings"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Setting Items */}
        <div className="space-y-3.5 text-xs">
          {/* Autonomous Walking */}
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <span className="font-semibold text-slate-800 dark:text-slate-200 block">
                {t.walkingEnabled}
              </span>
              <span className="text-[11px] text-slate-400 block">
                Allows NEX to stroll periodically
              </span>
            </div>
            <button
              onClick={() => onUpdatePreferences({ walkingEnabled: !preferences.walkingEnabled })}
              className={`w-10 h-5 flex items-center rounded-full p-0.5 transition-colors ${
                preferences.walkingEnabled ? 'bg-teal-600' : 'bg-slate-300 dark:bg-slate-700'
              }`}
              aria-label="Toggle autonomous walking"
            >
              <div
                className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                  preferences.walkingEnabled ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Speech Synthesis Voice */}
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <span className="font-semibold text-slate-800 dark:text-slate-200 block">
                {t.voiceEnabled}
              </span>
              <span className="text-[11px] text-slate-400 block">
                Browser audio voice read-back
              </span>
            </div>
            <button
              onClick={() => onUpdatePreferences({ voiceEnabled: !preferences.voiceEnabled })}
              className={`w-10 h-5 flex items-center rounded-full p-0.5 transition-colors ${
                preferences.voiceEnabled ? 'bg-teal-600' : 'bg-slate-300 dark:bg-slate-700'
              }`}
              aria-label="Toggle voice output"
            >
              <div
                className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                  preferences.voiceEnabled ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Automatic Contextual Greetings */}
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <span className="font-semibold text-slate-800 dark:text-slate-200 block">
                {t.autoGreetings}
              </span>
              <span className="text-[11px] text-slate-400 block">
                Helpful contextual tips on navigation
              </span>
            </div>
            <button
              onClick={() => onUpdatePreferences({ autoGreetings: !preferences.autoGreetings })}
              className={`w-10 h-5 flex items-center rounded-full p-0.5 transition-colors ${
                preferences.autoGreetings ? 'bg-teal-600' : 'bg-slate-300 dark:bg-slate-700'
              }`}
              aria-label="Toggle automatic greetings"
            >
              <div
                className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                  preferences.autoGreetings ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Language Selection */}
          <div className="space-y-1 pt-1 border-t border-slate-100 dark:border-slate-800">
            <span className="font-semibold text-slate-800 dark:text-slate-200 block">
              {t.languageLabel}
            </span>
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => onUpdatePreferences({ language: 'en' })}
                className={`py-1.5 px-3 rounded text-xs font-medium border transition-colors ${
                  preferences.language === 'en'
                    ? 'bg-slate-900 text-white dark:bg-teal-600 dark:text-white border-transparent'
                    : 'bg-stone-50 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700'
                }`}
              >
                English (EN)
              </button>
              <button
                onClick={() => onUpdatePreferences({ language: 'th' })}
                className={`py-1.5 px-3 rounded text-xs font-medium border transition-colors ${
                  preferences.language === 'th'
                    ? 'bg-slate-900 text-white dark:bg-teal-600 dark:text-white border-transparent'
                    : 'bg-stone-50 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700'
                }`}
              >
                ภาษาไทย (TH)
              </button>
            </div>
          </div>

          {/* Size Scale */}
          <div className="space-y-1 pt-1 border-t border-slate-100 dark:border-slate-800">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-slate-800 dark:text-slate-200">
                {t.sizeLabel}
              </span>
              <span className="font-mono text-[11px] text-slate-400">
                {preferences.scale <= 0.85 ? 'Compact' : preferences.scale >= 1.2 ? 'Large' : 'Standard'}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => onUpdatePreferences({ scale: 0.85 })}
                className={`flex-1 py-1 text-xs rounded border transition-colors ${
                  preferences.scale === 0.85
                    ? 'bg-teal-50 dark:bg-teal-950/60 text-teal-700 dark:text-teal-300 border-teal-300 dark:border-teal-800 font-semibold'
                    : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700'
                }`}
              >
                Small
              </button>
              <button
                onClick={() => onUpdatePreferences({ scale: 1.0 })}
                className={`flex-1 py-1 text-xs rounded border transition-colors ${
                  preferences.scale === 1.0
                    ? 'bg-teal-50 dark:bg-teal-950/60 text-teal-700 dark:text-teal-300 border-teal-300 dark:border-teal-800 font-semibold'
                    : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700'
                }`}
              >
                Medium
              </button>
              <button
                onClick={() => onUpdatePreferences({ scale: 1.25 })}
                className={`flex-1 py-1 text-xs rounded border transition-colors ${
                  preferences.scale === 1.25
                    ? 'bg-teal-50 dark:bg-teal-950/60 text-teal-700 dark:text-teal-300 border-teal-300 dark:border-teal-800 font-semibold'
                    : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700'
                }`}
              >
                Large
              </button>
            </div>
          </div>

          {/* Reset Position & Visibility Actions */}
          <div className="pt-2 border-t border-slate-100 dark:border-slate-800 space-y-2">
            <button
              onClick={() => {
                onResetPosition();
                onClose();
              }}
              className="w-full py-2 px-3 text-xs font-medium text-slate-700 dark:text-slate-300 bg-stone-100 dark:bg-slate-800 hover:bg-stone-200 dark:hover:bg-slate-700 rounded-md transition-colors flex items-center justify-center gap-1.5"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>{t.resetPosition}</span>
            </button>

            <button
              onClick={() => {
                onUpdatePreferences({ visible: false });
                onClose();
              }}
              className="w-full py-1.5 text-xs text-rose-600 dark:text-rose-400 hover:underline flex items-center justify-center gap-1"
            >
              <EyeOff className="w-3.5 h-3.5" />
              <span>{t.hideNex}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
