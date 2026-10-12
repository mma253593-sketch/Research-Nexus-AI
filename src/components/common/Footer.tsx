import { useState } from 'react';
import { X, ExternalLink, ShieldCheck, BookOpen, Mail, Info, FileSpreadsheet } from 'lucide-react';
import { useLanguage } from '../../context/LanguageContext';

export function Footer() {
  const [activeModal, setActiveModal] = useState<'about' | 'docs' | 'privacy' | 'contact' | null>(null);
  const { t, language } = useLanguage();

  return (
    <>
      <footer className="border-t border-stone-300 dark:border-stone-800 bg-[#FAF7F2] dark:bg-[#11161B] py-12 px-4 sm:px-6 lg:px-8 text-xs text-stone-600 dark:text-stone-400 transition-colors">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-1.5">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#1B4332] dark:bg-[#52B788] inline-block" />
              <p className="font-serif font-semibold text-stone-900 dark:text-stone-100 text-sm">
                Research Nexus AI
              </p>
            </div>
            <p className="text-[12px] text-stone-500 max-w-md font-sans">
              {language === 'th'
                ? 'แพลตฟอร์มการวิจัยทางวิทยาศาสตร์สำหรับการตั้งสมมติฐานเชิงโครงสร้าง การย่อยเอกสารวิจัย และสถาปัตยกรรมการทดลองที่ทำซ้ำได้'
                : 'Scientific research platform for structured hypothesis formulation, literature decomposition, and reproducible experiment architecture.'}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-6 text-xs">
            <button
              onClick={() => setActiveModal('about')}
              className="hover:text-stone-900 dark:hover:text-stone-200 transition-colors cursor-pointer"
            >
              {t('footer.constitution', 'Editorial Constitution')}
            </button>
            <button
              onClick={() => setActiveModal('docs')}
              className="hover:text-stone-900 dark:hover:text-stone-200 transition-colors cursor-pointer"
            >
              {t('footer.methodology', 'Methodology & Protocols')}
            </button>
            <button
              onClick={() => setActiveModal('privacy')}
              className="hover:text-stone-900 dark:hover:text-stone-200 transition-colors cursor-pointer"
            >
              {t('footer.privacy', 'Data Ethics & Provenance')}
            </button>
            <button
              onClick={() => setActiveModal('contact')}
              className="hover:text-stone-900 dark:hover:text-stone-200 transition-colors cursor-pointer"
            >
              {t('footer.contact', 'Academic Inquiries')}
            </button>
          </div>

          <div className="text-[11px] text-stone-400 font-mono">
            <span>{t('footer.version', 'Open Science Architecture · Version 4.2')}</span>
          </div>
        </div>
      </footer>

      {/* Accessible Modals */}
      {activeModal && (
        <div 
          className="fixed inset-0 z-50 bg-stone-950/60 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setActiveModal(null)}
          role="dialog"
          aria-modal="true"
        >
          <div 
            className="w-full max-w-xl bg-[#FAF7F2] dark:bg-[#161C22] border border-stone-300 dark:border-stone-700 rounded-xs shadow-xl overflow-hidden p-6 max-h-[85vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-stone-200 dark:border-stone-800">
              <div className="flex items-center gap-2">
                {activeModal === 'about' && <Info className="w-4 h-4 text-[#1B4332] dark:text-[#52B788]" />}
                {activeModal === 'docs' && <BookOpen className="w-4 h-4 text-[#1B4332] dark:text-[#52B788]" />}
                {activeModal === 'privacy' && <ShieldCheck className="w-4 h-4 text-[#1B4332] dark:text-[#52B788]" />}
                {activeModal === 'contact' && <Mail className="w-4 h-4 text-[#1B4332] dark:text-[#52B788]" />}
                <h3 className="text-sm font-serif font-bold text-stone-900 dark:text-stone-100">
                  {activeModal === 'about' && 'Editorial Constitution & Principles'}
                  {activeModal === 'docs' && 'Methodological Documentation'}
                  {activeModal === 'privacy' && 'Data Ethics & Scientific Integrity'}
                  {activeModal === 'contact' && 'Academic Inquiries & Collaboration'}
                </h3>
              </div>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 text-stone-400 hover:text-stone-600 dark:hover:text-stone-200 rounded cursor-pointer"
                aria-label="Close dialog"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="py-4 space-y-3.5 text-xs text-stone-700 dark:text-stone-300 leading-relaxed font-sans">
              {activeModal === 'about' && (
                <>
                  <p>
                    Research Nexus AI was conceived to bridge the gap between vast unstructured scientific literature and the disciplined design of testable experiments.
                  </p>
                  <p>
                    Unlike conversational AI chatbots that invent plausible-sounding answers, the platform insists on directional causal mechanisms, explicit assumption registers, and empirical balance sheets.
                  </p>
                  <div className="p-3 bg-white dark:bg-[#1A222B] rounded-xs border border-stone-200 dark:border-stone-800 text-[11px]">
                    <span className="font-semibold text-stone-900 dark:text-stone-100">Anti-Hallucination Policy:</span> Zero fabricated DOIs, explicit separation of extracted primary quotes from exploratory analysis, and transparent criteria for hypothesis confidence.
                  </div>
                </>
              )}

              {activeModal === 'docs' && (
                <>
                  <p>
                    The platform enforces a five-stage scientific workflow:
                  </p>
                  <ol className="list-decimal pl-4 space-y-1 text-stone-700 dark:text-stone-300 font-sans">
                    <li><strong>Research Question:</strong> Precise boundary parameters for the biological or material unknown.</li>
                    <li><strong>Literature Review:</strong> Grounded extraction of peer-reviewed findings, study sample sizes, and limitations.</li>
                    <li><strong>Hypothesis Formulation:</strong> Dual-evidence balance sheets tracking both supporting and contradicting data.</li>
                    <li><strong>Experiment Designer:</strong> Parameterization of independent, dependent, and controlled variables.</li>
                    <li><strong>Results & Evaluation:</strong> Statistical criterion definition (ANOVA, CI, power calculations).</li>
                  </ol>
                </>
              )}

              {activeModal === 'privacy' && (
                <>
                  <p>
                    All workspace data is maintained locally in your browser session. Proprietary hypotheses, unpublished parameters, and lab notes are never transmitted to commercial ad networks.
                  </p>
                  <p>
                    All citations are mapped to verified academic indexes adhering to academic FAIR data standards.
                  </p>
                </>
              )}

              {activeModal === 'contact' && (
                <>
                  <p>
                    For institutional pilots, research laboratory licensing, or to contribute curated domain graph ontologies:
                  </p>
                  <div className="p-3 bg-white dark:bg-[#1A222B] border border-stone-200 dark:border-stone-800 rounded-xs font-mono text-[11px] text-stone-800 dark:text-stone-200">
                    inquiries@research-nexus.science
                  </div>
                </>
              )}
            </div>

            <div className="pt-3 border-t border-stone-200 dark:border-stone-800 flex justify-end">
              <button
                onClick={() => setActiveModal(null)}
                className="px-3.5 py-1.5 text-xs font-medium text-stone-700 dark:text-stone-300 bg-white dark:bg-stone-800 border border-stone-300 dark:border-stone-700 rounded-xs hover:bg-stone-100 cursor-pointer transition-colors"
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
