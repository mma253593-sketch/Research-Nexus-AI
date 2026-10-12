import { useState, useEffect } from 'react';
import { 
  getStoredProjects, saveStoredProjects,
  getStoredActiveProjectId, saveStoredActiveProjectId,
  getStoredPapers, saveStoredPapers,
  getStoredHypotheses, saveStoredHypotheses,
  getStoredExperiments, saveStoredExperiments,
  getStoredTheme, saveStoredTheme
} from './utils/storage';
import { ResearchProject, ScientificPaper, Hypothesis, ExperimentPlan, GraphNode } from './types/research';
import { ToastProvider, useToast } from './components/common/Toast';
import { Navbar } from './components/common/Navbar';
import { Footer } from './components/common/Footer';
import { CommandPalette } from './components/common/CommandPalette';
import { Homepage } from './components/home/Homepage';
import { Workspace } from './components/workspace/Workspace';
import { InteractiveKnowledgeGraph } from './components/graph/InteractiveKnowledgeGraph';
import { PaperAnalysis } from './components/paper/PaperAnalysis';
import { HypothesisLab } from './components/hypothesis/HypothesisLab';
import { ExperimentDesigner } from './components/experiment/ExperimentDesigner';
import { SavedPapers } from './components/library/SavedPapers';
import { NexCompanion } from './components/companion/NexCompanion';
import { LanguageProvider } from './context/LanguageContext';

export default function App() {
  return (
    <LanguageProvider>
      <ToastProvider>
        <MainApp />
      </ToastProvider>
    </LanguageProvider>
  );
}

function MainApp() {
  const { showToast } = useToast();

  // Navigation State
  const [currentView, setCurrentView] = useState<'home' | 'workspace' | 'graph' | 'hypotheses' | 'experiments' | 'paper-analysis' | 'saved-papers'>('home');
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false);

  // Companion Event State
  const [companionEvent, setCompanionEvent] = useState<{
    type: 'nav' | 'hypothesis_saved' | 'experiment_saved' | 'concept_selected';
    payload?: string;
  } | null>(null);

  // Theme State
  const [theme, setTheme] = useState<'light' | 'dark'>(() => getStoredTheme());

  // Data State
  const [projects, setProjects] = useState<ResearchProject[]>(() => getStoredProjects());
  const [activeProjectId, setActiveProjectId] = useState<string>(() => getStoredActiveProjectId());
  const [papers, setPapers] = useState<ScientificPaper[]>(() => getStoredPapers());
  const [hypotheses, setHypotheses] = useState<Hypothesis[]>(() => getStoredHypotheses());
  const [experiments, setExperiments] = useState<ExperimentPlan[]>(() => getStoredExperiments());

  // Bridging State
  const [graphSelectedNodeId, setGraphSelectedNodeId] = useState<string | null>(null);
  const [hypothesisToExperimentTitle, setHypothesisToExperimentTitle] = useState<string | undefined>(undefined);

  // Sync theme with document
  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    saveStoredTheme(theme);
  }, [theme]);

  // Keyboard shortcut for Command Palette
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsCommandPaletteOpen((prev) => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleToggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
  };

  const navigateTo = (view: any) => {
    setCurrentView(view);
    setCompanionEvent({ type: 'nav', payload: view });
  };

  // Active Project
  const activeProject = projects.find((p) => p.id === activeProjectId) || projects[0] || {
    id: 'proj-kras-01',
    title: 'Targeting KRAS G12D Resistance in Pancreatic Ductal Adenocarcinoma',
    shortCode: 'ONC-702',
    description: 'Investigating adaptive receptor tyrosine kinase (RTK) feedback loops following allosteric inhibition of KRAS G12D with MRTX1133.',
    domain: 'Molecular Oncology',
    currentStage: 'hypothesis',
    tags: ['KRAS G12D', 'RTK Feedback', 'SOS1'],
    createdAt: '2026-08-14',
    updatedAt: '2026-10-09',
    stageNotes: {} as any,
    hypothesesCount: 3,
    papersCount: 8,
    experimentsCount: 2
  };

  // Handlers for Projects
  const handleSelectProject = (id: string) => {
    setActiveProjectId(id);
    saveStoredActiveProjectId(id);
  };

  const handleSaveProject = (updated: ResearchProject) => {
    setProjects((prev) => {
      const exists = prev.some((p) => p.id === updated.id);
      const next = exists ? prev.map((p) => (p.id === updated.id ? updated : p)) : [updated, ...prev];
      saveStoredProjects(next);
      return next;
    });
  };

  const handleDeleteProject = (id: string) => {
    setProjects((prev) => {
      const next = prev.filter((p) => p.id !== id);
      saveStoredProjects(next);
      if (activeProjectId === id && next.length > 0) {
        setActiveProjectId(next[0].id);
        saveStoredActiveProjectId(next[0].id);
      }
      return next;
    });
  };

  // Handlers for Hypotheses
  const handleSaveHypothesis = (hypo: Hypothesis) => {
    setHypotheses((prev) => {
      const exists = prev.some((h) => h.id === hypo.id);
      const next = exists ? prev.map((h) => (h.id === hypo.id ? hypo : h)) : [hypo, ...prev];
      saveStoredHypotheses(next);
      return next;
    });
    setCompanionEvent({ type: 'hypothesis_saved', payload: hypo.title });
  };

  const handleDeleteHypothesis = (id: string) => {
    setHypotheses((prev) => {
      const next = prev.filter((h) => h.id !== id);
      saveStoredHypotheses(next);
      return next;
    });
  };

  // Handlers for Experiments
  const handleSaveExperiment = (exp: ExperimentPlan) => {
    setExperiments((prev) => {
      const exists = prev.some((e) => e.id === exp.id);
      const next = exists ? prev.map((e) => (e.id === exp.id ? exp : e)) : [exp, ...prev];
      saveStoredExperiments(next);
      return next;
    });
    setCompanionEvent({ type: 'experiment_saved', payload: exp.title });
  };

  // Handlers for Papers
  const handleSavePaper = (paper: ScientificPaper) => {
    setPapers((prev) => {
      const exists = prev.some((p) => p.id === paper.id);
      if (exists) return prev;
      const next = [paper, ...prev];
      saveStoredPapers(next);
      return next;
    });
    showToast({
      type: 'success',
      title: 'Saved to Library',
      message: `"${paper.title.slice(0, 48)}..."`
    });
  };

  const handleDeletePaper = (id: string) => {
    setPapers((prev) => {
      const next = prev.filter((p) => p.id !== id);
      saveStoredPapers(next);
      return next;
    });
    showToast({
      type: 'info',
      title: 'Paper Removed',
      message: 'Article removed from local library.'
    });
  };

  // Cross-Navigation Bridges
  const handleStartResearching = (initialQuery?: string) => {
    if (initialQuery) {
      const q = initialQuery.toLowerCase();
      let matchedProj = projects.find(p => 
        p.title.toLowerCase().includes(q) || 
        p.tags.some(t => q.includes(t.toLowerCase())) ||
        q.includes(p.domain.toLowerCase())
      );

      if (!matchedProj) {
        if (q.includes('perovskite') || q.includes('solar') || q.includes('tandem') || q.includes('halide')) {
          matchedProj = projects.find(p => p.id === 'proj-perov-02');
        } else if (q.includes('synap') || q.includes('tau') || q.includes('pruning') || q.includes('microgli') || q.includes('c1q')) {
          matchedProj = projects.find(p => p.id === 'proj-neuro-03');
        } else if (q.includes('kras') || q.includes('rtk') || q.includes('pdac') || q.includes('oncolog') || q.includes('sos1')) {
          matchedProj = projects.find(p => p.id === 'proj-kras-01');
        }
      }

      if (matchedProj) {
        handleSelectProject(matchedProj.id);
      }

      showToast({
        type: 'info',
        title: 'Research Focus Activated',
        message: matchedProj ? `Focused on ${matchedProj.shortCode}: ${matchedProj.title.slice(0, 42)}...` : initialQuery
      });
    }
    navigateTo('workspace');
  };

  const handleExploreKnowledge = () => {
    navigateTo('graph');
  };

  const handleConceptToHypothesis = (node: GraphNode) => {
    setCompanionEvent({ type: 'concept_selected', payload: node.label });
    navigateTo('hypotheses');
    showToast({
      type: 'info',
      title: 'Concept Selected for Hypothesis',
      message: `Formulating hypothesis around ${node.label} (${node.category})`
    });
  };

  const handleDesignExperimentForHypothesis = (hypo: Hypothesis) => {
    setHypothesisToExperimentTitle(hypo.title);
    navigateTo('experiments');
    showToast({
      type: 'info',
      title: 'Hypothesis Bridged to Protocol',
      message: `Designing empirical assay for: ${hypo.title.slice(0, 40)}...`
    });
  };

  const handlePaperToHypothesis = (paper: ScientificPaper) => {
    navigateTo('hypotheses');
    showToast({
      type: 'info',
      title: 'Paper Findings Bridged',
      message: `Deconstructing findings from ${paper.authors[0] || 'study'} into hypothesis`
    });
  };

  const handlePaperOpenAnalysis = (paper: ScientificPaper) => {
    navigateTo('paper-analysis');
  };

  return (
    <div className="min-h-screen flex flex-col bg-[#FAF7F2] dark:bg-[#0D1217] text-[#1F2421] dark:text-[#E8ECE9] transition-colors">
      {/* Strict 3-Zone Navigation Header */}
      <Navbar
        currentView={currentView}
        onNavigate={navigateTo}
        theme={theme}
        onToggleTheme={handleToggleTheme}
        onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
      />

      {/* Main Content Area */}
      <div className="flex-1 px-4 sm:px-6 lg:px-8 py-6">
        {currentView === 'home' && (
          <Homepage
            onStartResearching={handleStartResearching}
            onExploreKnowledge={handleExploreKnowledge}
            onSelectProject={handleSelectProject}
            projects={projects}
          />
        )}

        {currentView === 'workspace' && (
          <Workspace
            projects={projects}
            activeProject={activeProject}
            onSelectProject={handleSelectProject}
            onSaveProject={handleSaveProject}
            onDeleteProject={handleDeleteProject}
            onNavigateTab={navigateTo}
            hypotheses={hypotheses}
            experiments={experiments}
            papers={papers}
          />
        )}

        {currentView === 'graph' && (
          <div className="space-y-4 max-w-7xl mx-auto">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-3 border-b border-stone-300 dark:border-stone-800">
              <div>
                <span className="text-[11px] font-mono uppercase tracking-widest text-[#B45309] dark:text-[#F59E0B] font-medium">
                  Relational Network Engine · Causal Pathways
                </span>
                <h1 className="text-2xl font-serif font-normal tracking-tight text-[#143628] dark:text-[#FAF7F2] mt-0.5">
                  Interactive Scientific Knowledge Graph
                </h1>
                <p className="text-xs text-stone-600 dark:text-stone-400 mt-1">
                  Explore causal mechanisms, molecular targets, compounds, and verified pathway relationships.
                </p>
              </div>
              <span className="text-[11px] font-mono text-stone-500 dark:text-stone-400">
                Drag nodes to reposition · Pan and zoom · Click for evidence inspection
              </span>
            </div>

            <InteractiveKnowledgeGraph
              onSelectConceptForHypothesis={handleConceptToHypothesis}
              initialSelectedNodeId={graphSelectedNodeId}
            />
          </div>
        )}

        {currentView === 'hypotheses' && (
          <HypothesisLab
            hypotheses={hypotheses}
            onSaveHypothesis={handleSaveHypothesis}
            onDeleteHypothesis={handleDeleteHypothesis}
            onDesignExperimentForHypothesis={handleDesignExperimentForHypothesis}
            activeProjectId={activeProject.id}
          />
        )}

        {currentView === 'experiments' && (
          <ExperimentDesigner
            experiments={experiments}
            onSaveExperiment={handleSaveExperiment}
            activeProjectId={activeProject.id}
            initialHypothesisTitle={hypothesisToExperimentTitle}
          />
        )}

        {currentView === 'paper-analysis' && (
          <PaperAnalysis
            onSendToHypothesis={handlePaperToHypothesis}
            onSaveToLibrary={handleSavePaper}
          />
        )}

        {currentView === 'saved-papers' && (
          <SavedPapers
            papers={papers}
            onOpenAnalysis={handlePaperOpenAnalysis}
            onDeletePaper={handleDeletePaper}
          />
        )}
      </div>

      {/* NEX — Your Research Companion (Interactive 3D-style mascot) */}
      <NexCompanion
        context={{
          currentView,
          activeProjectTitle: activeProject.title,
          activeProjectShortCode: activeProject.shortCode,
          activeProjectDomain: activeProject.domain,
          currentStage: activeProject.currentStage,
          selectedConcept: graphSelectedNodeId || undefined,
          hypothesesCount: hypotheses.length,
          experimentsCount: experiments.length
        }}
        onNavigateView={navigateTo}
        appEvent={companionEvent}
      />

      {/* Global Command Palette */}
      <CommandPalette
        isOpen={isCommandPaletteOpen}
        onClose={() => setIsCommandPaletteOpen(false)}
        onNavigate={navigateTo}
        theme={theme}
        onToggleTheme={handleToggleTheme}
        onSelectConcept={(conceptId) => {
          setGraphSelectedNodeId(conceptId);
          navigateTo('graph');
        }}
      />

      {/* Clean Scientific Footer */}
      <Footer />
    </div>
  );
}
