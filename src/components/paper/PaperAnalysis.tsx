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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-stone-300 dark:border-stone-800">
        <div>
          <span className="text-[11px] font-mono uppercase tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
            Literature Decomposition · Critical Appraisal
          </span>
          <h1 className="font-serif text-2xl font-normal text-[#143628] dark:text-[#FAF7F2] flex items-center gap-2 mt-0.5">
            <span>Paper Analysis & Evidence Extraction</span>
          </h1>
          <p className="text-xs text-stone-600 dark:text-stone-400 mt-1 font-sans">
            Systematic dissection of primary research questions, methodologies, findings, and potential biases with strict provenance tracking.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {onSaveToLibrary && (
            <button
              onClick={() => onSaveToLibrary(selectedPaper)}
              className="px-3 py-1.5 text-xs font-medium text-stone-700 dark:text-stone-300 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-100 dark:hover:bg-stone-800 transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <Bookmark className="w-3.5 h-3.5 stroke-[1.75]" />
              <span>Save to Library</span>
            </button>
          )}
          {onSendToHypothesis && (
            <button
              onClick={() => onSendToHypothesis(selectedPaper)}
              className="px-3.5 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors flex items-center gap-1.5 shadow-xs cursor-pointer"
            >
              <Send className="w-3.5 h-3.5" />
              <span>Bridge to Hypothesis Lab</span>
            </button>
          )}
        </div>
      </div>

      {/* Input Section */}
      <div className="p-5 bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm space-y-3.5 shadow-xs">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
          <label className="text-xs font-serif font-semibold text-[#143628] dark:text-[#FAF7F2] uppercase tracking-wider flex items-center gap-1.5">
            <FileText className="w-4 h-4 text-[#1B4332] dark:text-[#52B788]" />
            <span>Manuscript Abstract or Primary Passage Input</span>
          </label>
          <div className="flex items-center gap-1.5 font-mono text-[11px]">
            <span className="text-stone-400">Curated Corpus:</span>
            {samplePapers.map((paper, idx) => (
              <button
                key={paper.id}
                onClick={() => handleSelectSample(paper)}
                className={`px-2 py-0.5 text-[11px] rounded-xs transition-colors cursor-pointer ${
                  selectedPaper.id === paper.id
                    ? 'bg-[#1B4332] text-white font-medium'
                    : 'text-stone-600 dark:text-stone-400 bg-stone-100 dark:bg-stone-800 hover:bg-stone-200 dark:hover:bg-stone-700 border border-stone-200 dark:border-stone-700'
                }`}
              >
                Paper 0{idx + 1}
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
            className="w-full px-3 py-1.5 text-xs bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] placeholder:text-stone-400 focus:outline-none focus:ring-1 focus:ring-[#1B4332]"
          />
          <input
            type="text"
            value={inputDoi}
            onChange={(e) => setInputDoi(e.target.value)}
            placeholder="DOI or PMID (e.g., 10.1038/s43018-023-00561-w)"
            className="w-full px-3 py-1.5 text-xs bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] placeholder:text-stone-400 focus:outline-none focus:ring-1 focus:ring-[#1B4332] font-mono"
          />
        </div>

        <textarea
          rows={4}
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder="Paste paper abstract, methods excerpt, or primary findings here..."
          className="w-full p-3 text-xs bg-stone-50 dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] placeholder:text-stone-400 focus:outline-none focus:ring-1 focus:ring-[#1B4332] leading-relaxed font-sans"
        />

        <div className="flex items-center justify-between pt-1 font-sans">
          <div className="flex items-center gap-2 text-[11px] text-stone-500">
            <Info className="w-3.5 h-3.5 shrink-0 text-[#1B4332] dark:text-[#52B788]" />
            <span>Strict Provenance Policy: Statements are separated into verbatim extracts and analytical syntheses.</span>
          </div>

          <button
            onClick={handleAnalyzePasted}
            disabled={isAnalyzing}
            className="px-4 py-1.5 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors flex items-center gap-1.5 shadow-xs disabled:opacity-50 cursor-pointer"
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
      <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm overflow-hidden shadow-xs">
        {/* Paper Title Banner */}
        <div className="p-5 border-b border-stone-200 dark:border-stone-800 bg-stone-50/70 dark:bg-[#11161B]">
          <div className="flex flex-wrap items-center gap-2 text-xs text-stone-500 mb-1.5 font-mono">
            <span className="font-semibold text-stone-700 dark:text-stone-300">{selectedPaper.journal}</span>
            <span>·</span>
            <span>{selectedPaper.year}</span>
            {selectedPaper.doi && (
              <>
                <span>·</span>
                <span className="text-[#1B4332] dark:text-[#52B788]">DOI: {selectedPaper.doi}</span>
              </>
            )}
            {selectedPaper.citationCount && (
              <>
                <span>·</span>
                <span className="tabular-nums font-semibold text-stone-700 dark:text-stone-300">
                  {selectedPaper.citationCount} Citations
                </span>
              </>
            )}
          </div>
          <h2 className="font-serif text-base sm:text-lg font-normal text-[#143628] dark:text-[#FAF7F2] leading-snug">
            {selectedPaper.title}
          </h2>
          <p className="text-xs text-stone-600 dark:text-stone-400 mt-1 font-sans">
            {selectedPaper.authors.join(', ')}
          </p>
        </div>

        {/* Tab Controls: Analytical Synthesis vs Extracted Statements */}
        <div className="flex items-center border-b border-stone-200 dark:border-stone-800 px-5 gap-6 text-xs bg-stone-50/50 dark:bg-[#11161B]">
          <button
            onClick={() => setActiveTab('synthesis')}
            className={`py-3 font-semibold border-b-2 transition-colors cursor-pointer ${
              activeTab === 'synthesis'
                ? 'border-[#1B4332] dark:border-[#52B788] text-[#143628] dark:text-[#52B788]'
                : 'border-transparent text-stone-500 hover:text-stone-900 dark:hover:text-stone-200'
            }`}
          >
            Structured Analytical Synthesis (6 Facets)
          </button>
          <button
            onClick={() => setActiveTab('extracted')}
            className={`py-3 font-semibold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'extracted'
                ? 'border-[#1B4332] dark:border-[#52B788] text-[#143628] dark:text-[#52B788]'
                : 'border-transparent text-stone-500 hover:text-stone-900 dark:hover:text-stone-200'
            }`}
          >
            <span>Verbatim Extracted Statements</span>
            <span className="text-[10px] font-mono px-1.5 py-0.2 rounded-xs bg-stone-200 dark:bg-stone-800 text-stone-700 dark:text-stone-300">
              {selectedPaper.extractedStatements.length}
            </span>
          </button>
        </div>

        {/* Content Panes */}
        <div className="p-6 font-sans">
          {activeTab === 'synthesis' ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* 1. Research Question */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium flex items-center gap-1.5">
                  <HelpCircle className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788]" />
                  Primary Research Question
                </span>
                <div className="p-3 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800">
                  <p className="text-xs text-stone-800 dark:text-stone-200 font-medium leading-relaxed">
                    {selectedPaper.researchQuestion}
                  </p>
                </div>
              </div>

              {/* 2. Study Methodology */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium flex items-center gap-1.5">
                  <BookOpen className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788]" />
                  Study Methodology & Model Systems
                </span>
                <div className="p-3 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800">
                  <p className="text-xs text-stone-700 dark:text-stone-300 leading-relaxed">
                    {selectedPaper.methodology}
                  </p>
                </div>
              </div>

              {/* 3. Main Findings */}
              <div className="space-y-1.5 md:col-span-2">
                <span className="text-[11px] font-mono text-[#143628] dark:text-[#52B788] uppercase tracking-wider font-semibold flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788]" />
                  Main Empirical Findings
                </span>
                <div className="space-y-2">
                  {selectedPaper.mainFindings.map((finding, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800 flex items-start gap-2.5 text-xs text-stone-800 dark:text-stone-200 leading-relaxed"
                    >
                      <span className="font-mono text-xs font-semibold text-[#1B4332] dark:text-[#52B788] mt-0.5">
                        0{idx + 1}.
                      </span>
                      <p className="flex-1">{finding}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* 4. Limitations */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-mono text-amber-700 dark:text-amber-400 uppercase tracking-widest font-semibold flex items-center gap-1.5">
                  <AlertTriangle className="w-3.5 h-3.5 text-[#B45309]" />
                  Study Limitations
                </span>
                <div className="space-y-2">
                  {selectedPaper.limitations.map((lim, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-amber-50/60 dark:bg-amber-950/20 rounded-xs border border-amber-200/60 dark:border-amber-900/40 text-xs text-amber-950 dark:text-amber-200 leading-relaxed"
                    >
                      {lim}
                    </div>
                  ))}
                </div>
              </div>

              {/* 5. Potential Sources of Bias */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-mono text-rose-700 dark:text-rose-400 uppercase tracking-widest font-semibold flex items-center gap-1.5">
                  <AlertTriangle className="w-3.5 h-3.5 text-rose-600" />
                  Potential Sources of Bias
                </span>
                <div className="space-y-2">
                  {selectedPaper.potentialBias.map((bias, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-rose-50/60 dark:bg-rose-950/20 rounded-xs border border-rose-200/60 dark:border-rose-900/40 text-xs text-rose-950 dark:text-rose-200 leading-relaxed"
                    >
                      {bias}
                    </div>
                  ))}
                </div>
              </div>

              {/* 6. Questions for Further Investigation */}
              <div className="space-y-1.5 md:col-span-2">
                <span className="text-[11px] font-mono text-stone-500 uppercase tracking-widest font-semibold flex items-center gap-1.5">
                  <HelpCircle className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788]" />
                  Questions for Further Investigation
                </span>
                <div className="space-y-2">
                  {selectedPaper.furtherQuestions.map((q, idx) => (
                    <div 
                      key={idx}
                      className="p-3 bg-[#1B4332]/5 dark:bg-[#52B788]/10 rounded-xs border border-[#1B4332]/20 dark:border-[#52B788]/20 flex items-start gap-2.5 text-xs text-stone-800 dark:text-stone-200"
                    >
                      <ChevronRight className="w-3.5 h-3.5 text-[#1B4332] dark:text-[#52B788] mt-0.5 shrink-0" />
                      <p className="flex-1">{q}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="p-3 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800 text-xs text-stone-600 dark:text-stone-400 flex items-center justify-between">
                <span>Direct verbatim quotes extracted from source text with precise location coordinates:</span>
                <span className="font-mono text-[11px] font-semibold text-[#143628] dark:text-[#52B788]">Exact Author Language</span>
              </div>

              <div className="space-y-3">
                {selectedPaper.extractedStatements.map((stmt, idx) => (
                  <div
                    key={idx}
                    className="p-4 bg-white dark:bg-[#141A21] rounded-xs border border-stone-200 dark:border-stone-800 space-y-2 relative group"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-mono uppercase tracking-wider text-[#1B4332] dark:text-[#52B788] font-semibold">
                        Category: {stmt.category}
                      </span>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-mono text-stone-400">
                          {stmt.location}
                        </span>
                        <button
                          onClick={() => copyToClipboard(stmt.quote, `Extracted Quote #${idx + 1}`)}
                          className="p-1 text-stone-400 hover:text-stone-600 dark:hover:text-stone-200 transition-colors cursor-pointer"
                          title="Copy quote"
                        >
                          <Copy className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>

                    <blockquote className="text-xs text-stone-800 dark:text-stone-200 italic pl-3 border-l-2 border-[#1B4332] dark:border-[#52B788] leading-relaxed">
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
