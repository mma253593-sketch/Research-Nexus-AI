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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-stone-300 dark:border-stone-800">
        <div>
          <span className="text-[11px] font-mono uppercase tracking-widest text-[#B45309] dark:text-[#F59E0B] font-semibold">
            Scholarly Archive · Grounded References
          </span>
          <h1 className="font-serif text-2xl font-normal text-[#143628] dark:text-[#FAF7F2] flex items-center gap-2 mt-0.5">
            <span>Saved Literature & Bibliographic Archive</span>
            <span className="text-xs font-mono font-normal text-stone-500 dark:text-stone-400">
              ({papers.length} Articles)
            </span>
          </h1>
          <p className="text-xs text-stone-600 dark:text-stone-400 mt-1 font-sans">
            Grounded scholarly corpus with structured metadata, DOIs, and instant BibTeX citation export.
          </p>
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-stone-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search papers, authors, DOIs..."
            className="w-full pl-8 pr-3 py-1.5 text-xs bg-white dark:bg-[#11161B] border border-stone-300 dark:border-stone-700 rounded-xs text-[#1F2421] dark:text-[#E8ECE9] placeholder:text-stone-400 focus:outline-none focus:ring-1 focus:ring-[#1B4332]"
          />
        </div>
      </div>

      {/* Grid: Paper List + Detail View */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Paper Cards */}
        <div className="lg:col-span-5 space-y-3">
          {filteredPapers.length === 0 ? (
            <div className="p-8 text-center text-xs text-stone-500 border border-dashed border-stone-300 dark:border-stone-800 rounded-xs">
              No matching articles found in your library.
            </div>
          ) : (
            filteredPapers.map((paper) => {
              const isSelected = selectedPaper?.id === paper.id;
              return (
                <div
                  key={paper.id}
                  onClick={() => setSelectedPaper(paper)}
                  className={`p-4 rounded-sm border transition-all cursor-pointer ${
                    isSelected
                      ? 'bg-white dark:bg-[#141A21] border-[#1B4332] dark:border-[#52B788] shadow-xs ring-1 ring-[#1B4332]/20'
                      : 'bg-white dark:bg-[#141A21] border-stone-300 dark:border-stone-800 hover:border-stone-400 dark:hover:border-stone-700'
                  }`}
                >
                  <div className="flex items-center justify-between text-xs text-stone-500 font-mono mb-1.5">
                    <span className="font-semibold text-stone-700 dark:text-stone-300">
                      {paper.journal} · {paper.year}
                    </span>
                    {paper.citationCount && (
                      <span className="tabular-nums text-stone-500">
                        {paper.citationCount} cited
                      </span>
                    )}
                  </div>
                  <h3 className="font-serif text-sm font-semibold text-[#143628] dark:text-[#FAF7F2] line-clamp-2 leading-snug">
                    {paper.title}
                  </h3>
                  <p className="text-[11px] text-stone-600 dark:text-stone-400 mt-1 line-clamp-1 font-sans">
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
            <div className="bg-white dark:bg-[#141A21] border border-stone-300 dark:border-stone-800 rounded-sm p-6 space-y-5 shadow-xs text-xs font-sans">
              <div className="flex items-start justify-between gap-4 pb-4 border-b border-stone-200 dark:border-stone-800">
                <div className="space-y-1">
                  <div className="flex items-center gap-2 font-mono text-xs text-stone-400">
                    <span className="text-[#143628] dark:text-[#52B788] font-semibold">{selectedPaper.journal}</span>
                    <span>·</span>
                    <span>{selectedPaper.year}</span>
                    {selectedPaper.doi && <span>· DOI: {selectedPaper.doi}</span>}
                  </div>
                  <h2 className="font-serif text-base font-normal text-[#143628] dark:text-[#FAF7F2] leading-snug">
                    {selectedPaper.title}
                  </h2>
                  <p className="text-xs text-stone-600 dark:text-stone-400 font-sans">
                    {selectedPaper.authors.join(', ')}
                  </p>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    onClick={() => copyCitation(selectedPaper)}
                    className="p-1.5 text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-stone-200 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-50 dark:hover:bg-stone-800 transition-colors cursor-pointer"
                    title="Copy Citation"
                  >
                    <Copy className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => exportBibTeX(selectedPaper)}
                    className="p-1.5 text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-stone-200 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-50 dark:hover:bg-stone-800 transition-colors cursor-pointer"
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
                    className="p-1.5 text-rose-500 hover:text-rose-700 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors cursor-pointer"
                    title="Delete paper"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Abstract */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium">
                  Abstract
                </span>
                <p className="p-3.5 bg-stone-50 dark:bg-[#11161B] rounded-xs border border-stone-200 dark:border-stone-800 text-stone-700 dark:text-stone-300 leading-relaxed">
                  {selectedPaper.abstract}
                </p>
              </div>

              {/* Research Question & Methodology */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1">
                  <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium">
                    Research Question
                  </span>
                  <p className="text-stone-800 dark:text-stone-200 leading-relaxed font-medium">
                    {selectedPaper.researchQuestion}
                  </p>
                </div>

                <div className="space-y-1">
                  <span className="text-[11px] font-mono text-stone-400 uppercase tracking-widest font-medium">
                    Core Methodology
                  </span>
                  <p className="text-stone-700 dark:text-stone-300 leading-relaxed">
                    {selectedPaper.methodology}
                  </p>
                </div>
              </div>

              {/* Key Findings List */}
              <div className="space-y-2">
                <span className="text-[11px] font-mono text-[#143628] dark:text-[#52B788] uppercase tracking-wider font-semibold">
                  Primary Empirical Findings
                </span>
                <div className="space-y-1.5">
                  {selectedPaper.mainFindings.map((finding, idx) => (
                    <div key={idx} className="p-2.5 bg-[#1B4332]/5 dark:bg-[#52B788]/10 border border-[#1B4332]/20 dark:border-[#52B788]/20 rounded-xs flex items-start gap-2">
                      <span className="font-mono text-[#1B4332] dark:text-[#52B788] font-semibold text-xs mt-0.5">
                        0{idx + 1}.
                      </span>
                      <p className="text-stone-800 dark:text-stone-200">{finding}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Action Button: Deconstruct in Paper Analysis */}
              <div className="pt-2 border-t border-stone-200 dark:border-stone-800 flex justify-end">
                <button
                  onClick={() => onOpenAnalysis(selectedPaper)}
                  className="px-4 py-2 text-xs font-semibold text-white bg-[#1B4332] hover:bg-[#143628] dark:bg-[#2D6A4F] dark:hover:bg-[#1B4332] rounded-xs transition-colors flex items-center gap-1.5 shadow-xs cursor-pointer"
                >
                  <FileText className="w-3.5 h-3.5" />
                  <span>Open Full Deconstruction in Paper Analysis</span>
                </button>
              </div>
            </div>
          ) : (
            <div className="p-12 text-center text-xs text-stone-500 border border-dashed border-stone-300 dark:border-stone-800 rounded-xs">
              Select an article on the left to inspect metadata, abstract, and findings.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
