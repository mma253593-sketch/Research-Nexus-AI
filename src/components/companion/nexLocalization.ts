import { NexLanguage } from './types';

export const nexStrings = {
  en: {
    name: 'NEX',
    tagline: 'Your Research Companion',
    greetingDefault: 'Hello! I am NEX, your scientific research assistant. How can I assist your investigation today?',
    greetingWorkspace: 'Welcome back to the Research Workspace! Ready to structure your project milestones?',
    greetingGraph: 'Exploring the Knowledge Graph! Click any node to inspect mechanistic relationships and evidence.',
    greetingHypothesis: 'In the Hypothesis Lab! Remember to log contradicting evidence alongside supporting data.',
    greetingExperiment: 'Designing an experiment! Check the rigor diagnostics to ensure controlled variables are locked.',
    greetingPaper: 'Analyzing literature! Notice how verbatim quotes are strictly separated from analytical synthesis.',
    celebrateHypothesis: 'Excellent! Your hypothesis record has been formulated and calibrated with confidence basis.',
    celebrateExperiment: 'Protocol generated! Independent, dependent, and controlled variables verified.',
    tipWalkDisabled: 'Autonomous walking paused while you work.',
    chatPlaceholder: 'Ask NEX a research question or navigation query...',
    suggestedQuestions: [
      'How do I start a research project?',
      'Explain the KRAS G12D pathway concept.',
      'Help me compare competing hypotheses.',
      'How should I design an experiment protocol?',
      'What should I investigate next in my project?'
    ],
    settingsTitle: 'NEX Companion Controls',
    showNex: 'Show NEX Companion',
    walkingEnabled: 'Autonomous Walking Movement',
    voiceEnabled: 'Speech Synthesis Audio',
    autoGreetings: 'Contextual Speech Bubbles',
    sizeLabel: 'Companion Scale',
    resetPosition: 'Reset to Default Dock Position',
    languageLabel: 'Assistant Language',
    close: 'Close',
    send: 'Send',
    offlineNotice: 'AI server currently in local offline mode. Using grounded workspace knowledge.',
    summonNex: 'Summon NEX Companion',
    hideNex: 'Hide NEX'
  },
  th: {
    name: 'เน็กซ์ (NEX)',
    tagline: 'เพื่อนคู่คิดงานวิจัยของคุณ',
    greetingDefault: 'สวัสดีครับ! ผมชื่อ NEX ผู้ช่วยวิจัยทางวิทยาศาสตร์ วันนี้ต้องการให้ผมช่วยสืบค้นหรือออกแบบการทดลองอะไรดีครับ?',
    greetingWorkspace: 'ยินดีต้อนรับสู่พื้นที่วิจัย! พร้อมที่จะจัดการลำดับขั้นและสมมติฐานของโครงการแล้วหรือยังครับ?',
    greetingGraph: 'กำลังสำรวจกราฟความรู้! คุณสามารถคลิกที่โหนดเพื่อดูกลไกและหลักฐานอ้างอิงได้เลยครับ',
    greetingHypothesis: 'อยู่ในห้องทดลองสมมติฐาน! อย่าลืมบันทึกหลักฐานที่ขัดแย้งควบคู่กับหลักฐานสนับสนุนด้วยนะครับ',
    greetingExperiment: 'กำลังออกแบบการทดลอง! ตรวจสอบตัวแปรควบคุมและเกณฑ์ทางสถิติให้ครบถ้วนเพื่อความรัดกุม',
    greetingPaper: 'กำลังวิเคราะห์บทความวิจัย! สังเกตข้อความที่ยกมาตรงๆ จะถูกแยกจากการสังเคราะห์อย่างชัดเจน',
    celebrateHypothesis: 'ยอดเยี่ยมครับ! บันทึกสมมติฐานได้รับการจัดเก็บพร้อมระดับความเชื่อมั่นแล้ว',
    celebrateExperiment: 'สร้างโปรโตคอลการทดลองสำเร็จแล้ว! ตัวแปรและขั้นตอนได้รับการตรวจสอบเรียบร้อย',
    tipWalkDisabled: 'หยุดการเดินอัตโนมัติขณะที่คุณกำลังใช้งาน',
    chatPlaceholder: 'ถามคำถามเกี่ยวกับการวิจัยหรือวิธีใช้งานกับ NEX...',
    suggestedQuestions: [
      'เริ่มต้นโครงการวิจัยใหม่อย่างไร?',
      'อธิบายแนวคิดกลไก KRAS G12D ให้ฟังหน่อย',
      'ช่วยเปรียบเทียบสมมติฐานที่แข่งขันกัน',
      'ออกแบบการทดลองอย่างไรให้รัดกุม?',
      'ขั้นตอนถัดไปที่ควรตรวจสอบในโครงการคืออะไร?'
    ],
    settingsTitle: 'การตั้งค่าผู้ช่วย NEX',
    showNex: 'แสดงผู้ช่วย NEX',
    walkingEnabled: 'อนุญาตให้เดินสำรวจอัตโนมัติ',
    voiceEnabled: 'เสียงพูดสังเคราะห์ (Speech Synthesis)',
    autoGreetings: 'กล่องคำพูดข้อความช่วยเหลืออัตโนมัติ',
    sizeLabel: 'ขนาดของตัวละคร',
    resetPosition: 'รีเซ็ตตำแหน่งกลับไปที่มุมจอ',
    languageLabel: 'ภาษาของผู้ช่วย',
    close: 'ปิด',
    send: 'ส่ง',
    offlineNotice: 'ระบบ AI อยู่ในโหมดออฟไลน์ กำลังใช้ฐานข้อมูลงานวิจัยในเครื่องแทน',
    summonNex: 'เรียก NEX',
    hideNex: 'ซ่อน NEX'
  }
};

export function getLocalized(lang: NexLanguage = 'en') {
  return nexStrings[lang] || nexStrings.en;
}
