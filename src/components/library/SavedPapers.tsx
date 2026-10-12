import { useState } from 'react';
import { ScientificPaper } from '../../types/research';
import { 
  Bookmark, Search, Copy, Download, ExternalLink, 
  Trash2, FileText, Check, ChevronRight, BookOpen
} from 'lucide-react';
import { useToast } from '../common/Toast';

interface SavedPapersProps {
  papers: ScientificPaper[];
  onOpenAnalysis: (paper: ScientificPaper) => void;
  onDeletePaper: (id: string) => void;
}

export function SavedPapers({ papers, onOpenAnalysis, onDeletePaper }: SavedPapersProps) {
  const { showToast } = useToast();
  const [search, setSearch] = useState('');
  const [selectedPaper, setSelectedPaper] = useState<ScientificPaper | null>(papers[0] || null);

  const filteredPapers = papers.filter((p) =>
    p.title.toLowerCase().includes(search.toLowerCase()) ||
    p.authors.some(a => a.toLowerCase().includes(search.toLowerCase())) ||
    p.journal.toLowerCase().includes(search.toLowerCase()) ||
    (p.doi && p.doi.toLowerCase().includes(search.toLowerCase()))
  );

  const copyCitation = (p: ScientificPaper) => {
    const citation = `${p.authors.join(', ')} (${p.year}). ${p.title}. ${p.journal}.${p.doi ? ` DOI: ${p.doi}` : ''}`;
    navigator.clipboard.writeText(citation);
    showToast({
      type: 'success',
      title: 'Citation Copied',
      message: 'APA citation copied to clipboard.'
    });
  };

  const exportBibTeX = (p: ScientificPaper) => {
    const citeKey = `${p.authors[0]?.split(',')[0]?.replace(/\s+/g, '') || 'Author'}${p.year}`;
    const bibtex = `@article{${citeKey},
  title = {${p.title}},
  author = {${p.authors.join(' and ')}},
  journal = {${p.journal}},
  year = {${p.year}},
  ${p.doi ? `doi = {${p.doi}},` : ''}
  abstract = {${p.abstract}}
}`;
    const blob = new Blob([bibtex], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${citeKey}.bib`;
    a.click();
    URL.revokeObjectURL(url);
    showToast({
      type: 'success',
      title: 'Exported BibTeX',
      message: `${citeKey}.bib generated`
    });
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <span>Saved Literature & Bibliographic Archive</span>
            <span className="text-xs font-mono font-normal text-slate-500">
              ({papers.length} Articles)
            </span>
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Grounded scholarly corpus with structured metadata, DOIs, and instant BibTeX citation export.
          </p>
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-slate-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search papers, authors, DOIs..."
            className="w-full pl-8 pr-3 py-1.5 text-xs bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500"
          />
        </div>
      </div>

      {/* Grid: Paper List + Detail View */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Paper Cards */}
        <div className="lg:col-span-5 space-y-3">
          {filteredPapers.length === 0 ? (
            <div className="p-8 text-center text-xs text-slate-500 border border-dashed border-slate-200 dark:border-slate-800 rounded-xl">
              No matching articles found in your library.
            </div>
          ) : (
            filteredPapers.map((paper) => {
              const isSelected = selectedPaper?.id === paper.id;
              return (
                <div
                  key={paper.id}
                  onClick={() => setSelectedPaper(paper)}
                  className={`p-4 rounded-xl border transition-all cursor-pointer ${
                    isSelected
                      ? 'bg-white dark:bg-slate-900 border-teal-500 shadow-xs ring-1 ring-teal-500/20'
                      : 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-center justify-between text-xs text-slate-500 font-mono mb-1.5">
                    <span className="font-semibold text-slate-700 dark:text-slate-300">
                      {paper.journal} · {paper.year}
                    </span>
                    {paper.citationCount && (
                      <span className="tabular-nums text-slate-500">
                        {paper.citationCount} cited
                      </span>
                    )}
                  </div>
                  <h3 className="text-xs font-bold text-slate-900 dark:text-slate-100 line-clamp-2 leading-snug">
                    {paper.title}
                  </h3>
                  <p className="text-[11px] text-slate-500 mt-1 line-clamp-1">
                    {paper.authors.join(', ')}
                  </p>
                </div>
              );
            })
          )}
        </div>

        {/* Right Column: Selected Paper Inspector */}
        <div className="lg:col-span-7">
          {selectedPaper ? (
            <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 space-y-5 shadow-xs text-xs">
              <div className="flex items-start justify-between gap-4 pb-4 border-b border-slate-100 dark:border-slate-800">
                <div className="space-y-1">
                  <div className="flex items-center gap-2 font-mono text-xs text-slate-400">
                    <span>{selectedPaper.journal}</span>
                    <span>·</span>
                    <span>{selectedPaper.year}</span>
                    {selectedPaper.doi && <span>· DOI: {selectedPaper.doi}</span>}
                  </div>
                  <h2 className="text-base font-bold text-slate-900 dark:text-slate-100 leading-snug">
                    {selectedPaper.title}
                  </h2>
                  <p className="text-xs text-slate-600 dark:text-slate-400">
                    {selectedPaper.authors.join(', ')}
                  </p>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    onClick={() => copyCitation(selectedPaper)}
                    className="p-1.5 text-slate-500 hover:text-slate-900 dark:hover:text-slate-200 border border-slate-200 dark:border-slate-800 rounded hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                    title="Copy Citation"
                  >
                    <Copy className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => exportBibTeX(selectedPaper)}
                    className="p-1.5 text-slate-500 hover:text-slate-900 dark:hover:text-slate-200 border border-slate-200 dark:border-slate-800 rounded hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                    title="Export BibTeX"
                  >
                    <Download className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm(`Remove "${selectedPaper.title}" from library?`)) {
                        onDeletePaper(selectedPaper.id);
                        setSelectedPaper(papers.filter(p => p.id !== selectedPaper.id)[0] || null);
                      }
                    }}
                    className="p-1.5 text-rose-500 hover:text-rose-700 border border-slate-200 dark:border-slate-800 rounded hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors"
                    title="Delete paper"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Abstract */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                  Abstract
                </span>
                <p className="p-3.5 bg-stone-50 dark:bg-slate-800/40 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300 leading-relaxed">
                  {selectedPaper.abstract}
                </p>
              </div>

              {/* Research Question & Methodology */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1">
                  <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                    Research Question
                  </span>
                  <p className="text-slate-800 dark:text-slate-200 leading-relaxed font-medium">
                    {selectedPaper.researchQuestion}
                  </p>
                </div>

                <div className="space-y-1">
                  <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                    Core Methodology
                  </span>
                  <p className="text-slate-700 dark:text-slate-300 leading-relaxed">
                    {selectedPaper.methodology}
                  </p>
                </div>
              </div>

              {/* Key Findings List */}
              <div className="space-y-2">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                  Primary Empirical Findings
                </span>
                <div className="space-y-1.5">
                  {selectedPaper.mainFindings.map((finding, idx) => (
                    <div key={idx} className="p-2.5 bg-emerald-50/30 dark:bg-emerald-950/20 border border-emerald-200/50 dark:border-emerald-900/30 rounded flex items-start gap-2">
                      <span className="font-mono text-emerald-600 font-semibold text-xs mt-0.5">
                        0{idx + 1}.
                      </span>
                      <p className="text-slate-800 dark:text-slate-200">{finding}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Action Button: Deconstruct in Paper Analysis */}
              <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex justify-end">
                <button
                  onClick={() => onOpenAnalysis(selectedPaper)}
                  className="px-4 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-md transition-colors flex items-center gap-1.5 shadow-xs"
                >
                  <FileText className="w-3.5 h-3.5" />
                  <span>Open Full Deconstruction in Paper Analysis</span>
                </button>
              </div>
            </div>
          ) : (
            <div className="p-12 text-center text-xs text-slate-500 border border-dashed border-slate-200 dark:border-slate-800 rounded-xl">
              Select an article on the left to inspect metadata, abstract, and findings.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
