import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export type Language = 'en' | 'th';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  toggleLanguage: () => void;
  t: (key: string, defaultText?: string) => string;
}

const LANGUAGE_STORAGE_KEY = 'nexus_app_language_v1';

export const translations: Record<Language, Record<string, string>> = {
  en: {
    // Brand & Top Header
    'brand.name': 'Research Nexus AI',
    'brand.tagline': 'Scientific Discovery System',
    'brand.volume': 'Volume IV · Open Methodological Framework',
    'brand.protocols': 'Peer-Grounded Protocols',

    // Nav
    'nav.workspace': 'Workspace',
    'nav.graph': 'Knowledge Graph',
    'nav.hypotheses': 'Hypothesis Lab',
    'nav.experiments': 'Experiment Designer',
    'nav.paperAnalysis': 'Paper Analysis',
    'nav.savedPapers': 'Saved Literature',
    'nav.overview': 'Overview',
    'nav.quickSearch': 'Quick Search',
    'nav.openPalette': 'Open Command Palette (⌘K)',

    // Hero
    'hero.badge': 'Rigorous Scientific Inquiry · Empirical Architecture',
    'hero.headline': 'Research beyond the obvious.',
    'hero.subtext': 'Explore scientific knowledge, investigate competing hypotheses, and turn unanswered questions into testable research with strict evidence balance sheets.',
    'hero.searchPlaceholder': 'Query a molecular target, materials property, or causal hypothesis...',
    'hero.startResearching': 'Start Researching',
    'hero.exploreKnowledge': 'Explore Knowledge',
    'hero.exampleInquiries': 'Curated Empirical Inquiries (Click to Load):',
    'hero.diagramCaption': 'Multi-axis causal concept network with calibrated mechanistic evidence links.',

    // Workflow
    'workflow.title': 'The Five-Stage Empirical Workflow',
    'workflow.subtitle': 'Structured scientific progress without data invention or speculative leaps.',
    'workflow.step1.title': 'Question Parameterization',
    'workflow.step1.sub': 'Isolate the causal or physical unknown',
    'workflow.step1.desc': 'Define rigorous biological, chemical, or materials boundaries rather than loose speculation.',
    'workflow.step2.title': 'Literature Decomposition',
    'workflow.step2.sub': 'Extract verbatim claims and evaluate potential biases',
    'workflow.step2.desc': 'Dissect primary publications to separate verified observations from author interpretations.',
    'workflow.step3.title': 'Hypothesis Formulation',
    'workflow.step3.sub': 'Construct dual supporting and counter-evidence ledgers',
    'workflow.step3.desc': 'Contrast competing mechanisms with explicit assumption auditing and calibrated confidence rationale.',
    'workflow.step4.title': 'Experiment Architecture',
    'workflow.step4.sub': 'Parameterize independent, dependent, and controlled variables',
    'workflow.step4.desc': 'Structure reproducible lab protocols with pre-registered statistical evaluation criteria.',
    'workflow.step5.title': 'Empirical Rigor & Review',
    'workflow.step5.sub': 'Audit findings against criteria without data invention',
    'workflow.step5.desc': 'Track stage milestones with power calculations (n ≥ 3) and combination indices.',

    // Projects
    'projects.title': 'Active Research Projects',
    'projects.subtitle': 'Grounded investigation projects maintained in local workspace storage.',
    'projects.exploreInWorkspace': 'Explore in Workspace',
    'projects.openWorkspace': 'Open Workspace',

    // Knowledge Graph
    'graph.title': 'Interactive Knowledge Graph',
    'graph.subtitle': 'Nodes represent research concepts and edges denote explicitly verified mechanistic relationships.',
    'graph.searchPlaceholder': 'Search concepts, genes, materials...',
    'graph.allCategories': 'All Categories',
    'graph.target': 'Target',
    'graph.pathway': 'Pathway',
    'graph.phenotype': 'Phenotype',
    'graph.material': 'Material',
    'graph.method': 'Method',
    'graph.zoomIn': 'Zoom In',
    'graph.zoomOut': 'Zoom Out',
    'graph.resetZoom': 'Reset Zoom',
    'graph.closeInspector': 'Close Inspector',
    'graph.evidenceLinks': 'Mechanistic Evidence Connections',
    'graph.confidenceScore': 'Confidence Score',
    'graph.bridgeToHypothesis': 'Bridge to Hypothesis Lab',

    // Hypothesis Lab
    'hypo.badge': 'Mechanistic Inquiry · Evidence Balance Ledger',
    'hypo.title': 'Hypothesis Lab',
    'hypo.activeRecords': 'Active Records',
    'hypo.description': 'Formulate, validate, and compare competing scientific explanations using structured evidence balance sheets.',
    'hypo.exportMarkdown': 'Export Markdown',
    'hypo.compareHypotheses': 'Compare Hypotheses',
    'hypo.exitComparison': 'Exit Comparison',
    'hypo.formulate': 'Formulate Hypothesis',
    'hypo.supportingEvidence': 'Supporting Evidence',
    'hypo.counterEvidence': 'Contradicting / Counter Evidence',
    'hypo.keyAssumptions': 'Key Operational Assumptions',
    'hypo.criticalUnknowns': 'Critical Unknowns & Vulnerabilities',
    'hypo.suggestedTests': 'Suggested Discriminating Experiments',
    'hypo.confidence': 'Confidence',
    'hypo.designProtocol': 'Generate Experiment Protocol for this Hypothesis',

    // Experiment Designer
    'exp.badge': 'Empirical Architecture · Protocol Specifications',
    'exp.title': 'Experiment Designer & Protocol Architecture',
    'exp.description': 'Parameterize independent, dependent, and controlled variables into structured, reproducible protocols with automated rigor checks.',
    'exp.exportProtocol': 'Export Protocol',
    'exp.editParameters': 'Edit Parameters',
    'exp.cancelEditing': 'Cancel Editing',
    'exp.newProtocol': 'New Protocol',
    'exp.objective': 'Scientific Objective',
    'exp.independentVars': 'Independent Variables',
    'exp.dependentVars': 'Dependent Endpoints',
    'exp.controlledVars': 'Controlled Variables',
    'exp.equipment': 'Instrumentation & Reagents',
    'exp.procedure': 'Execution Sequence Protocol',
    'exp.statsCriteria': 'Pre-Registered Statistical Evaluation Criteria',
    'exp.saveProtocol': 'Save Protocol & Verify Integrity',

    // Paper Analysis
    'paper.badge': 'Literature Decomposition · Critical Appraisal',
    'paper.title': 'Paper Analysis & Evidence Extraction',
    'paper.description': 'Systematic dissection of primary research questions, methodologies, findings, and potential biases with strict provenance tracking.',
    'paper.saveToLibrary': 'Save to Library',
    'paper.bridgeToHypo': 'Bridge to Hypothesis Lab',
    'paper.inputTitle': 'Manuscript Abstract or Primary Passage Input',
    'paper.deconstruct': 'Deconstruct & Analyze',
    'paper.verbatimTab': 'Verbatim Extracted Statements',
    'paper.synthesisTab': 'Structured Analytical Synthesis (6 Facets)',

    // Library
    'lib.badge': 'Scholarly Archive · Grounded References',
    'lib.title': 'Saved Literature & Bibliographic Archive',
    'lib.description': 'Grounded scholarly corpus with structured metadata, DOIs, and instant BibTeX citation export.',
    'lib.searchPlaceholder': 'Search papers, authors, DOIs...',
    'lib.openFull': 'Open Full Deconstruction in Paper Analysis',

    // Footer
    'footer.constitution': 'Editorial Constitution',
    'footer.methodology': 'Methodology & Protocols',
    'footer.privacy': 'Data Ethics & Provenance',
    'footer.contact': 'Academic Inquiries',
    'footer.version': 'Open Science Architecture · Version 4.2',

    // Language Toggle
    'lang.switch': 'ไทย'
  },
  th: {
    // Brand & Top Header
    'brand.name': 'Research Nexus AI',
    'brand.tagline': 'ระบบการค้นพบและวิจัยทางวิทยาศาสตร์',
    'brand.volume': 'ฉบับที่ 4 · กรอบวิธีวิทยาแบบเปิด (Open Framework)',
    'brand.protocols': 'เกณฑ์การวิจัยที่ผ่านการสอบทาน',

    // Nav
    'nav.workspace': 'พื้นที่ทำงาน (Workspace)',
    'nav.graph': 'กราฟความรู้ (Knowledge Graph)',
    'nav.hypotheses': 'ห้องทดลองสมมติฐาน (Hypothesis Lab)',
    'nav.experiments': 'ออกแบบการทดลอง (Experiment Designer)',
    'nav.paperAnalysis': 'วิเคราะห์บทความวิจัย (Paper Analysis)',
    'nav.savedPapers': 'คลังเอกสารอ้างอิง',
    'nav.overview': 'ภาพรวม',
    'nav.quickSearch': 'ค้นหาด่วน',
    'nav.openPalette': 'เปิดแถบคำสั่ง (⌘K)',

    // Hero
    'hero.badge': 'การสืบค้นทางวิทยาศาสตร์อย่างรัดกุม · สถาปัตยกรรมการทดลองเชิงประจักษ์',
    'hero.headline': 'วิจัยให้ลึกเกินกว่าที่เห็น',
    'hero.subtext': 'สำรวจองค์ความรู้ทางวิทยาศาสตร์ ตรวจสอบสมมติฐานที่แข่งขันกัน และเปลี่ยนคำถามที่ยังไม่มีคำตอบให้กลายเป็นการทดลองที่พิสูจน์ได้จริง พร้อมบัญชีสมดุลหลักฐานเชิงประจักษ์',
    'hero.searchPlaceholder': 'สืบค้นเป้าหมายโมเลกุล คุณสมบัติวัสดุ หรือสมมติฐานเชิงกลไก...',
    'hero.startResearching': 'เริ่มการวิจัย',
    'hero.exploreKnowledge': 'สำรวจองค์ความรู้',
    'hero.exampleInquiries': 'คำถามวิจัยตัวอย่างที่คัดสรร (คลิกเพื่อโหลด):',
    'hero.diagramCaption': 'เครือข่ายแนวคิดเชิงสาเหตุหลายแกน พร้อมหลักฐานเชื่อมโยงเชิงกลไกที่ผ่านการสอบทาน',

    // Workflow
    'workflow.title': 'ขั้นตอนกระบวนการวิจัยเชิงประจักษ์ 5 ระยะ',
    'workflow.subtitle': 'ความก้าวหน้าทางวิทยาศาสตร์ที่มีโครงสร้างชัดเจน ไม่มีการสร้างข้อมูลเท็จหรือคาดเดาลอยๆ',
    'workflow.step1.title': 'การกำหนดพารามิเตอร์ของคำถาม',
    'workflow.step1.sub': 'แยกประเด็นหรือตัวแปรเชิงสาเหตุที่ไม่ทราบแน่ชัด',
    'workflow.step1.desc': 'กำหนดขอบเขตทางชีววิทยา เคมี หรือวัสดุศาสตร์อย่างแม่นยำแทนการคาดเดาแบบผิวเผิน',
    'workflow.step2.title': 'การแยกแยะและย่อยวรรณกรรม',
    'workflow.step2.sub': 'สกัดข้ออ้างอิงที่แท้จริงและประเมินอคติที่อาจเกิดขึ้น',
    'workflow.step2.desc': 'ชำแหละผลงานตีพิมพ์ฉบับหลักเพื่อแยกข้อสังเกตที่มีการตรวจสอบแล้วออกจากข้อสรุปส่วนตัวของผู้เขียน',
    'workflow.step3.title': 'การกำหนดสมมติฐาน',
    'workflow.step3.sub': 'สร้างบัญชีสมดุลหลักฐานทั้งด้านสนับสนุนและขัดแย้ง',
    'workflow.step3.desc': 'เปรียบเทียบกลไกที่แข่งขันกัน ตรวจสอบข้อสมมติฐานตั้งต้น และระบุระดับความเชื่อมั่นอย่างโปร่งใส',
    'workflow.step4.title': 'สถาปัตยกรรมการออกแบบการทดลอง',
    'workflow.step4.sub': 'กำหนดตัวแปรต้น ตัวแปรตาม และตัวแปรควบคุมอย่างเป็นระบบ',
    'workflow.step4.desc': 'วางโครงสร้างระเบียบวิธีการทดลองที่ทำซ้ำได้ พร้อมกำหนดเกณฑ์ประเมินผลทางสถิติล่วงหน้า',
    'workflow.step5.title': 'ความรัดกุมเชิงประจักษ์และการทบทวน',
    'workflow.step5.sub': 'ตรวจสอบผลการทดลองเทียบกับเกณฑ์โดยไม่แต่งเติมข้อมูล',
    'workflow.step5.desc': 'ติดตามความคืบหน้าของโครงการด้วยการคำนวณกำลังทางสถิติ (n ≥ 3) และดัชนีผลลัพธ์ร่วม',

    // Projects
    'projects.title': 'โครงการวิจัยที่กำลังดำเนินการ',
    'projects.subtitle': 'โครงการสืบค้นทางวิทยาศาสตร์ที่บันทึกไว้ในพื้นที่ทำงาน',
    'projects.exploreInWorkspace': 'เปิดดูในพื้นที่ทำงาน',
    'projects.openWorkspace': 'เปิดพื้นที่ทำงาน',

    // Knowledge Graph
    'graph.title': 'กราฟความรู้เชิงโต้ตอบ (Interactive Knowledge Graph)',
    'graph.subtitle': 'โหนดแสดงถึงแนวคิดการวิจัย และเส้นเชื่อมโยงแสดงถึงความสัมพันธ์เชิงกลไกที่พิสูจน์แล้ว',
    'graph.searchPlaceholder': 'ค้นหาแนวคิด ยีน วัสดุ หรือกลไก...',
    'graph.allCategories': 'ทุกหมวดหมู่',
    'graph.target': 'เป้าหมายชีวโมเลกุล (Target)',
    'graph.pathway': 'วิถีการส่งสัญญาณ (Pathway)',
    'graph.phenotype': 'ฟีโนไทป์/ผลลัพธ์ (Phenotype)',
    'graph.material': 'วัสดุศาสตร์ (Material)',
    'graph.method': 'ระเบียบวิธี (Method)',
    'graph.zoomIn': 'ขยาย',
    'graph.zoomOut': 'ย่อ',
    'graph.resetZoom': 'รีเซ็ตมุมมอง',
    'graph.closeInspector': 'ปิดแผงข้อมูล',
    'graph.evidenceLinks': 'ความสัมพันธ์และหลักฐานเชิงกลไก',
    'graph.confidenceScore': 'ระดับความเชื่อมั่น',
    'graph.bridgeToHypothesis': 'ส่งต่อไปยังห้องทดลองสมมติฐาน',

    // Hypothesis Lab
    'hypo.badge': 'การไต่สวนเชิงกลไก · บัญชีสมดุลหลักฐาน',
    'hypo.title': 'ห้องทดลองสมมติฐาน (Hypothesis Lab)',
    'hypo.activeRecords': 'รายการที่ใช้งานอยู่',
    'hypo.description': 'ตั้งสมมติฐาน ตรวจสอบความถูกต้อง และเปรียบเทียบคำอธิบายทางวิทยาศาสตร์ที่แข่งขันกันด้วยบัญชีสมดุลหลักฐาน',
    'hypo.exportMarkdown': 'ส่งออก Markdown',
    'hypo.compareHypotheses': 'เปรียบเทียบสมมติฐาน',
    'hypo.exitComparison': 'ออกจากการเปรียบเทียบ',
    'hypo.formulate': 'ตั้งสมมติฐานใหม่',
    'hypo.supportingEvidence': 'หลักฐานสนับสนุน (Supporting)',
    'hypo.counterEvidence': 'หลักฐานขัดแย้ง/โต้แย้ง (Counter)',
    'hypo.keyAssumptions': 'ข้อสมมติฐานในการดำเนินการ',
    'hypo.criticalUnknowns': 'จุดที่ยังไม่ทราบและช่องโหว่ที่สำคัญ',
    'hypo.suggestedTests': 'ข้อเสนอแนะการทดลองเพื่อจำแนกผล',
    'hypo.confidence': 'ความเชื่อมั่น',
    'hypo.designProtocol': 'สร้างโปรโตคอลการทดลองสำหรับสมมติฐานนี้',

    // Experiment Designer
    'exp.badge': 'สถาปัตยกรรมเชิงประจักษ์ · ข้อกำหนดโปรโตคอล',
    'exp.title': 'ออกแบบการทดลองและโปรโตคอลวิจัย',
    'exp.description': 'กำหนดตัวแปรต้น ตัวแปรตาม และตัวแปรควบคุมให้เป็นระเบียบวิธีที่ทำซ้ำได้ พร้อมระบบตรวจวัดความรัดกุมอัตโนมัติ',
    'exp.exportProtocol': 'ส่งออกโปรโตคอล',
    'exp.editParameters': 'แก้ไขพารามิเตอร์',
    'exp.cancelEditing': 'ยกเลิกการแก้ไข',
    'exp.newProtocol': 'สร้างโปรโตคอลใหม่',
    'exp.objective': 'วัตถุประสงค์ทางวิทยาศาสตร์',
    'exp.independentVars': 'ตัวแปรต้น (Treatment Conditions)',
    'exp.dependentVars': 'ตัวแปรตาม (Endpoints)',
    'exp.controlledVars': 'ตัวแปรควบคุม (Controlled Variables)',
    'exp.equipment': 'เครื่องมือวัดและสารเคมี/รีเอเจนต์',
    'exp.procedure': 'ลำดับขั้นตอนการปฏิบัติการ',
    'exp.statsCriteria': 'เกณฑ์การประเมินทางสถิติที่กำหนดล่วงหน้า',
    'exp.saveProtocol': 'บันทึกโปรโตคอลและตรวจสอบความสมบูรณ์',

    // Paper Analysis
    'paper.badge': 'การย่อยวรรณกรรม · การประเมินเชิงวิพากษ์',
    'paper.title': 'วิเคราะห์บทความวิจัยและสกัดหลักฐาน',
    'paper.description': 'ชำแหละคำถามวิจัย วิธีการ ผลลัพธ์ และประเมินอคติที่อาจแฝงอยู่ พร้อมระบบบันทึกแหล่งที่มาที่แม่นยำ',
    'paper.saveToLibrary': 'บันทึกเข้าคลัง',
    'paper.bridgeToHypo': 'ส่งต่อไปห้องทดลองสมมติฐาน',
    'paper.inputTitle': 'บทคัดย่อหรือข้อความจากเอกสารวิจัย',
    'paper.deconstruct': 'แยกแยะและวิเคราะห์เนื้อหา',
    'paper.verbatimTab': 'ข้อความยกมาตรงๆ จากเอกสาร (Verbatim)',
    'paper.synthesisTab': 'การสังเคราะห์เชิงโครงสร้าง 6 มิติ',

    // Library
    'lib.badge': 'คลังเอกสารวิชาการ · แหล่งอ้างอิงที่เชื่อถือได้',
    'lib.title': 'คลังวรรณกรรมและบรรณานุกรมที่บันทึกไว้',
    'lib.description': 'คลังบทความวิจัยพร้อมข้อมูลอภิมิติ (Metadata), รหัส DOI และการส่งออกรูปแบบการอ้างอิง BibTeX ทันที',
    'lib.searchPlaceholder': 'ค้นหาบทความ, ผู้วิจัย, รหัส DOI...',
    'lib.openFull': 'เปิดการวิเคราะห์แบบเต็มใน Paper Analysis',

    // Footer
    'footer.constitution': 'เจตนารมณ์และหลักการ',
    'footer.methodology': 'ระเบียบวิธีและโปรโตคอล',
    'footer.privacy': 'จริยธรรมข้อมูลและความโปร่งใส',
    'footer.contact': 'ติดต่อฝ่ายวิชาการ',
    'footer.version': 'สถาปัตยกรรมวิทยาศาสตร์แบบเปิด · รุ่น 4.2',

    // Language Toggle
    'lang.switch': 'EN'
  }
};

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [language, setLanguageState] = useState<Language>(() => {
    try {
      const stored = localStorage.getItem(LANGUAGE_STORAGE_KEY);
      if (stored === 'th' || stored === 'en') return stored;
      // Check browser language
      if (typeof navigator !== 'undefined' && navigator.language?.toLowerCase().startsWith('th')) {
        return 'th';
      }
    } catch {}
    return 'en';
  });

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
    try {
      localStorage.setItem(LANGUAGE_STORAGE_KEY, lang);
    } catch {}
  };

  const toggleLanguage = () => {
    setLanguage(language === 'en' ? 'th' : 'en');
  };

  const t = (key: string, defaultText?: string): string => {
    const langDict = translations[language] || translations.en;
    if (langDict[key]) return langDict[key];
    if (translations.en[key]) return translations.en[key];
    return defaultText || key;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, toggleLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
}
