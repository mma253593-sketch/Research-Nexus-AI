export type NexState =
  | 'idle'
  | 'blinking'
  | 'walking'
  | 'looking_at_user'
  | 'waving'
  | 'thinking'
  | 'talking'
  | 'explaining'
  | 'happy'
  | 'surprised'
  | 'sleeping';

export type NexLanguage = 'en' | 'th';

export interface NexPosition {
  x: number;
  y: number;
}

export interface NexPreferences {
  visible: boolean;
  walkingEnabled: boolean;
  voiceEnabled: boolean;
  autoGreetings: boolean;
  scale: number; // 0.85 = small, 1.0 = normal, 1.25 = large
  language: NexLanguage;
  savedPosition: NexPosition | null;
}

export interface ChatMessage {
  id: string;
  sender: 'user' | 'nex';
  text: string;
  timestamp: string;
  isError?: boolean;
  isFallback?: boolean;
  suggestedAction?: {
    label: string;
    view: string;
  };
}

export interface NexContextInfo {
  currentView: string;
  activeProjectTitle?: string;
  activeProjectShortCode?: string;
  activeProjectDomain?: string;
  currentStage?: string;
  selectedConcept?: string;
  hypothesesCount?: number;
  experimentsCount?: number;
}
