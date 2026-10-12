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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <span>Experiment Designer & Protocol Architecture</span>
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Parameterize independent, dependent, and controlled variables into structured, reproducible protocols with automated rigor checks.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={exportMarkdown}
            className="px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors flex items-center gap-1.5"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Export Protocol</span>
          </button>
          
          <button
            onClick={() => setIsEditing(!isEditing)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors border ${
              isEditing
                ? 'bg-stone-200 dark:bg-slate-800 text-slate-900 dark:text-slate-100 border-slate-300 dark:border-slate-700'
                : 'text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-900'
            }`}
          >
            {isEditing ? 'Cancel Editing' : 'Edit Parameters'}
          </button>

          <button
            onClick={handleCreateNew}
            className="px-3.5 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors flex items-center gap-1.5 shadow-xs"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>New Protocol</span>
          </button>
        </div>
      </div>

      {/* Protocol Selector Bar */}
      <div className="flex items-center gap-2 overflow-x-auto py-1 border-b border-slate-100 dark:border-slate-800">
        <span className="text-xs text-slate-400 font-medium whitespace-nowrap mr-1">Stored Protocols:</span>
        {experiments.map((exp) => (
          <button
            key={exp.id}
            onClick={() => handleSelectExperiment(exp)}
            className={`px-3 py-1 text-xs rounded-md whitespace-nowrap transition-colors flex items-center gap-2 ${
              selectedExperiment?.id === exp.id
                ? 'bg-slate-900 text-white dark:bg-slate-100 dark:text-slate-900 font-semibold'
                : 'bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800'
            }`}
          >
            <span>{exp.title.slice(0, 32)}...</span>
            <span className={`text-[10px] font-mono px-1 rounded ${exp.status === 'ready' ? 'text-emerald-500' : 'text-amber-500'}`}>
              ● {exp.status}
            </span>
          </button>
        ))}
      </div>

      {/* Warnings & Integrity Strip */}
      {warnings.length > 0 && (
        <div className="p-4 bg-amber-50/50 dark:bg-amber-950/20 border border-amber-200/80 dark:border-amber-900/60 rounded-xl space-y-2">
          <div className="flex items-center gap-2 text-xs font-semibold text-amber-900 dark:text-amber-200">
            <ShieldAlert className="w-4 h-4 text-amber-600 shrink-0" />
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
        <form onSubmit={handleSave} className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 space-y-6 shadow-xs text-xs">
          <div className="space-y-4">
            <h2 className="text-sm font-bold text-slate-900 dark:text-slate-100 border-b border-slate-100 dark:border-slate-800 pb-2">
              1. Title & Primary Research Objective
            </h2>
            <div>
              <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                Experiment Title *
              </label>
              <input
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs focus:ring-1 focus:ring-teal-500"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                Research Objective *
              </label>
              <textarea
                rows={3}
                required
                value={objective}
                onChange={(e) => setObjective(e.target.value)}
                placeholder="Explicitly define what scientific unknown or hypothesis this experiment tests..."
                className="w-full p-3 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 text-xs leading-relaxed"
              />
            </div>
          </div>

          {/* Variables Form */}
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-2">
              <h2 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                2. Independent Variables (Treatment Conditions)
              </h2>
              <button
                type="button"
                onClick={() => setIndependentVars([...independentVars, { name: '', range: '', unit: '' }])}
                className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline flex items-center gap-1"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Variable</span>
              </button>
            </div>
            <div className="space-y-3">
              {independentVars.map((v, idx) => (
                <div key={idx} className="grid grid-cols-1 sm:grid-cols-12 gap-2 items-center bg-stone-50/60 dark:bg-slate-800/40 p-2.5 rounded-lg border border-slate-200 dark:border-slate-800">
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
                      className="w-full px-2.5 py-1.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded text-xs"
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
                      className="w-full px-2.5 py-1.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded text-xs"
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
                      className="w-full px-2.5 py-1.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded text-xs font-mono"
                    />
                  </div>
                  <div className="sm:col-span-1 flex justify-end">
                    <button
                      type="button"
                      onClick={() => setIndependentVars(independentVars.filter((_, i) => i !== idx))}
                      className="text-rose-500 hover:text-rose-700 p-1"
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
                    className="flex-1 px-3 py-1.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded text-xs"
                  />
                  <button
                    type="button"
                    onClick={() => setControlledVars(controlledVars.filter((_, i) => i !== idx))}
                    className="text-slate-400 hover:text-rose-500 p-1"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Step-by-Step Procedure */}
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-2">
              <h2 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                4. Procedural Protocol Steps
              </h2>
              <button
                type="button"
                onClick={() => setProcedureSteps([...procedureSteps, ''])}
                className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline flex items-center gap-1"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Step</span>
              </button>
            </div>
            <div className="space-y-2">
              {procedureSteps.map((step, idx) => (
                <div key={idx} className="flex items-start gap-2">
                  <span className="font-mono text-xs font-semibold text-slate-400 mt-2 shrink-0">
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
                    className="flex-1 p-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded text-xs"
                  />
                  <button
                    type="button"
                    onClick={() => setProcedureSteps(procedureSteps.filter((_, i) => i !== idx))}
                    className="text-slate-400 hover:text-rose-500 p-1 mt-1"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Evaluation Criteria & Statistical Plan */}
          <div className="space-y-4 border-t border-slate-100 dark:border-slate-800 pt-4">
            <h2 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              5. Statistical Evaluation Criteria
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Statistical Test Model *
                </label>
                <input
                  type="text"
                  value={statisticalTest}
                  onChange={(e) => setStatisticalTest(e.target.value)}
                  placeholder="e.g. Two-way ANOVA with Tukey post-hoc"
                  className="w-full px-3 py-1.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded text-xs"
                />
              </div>
              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Significance Threshold
                </label>
                <input
                  type="text"
                  value={significanceThreshold}
                  onChange={(e) => setSignificanceThreshold(e.target.value)}
                  placeholder="e.g. p < 0.01; CI < 0.70"
                  className="w-full px-3 py-1.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded text-xs font-mono"
                />
              </div>
              <div>
                <label className="font-semibold text-slate-700 dark:text-slate-300 block mb-1">
                  Replication Count (n)
                </label>
                <input
                  type="number"
                  min="1"
                  max="50"
                  value={replicationCount}
                  onChange={(e) => setReplicationCount(parseInt(e.target.value) || 1)}
                  className="w-full px-3 py-1.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded text-xs font-mono"
                />
              </div>
            </div>
          </div>

          {/* Submit Actions */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setIsEditing(false)}
              className="px-4 py-2 text-xs font-medium text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 rounded-md"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-5 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md shadow-xs"
            >
              Save Protocol & Verify Integrity
            </button>
          </div>
        </form>
      ) : (
        /* Structured Read-only Protocol View */
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs">
          {/* Top Title Banner */}
          <div className="p-6 border-b border-slate-200 dark:border-slate-800 bg-stone-50/70 dark:bg-slate-950/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2 text-xs font-mono text-slate-500">
                <span className="uppercase tracking-wider text-teal-600 dark:text-teal-400 font-semibold">
                  Protocol Specification
                </span>
                <span>·</span>
                <span>Created {selectedExperiment.createdAt}</span>
                <span>·</span>
                <span className={`capitalize font-semibold ${selectedExperiment.status === 'ready' ? 'text-emerald-600' : 'text-amber-600'}`}>
                  ● {selectedExperiment.status}
                </span>
              </div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                {selectedExperiment.title}
              </h2>
            </div>
            <button
              onClick={() => setIsEditing(true)}
              className="px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors shrink-0"
            >
              Modify Protocol
            </button>
          </div>

          <div className="p-6 space-y-6 text-xs">
            {/* Objective */}
            <div className="space-y-1.5">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                1. Scientific Objective
              </span>
              <p className="p-3.5 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200 leading-relaxed font-medium">
                {selectedExperiment.researchObjective}
              </p>
            </div>

            {/* Variables Matrix Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Independent */}
              <div className="space-y-2 p-4 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800">
                <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block">
                  Independent Variables
                </span>
                <div className="space-y-2">
                  {selectedExperiment.independentVariables.map((v, i) => (
                    <div key={i} className="text-xs">
                      <p className="font-semibold text-slate-900 dark:text-slate-100">{v.name}</p>
                      <p className="font-mono text-[11px] text-slate-500 dark:text-slate-400">
                        Range: {v.range} {v.unit}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Dependent */}
              <div className="space-y-2 p-4 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800">
                <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block">
                  Dependent Endpoints
                </span>
                <div className="space-y-2">
                  {selectedExperiment.dependentVariables.map((v, i) => (
                    <div key={i} className="text-xs">
                      <p className="font-semibold text-slate-900 dark:text-slate-100">{v.name}</p>
                      <p className="text-[11px] text-slate-600 dark:text-slate-400">
                        Method: {v.measurementMethod}
                      </p>
                      <p className="font-mono text-[10px] text-slate-400">Baseline: {v.expectedBaseline}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Controlled */}
              <div className="space-y-2 p-4 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800">
                <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block">
                  Controlled Variables ({selectedExperiment.controlledVariables.length})
                </span>
                <ul className="list-disc pl-4 space-y-1 text-slate-600 dark:text-slate-400 text-[11px]">
                  {selectedExperiment.controlledVariables.map((c, i) => (
                    <li key={i}>{c}</li>
                  ))}
                </ul>
              </div>
            </div>

            {/* Equipment & Reagents */}
            <div className="space-y-1.5">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                2. Instrumentation & Reagents
              </span>
              <div className="flex flex-wrap gap-2">
                {selectedExperiment.equipmentAndResources.map((eq, i) => (
                  <span
                    key={i}
                    className="px-2.5 py-1 bg-stone-100 dark:bg-slate-800 rounded border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-mono text-[11px]"
                  >
                    {eq}
                  </span>
                ))}
              </div>
            </div>

            {/* Procedural Sequence */}
            <div className="space-y-2">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                3. Execution Sequence Protocol
              </span>
              <div className="space-y-2">
                {selectedExperiment.procedureSteps.map((step, i) => (
                  <div
                    key={i}
                    className="p-3 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 flex items-start gap-3"
                  >
                    <span className="font-mono text-xs font-semibold text-teal-600 dark:text-teal-400 mt-0.5">
                      0{i + 1}.
                    </span>
                    <p className="flex-1 text-xs text-slate-800 dark:text-slate-200 leading-relaxed">
                      {step}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            {/* Statistical Plan & Power */}
            <div className="p-4 bg-teal-50/30 dark:bg-teal-950/20 border border-teal-200/50 dark:border-teal-900/40 rounded-xl space-y-2">
              <span className="text-[11px] font-semibold text-teal-900 dark:text-teal-300 uppercase tracking-wider block">
                4. Pre-Registered Statistical Evaluation Criteria
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs pt-1">
                <div>
                  <span className="text-slate-500 block text-[11px]">Primary Statistical Model:</span>
                  <span className="font-semibold text-slate-900 dark:text-slate-100">
                    {selectedExperiment.evaluationCriteria.statisticalTest}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500 block text-[11px]">Significance Cutoff:</span>
                  <span className="font-mono font-semibold text-teal-600 dark:text-teal-400">
                    {selectedExperiment.evaluationCriteria.significanceThreshold}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500 block text-[11px]">Replication Power:</span>
                  <span className="font-mono font-semibold text-slate-900 dark:text-slate-100">
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
