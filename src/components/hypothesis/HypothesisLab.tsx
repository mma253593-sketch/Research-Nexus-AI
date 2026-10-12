import { useState } from 'react';
import { Hypothesis, EvidenceItem } from '../../types/research';
import { 
  FlaskConical, Plus, Trash2, Edit3, ArrowLeftRight, CheckCircle2, 
  AlertCircle, HelpCircle, FileText, ChevronDown, ChevronUp, Copy,
  Check, X, Sparkles, Scale, TestTube2, Download
} from 'lucide-react';
import { useToast } from '../common/Toast';

interface HypothesisLabProps {
  hypotheses: Hypothesis[];
  onSaveHypothesis: (hypothesis: Hypothesis) => void;
  onDeleteHypothesis: (id: string) => void;
  onDesignExperimentForHypothesis?: (hypothesis: Hypothesis) => void;
  activeProjectId?: string;
}

export function HypothesisLab({
  hypotheses,
  onSaveHypothesis,
  onDeleteHypothesis,
  onDesignExperimentForHypothesis,
  activeProjectId
}: HypothesisLabProps) {
  const { showToast } = useToast();
  const [isCompareMode, setIsCompareMode] = useState(false);
  const [selectedForCompare, setSelectedForCompare] = useState<string[]>([]);
  const [editingHypothesis, setEditingHypothesis] = useState<Hypothesis | null>(null);
  const [isCreatingNew, setIsCreatingNew] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(hypotheses[0]?.id || null);

  // Form states for create/edit
  const [formData, setFormData] = useState<Partial<Hypothesis>>({
    title: '',
    statement: '',
    rationale: '',
    assumptions: [''],
    unknowns: [''],
    suggestedTests: [''],
    confidenceScore: 0.70,
    confidenceBasis: '',
    status: 'formulated'
  });

  const handleOpenCreate = () => {
    setFormData({
      title: '',
      statement: '',
      rationale: '',
      assumptions: [''],
      unknowns: [''],
      suggestedTests: [''],
      confidenceScore: 0.70,
      confidenceBasis: '',
      status: 'formulated'
    });
    setEditingHypothesis(null);
    setIsCreatingNew(true);
  };

  const handleOpenEdit = (hypo: Hypothesis) => {
    setFormData({ ...hypo });
    setEditingHypothesis(hypo);
    setIsCreatingNew(true);
  };

  const handleSaveForm = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.title?.trim() || !formData.statement?.trim()) {
      showToast({
        type: 'warning',
        title: 'Required Fields Missing',
        message: 'Please provide both a title and hypothesis statement.'
      });
      return;
    }

    const newHypo: Hypothesis = {
      id: editingHypothesis ? editingHypothesis.id : `hypo-${Date.now()}`,
      projectId: activeProjectId || 'proj-kras-01',
      title: formData.title.trim(),
      statement: formData.statement.trim(),
      rationale: formData.rationale?.trim() || '',
      supportingEvidence: editingHypothesis?.supportingEvidence || [
        {
          id: `ev-sup-${Date.now()}`,
          sourceTitle: 'Literature Preclinical Review',
          sourceCitation: 'Journal of Molecular Biology 2024',
          evidenceText: 'Preliminary binding assays demonstrate dose-dependent target engagement.',
          evidenceType: 'in_vitro'
        }
      ],
      contradictingEvidence: editingHypothesis?.contradictingEvidence || [],
      assumptions: (formData.assumptions || []).filter(a => a.trim().length > 0),
      unknowns: (formData.unknowns || []).filter(u => u.trim().length > 0),
      suggestedTests: (formData.suggestedTests || []).filter(t => t.trim().length > 0),
      confidenceScore: Number(formData.confidenceScore) || 0.65,
      confidenceBasis: formData.confidenceBasis?.trim() || 'Estimated from preliminary evidence balance sheet.',
      status: formData.status || 'formulated',
      createdAt: editingHypothesis?.createdAt || new Date().toISOString().split('T')[0],
      updatedAt: new Date().toISOString().split('T')[0]
    };

    onSaveHypothesis(newHypo);
    setIsCreatingNew(false);
    setEditingHypothesis(null);
    showToast({
      type: 'success',
      title: editingHypothesis ? 'Hypothesis Updated' : 'Hypothesis Formulated',
      message: `"${newHypo.title.slice(0, 40)}..."`
    });
  };

  const toggleCompareSelection = (id: string) => {
    setSelectedForCompare((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  };

  const exportHypothesesMarkdown = () => {
    const content = hypotheses.map(h => `
# Hypothesis: ${h.title}
**Status:** ${h.status} | **Confidence:** ${(h.confidenceScore * 100).toFixed(0)}%
**Confidence Rationale:** ${h.confidenceBasis}

### Statement:
${h.statement}

### Theoretical Rationale:
${h.rationale}

### Supporting Evidence:
${h.supportingEvidence.map(e => `- **${e.sourceCitation}**: ${e.evidenceText}`).join('\n')}

### Contradicting Evidence:
${h.contradictingEvidence.map(e => `- **${e.sourceCitation}**: ${e.evidenceText}`).join('\n')}

### Assumptions:
${h.assumptions.map(a => `- ${a}`).join('\n')}

### Key Unknowns:
${h.unknowns.map(u => `- ${u}`).join('\n')}

### Suggested Empirical Tests:
${h.suggestedTests.map(t => `- ${t}`).join('\n')}
---
`).join('\n\n');

    const blob = new Blob([content], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `hypotheses-evaluation-${Date.now()}.md`;
    a.click();
    URL.revokeObjectURL(url);
    showToast({
      type: 'success',
      title: 'Exported Markdown Protocol',
      message: 'Hypotheses exported to Markdown file.'
    });
  };

  const comparedHypotheses = hypotheses.filter((h) => selectedForCompare.includes(h.id));

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <span>Hypothesis Lab</span>
            <span className="text-xs font-mono font-normal text-slate-500">
              ({hypotheses.length} Active Records)
            </span>
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Formulate, validate, and compare competing scientific explanations using structured evidence balance sheets.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            onClick={exportHypothesesMarkdown}
            className="px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors flex items-center gap-1.5"
            title="Export Markdown"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Export Markdown</span>
          </button>

          <button
            onClick={() => {
              setIsCompareMode(!isCompareMode);
              if (!isCompareMode && selectedForCompare.length === 0) {
                setSelectedForCompare(hypotheses.slice(0, 2).map((h) => h.id));
              }
            }}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 border ${
              isCompareMode
                ? 'bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300 border-teal-300 dark:border-teal-800'
                : 'text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-900'
            }`}
          >
            <ArrowLeftRight className="w-3.5 h-3.5" />
            <span>{isCompareMode ? 'Exit Comparison' : 'Compare Hypotheses'}</span>
          </button>

          <button
            onClick={handleOpenCreate}
            className="px-3.5 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors flex items-center gap-1.5 shadow-xs"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Formulate Hypothesis</span>
          </button>
        </div>
      </div>

      {/* Comparison Mode View */}
      {isCompareMode ? (
        <div className="space-y-4">
          <div className="p-3 bg-stone-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-lg flex flex-wrap items-center justify-between gap-3 text-xs">
            <span className="font-semibold text-slate-700 dark:text-slate-300">
              Select hypotheses to contrast side-by-side ({selectedForCompare.length} selected):
            </span>
            <div className="flex flex-wrap gap-2">
              {hypotheses.map((h) => (
                <button
                  key={h.id}
                  onClick={() => toggleCompareSelection(h.id)}
                  className={`px-2.5 py-1 text-xs rounded transition-colors ${
                    selectedForCompare.includes(h.id)
                      ? 'bg-teal-600 text-white font-medium'
                      : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-700'
                  }`}
                >
                  {h.title.slice(0, 32)}...
                </button>
              ))}
            </div>
          </div>

          {comparedHypotheses.length === 0 ? (
            <div className="p-12 text-center text-xs text-slate-500 border border-dashed border-slate-200 dark:border-slate-800 rounded-xl">
              Please select at least 2 hypotheses above to view side-by-side comparative analysis.
            </div>
          ) : (
            <div className={`grid grid-cols-1 md:grid-cols-${Math.min(comparedHypotheses.length, 3)} gap-4`}>
              {comparedHypotheses.map((hypo) => (
                <div
                  key={hypo.id}
                  className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-5 space-y-4 shadow-xs flex flex-col justify-between"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between pb-2 border-b border-slate-100 dark:border-slate-800">
                      <span className="text-[11px] font-mono text-slate-400 uppercase tracking-wider">
                        {hypo.status}
                      </span>
                      <div className="flex items-center gap-1.5 font-mono text-xs">
                        <span className="text-slate-400">Confidence:</span>
                        <span className="font-semibold text-slate-900 dark:text-slate-100 tabular-nums">
                          {(hypo.confidenceScore * 100).toFixed(0)}%
                        </span>
                      </div>
                    </div>

                    <h3 className="font-bold text-sm text-slate-900 dark:text-slate-100 leading-snug">
                      {hypo.title}
                    </h3>

                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-400 tracking-wider">Statement</span>
                      <p className="text-xs text-slate-700 dark:text-slate-300 mt-1 leading-relaxed">
                        {hypo.statement}
                      </p>
                    </div>

                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-400 tracking-wider">
                        Supporting ({hypo.supportingEvidence.length})
                      </span>
                      <div className="mt-1 space-y-1.5">
                        {hypo.supportingEvidence.map((ev) => (
                          <div key={ev.id} className="p-2 bg-emerald-50/40 dark:bg-emerald-950/20 border border-emerald-200/50 dark:border-emerald-900/30 rounded text-[11px] text-emerald-950 dark:text-emerald-200">
                            <p className="font-medium">{ev.sourceCitation}</p>
                            <p className="text-slate-600 dark:text-slate-400 mt-0.5">{ev.evidenceText}</p>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-400 tracking-wider">
                        Contradicting ({hypo.contradictingEvidence.length})
                      </span>
                      <div className="mt-1 space-y-1.5">
                        {hypo.contradictingEvidence.length === 0 ? (
                          <p className="text-[11px] text-slate-400 italic">No contradictory evidence identified yet.</p>
                        ) : (
                          hypo.contradictingEvidence.map((ev) => (
                            <div key={ev.id} className="p-2 bg-rose-50/40 dark:bg-rose-950/20 border border-rose-200/50 dark:border-rose-900/30 rounded text-[11px] text-rose-950 dark:text-rose-200">
                              <p className="font-medium">{ev.sourceCitation}</p>
                              <p className="text-slate-600 dark:text-slate-400 mt-0.5">{ev.evidenceText}</p>
                            </div>
                          ))
                        )}
                      </div>
                    </div>

                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-400 tracking-wider">Key Assumptions</span>
                      <ul className="mt-1 list-disc pl-4 space-y-0.5 text-[11px] text-slate-600 dark:text-slate-400">
                        {hypo.assumptions.map((assump, i) => (
                          <li key={i}>{assump}</li>
                        ))}
                      </ul>
                    </div>

                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-400 tracking-wider">Suggested Empirical Tests</span>
                      <ul className="mt-1 list-decimal pl-4 space-y-1 text-[11px] text-slate-700 dark:text-slate-300">
                        {hypo.suggestedTests.map((test, i) => (
                          <li key={i}>{test}</li>
                        ))}
                      </ul>
                    </div>
                  </div>

                  {onDesignExperimentForHypothesis && (
                    <div className="pt-3 border-t border-slate-100 dark:border-slate-800">
                      <button
                        onClick={() => onDesignExperimentForHypothesis(hypo)}
                        className="w-full py-2 px-3 text-xs font-semibold text-teal-700 dark:text-teal-300 bg-teal-50 dark:bg-teal-950/40 hover:bg-teal-100 dark:hover:bg-teal-900/40 border border-teal-200 dark:border-teal-800 rounded-md transition-colors flex items-center justify-center gap-1.5"
                      >
                        <TestTube2 className="w-3.5 h-3.5" />
                        <span>Design Experiment for this Hypothesis</span>
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      ) : (
        /* Standard List of Hypotheses */
        <div className="space-y-4">
          {hypotheses.map((hypo) => {
            const isExpanded = expandedId === hypo.id;
            return (
              <div
                key={hypo.id}
                className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs transition-colors"
              >
                {/* Header Card Row */}
                <div 
                  className="p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 cursor-pointer hover:bg-stone-50/50 dark:hover:bg-slate-800/20"
                  onClick={() => setExpandedId(isExpanded ? null : hypo.id)}
                >
                  <div className="space-y-1 flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500 font-mono">
                      <span className="uppercase text-[11px] tracking-wider text-teal-600 dark:text-teal-400 font-semibold">
                        {hypo.status}
                      </span>
                      <span>·</span>
                      <span>Updated {hypo.updatedAt}</span>
                      <span>·</span>
                      <span className="tabular-nums">
                        Confidence: {(hypo.confidenceScore * 100).toFixed(0)}%
                      </span>
                    </div>
                    <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                      {hypo.title}
                    </h3>
                    <p className="text-xs text-slate-600 dark:text-slate-400 line-clamp-2">
                      {hypo.statement}
                    </p>
                  </div>

                  <div className="flex items-center gap-2 shrink-0" onClick={(e) => e.stopPropagation()}>
                    <button
                      onClick={() => handleOpenEdit(hypo)}
                      className="p-1.5 text-slate-500 hover:text-slate-800 dark:hover:text-slate-200 rounded-md border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                      title="Edit Hypothesis"
                    >
                      <Edit3 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => {
                        if (confirm(`Are you sure you want to delete hypothesis: "${hypo.title}"?`)) {
                          onDeleteHypothesis(hypo.id);
                          showToast({
                            type: 'info',
                            title: 'Hypothesis Removed',
                            message: hypo.title
                          });
                        }
                      }}
                      className="p-1.5 text-rose-500 hover:text-rose-700 rounded-md border border-slate-200 dark:border-slate-800 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors"
                      title="Delete Hypothesis"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => setExpandedId(isExpanded ? null : hypo.id)}
                      className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-md border border-slate-200 dark:border-slate-800"
                      aria-label="Expand card"
                    >
                      {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                {/* Expanded Details */}
                {isExpanded && (
                  <div className="px-5 pb-6 pt-2 border-t border-slate-100 dark:border-slate-800 space-y-5 text-xs">
                    {/* Theoretical Rationale */}
                    <div>
                      <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                        Theoretical Mechanism & Rationale
                      </span>
                      <p className="text-xs text-slate-700 dark:text-slate-300 mt-1 leading-relaxed">
                        {hypo.rationale}
                      </p>
                    </div>

                    {/* Dual Evidence Balance Sheet */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {/* Supporting */}
                      <div className="p-4 bg-emerald-50/30 dark:bg-emerald-950/20 border border-emerald-200/50 dark:border-emerald-900/30 rounded-lg space-y-2.5">
                        <span className="text-[11px] font-semibold text-emerald-800 dark:text-emerald-300 uppercase tracking-wider flex items-center gap-1.5">
                          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                          Supporting Evidence ({hypo.supportingEvidence.length})
                        </span>
                        <div className="space-y-2">
                          {hypo.supportingEvidence.map((ev) => (
                            <div key={ev.id} className="p-2.5 bg-white dark:bg-slate-900 rounded border border-emerald-100 dark:border-emerald-950 text-xs">
                              <p className="font-semibold text-slate-800 dark:text-slate-200">{ev.sourceCitation}</p>
                              <p className="text-slate-600 dark:text-slate-400 mt-1 italic">"{ev.evidenceText}"</p>
                              <span className="text-[10px] font-mono text-emerald-600 dark:text-emerald-400 mt-1 block">
                                Type: {ev.evidenceType}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Contradicting */}
                      <div className="p-4 bg-rose-50/30 dark:bg-rose-950/20 border border-rose-200/50 dark:border-rose-900/30 rounded-lg space-y-2.5">
                        <span className="text-[11px] font-semibold text-rose-800 dark:text-rose-300 uppercase tracking-wider flex items-center gap-1.5">
                          <AlertCircle className="w-3.5 h-3.5 text-rose-600" />
                          Contradicting / Counter-Evidence ({hypo.contradictingEvidence.length})
                        </span>
                        <div className="space-y-2">
                          {hypo.contradictingEvidence.length === 0 ? (
                            <div className="p-3 bg-white dark:bg-slate-900 rounded border border-slate-100 dark:border-slate-800 text-[11px] text-slate-400 italic">
                              No explicit counter-evidence recorded yet. Further adversarial literature review recommended.
                            </div>
                          ) : (
                            hypo.contradictingEvidence.map((ev) => (
                              <div key={ev.id} className="p-2.5 bg-white dark:bg-slate-900 rounded border border-rose-100 dark:border-rose-950 text-xs">
                                <p className="font-semibold text-slate-800 dark:text-slate-200">{ev.sourceCitation}</p>
                                <p className="text-slate-600 dark:text-slate-400 mt-1 italic">"{ev.evidenceText}"</p>
                                <span className="text-[10px] font-mono text-rose-600 dark:text-rose-400 mt-1 block">
                                  Type: {ev.evidenceType}
                                </span>
                              </div>
                            ))
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Assumptions & Unknowns */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                          Key Operational Assumptions
                        </span>
                        <ul className="mt-1.5 list-disc pl-4 space-y-1 text-slate-600 dark:text-slate-300">
                          {hypo.assumptions.map((assump, i) => (
                            <li key={i}>{assump}</li>
                          ))}
                        </ul>
                      </div>

                      <div>
                        <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                          Critical Unknowns & Vulnerabilities
                        </span>
                        <ul className="mt-1.5 list-disc pl-4 space-y-1 text-slate-600 dark:text-slate-300">
                          {hypo.unknowns.map((unkn, i) => (
                            <li key={i}>{unkn}</li>
                          ))}
                        </ul>
                      </div>
                    </div>

                    {/* Confidence Assessment Basis */}
                    <div className="p-3.5 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 flex items-start gap-3">
                      <Scale className="w-4 h-4 text-teal-600 dark:text-teal-400 mt-0.5 shrink-0" />
                      <div className="space-y-1 flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-slate-900 dark:text-slate-100 text-xs">
                            Confidence Assessment: {(hypo.confidenceScore * 100).toFixed(0)}%
                          </span>
                          <span className="text-[10px] font-mono text-slate-400">
                            (Calibrated against 2-axis proof balance)
                          </span>
                        </div>
                        <p className="text-slate-600 dark:text-slate-400 leading-relaxed text-xs">
                          {hypo.confidenceBasis}
                        </p>
                      </div>
                    </div>

                    {/* Suggested Empirical Tests */}
                    <div>
                      <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                        Suggested Discriminating Experiments
                      </span>
                      <div className="mt-2 space-y-1.5">
                        {hypo.suggestedTests.map((test, i) => (
                          <div key={i} className="p-2.5 bg-stone-50 dark:bg-slate-800/40 rounded-md border border-slate-200 dark:border-slate-800 flex items-start gap-2.5 text-xs text-slate-800 dark:text-slate-200">
                            <span className="font-mono text-xs font-semibold text-teal-600 dark:text-teal-400 mt-0.5">
                              0{i + 1}.
                            </span>
                            <p className="flex-1">{test}</p>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Action Bar */}
                    {onDesignExperimentForHypothesis && (
                      <div className="pt-2 flex justify-end">
                        <button
                          onClick={() => onDesignExperimentForHypothesis(hypo)}
                          className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-500 rounded-md transition-colors flex items-center gap-2 shadow-xs"
                        >
                          <TestTube2 className="w-3.5 h-3.5" />
                          <span>Generate Experiment Protocol for this Hypothesis</span>
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Modal / Slide-in: Formulate or Edit Hypothesis */}
      {isCreatingNew && (
        <div 
          className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
          onClick={() => setIsCreatingNew(false)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-xl overflow-hidden p-6 max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <FlaskConical className="w-4 h-4 text-teal-600 dark:text-teal-400" />
                <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100">
                  {editingHypothesis ? 'Edit Hypothesis Record' : 'Formulate New Scientific Hypothesis'}
                </h3>
              </div>
              <button
                onClick={() => setIsCreatingNew(false)}
                className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSaveForm} className="py-4 space-y-4 text-xs">
              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Hypothesis Title *
                </label>
                <input
                  type="text"
                  required
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="e.g., SOS1 Allosteric Blockade Synergizes with MRTX1133"
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500 text-xs"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Hypothesis Statement (Causal Claim) *
                </label>
                <textarea
                  rows={3}
                  required
                  value={formData.statement}
                  onChange={(e) => setFormData({ ...formData, statement: e.target.value })}
                  placeholder="State the testable causal mechanism clearly without hand-waving..."
                  className="w-full p-3 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500 text-xs leading-relaxed"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Theoretical Rationale & Pathway Dynamics
                </label>
                <textarea
                  rows={2}
                  value={formData.rationale}
                  onChange={(e) => setFormData({ ...formData, rationale: e.target.value })}
                  placeholder="Explain why this mechanism occurs based on existing biochemical or physical laws..."
                  className="w-full p-3 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500 text-xs"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                    Confidence Assessment Score ({Math.round((Number(formData.confidenceScore) || 0.5) * 100)}%)
                  </label>
                  <input
                    type="range"
                    min="0.1"
                    max="0.99"
                    step="0.01"
                    value={formData.confidenceScore}
                    onChange={(e) => setFormData({ ...formData, confidenceScore: parseFloat(e.target.value) })}
                    className="w-full accent-teal-600"
                  />
                </div>

                <div>
                  <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                    Investigation Status
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as any })}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs"
                  >
                    <option value="formulated">Formulated</option>
                    <option value="testing">Testing in Progress</option>
                    <option value="supported">Supported by Data</option>
                    <option value="refuted">Refuted by Trials</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Confidence Basis Rationale
                </label>
                <input
                  type="text"
                  value={formData.confidenceBasis}
                  onChange={(e) => setFormData({ ...formData, confidenceBasis: e.target.value })}
                  placeholder="e.g., Supported by 2 independent in vivo studies; tempered by limited clinical phase 1 safety windows."
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500 text-xs"
                />
              </div>

              <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setIsCreatingNew(false)}
                  className="px-3.5 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-md transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors shadow-xs"
                >
                  {editingHypothesis ? 'Save Changes' : 'Record Hypothesis'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
