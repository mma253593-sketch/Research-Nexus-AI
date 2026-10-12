import React, { useState, useRef, useEffect } from 'react';
import { ChatMessage, NexContextInfo, NexLanguage, NexPreferences } from './types';
import { getLocalized } from './nexLocalization';
import { askNex } from './nexAiService';
import { 
  Bot, Send, X, Volume2, VolumeX, RotateCcw, 
  Sparkles, AlertCircle, Settings, ChevronDown, Check, User
} from 'lucide-react';

interface NexChatPanelProps {
  isOpen: boolean;
  onClose: () => void;
  context: NexContextInfo;
  preferences: NexPreferences;
  onOpenSettings: () => void;
  onNavigateView?: (view: string) => void;
}

export function NexChatPanel({
  isOpen,
  onClose,
  context,
  preferences,
  onOpenSettings,
  onNavigateView
}: NexChatPanelProps) {
  const t = getLocalized(preferences.language);
  const [messages, setMessages] = useState<ChatMessage[]>(() => [
    {
      id: 'welcome-1',
      sender: 'nex',
      text: t.greetingDefault,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSpeakingId, setIsSpeakingId] = useState<string | null>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 100);
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [isOpen]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  if (!isOpen) return null;

  const handleSend = async (textToSend?: string) => {
    const query = (textToSend || input).trim();
    if (!query || isLoading) return;

    const userMsg: ChatMessage = {
      id: `user-${Date.now()}`,
      sender: 'user',
      text: query,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsLoading(true);

    try {
      const res = await askNex(query, context, preferences.language);
      
      const nexMsg: ChatMessage = {
        id: `nex-${Date.now()}`,
        sender: 'nex',
        text: res.reply,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        isFallback: res.isFallback,
        isError: !!res.error && !res.isFallback
      };

      setMessages((prev) => [...prev, nexMsg]);

      // If voice enabled, speak response
      if (preferences.voiceEnabled) {
        speakText(res.reply, nexMsg.id);
      }
    } catch (e: any) {
      const errMsg: ChatMessage = {
        id: `nex-err-${Date.now()}`,
        sender: 'nex',
        text: 'Sorry, I encountered an issue retrieving that answer. You can retry or explore the local modules.',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        isError: true
      };
      setMessages((prev) => [...prev, errMsg]);
    } finally {
      setIsLoading(false);
    }
  };

  const speakText = (text: string, msgId?: string) => {
    if (typeof window === 'undefined' || !('speechSynthesis' in window)) return;

    window.speechSynthesis.cancel();
    if (isSpeakingId === msgId) {
      setIsSpeakingId(null);
      return;
    }

    const cleanText = text.replace(/\[.*?\]/g, '').replace(/[*_#]/g, '');
    const utterance = new SpeechSynthesisUtterance(cleanText);
    utterance.lang = preferences.language === 'th' ? 'th-TH' : 'en-US';
    utterance.rate = 1.0;

    utterance.onend = () => setIsSpeakingId(null);
    utterance.onerror = () => setIsSpeakingId(null);

    if (msgId) setIsSpeakingId(msgId);
    window.speechSynthesis.speak(utterance);
  };

  const stopSpeaking = () => {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      setIsSpeakingId(null);
    }
  };

  return (
    <div
      className="fixed bottom-24 right-6 sm:right-8 z-50 w-full max-w-[360px] sm:max-w-[400px] bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-2xl flex flex-col h-[520px] max-h-[80vh] overflow-hidden animate-in fade-in slide-in-from-bottom-5 duration-200"
      role="dialog"
      aria-label="NEX Chat Assistant"
    >
      {/* Panel Header */}
      <div className="p-3.5 border-b border-slate-200 dark:border-slate-800 bg-stone-50/80 dark:bg-slate-950/60 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-full bg-teal-500/10 border border-teal-500/30 flex items-center justify-center text-teal-600 dark:text-teal-400">
            <Bot className="w-4 h-4" />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <h2 className="text-xs font-bold text-slate-900 dark:text-slate-100">
                {t.name}
              </h2>
              <span className="text-[10px] font-mono text-teal-600 dark:text-teal-400 px-1 py-0.2 rounded bg-teal-50 dark:bg-teal-950/60">
                AI Companion
              </span>
            </div>
            <p className="text-[10px] text-slate-400">
              {isLoading ? 'Synthesizing response...' : t.tagline}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1">
          {isSpeakingId && (
            <button
              onClick={stopSpeaking}
              className="p-1.5 text-teal-600 dark:text-teal-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded transition-colors"
              title="Stop audio speech"
              aria-label="Stop audio speech"
            >
              <VolumeX className="w-3.5 h-3.5 animate-pulse" />
            </button>
          )}

          <button
            onClick={onOpenSettings}
            className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded transition-colors"
            title="Companion settings"
            aria-label="Companion settings"
          >
            <Settings className="w-3.5 h-3.5" />
          </button>

          <button
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded transition-colors"
            title="Close chat"
            aria-label="Close chat"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Active Context Awareness Strip */}
      <div className="px-3.5 py-1.5 bg-slate-100/60 dark:bg-slate-800/40 border-b border-slate-100 dark:border-slate-800/60 flex items-center justify-between text-[10.5px] font-mono text-slate-500">
        <span className="truncate max-w-[240px]">
          Context: {context.activeProjectShortCode || 'General'} · {context.currentView}
        </span>
        {context.currentStage && (
          <span className="capitalize text-teal-600 dark:text-teal-400 font-semibold shrink-0">
            {context.currentStage}
          </span>
        )}
      </div>

      {/* Conversation Messages */}
      <div className="flex-1 p-3.5 overflow-y-auto space-y-3 text-xs">
        {messages.map((msg) => {
          const isNex = msg.sender === 'nex';
          return (
            <div
              key={msg.id}
              className={`flex flex-col ${isNex ? 'items-start' : 'items-end'}`}
            >
              <div
                className={`max-w-[85%] p-3 rounded-2xl leading-relaxed ${
                  isNex
                    ? 'bg-stone-50 dark:bg-slate-800/70 border border-slate-200 dark:border-slate-700/60 text-slate-800 dark:text-slate-200 rounded-tl-xs'
                    : 'bg-slate-900 text-white dark:bg-teal-600 rounded-tr-xs shadow-xs'
                }`}
              >
                {/* Fallback Notice Badge if offline */}
                {isNex && msg.isFallback && (
                  <div className="flex items-center gap-1 text-[9.5px] font-mono text-teal-600 dark:text-teal-400 mb-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-teal-500" />
                    <span>Grounded Knowledge Base</span>
                  </div>
                )}

                <p className="whitespace-pre-wrap">{msg.text}</p>
              </div>

              {/* Timestamp & Speak Action */}
              <div className="flex items-center gap-2 mt-1 px-1 text-[10px] text-slate-400 font-mono">
                <span>{msg.timestamp}</span>
                {isNex && (
                  <button
                    onClick={() => speakText(msg.text, msg.id)}
                    className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors flex items-center gap-0.5"
                    title="Read response aloud"
                  >
                    <Volume2 className="w-2.5 h-2.5" />
                    <span>{isSpeakingId === msg.id ? 'Playing...' : 'Audio'}</span>
                  </button>
                )}
              </div>
            </div>
          );
        })}

        {/* Typing indicator */}
        {isLoading && (
          <div className="flex items-center gap-2 p-3 bg-stone-50 dark:bg-slate-800/70 border border-slate-200 dark:border-slate-700/60 rounded-2xl rounded-tl-xs w-24">
            <span className="w-1.5 h-1.5 rounded-full bg-teal-500 animate-bounce" />
            <span className="w-1.5 h-1.5 rounded-full bg-teal-500 animate-bounce [animation-delay:0.15s]" />
            <span className="w-1.5 h-1.5 rounded-full bg-teal-500 animate-bounce [animation-delay:0.3s]" />
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Suggested Questions Carousel */}
      <div className="p-2 border-t border-slate-100 dark:border-slate-800/80 bg-stone-50/50 dark:bg-slate-950/40">
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
          {t.suggestedQuestions.map((q, idx) => (
            <button
              key={idx}
              onClick={() => handleSend(q)}
              className="text-[10.5px] px-2.5 py-1 rounded-md bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:border-teal-500 hover:text-teal-600 whitespace-nowrap transition-colors shrink-0"
            >
              {q}
            </button>
          ))}
        </div>
      </div>

      {/* Input Form */}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleSend();
        }}
        className="p-3 border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center gap-2"
      >
        <input
          ref={inputRef}
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder={t.chatPlaceholder}
          className="flex-1 px-3 py-2 text-xs bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500"
        />
        <button
          type="submit"
          disabled={!input.trim() || isLoading}
          className="p-2 bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 text-white rounded-lg transition-colors disabled:opacity-40 shadow-xs shrink-0"
          aria-label="Send message to NEX"
        >
          <Send className="w-3.5 h-3.5" />
        </button>
      </form>
    </div>
  );
}
