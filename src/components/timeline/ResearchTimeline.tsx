import { useState } from 'react';
import { ResearchProject, ResearchStage, StageNote } from '../../types/research';
import { 
  CheckCircle2, CircleDot, Circle, Edit3, Save, 
  HelpCircle, BookOpen, FlaskConical, TestTube2, BarChart2,
  Calendar, Clock, Check
} from 'lucide-react';
import { useToast } from '../common/Toast';

interface ResearchTimelineProps {
  project: ResearchProject;
  onUpdateStageNotes: (stage: ResearchStage, updatedNote: StageNote) => void;
  onSelectStage?: (stage: ResearchStage) => void;
}

const STAGES: { id: ResearchStage; label: string; icon: any; order: number }[] = [
  { id: 'question', label: 'Research Question', icon: HelpCircle, order: 1 },
  { id: 'literature', label: 'Literature Review', icon: BookOpen, order: 2 },
  { id: 'hypothesis', label: 'Hypothesis Formulation', icon: FlaskConical, order: 3 },
  { id: 'experiment', label: 'Experiment Execution', icon: TestTube2, order: 4 },
  { id: 'results', label: 'Results & Evaluation', icon: BarChart2, order: 5 }
];

export function ResearchTimeline({
  project,
  onUpdateStageNotes,
  onSelectStage
}: ResearchTimelineProps) {
  const { showToast } = useToast();
  const [activeStageId, setActiveStageId] = useState<ResearchStage>(project.currentStage);
  const [isEditingNotes, setIsEditingNotes] = useState(false);
  const [editableSummary, setEditableSummary] = useState('');
  const [editableQuestions, setEditableQuestions] = useState<string[]>([]);

  const activeStageNote = project.stageNotes[activeStageId] || {
    stage: activeStageId,
    status: 'upcoming',
    summary: 'No notes entered for this stage yet.',
    keyQuestions: [],
    lastUpdated: new Date().toISOString().split('T')[0]
  };

  const handleSelectStage = (stageId: ResearchStage) => {
    setActiveStageId(stageId);
    setIsEditingNotes(false);
    onSelectStage?.(stageId);
  };

  const handleStartEditing = () => {
    setEditableSummary(activeStageNote.summary);
    setEditableQuestions([...activeStageNote.keyQuestions]);
    setIsEditingNotes(true);
  };

  const handleSaveNotes = () => {
    const updated: StageNote = {
      ...activeStageNote,
      summary: editableSummary.trim(),
      keyQuestions: editableQuestions.filter((q) => q.trim().length > 0),
      lastUpdated: new Date().toISOString().split('T')[0]
    };

    onUpdateStageNotes(activeStageId, updated);
    setIsEditingNotes(false);
    showToast({
      type: 'success',
      title: 'Stage Notes Saved',
      message: `Updated notes for ${activeStageId}`
    });
  };

  return (
    <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm overflow-hidden shadow-xs">
      {/* Workflow Stepper Bar */}
      <div className="p-4 sm:p-5 border-b border-stone-200 dark:border-stone-800 bg-stone-50/70 dark:bg-[#11161B]">
        <div className="flex items-center justify-between mb-4">
          <div>
            <span className="text-[10px] uppercase font-mono tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
              Research Progression
            </span>
            <h3 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
              Five-Stage Scientific Discovery Workflow
            </h3>
          </div>
          <span className="text-xs font-mono text-stone-500 dark:text-stone-400">
            Active: {project.stageNotes[project.currentStage]?.stage || project.currentStage}
          </span>
        </div>

        {/* Stepper Grid */}
        <div className="grid grid-cols-5 gap-2 relative">
          {/* Connector Line */}
          <div className="hidden sm:block absolute top-4 left-6 right-6 h-0.5 bg-stone-200 dark:border-stone-800 -z-0" />

          {STAGES.map((stage, idx) => {
            const note = project.stageNotes[stage.id];
            const isSelected = activeStageId === stage.id;
            const isCompleted = note?.status === 'completed';
            const isActive = note?.status === 'active';
            const Icon = stage.icon;

            return (
              <button
                key={stage.id}
                onClick={() => handleSelectStage(stage.id)}
                className={`flex flex-col items-center text-center p-2 rounded-xs transition-all z-10 cursor-pointer ${
                  isSelected
                    ? 'bg-white dark:bg-[#161C22] shadow-xs ring-1 ring-[#1B4332] dark:ring-[#52B788]'
                    : 'hover:bg-white/60 dark:hover:bg-stone-800/40'
                }`}
              >
                <div
                  className={`w-7 h-7 sm:w-8 sm:h-8 rounded-full flex items-center justify-center transition-colors mb-1.5 ${
                    isCompleted
                      ? 'bg-[#1B4332] text-white'
                      : isActive
                      ? 'bg-[#2D6A4F] text-white ring-3 ring-[#2D6A4F]/20'
                      : 'bg-stone-100 dark:bg-stone-800 text-stone-400'
                  }`}
                >
                  {isCompleted ? (
                    <CheckCircle2 className="w-3.5 h-3.5 sm:w-4 sm:h-4 stroke-[2]" />
                  ) : isActive ? (
                    <CircleDot className="w-3.5 h-3.5 sm:w-4 sm:h-4 stroke-[2]" />
                  ) : (
                    <Circle className="w-3 h-3 sm:w-3.5 sm:h-3.5" />
                  )}
                </div>

                <span className={`text-[11px] font-medium leading-tight line-clamp-1 ${
                  isSelected ? 'text-[#143628] dark:text-[#52B788] font-semibold' : 'text-stone-700 dark:text-stone-300'
                }`}>
                  {stage.label}
                </span>

                <span className="text-[10px] font-mono text-stone-400 mt-0.5 capitalize">
                  {note?.status || 'upcoming'}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected Stage Detail Panel */}
      <div className="p-5 space-y-4 text-xs font-sans">
        <div className="flex items-center justify-between pb-3 border-b border-stone-200 dark:border-stone-800">
          <div className="flex items-center gap-2">
            <span className="font-serif font-semibold text-[#143628] dark:text-[#FAF7F2] text-sm">
              Stage Notes: {STAGES.find((s) => s.id === activeStageId)?.label}
            </span>
            <span className={`text-[10px] font-mono px-2 py-0.5 rounded-xs capitalize ${
              activeStageNote.status === 'completed'
                ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800'
                : activeStageNote.status === 'active'
                ? 'bg-[#1B4332]/10 dark:bg-[#52B788]/15 text-[#143628] dark:text-[#52B788] font-semibold border border-[#1B4332]/20'
                : 'bg-stone-100 dark:bg-stone-800 text-stone-500'
            }`}>
              ● {activeStageNote.status}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <span className="text-[11px] text-stone-400 font-mono">
              Last updated: {activeStageNote.lastUpdated}
            </span>
            {!isEditingNotes ? (
              <button
                onClick={handleStartEditing}
                className="px-2.5 py-1 text-xs font-medium text-stone-700 dark:text-stone-300 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-100 dark:hover:bg-stone-800 transition-colors flex items-center gap-1 cursor-pointer"
              >
                <Edit3 className="w-3 h-3" />
                <span>Edit Notes</span>
              </button>
            ) : (
              <button
                onClick={handleSaveNotes}
                className="px-3 py-1 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] rounded-xs transition-colors flex items-center gap-1 shadow-xs cursor-pointer"
              >
                <Save className="w-3 h-3" />
                <span>Save Notes</span>
              </button>
            )}
          </div>
        </div>

        {/* Notes Content */}
        {isEditingNotes ? (
          <div className="space-y-4">
            <div>
              <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                Stage Synthesis & Milestone Summary
              </label>
              <textarea
                rows={3}
                value={editableSummary}
                onChange={(e) => setEditableSummary(e.target.value)}
                className="w-full p-2.5 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none leading-relaxed"
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="font-medium text-stone-700 dark:text-stone-300">
                  Key Questions for this Stage
                </label>
                <button
                  type="button"
                  onClick={() => setEditableQuestions([...editableQuestions, ''])}
                  className="text-[#1B4332] dark:text-[#52B788] font-medium hover:underline text-[11px] cursor-pointer"
                >
                  + Add Question
                </button>
              </div>
              <div className="space-y-2">
                {editableQuestions.map((q, idx) => (
                  <input
                    key={idx}
                    type="text"
                    value={q}
                    onChange={(e) => {
                      const copy = [...editableQuestions];
                      copy[idx] = e.target.value;
                      setEditableQuestions(copy);
                    }}
                    placeholder={`Key question ${idx + 1}...`}
                    className="w-full px-3 py-1.5 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
                  />
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="p-3.5 bg-stone-50/80 dark:bg-stone-900/40 rounded-xs border border-stone-200 dark:border-stone-800 text-stone-800 dark:text-stone-200 leading-relaxed font-sans">
              {activeStageNote.summary}
            </div>

            {activeStageNote.keyQuestions.length > 0 && (
              <div>
                <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest block mb-2 font-medium">
                  Active Inquiries & Next Milestones
                </span>
                <div className="space-y-1.5">
                  {activeStageNote.keyQuestions.map((q, idx) => (
                    <div
                      key={idx}
                      className="p-2.5 bg-white dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800 flex items-start gap-2.5 text-xs text-stone-700 dark:text-stone-300"
                    >
                      <span className="font-mono text-[#1B4332] dark:text-[#52B788] font-semibold mt-0.5">
                        Q{idx + 1}.
                      </span>
                      <p className="flex-1 leading-relaxed">{q}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
