import { useState } from 'react';
import { X, ExternalLink, ShieldCheck, BookOpen, Mail, Info } from 'lucide-react';

export function Footer() {
  const [activeModal, setActiveModal] = useState<'about' | 'docs' | 'privacy' | 'contact' | null>(null);

  return (
    <>
      <footer className="border-t border-slate-200 dark:border-slate-800 bg-white/50 dark:bg-slate-950/50 py-10 px-4 sm:px-6 lg:px-8 text-xs text-slate-500 transition-colors">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-1">
            <p className="font-semibold text-slate-900 dark:text-slate-100 text-sm">
              Research Nexus AI
            </p>
            <p className="text-[12px] text-slate-500 max-w-md">
              Evidence-driven scientific discovery platform for structured hypothesis formulation, literature decomposition, and rigorous experiment planning.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-6 text-xs">
            <button
              onClick={() => setActiveModal('about')}
              className="hover:text-slate-900 dark:hover:text-slate-200 transition-colors cursor-pointer"
            >
              About the Platform
            </button>
            <button
              onClick={() => setActiveModal('docs')}
              className="hover:text-slate-900 dark:hover:text-slate-200 transition-colors cursor-pointer"
            >
              Methodology & Docs
            </button>
            <button
              onClick={() => setActiveModal('privacy')}
              className="hover:text-slate-900 dark:hover:text-slate-200 transition-colors cursor-pointer"
            >
              Data Ethics & Privacy
            </button>
            <button
              onClick={() => setActiveModal('contact')}
              className="hover:text-slate-900 dark:hover:text-slate-200 transition-colors cursor-pointer"
            >
              Academic Inquiries
            </button>
          </div>

          <div className="text-[11px] text-slate-400 font-mono">
            <span>Illustrative Demonstration Mode · Open Science Architecture</span>
          </div>
        </div>
      </footer>

      {/* Accessible Modals */}
      {activeModal && (
        <div 
          className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setActiveModal(null)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-xl overflow-hidden p-6 max-h-[85vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-2">
                {activeModal === 'about' && <Info className="w-4 h-4 text-teal-600 dark:text-teal-400" />}
                {activeModal === 'docs' && <BookOpen className="w-4 h-4 text-teal-600 dark:text-teal-400" />}
                {activeModal === 'privacy' && <ShieldCheck className="w-4 h-4 text-teal-600 dark:text-teal-400" />}
                {activeModal === 'contact' && <Mail className="w-4 h-4 text-teal-600 dark:text-teal-400" />}
                <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100 capitalize">
                  {activeModal === 'about' && 'About Research Nexus AI'}
                  {activeModal === 'docs' && 'Methodological Documentation'}
                  {activeModal === 'privacy' && 'Data Ethics & Integrity Guarantee'}
                  {activeModal === 'contact' && 'Academic Collaboration & Contact'}
                </h3>
              </div>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded"
                aria-label="Close dialog"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="py-4 space-y-3.5 text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
              {activeModal === 'about' && (
                <>
                  <p>
                    Research Nexus AI was created to address a critical bottleneck in contemporary scholarship: the gap between vast unstructured scientific literature and the disciplined design of testable experiments.
                  </p>
                  <p>
                    Rather than treating scientific research as casual conversational synthesis, the platform anchors discovery in verifiable concepts, directional causal relationships, and structured evidence balance sheets.
                  </p>
                  <div className="p-3 bg-stone-100 dark:bg-slate-800/60 rounded-md border border-slate-200 dark:border-slate-700/60 text-[11px]">
                    <span className="font-semibold text-slate-900 dark:text-slate-100">Design Philosophy:</span> Grounded claims, zero fabricated citations, explicit separation of extracted primary evidence from exploratory synthesis, and mathematical transparency in hypothesis confidence evaluation.
                  </div>
                </>
              )}

              {activeModal === 'docs' && (
                <>
                  <p>
                    The platform enforces a five-stage scientific workflow:
                  </p>
                  <ol className="list-decimal pl-4 space-y-1 text-slate-700 dark:text-slate-300">
                    <li><strong>Research Question:</strong> Clear articulation of the biological, physical, or chemical unknown.</li>
                    <li><strong>Literature Review:</strong> Grounded extraction of peer-reviewed findings, study sample sizes, and limitations.</li>
                    <li><strong>Hypothesis Formulation:</strong> Dual-evidence balance sheets tracking both supporting and contradicting data.</li>
                    <li><strong>Experiment Designer:</strong> Parameterization of independent, dependent, and controlled variables.</li>
                    <li><strong>Results & Evaluation:</strong> Statistical criterion definition (ANOVA, CI, power calculations).</li>
                  </ol>
                  <p className="text-[11px] text-slate-500">
                    Integrated with open scholarly APIs including Europe PMC, OpenAlex, and NCBI Entrez guidelines.
                  </p>
                </>
              )}

              {activeModal === 'privacy' && (
                <>
                  <p>
                    Research Nexus AI stores your workspace investigations locally in your browser storage. No proprietary hypotheses or unsubmitted lab protocols are transmitted to third-party ad networks or trained into public weights without consent.
                  </p>
                  <p>
                    All bibliographic citations, DOIs, and PubMed records are queried directly against public open-access repositories (Europe PMC, OpenAlex) complying with academic FAIR data standards.
                  </p>
                </>
              )}

              {activeModal === 'contact' && (
                <>
                  <p>
                    For institutional pilots, research laboratory licensing, or to contribute curated domain graph ontologies, reach out to our team:
                  </p>
                  <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-md font-mono text-[11px] text-slate-800 dark:text-slate-200">
                    contact@research-nexus.science
                  </div>
                  <p className="text-[11px] text-slate-500">
                    Dedicated support for universities, translational biotechnology institutes, and materials laboratories.
                  </p>
                </>
              )}
            </div>

            <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end">
              <button
                onClick={() => setActiveModal(null)}
                className="px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-md transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
