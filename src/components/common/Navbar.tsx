import { Search, Sun, Moon, Menu, X, ArrowUpRight } from 'lucide-react';
import { useState } from 'react';

interface NavbarProps {
  currentView: string;
  onNavigate: (view: string, subTab?: string) => void;
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
  onOpenCommandPalette: () => void;
}

export function Navbar({
  currentView,
  onNavigate,
  theme,
  onToggleTheme,
  onOpenCommandPalette
}: NavbarProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navLinks = [
    { id: 'workspace', label: 'Workspace' },
    { id: 'graph', label: 'Knowledge Graph' },
    { id: 'hypotheses', label: 'Hypothesis Lab' },
    { id: 'experiments', label: 'Experiment Designer' },
    { id: 'paper-analysis', label: 'Paper Analysis' }
  ];

  return (
    <header className="sticky top-0 z-40 bg-[#FAF7F2]/95 dark:bg-[#11161B]/95 backdrop-blur-md border-b border-stone-300 dark:border-stone-800 transition-colors">
      <div className="max-w-7xl mx-auto flex items-center justify-between gap-8 px-4 sm:px-6 lg:px-8 h-15">
        {/* Zone 1: Brand Wordmark (Single text element) */}
        <button
          onClick={() => {
            onNavigate('home');
            setMobileMenuOpen(false);
          }}
          className="text-base sm:text-lg font-serif font-semibold tracking-tight text-[#143628] dark:text-[#FAF7F2] whitespace-nowrap shrink-0 hover:text-[#1B4332] dark:hover:text-[#52B788] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#1B4332] rounded-xs cursor-pointer flex items-center gap-2"
        >
          <span className="w-2.5 h-2.5 rounded-full bg-[#1B4332] dark:bg-[#52B788] inline-block" />
          <span>Research Nexus AI</span>
        </button>

        {/* Zone 2: 4-5 single-line clean navigation links */}
        <nav className="hidden lg:flex items-center gap-7 text-xs font-medium text-stone-600 dark:text-stone-300">
          {navLinks.map((link) => {
            const isActive = currentView === link.id;
            return (
              <button
                key={link.id}
                onClick={() => onNavigate(link.id)}
                className={`transition-colors whitespace-nowrap shrink-0 py-1 border-b-2 cursor-pointer ${
                  isActive
                    ? 'text-[#1B4332] dark:text-[#52B788] border-[#1B4332] dark:border-[#52B788] font-semibold'
                    : 'text-stone-600 dark:text-stone-400 border-transparent hover:text-stone-900 dark:hover:text-stone-100'
                }`}
              >
                {link.label}
              </button>
            );
          })}
        </nav>

        {/* Zone 3: 1 Primary Action + Quick Utilities */}
        <div className="flex items-center gap-2.5 shrink-0">
          <button
            onClick={onOpenCommandPalette}
            className="hidden sm:flex items-center gap-2 px-2.5 py-1.5 text-xs text-stone-500 dark:text-stone-400 bg-white/70 dark:bg-stone-900 border border-stone-200 dark:border-stone-800 rounded-xs hover:border-stone-400 dark:hover:border-stone-700 transition-colors cursor-pointer"
            aria-label="Open Command Search"
          >
            <Search className="w-3.5 h-3.5 stroke-[1.75]" />
            <span className="font-mono text-[11px] text-stone-400">⌘K</span>
          </button>

          <button
            onClick={onToggleTheme}
            className="p-1.5 text-stone-500 dark:text-stone-400 hover:text-stone-900 dark:hover:text-white rounded-xs border border-transparent hover:border-stone-200 dark:hover:border-stone-800 transition-colors cursor-pointer"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {theme === 'dark' ? <Sun className="w-4 h-4 stroke-[1.75]" /> : <Moon className="w-4 h-4 stroke-[1.75]" />}
          </button>

          {currentView === 'home' ? (
            <button
              onClick={() => onNavigate('workspace')}
              className="px-3.5 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors whitespace-nowrap shrink-0 shadow-xs flex items-center gap-1.5 cursor-pointer"
            >
              <span>Workspace</span>
              <ArrowUpRight className="w-3.5 h-3.5 opacity-80" />
            </button>
          ) : (
            <button
              onClick={() => onNavigate('home')}
              className="px-3 py-1.5 text-xs font-medium text-stone-700 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-100 dark:hover:bg-stone-900 transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              Overview
            </button>
          )}

          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden p-1.5 text-stone-600 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white rounded-xs border border-stone-300 dark:border-stone-700 cursor-pointer"
            aria-label="Toggle navigation menu"
          >
            {mobileMenuOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Mobile Navigation Drawer */}
      {mobileMenuOpen && (
        <div className="lg:hidden border-t border-stone-200 dark:border-stone-800 bg-[#FAF7F2] dark:bg-[#11161B] px-4 py-3 space-y-1">
          {navLinks.map((link) => (
            <button
              key={link.id}
              onClick={() => {
                onNavigate(link.id);
                setMobileMenuOpen(false);
              }}
              className={`w-full text-left px-3 py-2 text-xs font-medium rounded-xs transition-colors cursor-pointer ${
                currentView === link.id
                  ? 'bg-stone-200/70 dark:bg-stone-800 text-[#1B4332] dark:text-[#52B788] font-semibold'
                  : 'text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-900'
              }`}
            >
              {link.label}
            </button>
          ))}
          <div className="pt-2 border-t border-stone-200 dark:border-stone-800 flex justify-between items-center px-3">
            <span className="text-[11px] text-stone-400 font-mono">Quick Search</span>
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                onOpenCommandPalette();
              }}
              className="text-xs text-[#1B4332] dark:text-[#52B788] font-medium cursor-pointer"
            >
              Open Command Palette (⌘K)
            </button>
          </div>
        </div>
      )}
    </header>
  );
}
