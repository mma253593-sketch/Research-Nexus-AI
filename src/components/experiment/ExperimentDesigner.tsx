import React, { useState } from 'react';
import { ExperimentPlan } from '../../types/research';
import { 
  TestTube2, Plus, Trash2, AlertTriangle, CheckCircle2, 
  FileText, Download, Copy, Printer, Sliders, ShieldAlert,
  ArrowRight, Sparkles, Check, Info
} from 'lucide-react';
import { useToast } from '../common/Toast';

interface ExperimentDesignerProps {
  experiments: ExperimentPlan[];
  onSaveExperiment: (experiment: ExperimentPlan) => void;
  activeProjectId?: string;
  initialHypothesisTitle?: string;
}

export function ExperimentDesigner({
  experiments,
  onSaveExperiment,
  activeProjectId,
  initialHypothesisTitle
}: ExperimentDesignerProps) {
  const { showToast } = useToast();
  const [selectedExperiment, setSelectedExperiment] = useState<ExperimentPlan>(experiments[0]);
  const [isEditing, setIsEditing] = useState(false);

  // Form State
  const [title, setTitle] = useState(selectedExperiment?.title || '');
  const [objective, setObjective] = useState(selectedExperiment?.researchObjective || '');
  const [measurementMethod, setMeasurementMethod] = useState(selectedExperiment?.measurementMethod || '');
  const [expectedOutcomes, setExpectedOutcomes] = useState(selectedExperiment?.expectedOutcomes || '');
  
  const [independentVars, setIndependentVars] = useState(
    selectedExperiment?.independentVariables || [{ name: '', range: '', unit: '' }]
  );
  const [dependentVars, setDependentVars] = useState(
    selectedExperiment?.dependentVariables || [{ name: '', measurementMethod: '', expectedBaseline: '' }]
  );
  const [controlledVars, setControlledVars] = useState<string[]>(
    selectedExperiment?.controlledVariables || ['']
  );
  const [equipment, setEquipment] = useState<string[]>(
    selectedExperiment?.equipmentAndResources || ['']
  );
  const [procedureSteps, setProcedureSteps] = useState<string[]>(
    selectedExperiment?.procedureSteps || ['']
  );
  const [alternativeExplanations, setAlternativeExplanations] = useState<string[]>(
    selectedExperiment?.alternativeExplanations || ['']
  );
  const [statisticalTest, setStatisticalTest] = useState(
    selectedExperiment?.evaluationCriteria?.statisticalTest || ''
  );
  const [significanceThreshold, setSignificanceThreshold] = useState(
    selectedExperiment?.evaluationCriteria?.significanceThreshold || 'p < 0.01'
  );
  const [replicationCount, setReplicationCount] = useState(
    selectedExperiment?.evaluationCriteria?.replicationCount || 3
  );
  const [successMetric, setSuccessMetric] = useState(
    selectedExperiment?.evaluationCriteria?.successMetric || ''
  );

  // Validation Warnings Calculator
  const computeWarnings = () => {
    const list: string[] = [];
    if (!objective.trim()) list.push('Research objective is undefined.');
    if (independentVars.filter(v => v.name.trim()).length === 0) {
      list.push('No independent variables parameterized.');
    }
    if (dependentVars.filter(v => v.name.trim()).length === 0) {
      list.push('No dependent variables defined.');
    }
    if (controlledVars.filter(v => v.trim()).length === 0) {
      list.push('Zero controlled variables declared. Severe risk of unmonitored confounders.');
    }
    if (procedureSteps.filter(s => s.trim()).length < 2) {
      list.push('Procedure contains fewer than 2 sequential execution steps.');
    }
    if (!statisticalTest.trim()) {
      list.push('Evaluation criteria missing designated statistical significance test (e.g. ANOVA, Welch t-test).');
    }
    if (replicationCount < 3) {
      list.push('Biological/technical replication count is below standard minimum (n ≥ 3).');
    }
    return list;
  };

  const warnings = computeWarnings();

  const handleSelectExperiment = (exp: ExperimentPlan) => {
    setSelectedExperiment(exp);
    setTitle(exp.title);
    setObjective(exp.researchObjective);
    setMeasurementMethod(exp.measurementMethod);
    setExpectedOutcomes(exp.expectedOutcomes);
    setIndependentVars(exp.independentVariables);
    setDependentVars(exp.dependentVariables);
    setControlledVars(exp.controlledVariables);
    setEquipment(exp.equipmentAndResources);
    setProcedureSteps(exp.procedureSteps);
    setAlternativeExplanations(exp.alternativeExplanations);
    setStatisticalTest(exp.evaluationCriteria.statisticalTest);
    setSignificanceThreshold(exp.evaluationCriteria.significanceThreshold);
    setReplicationCount(exp.evaluationCriteria.replicationCount);
    setSuccessMetric(exp.evaluationCriteria.successMetric);
    setIsEditing(false);
  };

  const handleCreateNew = () => {
    setTitle(initialHypothesisTitle ? `Empirical Protocol: ${initialHypothesisTitle}` : 'New Empirical Investigation Protocol');
    setObjective('');
    setMeasurementMethod('');
    setExpectedOutcomes('');
    setIndependentVars([{ name: 'Primary Treatment Concentration', range: '0, 10, 50, 200', unit: 'nM' }]);
    setDependentVars([{ name: 'Primary Phenotypic Endpoint', measurementMethod: 'Fluorescence spectrophotometry', expectedBaseline: '100% control' }]);
    setControlledVars(['Incubation temperature (37.0 ± 0.5°C)', 'Atmospheric CO2 (5.0%)', 'Vehicle solvent concentration']);
    setEquipment(['Biosafety Cabinet Class II', 'Microplate Spectrophotometer']);
    setProcedureSteps(['Seed biological replicates under standardized density.', 'Equilibrate test compounds in growth media.', 'Measure endpoint signal at designated timepoints.']);
    setAlternativeExplanations(['Non-specific cytotoxicity or off-target membrane disruption.']);
    setStatisticalTest('Two-way ANOVA with Dunnett multiple comparisons test');
    setSignificanceThreshold('p < 0.05');
    setReplicationCount(3);
    setSuccessMetric('>50% reduction in phenotypic endpoint relative to vehicle baseline');
    setIsEditing(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !objective.trim()) {
      showToast({
        type: 'warning',
        title: 'Title & Objective Required',
        message: 'Please provide both an experiment title and research objective.'
      });
      return;
    }

    const updatedPlan: ExperimentPlan = {
      id: isEditing && selectedExperiment?.id ? selectedExperiment.id : `exp-${Date.now()}`,
      projectId: activeProjectId || 'proj-kras-01',
      title: title.trim(),
      researchObjective: objective.trim(),
      independentVariables: independentVars.filter(v => v.name.trim()),
      dependentVariables: dependentVars.filter(v => v.name.trim()),
      controlledVariables: controlledVars.filter(c => c.trim()),
      equipmentAndResources: equipment.filter(e => e.trim()),
      procedureSteps: procedureSteps.filter(s => s.trim()),
      measurementMethod: measurementMethod.trim() || 'Specified per protocol assay',
      expectedOutcomes: expectedOutcomes.trim() || 'Pre-specified threshold confirmation',
      alternativeExplanations: alternativeExplanations.filter(a => a.trim()),
      evaluationCriteria: {
        statisticalTest: statisticalTest.trim() || 'Two-tailed Student t-test',
        significanceThreshold: significanceThreshold.trim() || 'p < 0.05',
        replicationCount: Number(replicationCount) || 3,
        successMetric: successMetric.trim() || 'Statistically significant effect size'
      },
      warnings,
      createdAt: selectedExperiment?.createdAt || new Date().toISOString().split('T')[0],
      status: warnings.length === 0 ? 'ready' : 'draft'
    };

    onSaveExperiment(updatedPlan);
    setSelectedExperiment(updatedPlan);
    setIsEditing(false);
    showToast({
      type: 'success',
      title: 'Experiment Protocol Saved',
      message: updatedPlan.title
    });
  };

  const exportMarkdown = () => {
    const p = selectedExperiment;
    const md = `
# EXPERIMENT PROTOCOL: ${p.title}
**Status:** ${p.status} | **Created:** ${p.createdAt}
**Project ID:** ${p.projectId}

## 1. RESEARCH OBJECTIVE
${p.researchObjective}

## 2. VARIABLES MATRIX
### Independent Variables:
${p.independentVariables.map(v => `- **${v.name}:** Range [${v.range}] (${v.unit})`).join('\n')}

### Dependent Variables:
${p.dependentVariables.map(v => `- **${v.name}:** Measurement via ${v.measurementMethod} (Baseline: ${v.expectedBaseline})`).join('\n')}

### Controlled Variables:
${p.controlledVariables.map(c => `- ${c}`).join('\n')}

## 3. EQUIPMENT & REAGENTS
${p.equipmentAndResources.map(e => `- ${e}`).join('\n')}

## 4. STEP-BY-STEP PROCEDURE
${p.procedureSteps.map((s, i) => `${i + 1}. ${s}`).join('\n')}

## 5. MEASUREMENT METHODOLOGY & EXPECTED OUTCOMES
- **Measurement Method:** ${p.measurementMethod}
- **Expected Outcomes:** ${p.expectedOutcomes}

## 6. ALTERNATIVE EXPLANATIONS & CONFOUNDS
${p.alternativeExplanations.map(a => `- ${a}`).join('\n')}

## 7. EVALUATION CRITERIA & STATISTICAL RIGOR
- **Statistical Test:** ${p.evaluationCriteria.statisticalTest}
- **Significance Threshold:** ${p.evaluationCriteria.significanceThreshold}
- **Replicates (n):** ${p.evaluationCriteria.replicationCount}
- **Success Metric:** ${p.evaluationCriteria.successMetric}
`;
    const blob = new Blob([md], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `experiment-protocol-${selectedExperiment.id}.md`;
    a.click();
    URL.revokeObjectURL(url);
    showToast({
      type: 'success',
      title: 'Protocol Exported',
      message: 'Markdown file generated.'
    });
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-stone-300 dark:border-stone-800">
        <div>
          <span className="text-[11px] font-mono uppercase tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
            Empirical Architecture · Protocol Specifications
          </span>
          <h1 className="font-serif text-2xl font-normal text-[#143628] dark:text-[#FAF7F2] flex items-center gap-2 mt-0.5">
            <span>Experiment Designer & Protocol Architecture</span>
          </h1>
          <p className="text-xs text-stone-600 dark:text-stone-400 mt-1 font-sans">
            Parameterize independent, dependent, and controlled variables into structured, reproducible protocols with automated rigor checks.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={exportMarkdown}
            className="px-3 py-1.5 text-xs font-medium text-stone-700 dark:text-stone-300 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-100 dark:hover:bg-stone-800 transition-colors flex items-center gap-1.5 cursor-pointer"
          >
            <Download className="w-3.5 h-3.5 stroke-[1.75]" />
            <span>Export Protocol</span>
          </button>
          
          <button
            onClick={() => setIsEditing(!isEditing)}
            className={`px-3 py-1.5 text-xs font-medium rounded-xs transition-colors border cursor-pointer ${
              isEditing
                ? 'bg-stone-200 dark:bg-stone-800 text-stone-900 dark:text-stone-100 border-stone-400 dark:border-stone-600'
                : 'text-stone-700 dark:text-stone-300 border-stone-300 dark:border-stone-700 hover:bg-stone-100 dark:hover:bg-stone-800'
            }`}
          >
            {isEditing ? 'Cancel Editing' : 'Edit Parameters'}
          </button>

          <button
            onClick={handleCreateNew}
            className="px-3.5 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors flex items-center gap-1.5 shadow-xs cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>New Protocol</span>
          </button>
        </div>
      </div>

      {/* Protocol Selector Bar */}
      <div className="flex items-center gap-2 overflow-x-auto py-1.5 border-b border-stone-200 dark:border-stone-800">
        <span className="text-xs font-mono text-stone-400 whitespace-nowrap mr-1 uppercase tracking-wider">Registered:</span>
        {experiments.map((exp) => (
          <button
            key={exp.id}
            onClick={() => handleSelectExperiment(exp)}
            className={`px-3 py-1 text-xs rounded-xs whitespace-nowrap transition-colors flex items-center gap-2 cursor-pointer ${
              selectedExperiment?.id === exp.id
                ? 'bg-[#1B4332] text-white font-medium shadow-xs'
                : 'bg-white dark:bg-[#161C22] text-stone-700 dark:text-stone-300 border border-stone-300 dark:border-stone-700 hover:bg-stone-100 dark:hover:bg-stone-800'
            }`}
          >
            <span>{exp.title.slice(0, 32)}...</span>
            <span className={`text-[10px] font-mono px-1 rounded-xs ${exp.status === 'ready' ? 'text-emerald-400 font-semibold' : 'text-amber-400 font-semibold'}`}>
              ● {exp.status}
            </span>
          </button>
        ))}
      </div>

      {/* Warnings & Integrity Strip */}
      {warnings.length > 0 && (
        <div className="p-4 bg-amber-50/70 dark:bg-amber-950/20 border border-amber-300 dark:border-amber-900/60 rounded-xs space-y-2 font-sans">
          <div className="flex items-center gap-2 text-xs font-semibold text-amber-900 dark:text-amber-200">
            <ShieldAlert className="w-4 h-4 text-[#B45309] shrink-0" />
            <span>Protocol Rigor Diagnostics ({warnings.length} Essential Items Missing)</span>
          </div>
          <ul className="list-disc pl-5 space-y-1 text-xs text-amber-950 dark:text-amber-300">
            {warnings.map((w, idx) => (
              <li key={idx}>{w}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Main Form or Structured Protocol View */}
      {isEditing ? (
        <form onSubmit={handleSave} className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm p-6 space-y-6 shadow-xs text-xs font-sans">
          <div className="space-y-4">
            <h2 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2] border-b border-stone-200 dark:border-stone-800 pb-2">
              1. Title & Primary Research Objective
            </h2>
            <div>
              <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                Experiment Title *
              </label>
              <input
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-3 py-2 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
              />
            </div>
            <div>
              <label className="font-medium text-stone-700 dark:text-stone-300 block mb-1">
                Research Objective *
              </label>
              <textarea
                rows={3}
                required
                value={objective}
                onChange={(e) => setObjective(e.target.value)}
                placeholder="Explicitly define what scientific unknown or hypothesis this experiment tests..."
                className="w-full p-3 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] text-xs leading-relaxed focus:ring-1 focus:ring-[#1B4332] focus:outline-none"
              />
            </div>
          </div>

          {/* Variables Form */}
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-stone-200 dark:border-stone-800 pb-2">
              <h2 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
                2. Independent Variables (Treatment Conditions)
              </h2>
              <button
                type="button"
                onClick={() => setIndependentVars([...independentVars, { name: '', range: '', unit: '' }])}
                className="text-xs text-[#1B4332] dark:text-[#52B788] font-medium hover:underline flex items-center gap-1 cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Variable</span>
              </button>
            </div>
            <div className="space-y-3">
              {independentVars.map((v, idx) => (
                <div key={idx} className="grid grid-cols-1 sm:grid-cols-12 gap-2 items-center bg-stone-50/70 dark:bg-[#11161B] p-2.5 rounded-xs border border-stone-200 dark:border-stone-800">
                  <div className="sm:col-span-5">
                    <input
                      type="text"
                      placeholder="Variable Name (e.g. MRTX1133 Concentration)"
                      value={v.name}
                      onChange={(e) => {
                        const copy = [...independentVars];
                        copy[idx].name = e.target.value;
                        setIndependentVars(copy);
                      }}
                      className="w-full px-2.5 py-1.5 bg-white dark:bg-[#161C22] border border-stone-300 dark:border-stone-700 rounded-xs text-xs focus:ring-1 focus:ring-[#1B4332]"
                    />
                  </div>
                  <div className="sm:col-span-4">
                    <input
                      type="text"
                      placeholder="Test Range (e.g. 0, 10, 30, 100, 300)"
                      value={v.range}
                      onChange={(e) => {
                        const copy = [...independentVars];
                        copy[idx].range = e.target.value;
                        setIndependentVars(copy);
                      }}
                      className="w-full px-2.5 py-1.5 bg-white dark:bg-[#161C22] border border-stone-300 dark:border-stone-700 rounded-xs text-xs focus:ring-1 focus:ring-[#1B4332]"
                    />
                  </div>
                  <div className="sm:col-span-2">
                    <input
                      type="text"
                      placeholder="Unit (e.g. nM)"
                      value={v.unit}
                      onChange={(e) => {
                        const copy = [...independentVars];
                        copy[idx].unit = e.target.value;
                        setIndependentVars(copy);
                      }}
                      className="w-full px-2.5 py-1.5 bg-white dark:bg-[#161C22] border border-stone-300 dark:border-stone-700 rounded-xs text-xs font-mono focus:ring-1 focus:ring-[#1B4332]"
                    />
                  </div>
                  <div className="sm:col-span-1 flex justify-end">
                    <button
                      type="button"
                      onClick={() => setIndependentVars(independentVars.filter((_, i) => i !== idx))}
                      className="text-stone-400 hover:text-rose-500 p-1 cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Controlled Variables */}
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-2">
              <h2 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                3. Controlled Variables (Confound Mitigation)
              </h2>
              <button
                type="button"
                onClick={() => setControlledVars([...controlledVars, ''])}
                className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline flex items-center gap-1"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Control</span>
              </button>
            </div>
            <div className="space-y-2">
              {controlledVars.map((c, idx) => (
                <div key={idx} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={c}
                    onChange={(e) => {
                      const copy = [...controlledVars];
                      copy[idx] = e.target.value;
                      setControlledVars(copy);
                    }}
                    placeholder="e.g. Fixed passage number (P4-8) / Vehicle DMSO fixed at 0.1%"
                    className="flex-1 px-3 py-1.5 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-xs text-[#1F2421] dark:text-[#E8ECE9] focus:ring-1 focus:ring-[#1B4332]"
                  />
                  <button
                    type="button"
                    onClick={() => setControlledVars(controlledVars.filter((_, i) => i !== idx))}
                    className="text-stone-400 hover:text-rose-500 p-1 cursor-pointer"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Step-by-Step Procedure */}
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-stone-200 dark:border-stone-800 pb-2">
              <h2 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
                4. Procedural Protocol Steps
              </h2>
              <button
                type="button"
                onClick={() => setProcedureSteps([...procedureSteps, ''])}
                className="text-xs text-[#1B4332] dark:text-[#52B788] font-medium hover:underline flex items-center gap-1 cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Step</span>
              </button>
            </div>
            <div className="space-y-2">
              {procedureSteps.map((step, idx) => (
                <div key={idx} className="flex items-start gap-2">
                  <span className="font-mono text-xs font-semibold text-stone-400 mt-2 shrink-0">
                    Step {idx + 1}:
                  </span>
                  <textarea
                    rows={2}
                    value={step}
                    onChange={(e) => {
                      const copy = [...procedureSteps];
                      copy[idx] = e.target.value;
                      setProcedureSteps(copy);
                    }}
                    placeholder={`Detailed action for Step ${idx + 1}...`}
                    className="flex-1 p-2 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-xs text-[#1F2421] dark:text-[#E8ECE9] leading-relaxed focus:ring-1 focus:ring-[#1B4332]"
                  />
                  <button
                    type="button"
                    onClick={() => setProcedureSteps(procedureSteps.filter((_, i) => i !== idx))}
                    className="text-stone-400 hover:text-rose-500 p-1 mt-1 cursor-pointer"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Evaluation Criteria & Statistical Plan */}
          <div className="space-y-4 border-t border-stone-200 dark:border-stone-800 pt-4">
            <h2 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2]">
              5. Statistical Evaluation Criteria
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="font-semibold text-stone-700 dark:text-stone-300 block mb-1">
                  Statistical Test Model *
                </label>
                <input
                  type="text"
                  value={statisticalTest}
                  onChange={(e) => setStatisticalTest(e.target.value)}
                  placeholder="e.g. Two-way ANOVA with Tukey post-hoc"
                  className="w-full px-3 py-1.5 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-xs text-[#1F2421] dark:text-[#E8ECE9]"
                />
              </div>
              <div>
                <label className="font-semibold text-stone-700 dark:text-stone-300 block mb-1">
                  Significance Threshold
                </label>
                <input
                  type="text"
                  value={significanceThreshold}
                  onChange={(e) => setSignificanceThreshold(e.target.value)}
                  placeholder="e.g. p < 0.01; CI < 0.70"
                  className="w-full px-3 py-1.5 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-xs font-mono text-[#1F2421] dark:text-[#E8ECE9]"
                />
              </div>
              <div>
                <label className="font-semibold text-stone-700 dark:text-stone-300 block mb-1">
                  Replication Count (n)
                </label>
                <input
                  type="number"
                  min="1"
                  max="50"
                  value={replicationCount}
                  onChange={(e) => setReplicationCount(parseInt(e.target.value) || 1)}
                  className="w-full px-3 py-1.5 bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-xs font-mono text-[#1F2421] dark:text-[#E8ECE9]"
                />
              </div>
            </div>
          </div>

          {/* Submit Actions */}
          <div className="pt-4 border-t border-stone-200 dark:border-stone-800 flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setIsEditing(false)}
              className="px-4 py-2 text-xs font-medium text-stone-700 dark:text-stone-300 bg-stone-100 dark:bg-stone-800 hover:bg-stone-200 rounded-xs cursor-pointer transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-5 py-2 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs shadow-xs cursor-pointer transition-colors"
            >
              Save Protocol & Verify Integrity
            </button>
          </div>
        </form>
      ) : (
        /* Structured Read-only Protocol View */
        <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm overflow-hidden shadow-xs">
          {/* Top Title Banner */}
          <div className="p-6 border-b border-stone-200 dark:border-stone-800 bg-stone-50/70 dark:bg-[#11161B] flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2 text-xs font-mono text-stone-500">
                <span className="uppercase tracking-wider text-[#B45309] dark:text-[#F59E0B] font-semibold">
                  Protocol Specification
                </span>
                <span>·</span>
                <span>Created {selectedExperiment.createdAt}</span>
                <span>·</span>
                <span className={`capitalize font-semibold ${selectedExperiment.status === 'ready' ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400'}`}>
                  ● {selectedExperiment.status}
                </span>
              </div>
              <h2 className="font-serif text-lg font-normal text-[#143628] dark:text-[#FAF7F2]">
                {selectedExperiment.title}
              </h2>
            </div>
            <button
              onClick={() => setIsEditing(true)}
              className="px-3.5 py-1.5 text-xs font-medium text-stone-700 dark:text-stone-300 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-100 dark:hover:bg-stone-800 transition-colors shrink-0 cursor-pointer"
            >
              Modify Protocol
            </button>
          </div>

          <div className="p-6 space-y-6 text-xs font-sans">
            {/* Objective */}
            <div className="space-y-1.5">
              <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium">
                1. Scientific Objective
              </span>
              <p className="p-3.5 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800 text-stone-800 dark:text-stone-200 leading-relaxed">
                {selectedExperiment.researchObjective}
              </p>
            </div>

            {/* Variables Matrix Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Independent */}
              <div className="space-y-2 p-4 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800">
                <span className="text-[11px] font-mono text-[#1B4332] dark:text-[#52B788] uppercase tracking-wider block font-semibold">
                  Independent Variables
                </span>
                <div className="space-y-2">
                  {selectedExperiment.independentVariables.map((v, i) => (
                    <div key={i} className="text-xs">
                      <p className="font-semibold text-stone-900 dark:text-stone-100">{v.name}</p>
                      <p className="font-mono text-[11px] text-stone-500 dark:text-stone-400">
                        Range: {v.range} {v.unit}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Dependent */}
              <div className="space-y-2 p-4 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800">
                <span className="text-[11px] font-mono text-[#1B4332] dark:text-[#52B788] uppercase tracking-wider block font-semibold">
                  Dependent Endpoints
                </span>
                <div className="space-y-2">
                  {selectedExperiment.dependentVariables.map((v, i) => (
                    <div key={i} className="text-xs">
                      <p className="font-semibold text-stone-900 dark:text-stone-100">{v.name}</p>
                      <p className="text-[11px] text-stone-600 dark:text-stone-400">
                        Method: {v.measurementMethod}
                      </p>
                      <p className="font-mono text-[10px] text-stone-400">Baseline: {v.expectedBaseline}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Controlled */}
              <div className="space-y-2 p-4 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800">
                <span className="text-[11px] font-mono text-stone-500 uppercase tracking-wider block font-semibold">
                  Controlled Variables ({selectedExperiment.controlledVariables.length})
                </span>
                <ul className="list-disc pl-4 space-y-1 text-stone-600 dark:text-stone-400 text-[11px]">
                  {selectedExperiment.controlledVariables.map((c, i) => (
                    <li key={i}>{c}</li>
                  ))}
                </ul>
              </div>
            </div>

            {/* Equipment & Reagents */}
            <div className="space-y-1.5">
              <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium">
                2. Instrumentation & Reagents
              </span>
              <div className="flex flex-wrap gap-2">
                {selectedExperiment.equipmentAndResources.map((eq, i) => (
                  <span
                    key={i}
                    className="px-2.5 py-1 bg-stone-100 dark:bg-[#161C22] rounded-xs border border-stone-200 dark:border-stone-700 text-stone-700 dark:text-stone-300 font-mono text-[11px]"
                  >
                    {eq}
                  </span>
                ))}
              </div>
            </div>

            {/* Procedural Sequence */}
            <div className="space-y-2">
              <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium">
                3. Execution Sequence Protocol
              </span>
              <div className="space-y-2">
                {selectedExperiment.procedureSteps.map((step, i) => (
                  <div
                    key={i}
                    className="p-3 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800 flex items-start gap-3"
                  >
                    <span className="font-mono text-xs font-semibold text-[#1B4332] dark:text-[#52B788] mt-0.5">
                      0{i + 1}.
                    </span>
                    <p className="flex-1 text-xs text-stone-800 dark:text-stone-200 leading-relaxed">
                      {step}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            {/* Statistical Plan & Power */}
            <div className="p-4 bg-[#1B4332]/5 dark:bg-[#52B788]/10 border border-[#1B4332]/20 dark:border-[#52B788]/20 rounded-xs space-y-2">
              <span className="text-[11px] font-mono text-[#143628] dark:text-[#52B788] uppercase tracking-wider block font-semibold">
                4. Pre-Registered Statistical Evaluation Criteria
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs pt-1">
                <div>
                  <span className="text-stone-500 block text-[11px]">Primary Statistical Model:</span>
                  <span className="font-semibold text-stone-900 dark:text-stone-100">
                    {selectedExperiment.evaluationCriteria.statisticalTest}
                  </span>
                </div>
                <div>
                  <span className="text-stone-500 block text-[11px]">Significance Cutoff:</span>
                  <span className="font-mono font-semibold text-[#1B4332] dark:text-[#52B788]">
                    {selectedExperiment.evaluationCriteria.significanceThreshold}
                  </span>
                </div>
                <div>
                  <span className="text-stone-500 block text-[11px]">Replication Power:</span>
                  <span className="font-mono font-semibold text-stone-900 dark:text-stone-100">
                    n = {selectedExperiment.evaluationCriteria.replicationCount} independent replicates
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
