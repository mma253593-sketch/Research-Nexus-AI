import React, { useState, useEffect, useRef } from 'react';
import { Search, FolderKanban, Network, FileText, FlaskConical, TestTube2, Bookmark, Sun, Moon, ArrowRight, X } from 'lucide-react';

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (view: string, subTab?: string) => void;
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
  onSelectConcept?: (conceptId: string) => void;
}

export function CommandPalette({
  isOpen,
  onClose,
  onNavigate,
  theme,
  onToggleTheme,
  onSelectConcept
}: CommandPaletteProps) {
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setQuery('');
      setSelectedIndex(0);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  const items = [
    {
      id: 'nav-overview',
      category: 'Workspace Navigation',
      title: 'Workspace Overview',
      subtitle: 'Dashboard, stage timeline and active research metrics',
      icon: FolderKanban,
      action: () => onNavigate('workspace', 'overview')
    },
    {
      id: 'nav-projects',
      category: 'Workspace Navigation',
      title: 'Research Projects',
      subtitle: 'Manage local investigation records and stages',
      icon: FolderKanban,
      action: () => onNavigate('workspace', 'projects')
    },
    {
      id: 'nav-graph',
      category: 'Tools & Discoveries',
      title: 'Interactive Knowledge Graph',
      subtitle: 'Explore molecular and scientific concept network',
      icon: Network,
      action: () => onNavigate('graph')
    },
    {
      id: 'nav-hypotheses',
      category: 'Tools & Discoveries',
      title: 'Hypothesis Lab',
      subtitle: 'Formulate, evaluate and compare competing hypotheses',
      icon: FlaskConical,
      action: () => onNavigate('hypotheses')
    },
    {
      id: 'nav-experiment',
      category: 'Tools & Discoveries',
      title: 'Experiment Designer',
      subtitle: 'Structure protocols, variables, and evaluation criteria',
      icon: TestTube2,
      action: () => onNavigate('experiments')
    },
    {
      id: 'nav-paper',
      category: 'Tools & Discoveries',
      title: 'Paper Analysis',
      subtitle: 'Inspect abstracts, verify methodology and biases',
      icon: FileText,
      action: () => onNavigate('paper-analysis')
    },
    {
      id: 'nav-saved',
      category: 'Tools & Discoveries',
      title: 'Saved Literature Library',
      subtitle: 'Browse stored papers and exported citations',
      icon: Bookmark,
      action: () => onNavigate('saved-papers')
    },
    {
      id: 'concept-kras',
      category: 'Scientific Concepts',
      title: 'Concept: KRAS G12D',
      subtitle: 'Target · Oncogenic driver GTPase codon 12',
      icon: Network,
      action: () => {
        onNavigate('graph');
        onSelectConcept?.('kras-g12d');
      }
    },
    {
      id: 'concept-sos1',
      category: 'Scientific Concepts',
      title: 'Concept: SOS1 GEF',
      subtitle: 'Target · Guanine nucleotide exchange factor',
      icon: Network,
      action: () => {
        onNavigate('graph');
        onSelectConcept?.('sos1');
      }
    },
    {
      id: 'concept-perov',
      category: 'Scientific Concepts',
      title: 'Concept: Cs/MA/FA Perovskite',
      subtitle: 'Target · Wide-bandgap triple-cation absorber',
      icon: Network,
      action: () => {
        onNavigate('graph');
        onSelectConcept?.('perovskite-tandem');
      }
    },
    {
      id: 'action-theme',
      category: 'Preferences',
      title: theme === 'dark' ? 'Switch to Light Theme' : 'Switch to Dark Theme',
      subtitle: 'Toggle clinical light / deep navy canvas',
      icon: theme === 'dark' ? Sun : Moon,
      action: () => onToggleTheme()
    }
  ];

  const filteredItems = items.filter((item) =>
    item.title.toLowerCase().includes(query.toLowerCase()) ||
    item.subtitle.toLowerCase().includes(query.toLowerCase()) ||
    item.category.toLowerCase().includes(query.toLowerCase())
  );

  useEffect(() => {
    setSelectedIndex(0);
  }, [query]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % (filteredItems.length || 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + filteredItems.length) % (filteredItems.length || 1));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filteredItems[selectedIndex]) {
        filteredItems[selectedIndex].action();
        onClose();
      }
    } else if (e.key === 'Escape') {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div 
      className="fixed inset-0 z-50 bg-[#0A0E12]/60 backdrop-blur-xs flex items-start justify-center pt-20 px-4"
      onClick={onClose}
    >
      <div 
        className="w-full max-w-xl bg-[#FAF7F2] dark:bg-[#141A21] border border-stone-300 dark:border-stone-700 rounded-sm shadow-2xl overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label="Command Palette"
      >
        <div className="flex items-center px-4 border-b border-stone-200 dark:border-stone-800">
          <Search className="w-4 h-4 text-stone-400 shrink-0 mr-3" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Type a command, tool, or scientific concept..."
            className="w-full py-3.5 bg-transparent text-xs text-[#1F2421] dark:text-[#E8ECE9] placeholder:text-stone-400 focus:outline-none"
          />
          <button
            onClick={onClose}
            className="p-1 text-stone-400 hover:text-stone-600 dark:hover:text-stone-200 rounded-xs cursor-pointer"
            aria-label="Close command palette"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="max-h-80 overflow-y-auto p-2">
          {filteredItems.length === 0 ? (
            <div className="py-8 text-center text-xs text-stone-500">
              No matching commands or scientific concepts found
            </div>
          ) : (
            filteredItems.map((item, index) => {
              const Icon = item.icon;
              const isSelected = index === selectedIndex;
              return (
                <button
                  key={item.id}
                  onClick={() => {
                    item.action();
                    onClose();
                  }}
                  onMouseEnter={() => setSelectedIndex(index)}
                  className={`w-full flex items-center justify-between p-2.5 rounded-xs text-left transition-colors cursor-pointer ${
                    isSelected
                      ? 'bg-[#1B4332]/10 dark:bg-[#52B788]/15 text-[#143628] dark:text-[#52B788]'
                      : 'text-stone-700 dark:text-stone-300 hover:bg-stone-100 dark:hover:bg-stone-800/40'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="p-1.5 rounded-xs bg-stone-100 dark:bg-[#161C22] text-[#1B4332] dark:text-[#52B788] shrink-0 border border-stone-200 dark:border-stone-700">
                      <Icon className="w-4 h-4" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-xs font-semibold truncate font-serif">{item.title}</p>
                      <p className="text-[11px] text-stone-500 dark:text-stone-400 truncate">{item.subtitle}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0 ml-3">
                    <span className="text-[10px] font-mono text-stone-400">{item.category}</span>
                    {isSelected && <ArrowRight className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788]" />}
                  </div>
                </button>
              );
            })
          )}
        </div>

        <div className="px-4 py-2 border-t border-stone-200 dark:border-stone-800 bg-stone-100/50 dark:bg-[#11161B] flex items-center justify-between text-[11px] text-stone-500 font-mono">
          <span>Navigate with <kbd className="px-1 py-0.5 border border-stone-300 dark:border-stone-700 rounded-xs bg-white dark:bg-[#161C22] text-[10px]">↑</kbd> <kbd className="px-1 py-0.5 border border-stone-300 dark:border-stone-700 rounded-xs bg-white dark:bg-[#161C22] text-[10px]">↓</kbd></span>
          <span>Press <kbd className="px-1 py-0.5 border border-stone-300 dark:border-stone-700 rounded-xs bg-white dark:bg-[#161C22] text-[10px]">ESC</kbd> to exit</span>
        </div>
      </div>
    </div>
  );
}
