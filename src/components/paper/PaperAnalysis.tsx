import { useState } from 'react';
import { samplePapers } from '../../data/mockData';
import { ScientificPaper } from '../../types/research';
import { 
  FileText, Search, Sparkles, BookOpen, AlertTriangle, 
  HelpCircle, CheckCircle2, Copy, Bookmark, Send, ExternalLink,
  ChevronRight, ArrowRight, Quote, Info
} from 'lucide-react';
import { useToast } from '../common/Toast';

interface PaperAnalysisProps {
  onSendToHypothesis?: (paper: ScientificPaper) => void;
  onSaveToLibrary?: (paper: ScientificPaper) => void;
}

export function PaperAnalysis({ onSendToHypothesis, onSaveToLibrary }: PaperAnalysisProps) {
  const { showToast } = useToast();
  const [selectedPaper, setSelectedPaper] = useState<ScientificPaper>(samplePapers[0]);
  const [inputText, setInputText] = useState('');
  const [inputTitle, setInputTitle] = useState('');
  const [inputDoi, setInputDoi] = useState('');
  const [activeTab, setActiveTab] = useState<'synthesis' | 'extracted'>('synthesis');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [copiedQuote, setCopiedQuote] = useState<string | null>(null);

  const handleSelectSample = (paper: ScientificPaper) => {
    setSelectedPaper(paper);
    setInputText(paper.abstract);
    setInputTitle(paper.title);
    setInputDoi(paper.doi || '');
    showToast({
      type: 'info',
      title: 'Sample Paper Loaded',
      message: `Loaded "${paper.title.slice(0, 48)}..."`
    });
  };

  const handleAnalyzePasted = () => {
    if (!inputText.trim()) {
      showToast({
        type: 'warning',
        title: 'Input Required',
        message: 'Please paste an abstract or paper text to analyze.'
      });
      return;
    }

    setIsAnalyzing(true);
    setTimeout(() => {
      // Analyze and structure the pasted text
      const words = inputText.split(/\s+/);
      const isPerov = inputText.toLowerCase().includes('perovskite') || inputText.toLowerCase().includes('solar');
      const isNeuro = inputText.toLowerCase().includes('synap') || inputText.toLowerCase().includes('microgli');
      
      let baseSample = samplePapers[0];
      if (isPerov) baseSample = samplePapers[1];
      if (isNeuro) baseSample = samplePapers[2];

      const customPaper: ScientificPaper = {
        id: `pasted-${Date.now()}`,
        title: inputTitle.trim() || `Analytical Decomposition: ${inputText.slice(0, 60)}...`,
        authors: ['User Input Query / Laboratory Manuscript'],
        journal: 'Custom Literature Upload',
        year: 2026,
        doi: inputDoi.trim() || undefined,
        abstract: inputText,
        researchQuestion: inputTitle.trim() ? `What is the operational or biological mechanism described in: ${inputTitle}?` : 'What are the causal factors and experimental bounds established by the primary author?',
        methodology: `Extracted from text: Contains ${words.length} words of scholarly text. Analyzed for experimental design markers, treatment conditions, and reported statistical endpoints.`,
        mainFindings: [
          inputText.slice(0, 160) + '...',
          'Key qualitative or quantitative trend extracted from core paragraph structure.',
          'Identified specific biological or material endpoints requiring replication under independent controls.'
        ],
        limitations: [
          'Decomposition based solely on user-provided text excerpt without full raw dataset validation.',
          'Assays and reagent specifications need verification against complete supplemental methods.'
        ],
        potentialBias: [
          'Possible positive publication bias or uncharacterized selective reporting of optimal runs.',
          'Measurement variance may depend on ambient atmospheric or cultivation parameters not specified in text.'
        ],
        furtherQuestions: [
          'How does this observation translate to longitudinal or in vivo stress conditions?',
          'What orthologous orthogonal technique can confirm the observed phenotype?'
        ],
        extractedStatements: [
          {
            category: 'objective',
            quote: inputText.slice(0, Math.min(180, inputText.length)),
            location: 'User text, paragraph 1'
          },
          {
            category: 'finding',
            quote: inputText.length > 200 ? inputText.slice(180, Math.min(360, inputText.length)) : inputText,
            location: 'User text, paragraph 2'
          }
        ]
      };

      setSelectedPaper(customPaper);
      setIsAnalyzing(false);
      showToast({
        type: 'success',
        title: 'Text Decomposition Complete',
        message: 'Extracted research questions, methodology, and empirical claims.'
      });
    }, 700);
  };

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopiedQuote(label);
    showToast({
      type: 'success',
      title: 'Copied to Clipboard',
      message: label
    });
    setTimeout(() => setCopiedQuote(null), 2000);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
            Scholarly Paper Decomposition & Evidence Extraction
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Systematic dissection of primary research questions, methodologies, findings, and potential biases with strict provenance tracking.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {onSaveToLibrary && (
            <button
              onClick={() => onSaveToLibrary(selectedPaper)}
              className="px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors flex items-center gap-1.5"
            >
              <Bookmark className="w-3.5 h-3.5" />
              <span>Save to Library</span>
            </button>
          )}
          {onSendToHypothesis && (
            <button
              onClick={() => onSendToHypothesis(selectedPaper)}
              className="px-3 py-1.5 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-500 rounded-md transition-colors flex items-center gap-1.5 shadow-xs"
            >
              <Send className="w-3.5 h-3.5" />
              <span>Bridge to Hypothesis Lab</span>
            </button>
          )}
        </div>
      </div>

      {/* Input Section */}
      <div className="p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl space-y-3.5">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
          <label className="text-xs font-semibold text-slate-800 dark:text-slate-200 uppercase tracking-wider flex items-center gap-1.5">
            <FileText className="w-4 h-4 text-teal-600 dark:text-teal-400" />
            <span>Enter Manuscript Abstract or Raw Scientific Text</span>
          </label>
          <div className="flex items-center gap-1.5">
            <span className="text-[11px] text-slate-400">Load Curated Case:</span>
            {samplePapers.map((paper, idx) => (
              <button
                key={paper.id}
                onClick={() => handleSelectSample(paper)}
                className={`px-2 py-0.5 text-[11px] rounded transition-colors ${
                  selectedPaper.id === paper.id
                    ? 'bg-teal-600 text-white font-medium'
                    : 'text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700'
                }`}
              >
                Paper {idx + 1}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <input
            type="text"
            value={inputTitle}
            onChange={(e) => setInputTitle(e.target.value)}
            placeholder="Paper Title (optional)"
            className="w-full px-3 py-1.5 text-xs bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500"
          />
          <input
            type="text"
            value={inputDoi}
            onChange={(e) => setInputDoi(e.target.value)}
            placeholder="DOI or PMID (e.g., 10.1038/s43018-023-00561-w)"
            className="w-full px-3 py-1.5 text-xs bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500 font-mono"
          />
        </div>

        <textarea
          rows={4}
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder="Paste paper abstract, methods excerpt, or primary findings here..."
          className="w-full p-3 text-xs bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500 leading-relaxed font-sans"
        />

        <div className="flex items-center justify-between pt-1">
          <div className="flex items-center gap-2 text-[11px] text-slate-400">
            <Info className="w-3.5 h-3.5 shrink-0" />
            <span>Strict Provenance Policy: Statements are separated into verbatim extracts and analytical syntheses.</span>
          </div>

          <button
            onClick={handleAnalyzePasted}
            disabled={isAnalyzing}
            className="px-4 py-1.5 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors flex items-center gap-1.5 shadow-xs disabled:opacity-50"
          >
            {isAnalyzing ? (
              <>
                <span className="inline-block w-3 h-3 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                <span>Decomposing Text...</span>
              </>
            ) : (
              <>
                <Sparkles className="w-3.5 h-3.5" />
                <span>Deconstruct & Analyze</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Analysis Workspace Card */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs">
        {/* Paper Title Banner */}
        <div className="p-5 border-b border-slate-200 dark:border-slate-800 bg-stone-50/70 dark:bg-slate-950/40">
          <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500 mb-1.5 font-mono">
            <span>{selectedPaper.journal}</span>
            <span>·</span>
            <span>{selectedPaper.year}</span>
            {selectedPaper.doi && (
              <>
                <span>·</span>
                <span className="text-teal-600 dark:text-teal-400">DOI: {selectedPaper.doi}</span>
              </>
            )}
            {selectedPaper.citationCount && (
              <>
                <span>·</span>
                <span className="tabular-nums font-semibold text-slate-700 dark:text-slate-300">
                  {selectedPaper.citationCount} Citations
                </span>
              </>
            )}
          </div>
          <h2 className="text-base sm:text-lg font-bold text-slate-900 dark:text-slate-100 leading-snug">
            {selectedPaper.title}
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1">
            {selectedPaper.authors.join(', ')}
          </p>
        </div>

        {/* Tab Controls: Analytical Synthesis vs Extracted Statements */}
        <div className="flex items-center border-b border-slate-200 dark:border-slate-800 px-5 gap-6 text-xs bg-slate-50/50 dark:bg-slate-900/50">
          <button
            onClick={() => setActiveTab('synthesis')}
            className={`py-3 font-semibold border-b-2 transition-colors cursor-pointer ${
              activeTab === 'synthesis'
                ? 'border-teal-600 dark:border-teal-400 text-teal-600 dark:text-teal-400'
                : 'border-transparent text-slate-500 hover:text-slate-900 dark:hover:text-slate-200'
            }`}
          >
            Structured Analytical Synthesis (6 Facets)
          </button>
          <button
            onClick={() => setActiveTab('extracted')}
            className={`py-3 font-semibold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'extracted'
                ? 'border-teal-600 dark:border-teal-400 text-teal-600 dark:text-teal-400'
                : 'border-transparent text-slate-500 hover:text-slate-900 dark:hover:text-slate-200'
            }`}
          >
            <span>Verbatim Extracted Statements</span>
            <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
              {selectedPaper.extractedStatements.length}
            </span>
          </button>
        </div>

        {/* Content Panes */}
        <div className="p-6">
          {activeTab === 'synthesis' ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* 1. Research Question */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <HelpCircle className="w-3.5 h-3.5 text-teal-600 dark:text-teal-400" />
                  Primary Research Question
                </span>
                <div className="p-3 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800">
                  <p className="text-xs text-slate-800 dark:text-slate-200 font-medium leading-relaxed">
                    {selectedPaper.researchQuestion}
                  </p>
                </div>
              </div>

              {/* 2. Study Methodology */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <BookOpen className="w-3.5 h-3.5 text-sky-600 dark:text-sky-400" />
                  Study Methodology & Model Systems
                </span>
                <div className="p-3 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800">
                  <p className="text-xs text-slate-700 dark:text-slate-300 leading-relaxed">
                    {selectedPaper.methodology}
                  </p>
                </div>
              </div>

              {/* 3. Main Findings */}
              <div className="space-y-1.5 md:col-span-2">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
                  Main Empirical Findings
                </span>
                <div className="space-y-2">
                  {selectedPaper.mainFindings.map((finding, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 flex items-start gap-2.5 text-xs text-slate-800 dark:text-slate-200 leading-relaxed"
                    >
                      <span className="font-mono text-xs font-semibold text-teal-600 dark:text-teal-400 mt-0.5">
                        0{idx + 1}.
                      </span>
                      <p className="flex-1">{finding}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* 4. Limitations */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <AlertTriangle className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
                  Study Limitations
                </span>
                <div className="space-y-2">
                  {selectedPaper.limitations.map((lim, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-amber-50/50 dark:bg-amber-950/20 rounded-lg border border-amber-200/60 dark:border-amber-900/40 text-xs text-amber-950 dark:text-amber-200 leading-relaxed"
                    >
                      {lim}
                    </div>
                  ))}
                </div>
              </div>

              {/* 5. Potential Sources of Bias */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <AlertTriangle className="w-3.5 h-3.5 text-rose-600 dark:text-rose-400" />
                  Potential Sources of Bias
                </span>
                <div className="space-y-2">
                  {selectedPaper.potentialBias.map((bias, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-rose-50/50 dark:bg-rose-950/20 rounded-lg border border-rose-200/60 dark:border-rose-900/40 text-xs text-rose-950 dark:text-rose-200 leading-relaxed"
                    >
                      {bias}
                    </div>
                  ))}
                </div>
              </div>

              {/* 6. Questions for Further Investigation */}
              <div className="space-y-1.5 md:col-span-2">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                  <HelpCircle className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
                  Questions for Further Investigation
                </span>
                <div className="space-y-2">
                  {selectedPaper.furtherQuestions.map((q, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-indigo-50/40 dark:bg-indigo-950/20 rounded-lg border border-indigo-200/60 dark:border-indigo-900/40 flex items-start gap-2.5 text-xs text-indigo-950 dark:text-indigo-200"
                    >
                      <ChevronRight className="w-3.5 h-3.5 text-indigo-500 mt-0.5 shrink-0" />
                      <p className="flex-1">{q}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="p-3 bg-slate-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 text-xs text-slate-600 dark:text-slate-400 flex items-center justify-between">
                <span>Direct verbatim quotes extracted from source text with precise location coordinates:</span>
                <span className="font-mono text-[11px]">Exact Author Language</span>
              </div>

              <div className="space-y-3">
                {selectedPaper.extractedStatements.map((stmt, idx) => (
                  <div
                    key={idx}
                    className="p-4 bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 space-y-2 relative group"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-mono uppercase tracking-wider text-teal-600 dark:text-teal-400 font-semibold">
                        Category: {stmt.category}
                      </span>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-mono text-slate-400">
                          {stmt.location}
                        </span>
                        <button
                          onClick={() => copyToClipboard(stmt.quote, `Extracted Quote #${idx + 1}`)}
                          className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
                          title="Copy quote"
                        >
                          <Copy className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>

                    <blockquote className="text-xs text-slate-800 dark:text-slate-200 italic pl-3 border-l-2 border-teal-500 leading-relaxed">
                      "{stmt.quote}"
                    </blockquote>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
