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
      className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-start justify-center pt-20 px-4"
      onClick={onClose}
    >
      <div 
        className="w-full max-w-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-2xl overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label="Command Palette"
      >
        <div className="flex items-center px-4 border-b border-slate-200 dark:border-slate-800">
          <Search className="w-4 h-4 text-slate-400 shrink-0 mr-3" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Type a command, tool, or scientific concept..."
            className="w-full py-3.5 bg-transparent text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none"
          />
          <button
            onClick={onClose}
            className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded"
            aria-label="Close command palette"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="max-h-80 overflow-y-auto p-2">
          {filteredItems.length === 0 ? (
            <div className="py-8 text-center text-xs text-slate-500">
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
                  className={`w-full flex items-center justify-between p-2.5 rounded-lg text-left transition-colors ${
                    isSelected
                      ? 'bg-slate-100 dark:bg-slate-800/80 text-slate-900 dark:text-slate-100'
                      : 'text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800/40'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="p-1.5 rounded-md bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 shrink-0">
                      <Icon className="w-4 h-4" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-xs font-medium truncate">{item.title}</p>
                      <p className="text-[11px] text-slate-500 truncate">{item.subtitle}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0 ml-3">
                    <span className="text-[10px] text-slate-400">{item.category}</span>
                    {isSelected && <ArrowRight className="w-3.5 h-3.5 text-teal-600 dark:text-teal-400" />}
                  </div>
                </button>
              );
            })
          )}
        </div>

        <div className="px-4 py-2 border-t border-slate-100 dark:border-slate-800/60 bg-slate-50/60 dark:bg-slate-900/60 flex items-center justify-between text-[11px] text-slate-400">
          <span>Navigate with <kbd className="px-1 py-0.5 border border-slate-300 dark:border-slate-700 rounded bg-white dark:bg-slate-800 text-[10px] font-mono">↑</kbd> <kbd className="px-1 py-0.5 border border-slate-300 dark:border-slate-700 rounded bg-white dark:bg-slate-800 text-[10px] font-mono">↓</kbd></span>
          <span>Press <kbd className="px-1 py-0.5 border border-slate-300 dark:border-slate-700 rounded bg-white dark:bg-slate-800 text-[10px] font-mono">ESC</kbd> to exit</span>
        </div>
      </div>
    </div>
  );
}
