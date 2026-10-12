import React, { useState } from 'react';
import { ResearchProject, ResearchStage, StageNote, Hypothesis, ExperimentPlan, ScientificPaper } from '../../types/research';
import { 
  FolderKanban, LayoutDashboard, Network, FlaskConical, 
  TestTube2, FileText, Bookmark, Plus, Edit3, Trash2, 
  ArrowUpRight, Clock, CheckCircle2, ChevronRight, X, AlertCircle, Sparkles
} from 'lucide-react';
import { ResearchTimeline } from '../timeline/ResearchTimeline';
import { useToast } from '../common/Toast';

interface WorkspaceProps {
  projects: ResearchProject[];
  activeProject: ResearchProject;
  onSelectProject: (id: string) => void;
  onSaveProject: (project: ResearchProject) => void;
  onDeleteProject: (id: string) => void;
  onNavigateTab: (tab: string) => void;
  hypotheses: Hypothesis[];
  experiments: ExperimentPlan[];
  papers: ScientificPaper[];
}

export function Workspace({
  projects,
  activeProject,
  onSelectProject,
  onSaveProject,
  onDeleteProject,
  onNavigateTab,
  hypotheses,
  experiments,
  papers
}: WorkspaceProps) {
  const { showToast } = useToast();
  const [sidebarTab, setSidebarTab] = useState<'overview' | 'projects'>('overview');
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [projectToDelete, setProjectToDelete] = useState<ResearchProject | null>(null);

  // Form states
  const [formTitle, setFormTitle] = useState('');
  const [formShortCode, setFormShortCode] = useState('');
  const [formDomain, setFormDomain] = useState('Molecular Oncology');
  const [formDescription, setFormDescription] = useState('');
  const [formStage, setFormStage] = useState<ResearchStage>('question');
  const [formTags, setFormTags] = useState('');

  const handleOpenCreate = () => {
    setFormTitle('');
    setFormShortCode(`PRJ-${Math.floor(100 + Math.random() * 900)}`);
    setFormDomain('Molecular Oncology');
    setFormDescription('');
    setFormStage('question');
    setFormTags('Oncology, Feedback Loop');
    setIsCreateModalOpen(true);
  };

  const handleOpenEdit = (project: ResearchProject) => {
    setFormTitle(project.title);
    setFormShortCode(project.shortCode);
    setFormDomain(project.domain);
    setFormDescription(project.description);
    setFormStage(project.currentStage);
    setFormTags(project.tags.join(', '));
    setIsEditModalOpen(true);
  };

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim()) {
      showToast({ type: 'warning', title: 'Title Required', message: 'Project title cannot be empty.' });
      return;
    }

    const defaultNotes: Record<ResearchStage, StageNote> = {
      question: {
        stage: 'question',
        status: formStage === 'question' ? 'active' : 'completed',
        summary: `Investigation objective: ${formDescription.slice(0, 100)}...`,
        keyQuestions: ['Define boundary conditions and key causal unknowns.'],
        lastUpdated: new Date().toISOString().split('T')[0]
      },
      literature: {
        stage: 'literature',
        status: formStage === 'literature' ? 'active' : 'upcoming',
        summary: 'Synthesize related literature from open scholarly databases.',
        keyQuestions: ['Identify consensus pathways and known effect sizes.'],
        lastUpdated: new Date().toISOString().split('T')[0]
      },
      hypothesis: {
        stage: 'hypothesis',
        status: formStage === 'hypothesis' ? 'active' : 'upcoming',
        summary: 'Formulate competing mechanistic models.',
        keyQuestions: ['Identify potential confounding assumptions.'],
        lastUpdated: new Date().toISOString().split('T')[0]
      },
      experiment: {
        stage: 'experiment',
        status: formStage === 'experiment' ? 'active' : 'upcoming',
        summary: 'Design statistical parameters and procedure protocols.',
        keyQuestions: ['Specify independent variables and measurement methods.'],
        lastUpdated: new Date().toISOString().split('T')[0]
      },
      results: {
        stage: 'results',
        status: formStage === 'results' ? 'active' : 'upcoming',
        summary: 'Evaluate findings against statistical success criteria.',
        keyQuestions: ['Confirm replication consistency (n ≥ 3).'],
        lastUpdated: new Date().toISOString().split('T')[0]
      }
    };

    const newProject: ResearchProject = {
      id: `proj-${Date.now()}`,
      title: formTitle.trim(),
      shortCode: formShortCode.trim() || `PRJ-${Math.floor(100 + Math.random() * 900)}`,
      description: formDescription.trim() || 'Custom scientific research project initialized in Research Nexus workspace.',
      domain: formDomain,
      currentStage: formStage,
      tags: formTags.split(',').map((t) => t.trim()).filter(Boolean),
      createdAt: new Date().toISOString().split('T')[0],
      updatedAt: new Date().toISOString().split('T')[0],
      stageNotes: defaultNotes,
      hypothesesCount: 0,
      papersCount: 0,
      experimentsCount: 0
    };

    onSaveProject(newProject);
    onSelectProject(newProject.id);
    setIsCreateModalOpen(false);
    showToast({
      type: 'success',
      title: 'Project Initialized',
      message: `Created "${newProject.title}"`
    });
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim()) return;

    const updated: ResearchProject = {
      ...activeProject,
      title: formTitle.trim(),
      shortCode: formShortCode.trim(),
      domain: formDomain,
      description: formDescription.trim(),
      currentStage: formStage,
      tags: formTags.split(',').map((t) => t.trim()).filter(Boolean),
      updatedAt: new Date().toISOString().split('T')[0]
    };

    onSaveProject(updated);
    setIsEditModalOpen(false);
    showToast({
      type: 'success',
      title: 'Project Updated',
      message: updated.title
    });
  };

  const handleConfirmDelete = () => {
    if (!projectToDelete) return;
    onDeleteProject(projectToDelete.id);
    setProjectToDelete(null);
    showToast({
      type: 'info',
      title: 'Project Deleted',
      message: 'Investigation record removed.'
    });
  };

  const handleStageChange = (newStage: ResearchStage) => {
    const updated = {
      ...activeProject,
      currentStage: newStage,
      updatedAt: new Date().toISOString().split('T')[0]
    };
    onSaveProject(updated);
    showToast({
      type: 'info',
      title: 'Active Stage Changed',
      message: `Shifted to ${newStage}`
    });
  };

  const handleUpdateStageNotes = (stage: ResearchStage, updatedNote: StageNote) => {
    const updated = {
      ...activeProject,
      stageNotes: {
        ...activeProject.stageNotes,
        [stage]: updatedNote
      },
      updatedAt: new Date().toISOString().split('T')[0]
    };
    onSaveProject(updated);
  };

  return (
    <div className="flex flex-col lg:flex-row gap-6 max-w-7xl mx-auto">
      {/* Compact Workspace Sidebar */}
      <aside className="w-full lg:w-64 shrink-0 space-y-4">
        {/* Project Selector Card */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-4 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase font-mono tracking-wider text-slate-400 font-semibold">
              Active Project
            </span>
            <button
              onClick={handleOpenCreate}
              className="p-1 text-teal-600 dark:text-teal-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded text-xs flex items-center gap-1 font-medium"
              title="Create New Project"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>New</span>
            </button>
          </div>

          <div className="space-y-1">
            <div className="flex items-center gap-2 font-mono text-[11px] text-teal-600 dark:text-teal-400 font-semibold">
              <span>{activeProject.shortCode}</span>
              <span className="text-slate-400">·</span>
              <span className="text-slate-500 capitalize">{activeProject.domain}</span>
            </div>
            <h2 className="text-xs font-bold text-slate-900 dark:text-slate-100 leading-snug">
              {activeProject.title}
            </h2>
          </div>

          <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-[11px]">
            <button
              onClick={() => handleOpenEdit(activeProject)}
              className="text-slate-500 hover:text-slate-900 dark:hover:text-slate-200 font-medium flex items-center gap-1"
            >
              <Edit3 className="w-3 h-3" />
              <span>Edit Title / Stage</span>
            </button>
            <span className="font-mono text-slate-400 text-[10px]">
              Stage: {activeProject.currentStage}
            </span>
          </div>
        </div>

        {/* Workspace Views Navigation */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-2 shadow-xs space-y-1">
          <span className="text-[10px] uppercase font-mono tracking-wider text-slate-400 px-3 py-1.5 block">
            Workspace Hub
          </span>

          <button
            onClick={() => setSidebarTab('overview')}
            className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
              sidebarTab === 'overview'
                ? 'bg-slate-100 dark:bg-slate-800 text-teal-600 dark:text-teal-400 font-semibold'
                : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50'
            }`}
          >
            <div className="flex items-center gap-2.5">
              <LayoutDashboard className="w-4 h-4" />
              <span>Overview & Progress</span>
            </div>
          </button>

          <button
            onClick={() => setSidebarTab('projects')}
            className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
              sidebarTab === 'projects'
                ? 'bg-slate-100 dark:bg-slate-800 text-teal-600 dark:text-teal-400 font-semibold'
                : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50'
            }`}
          >
            <div className="flex items-center gap-2.5">
              <FolderKanban className="w-4 h-4" />
              <span>All Research Projects</span>
            </div>
            <span className="font-mono text-[10px] text-slate-400 tabular-nums">
              {projects.length}
            </span>
          </button>

          <span className="text-[10px] uppercase font-mono tracking-wider text-slate-400 px-3 pt-3 pb-1 block">
            Research Modules
          </span>

          <button
            onClick={() => onNavigateTab('graph')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
          >
            <div className="flex items-center gap-2.5">
              <Network className="w-4 h-4 text-sky-500" />
              <span>Knowledge Graph</span>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => onNavigateTab('hypotheses')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
          >
            <div className="flex items-center gap-2.5">
              <FlaskConical className="w-4 h-4 text-teal-500" />
              <span>Hypothesis Lab</span>
            </div>
            <span className="font-mono text-[10px] text-slate-400 tabular-nums">
              {hypotheses.length}
            </span>
          </button>

          <button
            onClick={() => onNavigateTab('experiments')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
          >
            <div className="flex items-center gap-2.5">
              <TestTube2 className="w-4 h-4 text-amber-500" />
              <span>Experiment Designer</span>
            </div>
            <span className="font-mono text-[10px] text-slate-400 tabular-nums">
              {experiments.length}
            </span>
          </button>

          <button
            onClick={() => onNavigateTab('paper-analysis')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
          >
            <div className="flex items-center gap-2.5">
              <FileText className="w-4 h-4 text-indigo-500" />
              <span>Paper Analysis</span>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => onNavigateTab('saved-papers')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
          >
            <div className="flex items-center gap-2.5">
              <Bookmark className="w-4 h-4 text-rose-500" />
              <span>Saved Literature</span>
            </div>
            <span className="font-mono text-[10px] text-slate-400 tabular-nums">
              {papers.length}
            </span>
          </button>
        </div>
      </aside>

      {/* Main Workspace Stage */}
      <main className="flex-1 space-y-6 min-w-0">
        {sidebarTab === 'overview' ? (
          <>
            {/* Project Banner Card */}
            <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs">
              <div className="p-6 space-y-3">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="flex items-center gap-2 font-mono text-xs text-slate-500">
                    <span className="px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 font-semibold text-slate-800 dark:text-slate-200">
                      {activeProject.shortCode}
                    </span>
                    <span>·</span>
                    <span>{activeProject.domain}</span>
                    <span>·</span>
                    <span>Created {activeProject.createdAt}</span>
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="text-xs text-slate-400">Current Stage:</span>
                    <select
                      value={activeProject.currentStage}
                      onChange={(e) => handleStageChange(e.target.value as ResearchStage)}
                      className="px-2 py-1 text-xs font-semibold bg-stone-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded text-slate-800 dark:text-slate-200"
                    >
                      <option value="question">1. Question</option>
                      <option value="literature">2. Literature</option>
                      <option value="hypothesis">3. Hypothesis</option>
                      <option value="experiment">4. Experiment</option>
                      <option value="results">5. Results</option>
                    </select>
                  </div>
                </div>

                <h1 className="text-lg sm:text-xl font-bold text-slate-900 dark:text-slate-100 leading-snug">
                  {activeProject.title}
                </h1>

                <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
                  {activeProject.description}
                </p>

                {/* Tags */}
                <div className="flex flex-wrap items-center gap-2 pt-1 text-xs text-slate-500">
                  <span className="text-[11px] font-mono text-slate-400">Keywords:</span>
                  {activeProject.tags.map((tag, i) => (
                    <span key={i} className="text-[11px] text-slate-600 dark:text-slate-400 font-medium">
                      {tag}{i < activeProject.tags.length - 1 ? ' ·' : ''}
                    </span>
                  ))}
                </div>
              </div>

              {/* Quick Metrics Bar */}
              <div className="grid grid-cols-3 border-t border-slate-100 dark:border-slate-800 bg-stone-50/50 dark:bg-slate-950/40 text-center py-3 text-xs">
                <div>
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Hypotheses</span>
                  <span className="font-mono text-base font-bold text-slate-900 dark:text-slate-100 tabular-nums">
                    {hypotheses.length}
                  </span>
                </div>
                <div className="border-x border-slate-100 dark:border-slate-800">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Experiments</span>
                  <span className="font-mono text-base font-bold text-slate-900 dark:text-slate-100 tabular-nums">
                    {experiments.length}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Cited Literature</span>
                  <span className="font-mono text-base font-bold text-slate-900 dark:text-slate-100 tabular-nums">
                    {papers.length}
                  </span>
                </div>
              </div>
            </div>

            {/* Interactive Research Timeline Section */}
            <ResearchTimeline
              project={activeProject}
              onUpdateStageNotes={handleUpdateStageNotes}
            />

            {/* Quick Action Discovery Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div 
                onClick={() => onNavigateTab('graph')}
                className="p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-teal-500/50 cursor-pointer transition-all shadow-xs group"
              >
                <div className="flex items-center justify-between text-teal-600 dark:text-teal-400 mb-2">
                  <Network className="w-4 h-4" />
                  <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                </div>
                <h3 className="text-xs font-bold text-slate-900 dark:text-slate-100">
                  Interactive Knowledge Graph
                </h3>
                <p className="text-[11px] text-slate-500 mt-1 line-clamp-2">
                  Inspect molecular interactions, targets, compounds, and pathways.
                </p>
              </div>

              <div 
                onClick={() => onNavigateTab('hypotheses')}
                className="p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-teal-500/50 cursor-pointer transition-all shadow-xs group"
              >
                <div className="flex items-center justify-between text-indigo-600 dark:text-indigo-400 mb-2">
                  <FlaskConical className="w-4 h-4" />
                  <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                </div>
                <h3 className="text-xs font-bold text-slate-900 dark:text-slate-100">
                  Hypothesis Formulation
                </h3>
                <p className="text-[11px] text-slate-500 mt-1 line-clamp-2">
                  Compare supporting vs contradicting evidence balance sheets.
                </p>
              </div>

              <div 
                onClick={() => onNavigateTab('experiments')}
                className="p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-teal-500/50 cursor-pointer transition-all shadow-xs group"
              >
                <div className="flex items-center justify-between text-amber-600 dark:text-amber-400 mb-2">
                  <TestTube2 className="w-4 h-4" />
                  <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                </div>
                <h3 className="text-xs font-bold text-slate-900 dark:text-slate-100">
                  Experiment Protocol Designer
                </h3>
                <p className="text-[11px] text-slate-500 mt-1 line-clamp-2">
                  Structure independent, dependent, and controlled variables.
                </p>
              </div>
            </div>
          </>
        ) : (
          /* Projects Management Hub */
          <div className="space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div>
                <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">
                  Local Demonstration Projects
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Manage independent scientific investigations, change stages, or formulate new scopes.
                </p>
              </div>
              <button
                onClick={handleOpenCreate}
                className="px-3.5 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors flex items-center gap-1.5 shadow-xs"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Initialize Project</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {projects.map((proj) => {
                const isSelected = activeProject.id === proj.id;
                return (
                  <div
                    key={proj.id}
                    className={`bg-white dark:bg-slate-900 border rounded-xl p-5 space-y-3.5 shadow-xs transition-all ${
                      isSelected
                        ? 'border-teal-500 ring-1 ring-teal-500/30'
                        : 'border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                    }`}
                  >
                    <div className="flex items-center justify-between text-xs font-mono text-slate-500">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-teal-600 dark:text-teal-400">
                          {proj.shortCode}
                        </span>
                        <span>·</span>
                        <span>{proj.domain}</span>
                      </div>
                      <span className="capitalize px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-[10px] font-medium text-slate-700 dark:text-slate-300">
                        {proj.currentStage}
                      </span>
                    </div>

                    <h3 className="font-bold text-sm text-slate-900 dark:text-slate-100 line-clamp-2">
                      {proj.title}
                    </h3>

                    <p className="text-xs text-slate-600 dark:text-slate-400 line-clamp-2 leading-relaxed">
                      {proj.description}
                    </p>

                    <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        {isSelected ? (
                          <span className="text-teal-600 dark:text-teal-400 font-medium text-[11px] flex items-center gap-1">
                            <CheckCircle2 className="w-3 h-3" />
                            <span>Currently Active</span>
                          </span>
                        ) : (
                          <button
                            onClick={() => {
                              onSelectProject(proj.id);
                              showToast({
                                type: 'info',
                                title: 'Project Activated',
                                message: proj.title
                              });
                            }}
                            className="text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white font-medium"
                          >
                            Set as Active
                          </button>
                        )}
                      </div>

                      <div className="flex items-center gap-1.5">
                        <button
                          onClick={() => handleOpenEdit(proj)}
                          className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded"
                          title="Edit Project"
                        >
                          <Edit3 className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => setProjectToDelete(proj)}
                          className="p-1.5 text-rose-400 hover:text-rose-600 rounded"
                          title="Delete Project"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </main>

      {/* Modal: Initialize New Project */}
      {isCreateModalOpen && (
        <div 
          className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setIsCreateModalOpen(false)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-lg bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-xl overflow-hidden p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100">
                Initialize Research Project
              </h3>
              <button onClick={() => setIsCreateModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateSubmit} className="py-4 space-y-4 text-xs">
              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Project Title *
                </label>
                <input
                  type="text"
                  required
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="e.g., Targeted Degradation of Tau Oligomers via PROTACs"
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs focus:ring-1 focus:ring-teal-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                    Short Identifier
                  </label>
                  <input
                    type="text"
                    value={formShortCode}
                    onChange={(e) => setFormShortCode(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                    Scientific Domain
                  </label>
                  <select
                    value={formDomain}
                    onChange={(e) => setFormDomain(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs"
                  >
                    <option value="Molecular Oncology">Molecular Oncology</option>
                    <option value="Materials Science">Materials Science</option>
                    <option value="Neurobiology">Neurobiology</option>
                    <option value="Structural Biology">Structural Biology</option>
                    <option value="Genomics & Variants">Genomics & Variants</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Research Description & Scope
                </label>
                <textarea
                  rows={3}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="Summarize the core scientific problem, known mechanisms, and targets..."
                  className="w-full p-2.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs leading-relaxed"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Starting Workflow Stage
                </label>
                <select
                  value={formStage}
                  onChange={(e) => setFormStage(e.target.value as ResearchStage)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs"
                >
                  <option value="question">1. Research Question</option>
                  <option value="literature">2. Literature Review</option>
                  <option value="hypothesis">3. Hypothesis Formulation</option>
                  <option value="experiment">4. Experiment Execution</option>
                  <option value="results">5. Results & Evaluation</option>
                </select>
              </div>

              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setIsCreateModalOpen(false)}
                  className="px-3 py-1.5 text-xs text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 rounded-md"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md shadow-xs"
                >
                  Create Project
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Edit Existing Project */}
      {isEditModalOpen && (
        <div 
          className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setIsEditModalOpen(false)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-lg bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-xl overflow-hidden p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100">
                Edit Research Project
              </h3>
              <button onClick={() => setIsEditModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleEditSubmit} className="py-4 space-y-4 text-xs">
              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Project Title *
                </label>
                <input
                  type="text"
                  required
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                    Short Code
                  </label>
                  <input
                    type="text"
                    value={formShortCode}
                    onChange={(e) => setFormShortCode(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                    Research Stage
                  </label>
                  <select
                    value={formStage}
                    onChange={(e) => setFormStage(e.target.value as ResearchStage)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs"
                  >
                    <option value="question">1. Question</option>
                    <option value="literature">2. Literature</option>
                    <option value="hypothesis">3. Hypothesis</option>
                    <option value="experiment">4. Experiment</option>
                    <option value="results">5. Results</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Description
                </label>
                <textarea
                  rows={3}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs leading-relaxed"
                />
              </div>

              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-3 py-1.5 text-xs text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 rounded-md"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md shadow-xs"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Modal: Delete Project */}
      {projectToDelete && (
        <div 
          className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setProjectToDelete(null)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-md bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-xl p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 text-rose-600">
              <AlertCircle className="w-5 h-5 shrink-0" />
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                Confirm Project Deletion
              </h3>
            </div>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Are you sure you want to permanently delete <strong>"{projectToDelete.title}"</strong> ({projectToDelete.shortCode})? Associated demonstration stage records will be removed.
            </p>
            <div className="pt-2 flex justify-end gap-2.5">
              <button
                onClick={() => setProjectToDelete(null)}
                className="px-3 py-1.5 text-xs text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 rounded-md"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmDelete}
                className="px-4 py-1.5 text-xs font-semibold text-white bg-rose-600 hover:bg-rose-500 rounded-md shadow-xs"
              >
                Delete Project
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
