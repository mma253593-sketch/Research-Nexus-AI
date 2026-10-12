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
    <header className="sticky top-0 z-40 bg-white/95 dark:bg-slate-950/95 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 transition-colors">
      <div className="max-w-7xl mx-auto flex items-center justify-between gap-8 px-4 sm:px-6 lg:px-8 h-14">
        {/* Zone 1: Brand Wordmark (Single text element) */}
        <button
          onClick={() => {
            onNavigate('home');
            setMobileMenuOpen(false);
          }}
          className="text-base sm:text-lg font-bold tracking-tight text-slate-900 dark:text-slate-100 whitespace-nowrap shrink-0 hover:text-teal-600 dark:hover:text-teal-400 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 rounded"
        >
          Research Nexus AI
        </button>

        {/* Zone 2: 4-5 single-line clean navigation links */}
        <nav className="hidden lg:flex items-center gap-7 text-xs font-medium text-slate-600 dark:text-slate-300">
          {navLinks.map((link) => {
            const isActive = currentView === link.id;
            return (
              <button
                key={link.id}
                onClick={() => onNavigate(link.id)}
                className={`transition-colors whitespace-nowrap shrink-0 py-1 border-b-2 ${
                  isActive
                    ? 'text-teal-600 dark:text-teal-400 border-teal-600 dark:border-teal-400 font-semibold'
                    : 'text-slate-600 dark:text-slate-300 border-transparent hover:text-slate-900 dark:hover:text-white'
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
            className="hidden sm:flex items-center gap-2 px-2.5 py-1.5 text-xs text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:border-slate-300 dark:hover:border-slate-700 transition-colors"
            aria-label="Open Command Search"
          >
            <Search className="w-3.5 h-3.5" />
            <span className="font-mono text-[11px] text-slate-400">⌘K</span>
          </button>

          <button
            onClick={onToggleTheme}
            className="p-1.5 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white rounded-md border border-transparent hover:border-slate-200 dark:hover:border-slate-800 transition-colors"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>

          {currentView === 'home' ? (
            <button
              onClick={() => onNavigate('workspace')}
              className="px-3.5 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors whitespace-nowrap shrink-0 shadow-xs flex items-center gap-1.5"
            >
              <span>Launch Workspace</span>
              <ArrowUpRight className="w-3.5 h-3.5 opacity-80" />
            </button>
          ) : (
            <button
              onClick={() => onNavigate('home')}
              className="px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-900 transition-colors whitespace-nowrap shrink-0"
            >
              Overview
            </button>
          )}

          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden p-1.5 text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white rounded-md border border-slate-200 dark:border-slate-800"
            aria-label="Toggle navigation menu"
          >
            {mobileMenuOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="lg:hidden border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 px-4 py-3 space-y-1">
          {navLinks.map((link) => (
            <button
              key={link.id}
              onClick={() => {
                onNavigate(link.id);
                setMobileMenuOpen(false);
              }}
              className={`w-full text-left px-3 py-2 text-xs font-medium rounded-md transition-colors ${
                currentView === link.id
                  ? 'bg-slate-100 dark:bg-slate-900 text-teal-600 dark:text-teal-400 font-semibold'
                  : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-900'
              }`}
            >
              {link.label}
            </button>
          ))}
          <div className="pt-2 border-t border-slate-100 dark:border-slate-900 flex justify-between items-center px-3">
            <span className="text-[11px] text-slate-400">Search shortcuts</span>
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                onOpenCommandPalette();
              }}
              className="text-xs text-teal-600 dark:text-teal-400 font-medium"
            >
              Open Command Palette
            </button>
          </div>
        </div>
      )}
    </header>
  );
}
