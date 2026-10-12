import { useState } from 'react';
import { sampleResearchQuestions } from '../../data/mockData';
import { ResearchProject } from '../../types/research';
import { SCIENTIFIC_IMAGES } from '../../assets/images';
import { ScientificImage } from '../common/ScientificImage';
import { 
  Search, ArrowRight, Network, BookOpen, 
  FlaskConical, TestTube2, BarChart2, ArrowUpRight,
  Compass, FileCheck2, Binary, Sparkles
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
      title: 'Question Parameterization',
      subtitle: 'Isolate the causal or physical unknown',
      desc: 'Define rigorous biological, chemical, or materials boundaries rather than loose speculation.',
      icon: Search
    },
    {
      num: '02',
      title: 'Literature Decomposition',
      subtitle: 'Extract verbatim claims and evaluate potential biases',
      desc: 'Dissect primary publications to separate verified observations from author interpretations.',
      icon: BookOpen
    },
    {
      num: '03',
      title: 'Hypothesis Formulation',
      subtitle: 'Construct dual supporting and counter-evidence ledgers',
      desc: 'Contrast competing mechanisms with explicit assumption auditing and calibrated confidence rationale.',
      icon: FlaskConical
    },
    {
      num: '04',
      title: 'Experiment Architecture',
      subtitle: 'Parameterize independent, dependent, and controlled variables',
      desc: 'Structure reproducible lab protocols with pre-registered statistical evaluation criteria.',
      icon: TestTube2
    },
    {
      num: '05',
      title: 'Empirical Rigor & Review',
      subtitle: 'Audit findings against criteria without data invention',
      desc: 'Track stage milestones with power calculations (n ≥ 3) and combination indices.',
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
    <div className="space-y-24 pb-20 max-w-7xl mx-auto">
      {/* 1. HERO SECTION: Scientific Editorial & Contemporary Lab */}
      <section className="pt-4 sm:pt-10">
        {/* Editorial Masthead Bar */}
        <div className="flex flex-wrap items-center justify-between gap-3 pb-4 mb-8 border-b border-stone-300 dark:border-stone-800 text-[11px] font-mono uppercase tracking-wider text-stone-500 dark:text-stone-400">
          <div className="flex items-center gap-3">
            <span className="font-semibold text-[#143628] dark:text-[#52B788]">Research Nexus</span>
            <span>·</span>
            <span>Scientific Discovery System</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="hidden sm:inline">Volume IV · Open Methodological Framework</span>
            <span className="text-[#B45309] font-medium">Peer-Grounded Protocols</span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-14 items-start">
          {/* Left Column: Editorial Headline & Actions */}
          <div className="lg:col-span-7 space-y-7">
            <div className="space-y-4">
              <span className="inline-block text-xs font-mono font-medium tracking-widest uppercase text-[#B45309] dark:text-[#F59E0B]">
                Hypothesis Engineering · Experiment Design · Concept Networks
              </span>
              <h1 className="font-serif text-4xl sm:text-6xl text-[#143628] dark:text-[#FAF7F2] font-normal tracking-tight leading-[1.08] text-balance">
                Research beyond the obvious.
              </h1>
              <p className="text-base sm:text-lg text-stone-700 dark:text-stone-300 leading-relaxed font-sans max-w-2xl">
                Explore scientific knowledge, investigate competing hypotheses, and turn unanswered questions into testable, reproducible research.
              </p>
            </div>

            {/* Interactive Research Query Bar */}
            <form onSubmit={handleSearchSubmit} className="space-y-3.5 max-w-2xl">
              <div className="relative flex items-center bg-white dark:bg-[#161C22] border border-stone-300 dark:border-stone-700 rounded-sm shadow-xs focus-within:border-[#1B4332] focus-within:ring-1 focus-within:ring-[#1B4332] transition-all">
                <Search className="absolute left-3.5 w-4 h-4 text-stone-400 pointer-events-none stroke-[1.75]" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Enter a research question, target (KRAS G12D, Perovskite), or DOI..."
                  className="w-full pl-10 pr-36 py-3.5 text-xs sm:text-sm bg-transparent text-[#1F2421] dark:text-[#E8ECE9] placeholder:text-stone-400 focus:outline-none font-sans"
                />
                <button
                  type="submit"
                  className="absolute right-1.5 px-4 py-2 text-xs font-medium text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors whitespace-nowrap"
                >
                  Initiate Investigation
                </button>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap items-center gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => onStartResearching(searchQuery)}
                  className="px-5 py-2.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-all shadow-xs flex items-center gap-2 cursor-pointer"
                >
                  <span>Open Research Workspace</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={onExploreKnowledge}
                  className="px-4 py-2.5 text-xs font-medium text-[#143628] dark:text-stone-200 hover:text-[#0E291E] bg-white dark:bg-[#1A222B] border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-50 dark:hover:bg-stone-800 transition-colors flex items-center gap-2 cursor-pointer"
                >
                  <Network className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788]" />
                  <span>Inspect Knowledge Graph</span>
                </button>
              </div>
            </form>

            {/* Clickable Grounded Questions */}
            <div className="space-y-2 pt-2 border-t border-stone-200 dark:border-stone-800">
              <span className="text-[11px] font-mono text-stone-500 uppercase tracking-wider block">
                Representative Inquiries:
              </span>
              <div className="flex flex-wrap gap-2">
                {sampleResearchQuestions.slice(0, 3).map((question, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => handleQuestionClick(question)}
                    className="text-left px-3 py-1.5 text-xs text-stone-700 dark:text-stone-300 bg-white/70 dark:bg-stone-900/60 hover:bg-stone-100 dark:hover:bg-stone-800 border border-stone-200 dark:border-stone-800 rounded-xs transition-colors line-clamp-1 max-w-full cursor-pointer hover:border-stone-400"
                  >
                    "{question}"
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Right Column: Prominent Scientific Photography & Restrained Caption */}
          <div className="lg:col-span-5 space-y-3">
            <div className="relative border border-stone-300 dark:border-stone-700 bg-white dark:bg-[#161C22] p-2 rounded-xs shadow-xs">
              <ScientificImage
                src={SCIENTIFIC_IMAGES.heroConceptGraph}
                fallbackSrc={SCIENTIFIC_IMAGES.publicHero}
                alt="High-resolution isometric mapping of molecular pathways and knowledge graph intersections"
                aspectRatioClass="aspect-16/11"
                className="w-full h-full object-cover rounded-xs"
              />

              <div className="p-3 pt-3.5 border-t border-stone-200 dark:border-stone-800 space-y-1.5 bg-[#FAF7F2] dark:bg-[#141A20]">
                <div className="flex items-center justify-between text-[11px] font-mono text-stone-500">
                  <span className="font-semibold text-[#1B4332] dark:text-[#52B788]">Figure 1.0</span>
                  <span>Isometric Knowledge Matrix</span>
                </div>
                <p className="text-xs text-stone-600 dark:text-stone-400 font-sans leading-relaxed">
                  Interconnected multi-scale concept network illustrating small-molecule binding, RTK feedback reactivation, and downstream transcriptional effectors.
                </p>
                <div className="pt-1 flex items-center justify-between text-[10px] font-mono text-stone-400">
                  <span>Source: Der et al. / Wang et al. 2023</span>
                  <button
                    onClick={onExploreKnowledge}
                    className="text-[#1B4332] dark:text-[#52B788] hover:underline font-medium flex items-center gap-1 cursor-pointer"
                  >
                    <span>Inspect Interactive Graph</span>
                    <ArrowUpRight className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 2. THE FIVE-STAGE RESEARCH WORKFLOW */}
      <section className="space-y-6 pt-4 border-t border-stone-300 dark:border-stone-800">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
          <div className="space-y-1.5">
            <span className="text-xs font-mono uppercase tracking-widest text-[#B45309] font-medium">
              Systematic Progression
            </span>
            <h2 className="font-serif text-3xl sm:text-4xl text-[#143628] dark:text-[#FAF7F2] font-normal tracking-tight">
              From exploratory inquiry to reproducible lab protocols
            </h2>
            <p className="text-xs sm:text-sm text-stone-600 dark:text-stone-400 max-w-2xl font-sans">
              A disciplined, non-hallucinatory progression designed to prevent premature conclusions and uphold scientific rigor.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 pt-2">
          {workflowSteps.map((step, idx) => {
            const Icon = step.icon;
            const isSelected = activeWorkflowIndex === idx;
            return (
              <div
                key={step.num}
                onClick={() => setActiveWorkflowIndex(idx)}
                className={`p-4 border transition-all cursor-pointer flex flex-col justify-between space-y-3 rounded-xs ${
                  isSelected
                    ? 'bg-white dark:bg-[#161C22] border-[#1B4332] dark:border-[#52B788] ring-1 ring-[#1B4332]/20'
                    : 'bg-white/60 dark:bg-stone-900/40 border-stone-200 dark:border-stone-800 hover:border-stone-400 dark:hover:border-stone-700'
                }`}
              >
                <div className="space-y-2">
                  <div className="flex items-center justify-between border-b border-stone-200 dark:border-stone-800 pb-2">
                    <span className="font-mono text-xs font-bold text-[#1B4332] dark:text-[#52B788]">
                      {step.num}
                    </span>
                    <Icon className="w-4 h-4 text-stone-400" />
                  </div>
                  <h3 className="text-xs font-bold text-stone-900 dark:text-stone-100 font-sans leading-snug">
                    {step.title}
                  </h3>
                  <p className="text-[11px] text-stone-600 dark:text-stone-400 leading-relaxed font-sans">
                    {step.desc}
                  </p>
                </div>
                <div className="pt-2 border-t border-stone-100 dark:border-stone-800 flex items-center justify-between text-[10px] text-stone-400 font-mono">
                  <span>Stage {idx + 1} of 5</span>
                  {isSelected && <span className="text-[#1B4332] dark:text-[#52B788] font-semibold">Active</span>}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* 3. ACTIVE RESEARCH PROJECTS: Real Imagery, Fields & Metrics */}
      <section className="space-y-6 pt-4 border-t border-stone-300 dark:border-stone-800">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
          <div className="space-y-1.5">
            <span className="text-xs font-mono uppercase tracking-widest text-[#B45309] font-medium">
              Empirical Exemplars
            </span>
            <h2 className="font-serif text-3xl sm:text-4xl text-[#143628] dark:text-[#FAF7F2] font-normal tracking-tight">
              Featured Research Investigations
            </h2>
            <p className="text-xs sm:text-sm text-stone-600 dark:text-stone-400 font-sans">
              Authentic multi-domain research records ready for immediate parameterization and hypothesis contrast.
            </p>
          </div>

          <button
            onClick={() => onStartResearching()}
            className="text-xs font-medium text-[#1B4332] dark:text-[#52B788] hover:underline flex items-center gap-1 shrink-0 cursor-pointer"
          >
            <span>Open All Projects in Workspace</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-2">
          {projects.map((project) => {
            const category = project.domain.toLowerCase().includes('oncol') 
              ? 'oncology' 
              : project.domain.toLowerCase().includes('mater') 
              ? 'materials' 
              : 'neuro';

            return (
              <div
                key={project.id}
                onClick={() => {
                  onSelectProject(project.id);
                  onStartResearching();
                }}
                className="bg-white dark:bg-[#161C22] border border-stone-200 dark:border-stone-800 rounded-xs overflow-hidden hover:border-stone-400 dark:hover:border-stone-700 transition-all cursor-pointer group flex flex-col justify-between shadow-xs"
              >
                <div>
                  {/* Research Photography Card Banner */}
                  <div className="relative">
                    <ScientificImage
                      src={project.image || ''}
                      alt={project.title}
                      category={category}
                      aspectRatioClass="aspect-16/10"
                      className="w-full h-full object-cover group-hover:scale-[1.02] transition-transform duration-500"
                    />
                    <div className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-xs bg-[#0F1E2E]/90 text-[10px] font-mono text-white font-medium border border-stone-600/40">
                      {project.shortCode}
                    </div>
                    <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded-xs bg-stone-900/90 text-[10px] font-mono text-stone-200 capitalize">
                      Stage: {project.currentStage}
                    </div>
                  </div>

                  <div className="p-5 space-y-2.5">
                    <span className="text-[11px] font-mono text-stone-500 uppercase tracking-wider block">
                      {project.domain}
                    </span>
                    <h3 className="font-serif text-base font-normal text-stone-900 dark:text-stone-100 group-hover:text-[#1B4332] dark:group-hover:text-[#52B788] transition-colors leading-snug">
                      {project.title}
                    </h3>
                    <p className="text-xs text-stone-600 dark:text-stone-400 line-clamp-3 leading-relaxed font-sans">
                      {project.description}
                    </p>
                  </div>
                </div>

                <div className="p-5 pt-0">
                  <div className="pt-3 border-t border-stone-100 dark:border-stone-800 flex items-center justify-between text-xs text-stone-500 font-mono">
                    <div className="flex items-center gap-3 text-[11px]">
                      <span>{project.hypothesesCount} Hypotheses</span>
                      <span>·</span>
                      <span>{project.papersCount} Papers</span>
                    </div>
                    <div className="flex items-center gap-1 text-[#1B4332] dark:text-[#52B788] group-hover:translate-x-0.5 transition-transform">
                      <span className="text-[11px] font-sans font-medium">Explore</span>
                      <ArrowUpRight className="w-3.5 h-3.5" />
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* 4. METHODOLOGY & PLATFORM INTEGRITY CALLOUT */}
      <section className="bg-white dark:bg-[#161C22] border border-stone-200 dark:border-stone-800 p-8 rounded-xs">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="space-y-2">
            <div className="flex items-center gap-2 text-[#1B4332] dark:text-[#52B788]">
              <FileCheck2 className="w-4 h-4 stroke-[1.75]" />
              <h3 className="text-xs font-mono font-semibold uppercase tracking-wider text-stone-900 dark:text-stone-100">
                Primary Grounding
              </h3>
            </div>
            <p className="text-xs text-stone-600 dark:text-stone-400 leading-relaxed font-sans">
              Explicit separation of author-extracted claims from exploratory AI synthesis. Zero hallucinated DOIs or fabricated citations.
            </p>
          </div>

          <div className="space-y-2">
            <div className="flex items-center gap-2 text-[#1B4332] dark:text-[#52B788]">
              <Binary className="w-4 h-4 stroke-[1.75]" />
              <h3 className="text-xs font-mono font-semibold uppercase tracking-wider text-stone-900 dark:text-stone-100">
                Directional Relationships
              </h3>
            </div>
            <p className="text-xs text-stone-600 dark:text-stone-400 leading-relaxed font-sans">
              Knowledge graph connections represent mathematically parameterized allosteric inhibition, transactivation, and degradation rates.
            </p>
          </div>

          <div className="space-y-2">
            <div className="flex items-center gap-2 text-[#1B4332] dark:text-[#52B788]">
              <Compass className="w-4 h-4 stroke-[1.75]" />
              <h3 className="text-xs font-mono font-semibold uppercase tracking-wider text-stone-900 dark:text-stone-100">
                Protocol Architecture
              </h3>
            </div>
            <p className="text-xs text-stone-600 dark:text-stone-400 leading-relaxed font-sans">
              Experiments validate variables, replication bounds (n ≥ 3), and statistical tests before laboratory bench execution.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
