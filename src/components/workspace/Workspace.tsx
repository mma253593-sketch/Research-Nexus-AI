import React, { useState } from 'react';
import { ResearchProject, ResearchStage, StageNote, Hypothesis, ExperimentPlan, ScientificPaper } from '../../types/research';
import { 
  FolderKanban, LayoutDashboard, Network, FlaskConical, 
  TestTube2, FileText, Bookmark, Plus, Edit3, Trash2, 
  ArrowUpRight, Clock, CheckCircle2, ChevronRight, X, AlertCircle, Sparkles
} from 'lucide-react';
import { ResearchTimeline } from '../timeline/ResearchTimeline';
import { useToast } from '../common/Toast';
import { ScientificImage } from '../common/ScientificImage';

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
        <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm p-4 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase font-mono tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
              Active Project
            </span>
            <button
              onClick={handleOpenCreate}
              className="px-2 py-0.5 text-[#1B4332] dark:text-[#52B788] hover:bg-stone-100 dark:hover:bg-stone-800 rounded-xs text-xs flex items-center gap-1 font-semibold transition-colors cursor-pointer"
              title="Create New Project"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>New</span>
            </button>
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center gap-2 font-mono text-[11px] text-[#1B4332] dark:text-[#52B788] font-semibold">
              <span>{activeProject.shortCode}</span>
              <span className="text-stone-300 dark:text-stone-700">·</span>
              <span className="text-stone-600 dark:text-stone-400 capitalize">{activeProject.domain}</span>
            </div>
            <h2 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2] leading-snug line-clamp-2">
              {activeProject.title}
            </h2>
          </div>

          <div className="pt-2.5 border-t border-stone-200 dark:border-stone-800 flex items-center justify-between text-[11px]">
            <button
              onClick={() => handleOpenEdit(activeProject)}
              className="text-stone-600 dark:text-stone-400 hover:text-[#143628] dark:hover:text-stone-200 font-medium flex items-center gap-1 cursor-pointer transition-colors"
            >
              <Edit3 className="w-3 h-3" />
              <span>Edit Details</span>
            </button>
            <span className="font-mono text-stone-500 dark:text-stone-400 text-[10px] uppercase">
              {activeProject.currentStage}
            </span>
          </div>
        </div>

        {/* Workspace Views Navigation */}
        <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm p-2 shadow-xs space-y-1">
          <span className="text-[10px] uppercase font-mono tracking-widest text-stone-400 px-3 py-1.5 block font-semibold">
            Workspace Hub
          </span>

          <button
            onClick={() => setSidebarTab('overview')}
            className={`w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs font-medium transition-colors cursor-pointer ${
              sidebarTab === 'overview'
                ? 'bg-[#1B4332]/10 dark:bg-[#52B788]/15 text-[#143628] dark:text-[#52B788] font-semibold'
                : 'text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60'
            }`}
          >
            <div className="flex items-center gap-2.5">
              <LayoutDashboard className="w-4 h-4 stroke-[1.75]" />
              <span>Overview & Progress</span>
            </div>
          </button>

          <button
            onClick={() => setSidebarTab('projects')}
            className={`w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs font-medium transition-colors cursor-pointer ${
              sidebarTab === 'projects'
                ? 'bg-[#1B4332]/10 dark:bg-[#52B788]/15 text-[#143628] dark:text-[#52B788] font-semibold'
                : 'text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60'
            }`}
          >
            <div className="flex items-center gap-2.5">
              <FolderKanban className="w-4 h-4 stroke-[1.75]" />
              <span>All Research Projects</span>
            </div>
            <span className="font-mono text-[10px] text-stone-400 tabular-nums">
              {projects.length}
            </span>
          </button>

          <span className="text-[10px] uppercase font-mono tracking-widest text-stone-400 px-3 pt-3 pb-1 block font-semibold">
            Research Modules
          </span>

          <button
            onClick={() => onNavigateTab('graph')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <Network className="w-4 h-4 text-[#1B4332] dark:text-[#52B788] stroke-[1.75]" />
              <span>Knowledge Graph</span>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-stone-400" />
          </button>

          <button
            onClick={() => onNavigateTab('hypotheses')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <FlaskConical className="w-4 h-4 text-[#B45309] dark:text-[#F59E0B] stroke-[1.75]" />
              <span>Hypothesis Lab</span>
            </div>
            <span className="font-mono text-[10px] text-stone-400 tabular-nums">
              {hypotheses.length}
            </span>
          </button>

          <button
            onClick={() => onNavigateTab('experiments')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <TestTube2 className="w-4 h-4 text-[#1D4ED8] dark:text-[#60A5FA] stroke-[1.75]" />
              <span>Experiment Designer</span>
            </div>
            <span className="font-mono text-[10px] text-stone-400 tabular-nums">
              {experiments.length}
            </span>
          </button>

          <button
            onClick={() => onNavigateTab('paper-analysis')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <FileText className="w-4 h-4 text-stone-600 dark:text-stone-300 stroke-[1.75]" />
              <span>Paper Analysis</span>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-stone-400" />
          </button>

          <button
            onClick={() => onNavigateTab('saved-papers')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xs text-xs text-stone-600 dark:text-stone-400 hover:bg-stone-100 dark:hover:bg-stone-800/60 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <Bookmark className="w-4 h-4 text-[#991B1B] dark:text-[#F87171] stroke-[1.75]" />
              <span>Saved Literature</span>
            </div>
            <span className="font-mono text-[10px] text-stone-400 tabular-nums">
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
            <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm overflow-hidden shadow-xs">
              <div className="p-6 space-y-3.5">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="flex items-center gap-2 font-mono text-xs text-stone-500">
                    <span className="px-2 py-0.5 rounded-xs bg-stone-100 dark:bg-stone-800 font-semibold text-[#143628] dark:text-[#52B788] border border-stone-200 dark:border-stone-700">
                      {activeProject.shortCode}
                    </span>
                    <span>·</span>
                    <span className="font-medium text-stone-700 dark:text-stone-300">{activeProject.domain}</span>
                    <span>·</span>
                    <span>Registered {activeProject.createdAt}</span>
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="text-xs font-mono text-stone-500">Workflow Stage:</span>
                    <select
                      value={activeProject.currentStage}
                      onChange={(e) => handleStageChange(e.target.value as ResearchStage)}
                      className="px-2.5 py-1 text-xs font-semibold bg-stone-50 dark:bg-[#161C22] border border-stone-300 dark:border-stone-700 rounded-xs text-[#143628] dark:text-[#52B788] focus:outline-none focus:ring-1 focus:ring-[#1B4332]"
                    >
                      <option value="question">1. Question</option>
                      <option value="literature">2. Literature</option>
                      <option value="hypothesis">3. Hypothesis</option>
                      <option value="experiment">4. Experiment</option>
                      <option value="results">5. Results</option>
                    </select>
                  </div>
                </div>

                <h1 className="font-serif text-xl sm:text-2xl font-normal text-[#143628] dark:text-[#FAF7F2] leading-snug">
                  {activeProject.title}
                </h1>

                <p className="text-xs sm:text-sm text-stone-600 dark:text-stone-300 leading-relaxed font-sans max-w-4xl">
                  {activeProject.description}
                </p>

                {/* Tags */}
                <div className="flex flex-wrap items-center gap-2 pt-1 text-xs text-stone-500">
                  <span className="text-[11px] font-mono text-stone-400 uppercase tracking-wider">Descriptors:</span>
                  {activeProject.tags.map((tag, i) => (
                    <span key={i} className="text-[11px] font-mono text-stone-700 dark:text-stone-300 bg-stone-100 dark:bg-stone-800 px-2 py-0.5 rounded-xs">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>

              {/* Quick Metrics Bar */}
              <div className="grid grid-cols-3 border-t border-stone-200 dark:border-stone-800 bg-stone-50/70 dark:bg-[#11161B] text-center py-3.5 text-xs">
                <div>
                  <span className="text-[10px] text-stone-400 font-mono uppercase tracking-widest block font-medium">Hypotheses</span>
                  <span className="font-mono text-lg font-bold text-[#143628] dark:text-[#FAF7F2] tabular-nums">
                    {hypotheses.length}
                  </span>
                </div>
                <div className="border-x border-stone-200 dark:border-stone-800">
                  <span className="text-[10px] text-stone-400 font-mono uppercase tracking-widest block font-medium">Protocols</span>
                  <span className="font-mono text-lg font-bold text-[#143628] dark:text-[#FAF7F2] tabular-nums">
                    {experiments.length}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] text-stone-400 font-mono uppercase tracking-widest block font-medium">Primary Literature</span>
                  <span className="font-mono text-lg font-bold text-[#143628] dark:text-[#FAF7F2] tabular-nums">
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
                className="p-4 bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm hover:border-[#1B4332] dark:hover:border-[#52B788] cursor-pointer transition-all shadow-xs group"
              >
                <div className="flex items-center justify-between text-[#1B4332] dark:text-[#52B788] mb-2">
                  <Network className="w-4 h-4 stroke-[1.75]" />
                  <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                </div>
                <h3 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
                  Knowledge Graph
                </h3>
                <p className="text-[11px] text-stone-600 dark:text-stone-400 mt-1 line-clamp-2 leading-relaxed">
                  Inspect molecular interactions, targets, compounds, and pathways.
                </p>
              </div>

              <div 
                onClick={() => onNavigateTab('hypotheses')}
                className="p-4 bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm hover:border-[#B45309] dark:hover:border-[#F59E0B] cursor-pointer transition-all shadow-xs group"
              >
                <div className="flex items-center justify-between text-[#B45309] dark:text-[#F59E0B] mb-2">
                  <FlaskConical className="w-4 h-4 stroke-[1.75]" />
                  <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                </div>
                <h3 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
                  Hypothesis Formulation
                </h3>
                <p className="text-[11px] text-stone-600 dark:text-stone-400 mt-1 line-clamp-2 leading-relaxed">
                  Compare supporting vs contradicting evidence balance sheets.
                </p>
              </div>

              <div 
                onClick={() => onNavigateTab('experiments')}
                className="p-4 bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm hover:border-[#1D4ED8] dark:hover:border-[#60A5FA] cursor-pointer transition-all shadow-xs group"
              >
                <div className="flex items-center justify-between text-[#1D4ED8] dark:text-[#60A5FA] mb-2">
                  <TestTube2 className="w-4 h-4 stroke-[1.75]" />
                  <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                </div>
                <h3 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
                  Protocol Designer
                </h3>
                <p className="text-[11px] text-stone-600 dark:text-stone-400 mt-1 line-clamp-2 leading-relaxed">
                  Structure independent, dependent, and controlled variables.
                </p>
              </div>
            </div>
          </>
        ) : (
          /* Projects Management Hub */
          <div className="space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-stone-300 dark:border-stone-800">
              <div>
                <h2 className="font-serif text-lg font-normal text-[#143628] dark:text-[#FAF7F2]">
                  Local Research Projects
                </h2>
                <p className="text-xs text-stone-600 dark:text-stone-400 mt-0.5">
                  Manage independent scientific investigations, change stages, or formulate new scopes.
                </p>
              </div>
              <button
                onClick={handleOpenCreate}
                className="px-3.5 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors flex items-center gap-1.5 shadow-xs cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Initialize Project</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {projects.map((proj) => {
                const isSelected = activeProject.id === proj.id;
                return (
                  <div
                    key={proj.id}
                    className={`bg-white dark:bg-[#161C22] border rounded-xs overflow-hidden shadow-xs transition-all flex flex-col justify-between ${
                      isSelected
                        ? 'border-[#1B4332] dark:border-[#52B788] ring-1 ring-[#1B4332]/30'
                        : 'border-stone-200 dark:border-stone-800 hover:border-stone-400 dark:hover:border-stone-700'
                    }`}
                  >
                    <div>
                      {proj.image && (
                        <div className="relative border-b border-stone-200 dark:border-stone-800">
                          <ScientificImage
                            src={proj.image}
                            alt={proj.title}
                            aspectRatioClass="aspect-16/9"
                            className="w-full h-full object-cover"
                          />
                          <div className="absolute top-2 left-2 px-2 py-0.5 rounded-xs bg-[#0F1E2E]/90 text-[10px] font-mono text-white font-medium border border-stone-600/40">
                            {proj.shortCode}
                          </div>
                        </div>
                      )}

                      <div className="p-4 space-y-2">
                        <div className="flex items-center justify-between text-xs font-mono text-stone-500">
                          <span className="font-semibold text-[#1B4332] dark:text-[#52B788]">
                            {proj.domain}
                          </span>
                          <span className="capitalize px-2 py-0.5 rounded-xs bg-stone-100 dark:bg-stone-800 text-[10px] font-medium text-stone-700 dark:text-stone-300">
                            Stage: {proj.currentStage}
                          </span>
                        </div>

                        <h3 className="font-serif text-sm font-semibold text-stone-900 dark:text-stone-100 line-clamp-2">
                          {proj.title}
                        </h3>

                        <p className="text-xs text-stone-600 dark:text-stone-400 line-clamp-2 leading-relaxed font-sans">
                          {proj.description}
                        </p>
                      </div>
                    </div>

                    <div className="p-4 pt-0">
                      <div className="pt-2.5 border-t border-stone-100 dark:border-stone-800 flex items-center justify-between text-xs">
                        <div className="flex items-center gap-2">
                          {isSelected ? (
                            <span className="text-[#1B4332] dark:text-[#52B788] font-medium text-[11px] flex items-center gap-1 font-sans">
                              <CheckCircle2 className="w-3.5 h-3.5" />
                              <span>Active Investigation</span>
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
                              className="text-stone-600 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white font-medium font-sans cursor-pointer"
                            >
                              Set as Active
                            </button>
                          )}
                        </div>

                        <div className="flex items-center gap-1.5">
                          <button
                            onClick={() => handleOpenEdit(proj)}
                            className="p-1.5 text-stone-400 hover:text-stone-700 dark:hover:text-stone-200 rounded cursor-pointer"
                            title="Edit Project"
                          >
                            <Edit3 className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => setProjectToDelete(proj)}
                            className="p-1.5 text-rose-400 hover:text-rose-600 rounded cursor-pointer"
                            title="Delete Project"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
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
          className="fixed inset-0 z-50 bg-[#0A0E12]/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setIsCreateModalOpen(false)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-lg bg-[#FAF7F2] dark:bg-[#141A21] border border-stone-300 dark:border-stone-700 rounded-sm shadow-xl overflow-hidden p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-stone-300 dark:border-stone-800">
              <div>
                <span className="text-[10px] font-mono uppercase tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
                  Investigation Protocol
                </span>
                <h3 className="font-serif text-base font-normal text-[#143628] dark:text-[#FAF7F2] mt-0.5">
                  Initialize Research Project
                </h3>
              </div>
              <button onClick={() => setIsCreateModalOpen(false)} className="text-stone-400 hover:text-stone-600 dark:hover:text-stone-200 cursor-pointer">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateSubmit} className="py-4 space-y-4 text-xs font-sans">
              <div>
                <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                  Project Title *
                </label>
                <input
                  type="text"
                  required
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="e.g., Targeted Degradation of Tau Oligomers via PROTACs"
                  className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                    Short Identifier
                  </label>
                  <input
                    type="text"
                    value={formShortCode}
                    onChange={(e) => setFormShortCode(e.target.value)}
                    className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs font-mono focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                  />
                </div>
                <div>
                  <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                    Scientific Domain
                  </label>
                  <select
                    value={formDomain}
                    onChange={(e) => setFormDomain(e.target.value)}
                    className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
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
                <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                  Research Description & Scope
                </label>
                <textarea
                  rows={3}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="Summarize the core scientific problem, known mechanisms, and targets..."
                  className="w-full p-2.5 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs leading-relaxed focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                />
              </div>

              <div>
                <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                  Starting Workflow Stage
                </label>
                <select
                  value={formStage}
                  onChange={(e) => setFormStage(e.target.value as ResearchStage)}
                  className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                >
                  <option value="question">1. Research Question</option>
                  <option value="literature">2. Literature Review</option>
                  <option value="hypothesis">3. Hypothesis Formulation</option>
                  <option value="experiment">4. Experiment Execution</option>
                  <option value="results">5. Results & Evaluation</option>
                </select>
              </div>

              <div className="pt-3 border-t border-stone-200 dark:border-stone-800 flex justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setIsCreateModalOpen(false)}
                  className="px-3 py-1.5 text-xs text-stone-600 dark:text-stone-400 bg-stone-200/60 dark:bg-stone-800 hover:bg-stone-200 rounded-xs cursor-pointer transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs shadow-xs cursor-pointer transition-colors"
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
          className="fixed inset-0 z-50 bg-[#0A0E12]/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setIsEditModalOpen(false)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-lg bg-[#FAF7F2] dark:bg-[#141A21] border border-stone-300 dark:border-stone-700 rounded-sm shadow-xl overflow-hidden p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-stone-300 dark:border-stone-800">
              <div>
                <span className="text-[10px] font-mono uppercase tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
                  Record Modification
                </span>
                <h3 className="font-serif text-base font-normal text-[#143628] dark:text-[#FAF7F2] mt-0.5">
                  Edit Research Project
                </h3>
              </div>
              <button onClick={() => setIsEditModalOpen(false)} className="text-stone-400 hover:text-stone-600 dark:hover:text-stone-200 cursor-pointer">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleEditSubmit} className="py-4 space-y-4 text-xs font-sans">
              <div>
                <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                  Project Title *
                </label>
                <input
                  type="text"
                  required
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                    Short Code
                  </label>
                  <input
                    type="text"
                    value={formShortCode}
                    onChange={(e) => setFormShortCode(e.target.value)}
                    className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs font-mono focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                  />
                </div>
                <div>
                  <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                    Research Stage
                  </label>
                  <select
                    value={formStage}
                    onChange={(e) => setFormStage(e.target.value as ResearchStage)}
                    className="w-full px-3 py-2 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
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
                <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                  Description
                </label>
                <textarea
                  rows={3}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full p-2.5 bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs leading-relaxed focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                />
              </div>

              <div className="pt-3 border-t border-stone-200 dark:border-stone-800 flex justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-3 py-1.5 text-xs text-stone-600 dark:text-stone-400 bg-stone-200/60 dark:bg-stone-800 hover:bg-stone-200 rounded-xs cursor-pointer transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs shadow-xs cursor-pointer transition-colors"
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
          className="fixed inset-0 z-50 bg-[#0A0E12]/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setProjectToDelete(null)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-md bg-[#FAF7F2] dark:bg-[#141A21] border border-stone-300 dark:border-stone-700 rounded-sm shadow-xl p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 text-[#991B1B]">
              <AlertCircle className="w-5 h-5 shrink-0" />
              <h3 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
                Confirm Project Deletion
              </h3>
            </div>
            <p className="text-xs text-stone-600 dark:text-stone-400 leading-relaxed font-sans">
              Are you sure you want to permanently delete <strong>"{projectToDelete.title}"</strong> ({projectToDelete.shortCode})? Associated demonstration stage records will be removed.
            </p>
            <div className="pt-2 flex justify-end gap-2.5">
              <button
                onClick={() => setProjectToDelete(null)}
                className="px-3 py-1.5 text-xs text-stone-600 dark:text-stone-400 bg-stone-200/60 dark:bg-stone-800 hover:bg-stone-200 rounded-xs cursor-pointer transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmDelete}
                className="px-4 py-1.5 text-xs font-semibold text-white bg-[#991B1B] hover:bg-[#7F1D1D] rounded-xs shadow-xs cursor-pointer transition-colors"
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
