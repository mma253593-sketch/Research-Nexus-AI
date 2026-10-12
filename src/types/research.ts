export type ResearchStage = 'question' | 'literature' | 'hypothesis' | 'experiment' | 'results';

export interface StageNote {
  stage: ResearchStage;
  status: 'completed' | 'active' | 'upcoming';
  summary: string;
  keyQuestions: string[];
  lastUpdated: string;
}

export interface ResearchProject {
  id: string;
  title: string;
  shortCode: string;
  description: string;
  domain: string;
  currentStage: ResearchStage;
  tags: string[];
  createdAt: string;
  updatedAt: string;
  stageNotes: Record<ResearchStage, StageNote>;
  hypothesesCount: number;
  papersCount: number;
  experimentsCount: number;
  image?: string;
}

export interface ScientificPaper {
  id: string;
  title: string;
  authors: string[];
  journal: string;
  year: number;
  doi?: string;
  pmid?: string;
  url?: string;
  abstract: string;
  researchQuestion: string;
  methodology: string;
  mainFindings: string[];
  limitations: string[];
  potentialBias: string[];
  furtherQuestions: string[];
  extractedStatements: {
    category: 'objective' | 'method' | 'finding' | 'limitation';
    quote: string;
    location: string;
  }[];
  citationCount?: number;
  openAccess?: boolean;
}

export interface EvidenceItem {
  id: string;
  sourceTitle: string;
  sourceCitation: string;
  evidenceText: string;
  evidenceType: 'in_vitro' | 'in_vivo' | 'clinical' | 'computational' | 'observational';
  doi?: string;
}

export interface Hypothesis {
  id: string;
  projectId: string;
  title: string;
  statement: string;
  rationale: string;
  supportingEvidence: EvidenceItem[];
  contradictingEvidence: EvidenceItem[];
  assumptions: string[];
  unknowns: string[];
  suggestedTests: string[];
  confidenceScore: number; // 0 to 1
  confidenceBasis: string;
  status: 'formulated' | 'testing' | 'supported' | 'refuted';
  createdAt: string;
  updatedAt: string;
}

export interface ExperimentPlan {
  id: string;
  projectId: string;
  hypothesisId?: string;
  title: string;
  researchObjective: string;
  independentVariables: { name: string; range: string; unit: string }[];
  dependentVariables: { name: string; measurementMethod: string; expectedBaseline: string }[];
  controlledVariables: string[];
  equipmentAndResources: string[];
  procedureSteps: string[];
  measurementMethod: string;
  expectedOutcomes: string;
  alternativeExplanations: string[];
  evaluationCriteria: {
    statisticalTest: string;
    significanceThreshold: string;
    replicationCount: number;
    successMetric: string;
  };
  warnings: string[];
  createdAt: string;
  status: 'draft' | 'ready' | 'in_execution' | 'completed';
}

export type ConceptCategory = 
  | 'Target' 
  | 'Pathway' 
  | 'Compound' 
  | 'Phenotype' 
  | 'Mechanism' 
  | 'Biomarker';

export interface GraphNode {
  id: string;
  label: string;
  category: ConceptCategory;
  description: string;
  evidenceExcerpt: string;
  supportingCitation: string;
  degree?: number;
  x?: number;
  y?: number;
  vx?: number;
  vy?: number;
}

export interface GraphEdge {
  id: string;
  source: string;
  target: string;
  relationship: string;
  mechanism: string;
  evidenceBasis: string;
}
