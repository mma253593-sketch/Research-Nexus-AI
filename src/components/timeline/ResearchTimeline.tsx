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
    <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs">
      {/* Workflow Stepper Bar */}
      <div className="p-4 sm:p-5 border-b border-slate-200 dark:border-slate-800 bg-stone-50/60 dark:bg-slate-950/40">
        <div className="flex items-center justify-between mb-4">
          <div>
            <span className="text-[10px] uppercase font-mono tracking-wider text-teal-600 dark:text-teal-400 font-semibold">
              Research Progression
            </span>
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Five-Stage Scientific Discovery Workflow
            </h3>
          </div>
          <span className="text-xs font-mono text-slate-500">
            Active: {project.stageNotes[project.currentStage]?.stage || project.currentStage}
          </span>
        </div>

        {/* Stepper Grid */}
        <div className="grid grid-cols-5 gap-2 relative">
          {/* Connector Line */}
          <div className="hidden sm:block absolute top-4 left-6 right-6 h-0.5 bg-slate-200 dark:bg-slate-800 -z-0" />

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
                className={`flex flex-col items-center text-center p-2 rounded-lg transition-all z-10 ${
                  isSelected
                    ? 'bg-white dark:bg-slate-800 shadow-xs ring-1 ring-teal-500'
                    : 'hover:bg-white/50 dark:hover:bg-slate-800/40'
                }`}
              >
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center transition-colors mb-1.5 ${
                    isCompleted
                      ? 'bg-emerald-600 text-white'
                      : isActive
                      ? 'bg-teal-600 text-white ring-4 ring-teal-100 dark:ring-teal-950'
                      : 'bg-slate-100 dark:bg-slate-800 text-slate-400'
                  }`}
                >
                  {isCompleted ? (
                    <CheckCircle2 className="w-4 h-4" />
                  ) : isActive ? (
                    <CircleDot className="w-4 h-4" />
                  ) : (
                    <Circle className="w-3.5 h-3.5" />
                  )}
                </div>

                <span className={`text-[11px] font-semibold leading-tight line-clamp-1 ${
                  isSelected ? 'text-teal-600 dark:text-teal-400' : 'text-slate-700 dark:text-slate-300'
                }`}>
                  {stage.label}
                </span>

                <span className="text-[10px] font-mono text-slate-400 mt-0.5 capitalize">
                  {note?.status || 'upcoming'}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected Stage Detail Panel */}
      <div className="p-5 space-y-4 text-xs">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-slate-900 dark:text-slate-100 text-sm">
              Stage Notes: {STAGES.find((s) => s.id === activeStageId)?.label}
            </span>
            <span className={`text-[10px] font-mono px-2 py-0.5 rounded capitalize ${
              activeStageNote.status === 'completed'
                ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300'
                : activeStageNote.status === 'active'
                ? 'bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300 font-semibold'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-500'
            }`}>
              ● {activeStageNote.status}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <span className="text-[11px] text-slate-400 font-mono">
              Last updated: {activeStageNote.lastUpdated}
            </span>
            {!isEditingNotes ? (
              <button
                onClick={handleStartEditing}
                className="px-2.5 py-1 text-xs font-medium text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-800 rounded hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors flex items-center gap-1"
              >
                <Edit3 className="w-3 h-3" />
                <span>Edit Notes</span>
              </button>
            ) : (
              <button
                onClick={handleSaveNotes}
                className="px-3 py-1 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-500 rounded transition-colors flex items-center gap-1 shadow-xs"
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
              <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                Stage Synthesis & Milestone Summary
              </label>
              <textarea
                rows={3}
                value={editableSummary}
                onChange={(e) => setEditableSummary(e.target.value)}
                className="w-full p-2.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs"
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="font-semibold text-slate-700 dark:text-slate-300">
                  Key Questions for this Stage
                </label>
                <button
                  type="button"
                  onClick={() => setEditableQuestions([...editableQuestions, ''])}
                  className="text-teal-600 dark:text-teal-400 font-medium hover:underline text-[11px]"
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
                    className="w-full px-3 py-1.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded text-xs"
                  />
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="p-3.5 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200 leading-relaxed">
              {activeStageNote.summary}
            </div>

            {activeStageNote.keyQuestions.length > 0 && (
              <div>
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-2">
                  Active Inquiries & Next Milestones
                </span>
                <div className="space-y-1.5">
                  {activeStageNote.keyQuestions.map((q, idx) => (
                    <div
                      key={idx}
                      className="p-2.5 bg-white dark:bg-slate-900 rounded border border-slate-100 dark:border-slate-800 flex items-start gap-2.5 text-xs text-slate-700 dark:text-slate-300"
                    >
                      <span className="font-mono text-teal-600 dark:text-teal-400 font-semibold mt-0.5">
                        Q{idx + 1}.
                      </span>
                      <p className="flex-1">{q}</p>
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
