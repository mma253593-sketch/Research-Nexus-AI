// Production-safe Vite static asset imports
import heroConceptGraph from './images/hero_scientific_concept_graph_1791775704373.jpg';
import oncologyPathway from './images/project_oncology_pathway_1791775717057.jpg';
import photovoltaicPerovskite from './images/project_photovoltaic_perovskite_1791775728611.jpg';
import neuroSynapse from './images/project_neuro_synapse_1791775738823.jpg';

export const SCIENTIFIC_IMAGES = {
  heroConceptGraph,
  oncologyPathway,
  photovoltaicPerovskite,
  neuroSynapse,
  // Public fallback paths (served from /public/images/)
  publicHero: '/images/hero_scientific_concept_graph.jpg',
  publicOncology: '/images/project_oncology_pathway.jpg',
  publicPerovskite: '/images/project_photovoltaic_perovskite.jpg',
  publicSynapse: '/images/project_neuro_synapse.jpg',
};

// Map legacy or raw project image paths to resolved Vite production URLs
export function resolveProjectImageUrl(pathOrKey?: string): string {
  if (!pathOrKey) return SCIENTIFIC_IMAGES.oncologyPathway;

  const key = pathOrKey.toLowerCase();
  if (key.includes('hero') || key.includes('concept')) {
    return SCIENTIFIC_IMAGES.heroConceptGraph;
  }
  if (key.includes('oncol') || key.includes('kras') || key.includes('pathway')) {
    return SCIENTIFIC_IMAGES.oncologyPathway;
  }
  if (key.includes('perov') || key.includes('photo') || key.includes('solar')) {
    return SCIENTIFIC_IMAGES.photovoltaicPerovskite;
  }
  if (key.includes('neuro') || key.includes('synap') || key.includes('microgli')) {
    return SCIENTIFIC_IMAGES.neuroSynapse;
  }

  return SCIENTIFIC_IMAGES.oncologyPathway;
}
