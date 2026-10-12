import { NexContextInfo, NexLanguage } from './types';

interface NexAiResponse {
  reply: string;
  isFallback?: boolean;
  error?: string;
}

export async function askNex(
  message: string,
  context: NexContextInfo,
  language: NexLanguage = 'en'
): Promise<NexAiResponse> {
  const contextString = [
    `Current Active View: ${context.currentView}`,
    context.activeProjectTitle ? `Project: ${context.activeProjectTitle} (${context.activeProjectShortCode || 'N/A'})` : '',
    context.activeProjectDomain ? `Domain: ${context.activeProjectDomain}` : '',
    context.currentStage ? `Stage: ${context.currentStage}` : '',
    context.selectedConcept ? `Selected Knowledge Concept: ${context.selectedConcept}` : '',
    context.hypothesesCount !== undefined ? `Recorded Hypotheses: ${context.hypothesesCount}` : '',
    context.experimentsCount !== undefined ? `Recorded Protocols: ${context.experimentsCount}` : ''
  ].filter(Boolean).join('\n');

  try {
    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message,
        context: contextString,
        language
      })
    });

    if (res.ok) {
      const data = await res.json();
      if (data.reply) {
        return { reply: data.reply, isFallback: false };
      }
    }

    const errData = await res.json().catch(() => ({}));
    const isKeyMissing = errData.error === 'GEMINI_API_KEY_NOT_CONFIGURED';

    return {
      reply: generateGroundedFallback(message, context, language, isKeyMissing),
      isFallback: true,
      error: isKeyMissing ? 'API Key not configured' : 'Network/Service unreachable'
    };
  } catch (err: any) {
    return {
      reply: generateGroundedFallback(message, context, language, false),
      isFallback: true,
      error: 'Offline connection'
    };
  }
}

function generateGroundedFallback(
  query: string,
  context: NexContextInfo,
  language: NexLanguage,
  isKeyMissing: boolean
): string {
  const q = query.toLowerCase();

  if (language === 'th') {
    if (q.includes('เริ่ม') || q.includes('start') || q.includes('สร้าง')) {
      return `[โหมดผู้ช่วยวิจัยในเครื่อง - Local Assistant]
หากต้องการเริ่มต้นโครงการวิจัยใหม่ใน Research Nexus:
1. ไปที่แท็บ **Workspace** ที่แถบเมนูด้านบน
2. คลิกปุ่ม **+ New** ในกล่องโครงการเพื่อกำหนดชื่อ, รหัส และสาขาวิทยาศาสตร์
3. กำหนดคำถามวิจัยหลักในขั้นตอนที่ 1 แล้วระบบจะนำทางคุณเข้าสู่การทบทวนวรรณกรรมและตั้งสมมติฐานครับ`;
    }

    if (q.includes('สมมติฐาน') || q.includes('hypothesis')) {
      return `[โหมดผู้ช่วยวิจัยในเครื่อง - Local Assistant]
ใน **Hypothesis Lab** คุณสามารถ:
- สร้างสมมติฐานเชิงกลไกพร้อมทั้งหลักฐานสนับสนุน (Supporting) และหลักฐานที่ขัดแย้ง (Contradicting)
- กดปุ่ม **Compare Hypotheses** เพื่อเปรียบเทียบสองสมมติฐานแบบเคียงข้างกัน
- ประเมินคะแนนความเชื่อมั่น (Confidence Score) ตามความน่าเชื่อถือของการทดลองจริงครับ`;
    }

    if (q.includes('ทดลอง') || q.includes('experiment')) {
      return `[โหมดผู้ช่วยวิจัยในเครื่อง - Local Assistant]
ใน **Experiment Designer**:
- ระบุตัวแปรต้น (Independent) และตัวแปรตาม (Dependent) พร้อมวิธีการวัดผล
- ระบบมีตัวตรวจสอบความรัดกุม (Rigor Diagnostics) เพื่อเตือนหากลืมกำหนดตัวแปรควบคุม (Controlled Variables) หรือกลุ่มตัวอย่าง n < 3
- คุณสามารถส่งออกโปรโตคอลเป็นไฟล์ Markdown เพื่อนำไปใช้ในห้องปฏิบัติการได้เลยครับ`;
    }

    return `[โหมดผู้ช่วยวิจัยในเครื่อง - Local Assistant]
ขณะนี้อยู่ในโครงการ **${context.activeProjectTitle || 'Research Nexus'}** (ขั้นตอน: ${context.currentStage || 'วิจัย'})
คุณสามารถใช้แท็บ **Knowledge Graph** เพื่อสำรวจความสัมพันธ์ของโมเลกุล หรือเปิด **Paper Analysis** เพื่อถอดรหัสข้อความจากเอกสารวิจัยได้ตลอดเวลาครับ!`;
  }

  // English grounded responses
  if (q.includes('start') || q.includes('begin') || q.includes('project') || q.includes('how do i')) {
    return `[Local Grounded Research Guide]
To begin or manage a research project in Research Nexus AI:
1. Navigate to the **Workspace** tab from the top navigation bar.
2. Click **+ New** in the project box to define your project title, short code, and domain (e.g. Molecular Oncology or Materials Science).
3. The platform will guide you through the 5-stage workflow: **Research Question → Literature Review → Hypothesis Formulation → Experiment Execution → Results Evaluation**.
4. You can edit notes and active milestones for any stage directly in the Research Timeline.`;
  }

  if (q.includes('kras') || q.includes('concept') || q.includes('pathway') || q.includes('sos1') || q.includes('perovskite')) {
    return `[Local Scientific Knowledge Base]
Regarding active model concepts in the platform:
- **KRAS G12D**: An oncogenic driver GTPase harboring an activating codon 12 mutation that blocks GTP hydrolysis. Targeted by small molecule MRTX1133.
- **SOS1 GEF**: Guanine nucleotide exchange factor recruited by upstream RTK feedback (EGFR/HER2) that reloads GTP onto KRAS. Co-targeting SOS1 with BI-3406 suppresses rebound resistance.
- **Perovskite Tandems**: Wide-bandgap (1.68 eV) absorbers passivated with 2PACz carbazole monolayers to suppress light-induced halide demixing and ion migration under ISOS-L-1 standards.
You can drag and inspect all these nodes directly in the **Knowledge Graph** tab!`;
  }

  if (q.includes('hypothesis') || q.includes('compare')) {
    return `[Local Grounded Research Guide]
In the **Hypothesis Lab**:
- Each hypothesis records both **supporting** and **contradicting** empirical evidence to combat confirmation bias.
- You can activate **Compare Hypotheses** to inspect competing theories side-by-side in a comparative matrix.
- Each hypothesis includes explicit assumptions, unknowns, and suggested tests.
- Once refined, click **"Generate Experiment Protocol for this Hypothesis"** to bridge directly into the Experiment Designer.`;
  }

  if (q.includes('experiment') || q.includes('design') || q.includes('protocol')) {
    return `[Local Grounded Research Guide]
In the **Experiment Designer**:
- Parameterize **Independent Variables** (with ranges and units), **Dependent Endpoints** (with measurement methods and expected baselines), and **Controlled Variables**.
- The system automatically triggers **Rigor Diagnostics** if controlled variables are omitted or replication count $n < 3$.
- Define pre-registered statistical tests (e.g., Two-way ANOVA with Tukey post-hoc) and significance thresholds.
- Click **Export Protocol** to generate a laboratory Markdown protocol.`;
  }

  if (q.includes('next') || q.includes('investigate') || q.includes('recommend')) {
    const stage = context.currentStage || 'question';
    return `[Local Workflow Recommendation]
Based on your current active stage (**${stage}**) in **${context.activeProjectShortCode || 'your active project'}**:
${stage === 'question' ? '• Solidify boundary conditions and enter the Literature Review to extract existing findings.' : ''}
${stage === 'literature' ? '• Review extracted findings in Paper Analysis, then formulate competing mechanistic models in the Hypothesis Lab.' : ''}
${stage === 'hypothesis' ? '• Contrast your active hypotheses in comparison mode and choose the most critical discriminating test to design an experiment.' : ''}
${stage === 'experiment' ? '• Execute protocol replicates (n ≥ 3) and evaluate combination indices or statistical thresholds in Results & Evaluation.' : ''}
${stage === 'results' ? '• Review replication power and publish your validated findings or open subsequent exploratory questions.' : ''}`;
  }

  return `[Local Grounded Research Guide]
I am NEX, your scientific research companion!
Currently focused on: **${context.activeProjectTitle || 'Research Nexus Platform'}** (${context.activeProjectDomain || 'Interdisciplinary Science'}).
- Currently in: **${context.currentView}** view (${context.currentStage || 'Investigation'} stage).
- Feel free to ask about setting up experiments, comparing hypotheses, inspecting knowledge graph nodes, or analyzing literature papers!`;
}
