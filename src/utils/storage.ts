import { ResearchProject, ScientificPaper, Hypothesis, ExperimentPlan } from '../types/research';
import { initialProjects, samplePapers, sampleHypotheses, sampleExperiments } from '../data/mockData';

const STORAGE_KEYS = {
  PROJECTS: 'nexus_research_projects_v1',
  ACTIVE_PROJECT_ID: 'nexus_active_project_id_v1',
  PAPERS: 'nexus_saved_papers_v1',
  HYPOTHESES: 'nexus_hypotheses_v1',
  EXPERIMENTS: 'nexus_experiments_v1',
  THEME: 'nexus_theme_mode_v1'
};

export function getStoredProjects(): ResearchProject[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.PROJECTS);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.PROJECTS, JSON.stringify(initialProjects));
      return initialProjects;
    }
    return JSON.parse(raw);
  } catch {
    return initialProjects;
  }
}

export function saveStoredProjects(projects: ResearchProject[]): void {
  try {
    localStorage.setItem(STORAGE_KEYS.PROJECTS, JSON.stringify(projects));
  } catch (e) {
    console.error('Failed to save projects to localStorage', e);
  }
}

export function getStoredActiveProjectId(): string {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.ACTIVE_PROJECT_ID);
    if (raw) return raw;
    return initialProjects[0]?.id ?? 'proj-kras-01';
  } catch {
    return 'proj-kras-01';
  }
}

export function saveStoredActiveProjectId(id: string): void {
  try {
    localStorage.setItem(STORAGE_KEYS.ACTIVE_PROJECT_ID, id);
  } catch (e) {
    console.error('Failed to save active project ID', e);
  }
}

export function getStoredPapers(): ScientificPaper[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.PAPERS);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.PAPERS, JSON.stringify(samplePapers));
      return samplePapers;
    }
    return JSON.parse(raw);
  } catch {
    return samplePapers;
  }
}

export function saveStoredPapers(papers: ScientificPaper[]): void {
  try {
    localStorage.setItem(STORAGE_KEYS.PAPERS, JSON.stringify(papers));
  } catch (e) {
    console.error('Failed to save papers', e);
  }
}

export function getStoredHypotheses(): Hypothesis[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.HYPOTHESES);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.HYPOTHESES, JSON.stringify(sampleHypotheses));
      return sampleHypotheses;
    }
    return JSON.parse(raw);
  } catch {
    return sampleHypotheses;
  }
}

export function saveStoredHypotheses(hypotheses: Hypothesis[]): void {
  try {
    localStorage.setItem(STORAGE_KEYS.HYPOTHESES, JSON.stringify(hypotheses));
  } catch (e) {
    console.error('Failed to save hypotheses', e);
  }
}

export function getStoredExperiments(): ExperimentPlan[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.EXPERIMENTS);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.EXPERIMENTS, JSON.stringify(sampleExperiments));
      return sampleExperiments;
    }
    return JSON.parse(raw);
  } catch {
    return sampleExperiments;
  }
}

export function saveStoredExperiments(experiments: ExperimentPlan[]): void {
  try {
    localStorage.setItem(STORAGE_KEYS.EXPERIMENTS, JSON.stringify(experiments));
  } catch (e) {
    console.error('Failed to save experiments', e);
  }
}

export function getStoredTheme(): 'light' | 'dark' {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.THEME);
    if (raw === 'dark' || raw === 'light') return raw;
    return 'light';
  } catch {
    return 'light';
  }
}

export function saveStoredTheme(theme: 'light' | 'dark'): void {
  try {
    localStorage.setItem(STORAGE_KEYS.THEME, theme);
  } catch (e) {
    console.error('Failed to save theme', e);
  }
}
