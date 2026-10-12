import { useState } from 'react';
import { sampleResearchQuestions, sampleKnowledgeGraph } from '../../data/mockData';
import { ResearchProject } from '../../types/research';
import { 
  Search, ArrowRight, Network, Sparkles, BookOpen, 
  FlaskConical, TestTube2, BarChart2, CheckCircle2, 
  ExternalLink, ArrowUpRight, ChevronRight
} from 'lucide-react';

interface HomepageProps {
  onStartResearching: (initialQuery?: string) => void;
  onExploreKnowledge: () => void;
  onSelectProject: (projectId: string) => void;
  projects: ResearchProject[];
}

export function Homepage({
  onStartResearching,
  onExploreKnowledge,
  onSelectProject,
  projects
}: HomepageProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeWorkflowIndex, setActiveWorkflowIndex] = useState(0);

  const workflowSteps = [
    {
      num: '01',
      title: 'Research Question Definition',
      subtitle: 'Isolate the core physical, biological, or chemical unknown.',
      desc: 'Formulate precise empirical boundaries, target alleles, or interfacial parameters rather than vague speculative inquiries.',
      icon: Search
    },
    {
      num: '02',
      title: 'Literature Review & Decomposition',
      subtitle: 'Extract verbatim claims and evaluate potential biases.',
      desc: 'Dissect published abstracts and methods to isolate primary endpoints, experimental constraints, and sample cohorts.',
      icon: BookOpen
    },
    {
      num: '03',
      title: 'Hypothesis Formulation Lab',
      subtitle: 'Construct dual supporting and contradicting evidence sheets.',
      desc: 'Compare competing mechanistic models with explicit assumption tracking and calibrated confidence scoring.',
      icon: FlaskConical
    },
    {
      num: '04',
      title: 'Experiment Protocol Designer',
      subtitle: 'Parameterize independent, dependent, and controlled variables.',
      desc: 'Generate executable step-by-step procedures with statistical power criteria (ANOVA, CI thresholds, replication count).',
      icon: TestTube2
    },
    {
      num: '05',
      title: 'Results & Rigor Evaluation',
      subtitle: 'Audit empirical findings against pre-registered criteria.',
      desc: 'Track stage milestones without inventing data, verifying reproducible effect sizes across biological and technical replicates.',
      icon: BarChart2
    }
  ];

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      onStartResearching(searchQuery.trim());
    } else {
      onStartResearching();
    }
  };

  const handleQuestionClick = (q: string) => {
    setSearchQuery(q);
  };

  return (
    <div className="space-y-20 pb-16">
      {/* Hero Section */}
      <section className="pt-8 pb-12 sm:pt-14 sm:pb-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
          {/* Left Column: Headline and Interactive Search */}
          <div className="lg:col-span-7 space-y-6">
            <div className="space-y-3">
              <span className="text-xs font-mono font-medium uppercase tracking-wider text-teal-600 dark:text-teal-400">
                Evidence-Driven Scientific Discovery
              </span>
              <h1 className="text-3xl sm:text-5xl font-bold tracking-tight text-slate-900 dark:text-slate-100 text-balance leading-[1.12]">
                Research beyond the obvious.
              </h1>
              <p className="text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed max-w-2xl">
                Explore scientific knowledge, investigate competing hypotheses, and turn unanswered questions into testable research.
              </p>
            </div>

            {/* Interactive Search Input Box */}
            <form onSubmit={handleSearchSubmit} className="space-y-3 max-w-xl">
              <div className="relative flex items-center shadow-xs">
                <Search className="absolute left-3.5 w-4 h-4 text-slate-400 pointer-events-none" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Enter a scientific question, target (KRAS, Perovskite), or DOI..."
                  className="w-full pl-10 pr-36 py-3 text-xs sm:text-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500/40 focus:border-teal-500 transition-all"
                />
                <button
                  type="submit"
                  className="absolute right-1.5 px-3.5 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors whitespace-nowrap shadow-xs"
                >
                  Start Researching
                </button>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap items-center gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => onStartResearching(searchQuery)}
                  className="px-4 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors shadow-xs flex items-center gap-2"
                >
                  <span>Launch Workspace</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={onExploreKnowledge}
                  className="px-4 py-2 text-xs font-medium text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors flex items-center gap-2"
                >
                  <Network className="w-3.5 h-3.5 text-teal-600 dark:text-teal-400" />
                  <span>Explore Knowledge Graph</span>
                </button>
              </div>
            </form>

            {/* Clickable Example Questions */}
            <div className="space-y-2 pt-2">
              <span className="text-[11px] font-mono text-slate-400 uppercase tracking-wider block">
                Example Scientific Questions:
              </span>
              <div className="flex flex-wrap gap-2">
                {sampleResearchQuestions.slice(0, 3).map((question, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => handleQuestionClick(question)}
                    className="text-left px-2.5 py-1 text-xs text-slate-600 dark:text-slate-400 hover:text-teal-600 dark:hover:text-teal-400 bg-white/80 dark:bg-slate-900/80 hover:bg-stone-100 dark:hover:bg-slate-800 border border-slate-200 dark:border-slate-800 rounded-md transition-all line-clamp-1 max-w-full"
                  >
                    "{question}"
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Right Column: High-Fidelity Scientific Concept Visual & Mini Interaction */}
          <div className="lg:col-span-5">
            <div className="relative bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden shadow-sm">
              <div className="relative aspect-16/10 overflow-hidden bg-slate-950">
                <img
                  src="/src/assets/images/hero_scientific_concept_graph_1791775704373.jpg"
                  alt="Scientific concept relationship network"
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover opacity-90 transition-transform duration-500 hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/30 to-transparent" />
                <div className="absolute bottom-3 left-4 right-4 flex items-center justify-between text-xs text-white">
                  <div>
                    <p className="font-semibold text-xs tracking-wide">Multi-scale Concept Synthesis</p>
                    <p className="text-[11px] text-slate-300">Target · Pathway · Mechanism</p>
                  </div>
                  <button
                    onClick={onExploreKnowledge}
                    className="px-2.5 py-1 text-[11px] font-medium bg-teal-500/90 text-white rounded hover:bg-teal-400 transition-colors flex items-center gap-1"
                  >
                    <span>Inspect</span>
                    <ArrowUpRight className="w-3 h-3" />
                  </button>
                </div>
              </div>

              {/* Grounded Concept Strip */}
              <div className="p-4 bg-stone-50/80 dark:bg-slate-900/80 border-t border-slate-100 dark:border-slate-800 space-y-2 text-xs">
                <div className="flex items-center justify-between">
                  <span className="font-mono text-[10px] text-slate-400 uppercase tracking-wider">
                    Model Concepts & Directional Edges
                  </span>
                  <span className="text-[10px] text-teal-600 dark:text-teal-400 font-mono">
                    14 Active Nodes
                  </span>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {sampleKnowledgeGraph.nodes.slice(0, 5).map((node) => (
                    <span
                      key={node.id}
                      className="text-[11px] px-2 py-0.5 rounded bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-medium"
                    >
                      {node.label}
                    </span>
                  ))}
                  <span className="text-[11px] text-slate-400 self-center pl-1 font-mono">
                    +9 more
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Section: The 5-Stage Scientific Workflow */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="space-y-2 pb-6 border-b border-slate-200 dark:border-slate-800">
          <span className="text-xs font-mono uppercase tracking-wider text-teal-600 dark:text-teal-400 font-semibold">
            Methodological Architecture
          </span>
          <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
            From unanswered questions to reproducible experiments
          </h2>
          <p className="text-xs sm:text-sm text-slate-500 max-w-2xl">
            A disciplined, non-hallucinatory progression designed to eliminate premature claims and preserve methodological rigor.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-3 pt-6">
          {workflowSteps.map((step, idx) => {
            const Icon = step.icon;
            const isSelected = activeWorkflowIndex === idx;
            return (
              <div
                key={step.num}
                onClick={() => setActiveWorkflowIndex(idx)}
                className={`p-4 rounded-xl border transition-all cursor-pointer flex flex-col justify-between space-y-3 ${
                  isSelected
                    ? 'bg-white dark:bg-slate-900 border-teal-500 shadow-xs ring-1 ring-teal-500/20'
                    : 'bg-white/60 dark:bg-slate-900/60 border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                }`}
              >
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs font-bold text-teal-600 dark:text-teal-400">
                      {step.num}
                    </span>
                    <Icon className="w-4 h-4 text-slate-400" />
                  </div>
                  <h3 className="text-xs font-bold text-slate-900 dark:text-slate-100 leading-snug">
                    {step.title}
                  </h3>
                  <p className="text-[11px] text-slate-500 leading-relaxed">
                    {step.desc}
                  </p>
                </div>
                <div className="pt-2 border-t border-slate-100 dark:border-slate-800/60 flex items-center justify-between text-[10px] text-slate-400 font-mono">
                  <span>Stage {idx + 1} of 5</span>
                  {isSelected && <span className="text-teal-600 dark:text-teal-400 font-semibold">Active Focus</span>}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Section: Curated Scientific Investigations */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pb-6 border-b border-slate-200 dark:border-slate-800">
          <div className="space-y-1">
            <span className="text-xs font-mono uppercase tracking-wider text-teal-600 dark:text-teal-400 font-semibold">
              Curated Exemplars
            </span>
            <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
              Active Research Projects
            </h2>
            <p className="text-xs sm:text-sm text-slate-500">
              Grounded, multi-domain demonstration workspaces available for immediate exploration.
            </p>
          </div>

          <button
            onClick={() => onStartResearching()}
            className="text-xs font-semibold text-teal-600 dark:text-teal-400 hover:text-teal-700 dark:hover:text-teal-300 flex items-center gap-1 shrink-0"
          >
            <span>View All in Workspace</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-6">
          {projects.map((project) => (
            <div
              key={project.id}
              onClick={() => {
                onSelectProject(project.id);
                onStartResearching();
              }}
              className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs hover:border-slate-300 dark:hover:border-slate-700 transition-all cursor-pointer group flex flex-col justify-between"
            >
              <div>
                {/* Project Image Banner */}
                {project.image && (
                  <div className="relative aspect-16/9 overflow-hidden bg-slate-950">
                    <img
                      src={project.image}
                      alt={project.title}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 opacity-90"
                    />
                    <div className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded bg-slate-900/80 backdrop-blur-xs text-[10px] font-mono text-teal-400 font-semibold border border-slate-700">
                      {project.shortCode}
                    </div>
                    <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded bg-slate-900/80 backdrop-blur-xs text-[10px] font-mono text-slate-200 capitalize">
                      Stage: {project.currentStage}
                    </div>
                  </div>
                )}

                <div className="p-5 space-y-2.5">
                  <span className="text-[11px] font-mono text-slate-400 uppercase tracking-wider">
                    {project.domain}
                  </span>
                  <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100 group-hover:text-teal-600 dark:group-hover:text-teal-400 transition-colors leading-snug">
                    {project.title}
                  </h3>
                  <p className="text-xs text-slate-600 dark:text-slate-400 line-clamp-3 leading-relaxed">
                    {project.description}
                  </p>
                </div>
              </div>

              <div className="p-5 pt-0">
                <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-xs text-slate-500 font-mono">
                  <div className="flex items-center gap-3 text-[11px]">
                    <span>{project.hypothesesCount} Hypotheses</span>
                    <span>·</span>
                    <span>{project.papersCount} Papers</span>
                  </div>
                  <ArrowUpRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-teal-600 transition-colors" />
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
