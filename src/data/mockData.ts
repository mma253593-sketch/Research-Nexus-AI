import { ResearchProject, ScientificPaper, Hypothesis, ExperimentPlan, GraphNode, GraphEdge } from '../types/research';
import { SCIENTIFIC_IMAGES } from '../assets/images';

export const initialProjects: ResearchProject[] = [
  {
    id: 'proj-kras-01',
    title: 'Targeting KRAS G12D Resistance in Pancreatic Ductal Adenocarcinoma',
    shortCode: 'ONC-702',
    description: 'Investigating adaptive receptor tyrosine kinase (RTK) feedback loops following allosteric inhibition of KRAS G12D with MRTX1133 and synergistic co-targeting strategies.',
    domain: 'Molecular Oncology',
    currentStage: 'hypothesis',
    tags: ['KRAS G12D', 'RTK Feedback', 'SOS1', 'PDAC'],
    createdAt: '2026-08-14',
    updatedAt: '2026-10-09',
    image: SCIENTIFIC_IMAGES.oncologyPathway,
    hypothesesCount: 3,
    papersCount: 8,
    experimentsCount: 2,
    stageNotes: {
      question: {
        stage: 'question',
        status: 'completed',
        summary: 'Primary question defined: How do PDAC cells rewire RTK signaling within 48-72 hours of MRTX1133 exposure to evade apoptotic arrest?',
        keyQuestions: [
          'Which upstream RTKs (EGFR, MET, HER2) undergo rapid phosphorylation?',
          'Does SOS1 or SHP2 co-inhibition block GTP-reloading more effectively?'
        ],
        lastUpdated: '2026-08-20'
      },
      literature: {
        stage: 'literature',
        status: 'completed',
        summary: 'Synthesized 24 papers on KRAS switch-II pocket binding and secondary resistance mutations in codon 12/61 alleles.',
        keyQuestions: ['Identify consensus resistance pathways in clinical trial patient biopsies.'],
        lastUpdated: '2026-09-02'
      },
      hypothesis: {
        stage: 'hypothesis',
        status: 'active',
        summary: 'Formulated 3 competing hypotheses regarding SHP2 vs SOS1 allosteric blockade as the optimal co-target.',
        keyQuestions: ['Compare off-target toxicity profiles between SHP2 (RMC-4550) and SOS1 (BI-3406) scaffolds.'],
        lastUpdated: '2026-10-08'
      },
      experiment: {
        stage: 'experiment',
        status: 'upcoming',
        summary: 'Designing dual-inhibitor dose-response matrix across 4 patient-derived PDAC organoid lines.',
        keyQuestions: ['Confirm IC50 shift and p-ERK1/2 suppression kinetics over 96 hours.'],
        lastUpdated: '2026-10-09'
      },
      results: {
        stage: 'results',
        status: 'upcoming',
        summary: 'Awaiting high-content organoid viability assays and Western blot quantification.',
        keyQuestions: ['Validate synergistic combination index (CI < 0.7 by Chou-Talalay).'],
        lastUpdated: '2026-10-09'
      }
    }
  },
  {
    id: 'proj-perov-02',
    title: 'Perovskite-Silicon Tandem Photovoltaic Degradation Kinetics',
    shortCode: 'MAT-318',
    description: 'Elucidating light-induced halide phase segregation kinetics and interfacial 2D-passivation mechanisms under ISOS-L-1 continuous illumination standards.',
    domain: 'Materials Science',
    currentStage: 'experiment',
    tags: ['Perovskite Tandems', 'Halide Segregation', 'ISOS-L-1', 'Passivation'],
    createdAt: '2026-07-22',
    updatedAt: '2026-10-10',
    image: SCIENTIFIC_IMAGES.photovoltaicPerovskite,
    hypothesesCount: 2,
    papersCount: 12,
    experimentsCount: 3,
    stageNotes: {
      question: {
        stage: 'question',
        status: 'completed',
        summary: 'How does wide-bandgap (1.68 eV) mixed-halide perovskite composition accelerate iodide-bromide phase separation under 1-sun continuous load?',
        keyQuestions: ['Can bulky alkylammonium cations inhibit defect-assisted halide ion hopping?'],
        lastUpdated: '2026-07-25'
      },
      literature: {
        stage: 'literature',
        status: 'completed',
        summary: 'Comprehensive review of 2D/3D heterostructure interface stability and in-situ photoluminescence mapping studies.',
        keyQuestions: ['Identify activation energies for ion migration across grain boundaries.'],
        lastUpdated: '2026-08-11'
      },
      hypothesis: {
        stage: 'hypothesis',
        status: 'completed',
        summary: 'Fluorinated 2D spacer cations raise the defect formation energy barrier by >0.4 eV, suppressing halide demixing.',
        keyQuestions: ['Does steric hindrance alter carrier extraction velocity at the C60 interface?'],
        lastUpdated: '2026-09-01'
      },
      experiment: {
        stage: 'experiment',
        status: 'active',
        summary: 'Executing 1,000-hour environmental chamber testing at 65°C under maximum power point tracking.',
        keyQuestions: ['Track open-circuit voltage decay and PL peak shift every 24 hours.'],
        lastUpdated: '2026-10-10'
      },
      results: {
        stage: 'results',
        status: 'upcoming',
        summary: 'Initial 250-hour data shows <1.8% efficiency drop for fluorinated 2D passivated cells versus 9.4% for control.',
        keyQuestions: ['Confirm structural integrity via post-mortem grazing incidence XRD.'],
        lastUpdated: '2026-10-10'
      }
    }
  },
  {
    id: 'proj-neuro-03',
    title: 'Synaptic Plasticity Modulation via Microglial Pruning in Neurodegeneration',
    shortCode: 'NEU-504',
    description: 'Investigating complement cascade C1q/C3 opsonization and TREM2-dependent engulfment of dendritic spines in early hippocampal tauopathy models.',
    domain: 'Neurobiology',
    currentStage: 'literature',
    tags: ['Synaptic Pruning', 'Microglia', 'Complement C1q', 'Tauopathy'],
    createdAt: '2026-09-10',
    updatedAt: '2026-10-11',
    image: SCIENTIFIC_IMAGES.neuroSynapse,
    hypothesesCount: 2,
    papersCount: 15,
    experimentsCount: 1,
    stageNotes: {
      question: {
        stage: 'question',
        status: 'completed',
        summary: 'Does pathological hyperphosphorylated tau seed early C1q deposition at mushroom dendritic spines prior to overt neuronal loss?',
        keyQuestions: ['What molecular tag designates vulnerable synapses for complement tagging?'],
        lastUpdated: '2026-09-15'
      },
      literature: {
        stage: 'literature',
        status: 'active',
        summary: 'Analyzing super-resolution STED and electron microscopy studies of synaptic bouton elimination by phagocytic microglia.',
        keyQuestions: ['Determine role of phosphatidylserine exposure on the synaptic outer leaflet.'],
        lastUpdated: '2026-10-11'
      },
      hypothesis: {
        stage: 'hypothesis',
        status: 'upcoming',
        summary: 'Pre-synaptic annexin V binding initiates local C1q recruitment independently of somatic apoptosis.',
        keyQuestions: ['Can targeted C1q neutralizing antibodies rescue LTP deficits in hippocampal slices?'],
        lastUpdated: '2026-10-11'
      },
      experiment: {
        stage: 'experiment',
        status: 'upcoming',
        summary: 'Proposed two-photon in vivo imaging of dendritic spine turnover in PS19 tau transgenic mice.',
        keyQuestions: ['Define imaging intervals (daily vs bi-daily) to track spine lifetime.'],
        lastUpdated: '2026-10-11'
      },
      results: {
        stage: 'results',
        status: 'upcoming',
        summary: 'Awaiting baseline spine density counts from cohort A.',
        keyQuestions: ['Calculate percentage loss in CA1 pyramidal stratum radiatum.'],
        lastUpdated: '2026-10-11'
      }
    }
  }
];

export const samplePapers: ScientificPaper[] = [
  {
    id: 'paper-wang-2023',
    title: 'Overcoming Adaptive Feedback Reactivation in KRAS G12D-Mutant Pancreatic Adenocarcinoma',
    authors: ['Wang, L.', 'Feldser, D. M.', 'Tuveson, D. A.', 'Der, C. J.'],
    journal: 'Nature Cancer',
    year: 2023,
    doi: '10.1038/s43018-023-00561-w',
    pmid: '37217590',
    citationCount: 142,
    openAccess: true,
    abstract: 'Direct inhibition of KRAS G12D by small-molecule MRTX1133 leads to marked tumor regression in preclinical models of pancreatic ductal adenocarcinoma (PDAC). However, sustained tumor control is frequently compromised by rapid adaptive signaling reactivation. Here, we demonstrate that MRTX1133 treatment relieves ERK-dependent negative feedback loops, triggering the rapid transactivation of multiple receptor tyrosine kinases (RTKs), predominantly EGFR and HER2. Phosphoproteomic profiling reveals that co-inhibition of the protein tyrosine phosphatase SHP2 or the guanine nucleotide exchange factor SOS1 attenuates RTK-driven GTP-reloading onto mutant and wild-type KRAS. Combination therapy of MRTX1133 with the SOS1 inhibitor BI-3406 induces durable complete responses without intolerable systemic toxicity in immunocompetent orthotopic mouse models.',
    researchQuestion: 'What adaptive signaling pathways drive resistance to direct KRAS G12D inhibition, and can targeting upstream regulatory nodes prevent tumor relapse?',
    methodology: 'Comprehensive phosphoproteomics (TMT 10-plex LC-MS/MS), patient-derived organoid viability assays, and orthotopic KPC (KrasLSL-G12D/+; Trp53LSL-R172H/+; Pdx1-Cre) murine models receiving vehicle, MRTX1133 monotherapy, or dual MRTX1133 + BI-3406.',
    mainFindings: [
      'MRTX1133 monotherapy leads to rapid (within 24-48h) rebound of phosphorylated ERK1/2 in 7 out of 9 PDAC lines.',
      'Phosphoproteomics confirmed that loss of ERK negative feedback leads to transcriptional up-regulation of EGFR and HER3 ligands (EGF and NRG1).',
      'Dual inhibition with SOS1 inhibitor BI-3406 prevented GTP-KRAS reconstitution and delayed acquired resistance emergence by >110 days in vivo.'
    ],
    limitations: [
      'Murine orthotopic models may not fully recapitulate the dense human desmoplastic stroma and hypoperfusion barriers.',
      'Study evaluated only codon 12D mutant lines; translatability to G12V or G12R alleles remains uncharacterized.'
    ],
    potentialBias: [
      'In vitro dosing (100 nM) may exceed physiologically achievable intratumoral concentrations in human clinical trials.',
      'Primary organoid lines were derived from pre-treated patient cohorts, potentially pre-selecting for survival phenotypes.'
    ],
    furtherQuestions: [
      'Does co-treatment with MEK inhibitors produce equivalent durability without excessive gastrointestinal dose-limiting toxicity?',
      'Can non-invasive ctDNA monitoring identify the emergence of secondary KRAS switch-II mutations before radiological progression?'
    ],
    extractedStatements: [
      {
        category: 'objective',
        quote: 'Here, we demonstrate that MRTX1133 treatment relieves ERK-dependent negative feedback loops, triggering the rapid transactivation of multiple receptor tyrosine kinases.',
        location: 'Abstract, lines 4-7'
      },
      {
        category: 'method',
        quote: 'Comprehensive phosphoproteomic profiling was conducted across KPC-derived organoid cultures exposed to 100 nM MRTX1133 for 6, 24, and 72 hours.',
        location: 'Methods § 2.1, p. 3'
      },
      {
        category: 'finding',
        quote: 'Dual combination of MRTX1133 with BI-3406 induced complete pathological regression in 80% (8/10) of orthotopic tumor-bearing mice at day 60.',
        location: 'Results § 3.4, p. 9'
      },
      {
        category: 'limitation',
        quote: 'Long-term pharmacokinetic assessments revealed mild hepatic transaminase elevations that resolved upon intermittent dosing schedules.',
        location: 'Discussion § 4.2, p. 14'
      }
    ]
  },
  {
    id: 'paper-alashouri-2021',
    title: 'Monolithic Perovskite/Silicon Tandem Solar Cells with 29.15% Efficiency via Interfacial Passivation',
    authors: ['Al-Ashouri, A.', 'Köhn, A.', 'Borghardt, S.', 'Albrecht, S.'],
    journal: 'Science',
    year: 2021,
    doi: '10.1126/science.abd4016',
    pmid: '33303611',
    citationCount: 489,
    openAccess: true,
    abstract: 'Monolithic tandem solar cells combining metal halide perovskites and silicon heterojunction cells offer an attractive path to exceed the single-junction thermodynamic limit. However, open-circuit voltage deficits in wide-bandgap (1.68 eV) top subcells, primarily caused by non-radiative recombination at the perovskite/hole-transport interface, restrict operational performance. Here, we demonstrate self-assembled carbazole-based monolayers (2PACz) that establish a highly conformal, defect-passivated interface. Tandem devices deliver a certified power conversion efficiency of 29.15% with an open-circuit voltage of 1.886 V. Operational stability testing under continuous 1-sun equivalent illumination at 65°C maintained 95% of peak efficiency over 1,000 hours under standard ISOS-L-1 protocols.',
    researchQuestion: 'How can molecular passivation at the hole-transport layer interface eliminate non-radiative recombination losses in wide-bandgap perovskite/silicon tandems?',
    methodology: 'Fabrication of textured silicon bottom cells paired with wide-bandgap Cs0.05(MA0.17FA0.83)0.95Pb(I0.83Br0.17)3 top cells passivated with self-assembled monolayer 2PACz. Evaluated via photoluminescence quantum yield (PLQY), transient absorption spectroscopy, and ISOS-L-1 continuous MPP tracking.',
    mainFindings: [
      'Self-assembled 2PACz monolayers minimized contact recombination velocity down to 2.4 cm/s at the selective interface.',
      'Certified tandem power conversion efficiency achieved 29.15%, setting a benchmark for monolithic two-terminal tandems.',
      'Demonstrated 1,000-hour operational stability retaining 95% initial performance without detectable halide segregation peaks.'
    ],
    limitations: [
      'Small active aperture area (0.16 cm²) requires validation on full-scale industrial textured M10 silicon wafers (182 mm × 182 mm).',
      'Long-term moisture ingress and thermal cycling beyond 85°C (ISOS-D-3) was not evaluated in this study.'
    ],
    potentialBias: [
      'Test cells utilized gold back contacts that prevent metal diffusion artifacts common in industrial silver-based metallization.',
      'Continuous illumination spectra simulated AM1.5G with LED arrays lacking deep UV components that accelerate degradation.'
    ],
    furtherQuestions: [
      'Can slot-die or vacuum blade-coating deposit 2PACz monolayers with equivalent nanometer conformity across textured pyramids?',
      'How do ambient humidity spikes during encapsulation breach affect the organic cation lattice?'
    ],
    extractedStatements: [
      {
        category: 'objective',
        quote: 'Here, we demonstrate self-assembled carbazole-based monolayers that establish a highly conformal, defect-passivated interface.',
        location: 'Abstract, lines 6-8'
      },
      {
        category: 'method',
        quote: 'ISOS-L-1 testing was executed at maximum power point under simulated 1-sun illumination in a nitrogen dry box at 65 ± 2°C.',
        location: 'Methods § Device Aging, p. 5'
      },
      {
        category: 'finding',
        quote: 'The tandem achieved a certified PCE of 29.15% with Voc = 1.886 V, Jsc = 19.4 mA/cm2, and FF = 79.6%.',
        location: 'Results § 2.2, p. 4'
      },
      {
        category: 'limitation',
        quote: 'Upscaling onto commercial 6-inch textured wafers will require modifications to the solution-processed SAM dipping protocol.',
        location: 'Discussion § 4.1, p. 8'
      }
    ]
  },
  {
    id: 'paper-hong-2020',
    title: 'Complement-Mediated Microglial Pruning of Hippocampal Synapses in Early Neurodegeneration',
    authors: ['Hong, S.', 'Beja-Glasser, V. F.', 'Nfonoyim, B. M.', 'Stevens, B.'],
    journal: 'Science',
    year: 2020,
    doi: '10.1126/science.aad8373',
    pmid: '32054772',
    citationCount: 375,
    openAccess: true,
    abstract: 'Synapse loss occurs early in neurodegenerative tauopathies and correlates more strongly with cognitive decline than histopathological tangle burden. The mechanisms initiating early synaptic vulnerability remain unresolved. In transgenic mouse models of tauopathy (PS19), we identify early deposition of classical complement proteins C1q and C3 at CA1 hippocampal dendritic spines prior to synaptic loss or overt neurofibrillary tangle formation. Phagocytic microglia engulf complement-tagged synapses via complement receptor 3 (CR3). Genetic deletion or pharmacological neutralization of C1q protects synapses against loss, rescues long-term potentiation (LTP), and mitigates cognitive impairment in fear-conditioning tests.',
    researchQuestion: 'Does the classical complement cascade trigger premature microglial engulfment of structurally intact synapses in early tauopathy?',
    methodology: 'High-resolution confocal and super-resolution STED microscopy of synaptosomes in PS19 tau transgenic mice; flow cytometric engulfment assays; electrophysiological field EPSP recordings in hippocampal slices; in vivo C1q-neutralizing antibody administration.',
    mainFindings: [
      'C1q specifically associates with pre- and post-synaptic compartments in the hippocampus at 2-3 months of age, months before overt neuronal loss.',
      'Microglia selectively engulf C1q/C3-positive synaptic elements within CD68-positive phagolysosomes.',
      'C1q neutralization via monoclonal antibody ANX005 preserves dendritic spine density and restores CA3-CA1 LTP amplitude.'
    ],
    limitations: [
      'Overexpression of human P301S tau under the PrP promoter may exaggerate non-physiological kinetics compared to sporadic human Alzheimer disease.',
      'Complement activation in rodents lacks human-specific regulators like CD55/CD59 isoform distribution.'
    ],
    potentialBias: [
      'Slice electrophysiology was conducted acutely ex vivo, which may alter microglial motility and surveillance states.',
      'Synaptosome isolation protocols risk shearing fragile spine necks and inducing non-specific complement protein deposition.'
    ],
    furtherQuestions: [
      'What upstream signal induces exposed phosphatidylserine or desialylation on the dendritic spine membrane to recruit C1q?',
      'Does chronic complement inhibition impair normal developmental or adult homeostatic synaptic remodeling in cortical circuits?'
    ],
    extractedStatements: [
      {
        category: 'objective',
        quote: 'In transgenic mouse models of tauopathy (PS19), we identify early deposition of classical complement proteins C1q and C3 at CA1 hippocampal dendritic spines.',
        location: 'Abstract, lines 4-7'
      },
      {
        category: 'method',
        quote: 'Microglial engulfment was quantified by measuring internalized synapsin-1 and PSD-95 puncta within 3D-reconstructed CD68+ lysosomes.',
        location: 'Methods § Imaging, p. 4'
      },
      {
        category: 'finding',
        quote: 'Administration of anti-C1q rescued field EPSP slope from 42% of baseline in untreated PS19 to 89% of wild-type levels (p < 0.001).',
        location: 'Results § 3.2, p. 7'
      },
      {
        category: 'limitation',
        quote: 'The study did not address potential long-term risks of systemic C1q blockade on bacterial immune surveillance.',
        location: 'Discussion § 4.3, p. 11'
      }
    ]
  }
];

export const sampleHypotheses: Hypothesis[] = [
  {
    id: 'hypo-kras-01',
    projectId: 'proj-kras-01',
    title: 'SOS1 Allosteric Blockade Synergizes with MRTX1133 to Prevent ERK Rebound',
    statement: 'Concurrent pharmacological inhibition of the catalytic domain of SOS1 with BI-3406 suppresses nucleotide exchange, thereby blocking RTK feedback-mediated GTP-loading of KRAS G12D and preventing ERK1/2 phosphorylation rebound in PDAC.',
    rationale: 'Direct switch-II KRAS G12D inhibitors like MRTX1133 trap the protein in an inactive GDP-bound conformation. However, rapid relief of negative feedback activates EGFR/HER2, which recruits SOS1 to reload GTP. Blocking SOS1 halts nucleotide exchange upstream of both mutant and wild-type alleles.',
    supportingEvidence: [
      {
        id: 'ev-1',
        sourceTitle: 'Overcoming Adaptive Feedback Reactivation in KRAS G12D-Mutant Pancreatic Adenocarcinoma',
        sourceCitation: 'Wang et al., Nature Cancer 2023, 4:561-574',
        evidenceText: 'Dual inhibition with SOS1 inhibitor BI-3406 delayed resistance emergence in vivo by >110 days and prevented GTP-reconstitution.',
        evidenceType: 'in_vivo',
        doi: '10.1038/s43018-023-00561-w'
      },
      {
        id: 'ev-2',
        sourceTitle: 'Targeting the SOS1:KRAS Interaction Prevents Receptor Tyrosine Kinase-Driven Resistance',
        sourceCitation: 'Hofmann et al., Cancer Discovery 2021, 11(1):142-157',
        evidenceText: 'BI-3406 binds the catalytic pocket of SOS1 with KD = 28 nM, effectively blocking SOS1-mediated nucleotide exchange across various KRAS mutations.',
        evidenceType: 'in_vitro',
        doi: '10.1158/2159-8290.CD-20-0142'
      }
    ],
    contradictingEvidence: [
      {
        id: 'ev-3',
        sourceTitle: 'SOS2 Compensates for SOS1 Ablation in Sustaining Basal MAPK Signaling in Solid Tumors',
        sourceCitation: 'Sheffels et al., Science Signaling 2022, 15(724):eabg4532',
        evidenceText: 'High SOS2 expression partially compensates for SOS1 catalytic inhibition in a subset of mesenchymal PDAC cell lines, permitting moderate residual ERK phosphorylation.',
        evidenceType: 'in_vitro',
        doi: '10.1126/scisignal.abg4532'
      }
    ],
    assumptions: [
      'SOS1 catalytic inhibition does not induce catastrophic homeostatic toxicity in normal intestinal epithelial cells.',
      'MRTX1133 maintains adequate intratumoral concentration within hypovascular stroma.'
    ],
    unknowns: [
      'Whether secondary point mutations in the SOS1 catalytic pocket (e.g., F895A) emerge under continuous co-selection pressure.',
      'Optimal dosing schedule (continuous vs pulsed) to maximize apoptotic index while sparing bone marrow progenitor cells.'
    ],
    suggestedTests: [
      'Surface plasmon resonance (SPR) competition assay measuring GDP/GTP exchange rates in recombinant KRAS G12D under titrated BI-3406 concentrations.',
      'Western blot time-course of p-ERK1/2 and p-AKT over 0, 6, 24, 48, 72 hours in KPC organoid lines treated with vehicle, MRTX1133 alone, or combination.',
      'In vivo xenograft survival assay comparing combination versus single-agent arms in immunocompetent mice.'
    ],
    confidenceScore: 0.84,
    confidenceBasis: 'High confidence based on two independent peer-reviewed in vivo trials demonstrating synergistic tumor shrinkage and clear biochemical mechanism; slightly tempered by in vitro reports of SOS2 redundancy.',
    status: 'testing',
    createdAt: '2026-09-04',
    updatedAt: '2026-10-08'
  },
  {
    id: 'hypo-kras-02',
    projectId: 'proj-kras-01',
    title: 'SHP2 Inhibition Abrogates Upstream Receptor Tyrosine Kinase Signal Transduction',
    statement: 'Allosteric inhibition of SHP2 (PTPN11) with RMC-4550 blocks adaptor protein Grb2 scaffolding at activated RTKs, disconnecting upstream growth factor cues from RAS GTPase activation more completely than SOS1-selective inhibition.',
    rationale: 'Because multiple RTKs (EGFR, MET, FGFR) feed into SHP2 upstream of SOS1 and SOS2, targeting the central phosphatase node may prevent redundant exchange factor compensation.',
    supportingEvidence: [
      {
        id: 'ev-4',
        sourceTitle: 'Allosteric Inhibition of SHP2 Suppresses Growth of RTK-Driven and KRAS-Mutant Human Tumors',
        sourceCitation: 'Chen et al., Nature 2018, 535:148-152',
        evidenceText: 'RMC-4550 allosterically stabilizes SHP2 in its auto-inhibited closed conformation, suppressing p-ERK in RTK-activated lines.',
        evidenceType: 'in_vitro',
        doi: '10.1038/s41586-018-0242-7'
      }
    ],
    contradictingEvidence: [
      {
        id: 'ev-5',
        sourceTitle: 'Clinical Dose-Limiting Thrombocytopenia with First-Generation SHP2 Inhibitors',
        sourceCitation: 'Clinical Trial Cohort Report, J Clin Oncol 2024, 42(15):3001',
        evidenceText: 'Grade 3/4 thrombocytopenia and edema were observed in 28% of human trial participants at therapeutic exposure levels.',
        evidenceType: 'clinical',
        doi: '10.1200/JCO.2024.42.15'
      }
    ],
    assumptions: [
      'SHP2 phosphatase activity is strictly required for Grb2 recruitment across all relevant PDAC RTKs.',
      'Dosing windows exist that preserve platelet survival.'
    ],
    unknowns: [
      'Comparative therapeutic index versus SOS1 inhibitors in human cohorts.',
      'Impact of stromal fibroblast SHP2 inhibition on the pancreatic tumor microenvironment.'
    ],
    suggestedTests: [
      'Co-immunoprecipitation of Grb2 and SOS1/2 in PDAC cell lysates under RMC-4550 challenge.',
      'Comparison of apoptotic markers (cleaved caspase-3, Annexin V) between SHP2 + MRTX1133 versus SOS1 + MRTX1133.',
      'Evaluation of megakaryocyte differentiation markers in bone marrow aspirates under inhibitor exposure.'
    ],
    confidenceScore: 0.68,
    confidenceBasis: 'Strong biological mechanism supported by multiple foundational papers, but lower clinical translatability score due to documented hematopoietic dose-limiting toxicities in phase 1 data.',
    status: 'formulated',
    createdAt: '2026-09-12',
    updatedAt: '2026-10-02'
  }
];

export const sampleExperiments: ExperimentPlan[] = [
  {
    id: 'exp-kras-dual-01',
    projectId: 'proj-kras-01',
    hypothesisId: 'hypo-kras-01',
    title: 'Dual MRTX1133 and BI-3406 Synergy & Phospho-Rebound Kinetics in PDAC Organoids',
    researchObjective: 'Determine the quantitative combination index (CI) and kinetics of p-ERK1/2 suppression in patient-derived PDAC organoids co-treated with MRTX1133 and SOS1 inhibitor BI-3406 over 72 hours.',
    independentVariables: [
      { name: 'MRTX1133 Concentration', range: '0, 10, 30, 100, 300, 1000', unit: 'nM' },
      { name: 'BI-3406 Concentration', range: '0, 50, 150, 500, 1500', unit: 'nM' },
      { name: 'Incubation Duration', range: '6, 24, 48, 72', unit: 'hours' }
    ],
    dependentVariables: [
      { name: 'Cell Viability (CellTiter-Glo 3D)', measurementMethod: 'Luminescent ATP quantification at 72h', expectedBaseline: '100% vehicle luminescence' },
      { name: 'p-ERK1/2 (Thr202/Tyr204) / Total ERK Ratio', measurementMethod: 'Capillary automated Western blot (Wes)', expectedBaseline: '1.0 normalized ratio' },
      { name: 'Apoptotic Index (Cleaved Caspase-3)', measurementMethod: 'High-content confocal immunofluorescence', expectedBaseline: '<3% positive nuclei' }
    ],
    controlledVariables: [
      'Cell passage number (strictly passage 4-8 across all replicate batches)',
      'Basal Matrigel dome density (2,500 organoids / 20 μL dome in 96-well format)',
      'Organoid growth media (Wnt3a, R-spondin-1, Noggin, EGF held at constant formulation)',
      'Vehicle DMSO concentration fixed at 0.1% (v/v) across all wells'
    ],
    equipmentAndResources: [
      'EnVision Multilabel Plate Reader (Luminescence)',
      'ProteinSimple Wes Capillary Immunoassay System',
      'Leica SP8 Confocal Microscope with high-throughput stage',
      'Patient-derived organoid line hPDAC-04 (confirmed KRAS G12D homozygous)'
    ],
    procedureSteps: [
      'Day 0: Seed hPDAC-04 organoids in 20 μL Growth Factor Reduced Matrigel domes at 2,500 organoids/well in 96-well black-walled clear-bottom plates.',
      'Day 1: Prepare drug dilutions in complete organoid medium using automated acoustic liquid dispenser (Echo 550) to minimize pipetting variance.',
      'Day 1: Apply 6×5 drug concentration matrix in biological triplicates (n = 3 per condition). Add DMSO (0.1%) control and Staurosporine (1 μM) positive kill controls.',
      'Day 2 (24h) & Day 3 (48h): Harvest dedicated replicate plates for Wes capillary lysate preparation; lyse in RIPA buffer supplemented with protease and phosphatase inhibitor cocktails.',
      'Day 4 (72h): Add CellTiter-Glo 3D reagent (100 μL/well), shake for 30 minutes at room temperature, and read luminescent signal on EnVision plate reader.',
      'Perform automated image acquisition for caspase-3 cleaved puncta on Leica SP8 confocal system.'
    ],
    measurementMethod: 'Luminescent ATP viability quantification (CellTiter-Glo 3D) and automated capillary electrophoresis immunoassay (Wes).',
    expectedOutcomes: 'Monotherapy MRTX1133 is expected to yield initial p-ERK suppression at 6h followed by 48h rebound to >60% baseline. Combination with BI-3406 (>150 nM) is expected to maintain p-ERK <15% of baseline at 72h and produce Chou-Talalay combination index CI < 0.65 across ED50, ED75, and ED90.',
    alternativeExplanations: [
      'Persistent viability suppression could stem from off-target toxicity rather than KRAS pathway shutdown if DMSO or vehicle crystallization occurs.',
      'Organoids harboring high intrinsic SOS2 levels may demonstrate muted synergy, requiring post-hoc stratification by baseline SOS2/SOS1 expression ratio.'
    ],
    evaluationCriteria: {
      statisticalTest: 'Two-way ANOVA with Tukey post-hoc multiple comparisons test; Chou-Talalay Median-Effect Equation for Combination Index (CI)',
      significanceThreshold: 'p < 0.01; CI < 0.70 designated as synergistic',
      replicationCount: 3,
      successMetric: '>80% sustained p-ERK inhibition at 72h and CI < 0.65 across 3 independent replicate runs'
    },
    warnings: [],
    status: 'ready',
    createdAt: '2026-09-28'
  }
];

export const sampleKnowledgeGraph: { nodes: GraphNode[]; edges: GraphEdge[] } = {
  nodes: [
    {
      id: 'kras-g12d',
      label: 'KRAS G12D',
      category: 'Target',
      description: 'Oncogenic driver GTPase harboring glycine-to-aspartate missense mutation at codon 12, common in pancreatic ductal adenocarcinoma and colorectal cancer.',
      evidenceExcerpt: 'Point mutation impairs intrinsic GTPase-activating protein (GAP)-mediated GTP hydrolysis, maintaining active downstream effector signaling.',
      supportingCitation: 'Der et al., Cell 1982 / Wang et al., Nature Cancer 2023',
      degree: 5,
      x: 320,
      y: 260
    },
    {
      id: 'mrtx1133',
      label: 'MRTX1133',
      category: 'Compound',
      description: 'First-in-class selective non-covalent small molecule inhibitor targeting the switch-II pocket of KRAS G12D in both active and inactive states.',
      evidenceExcerpt: 'Binds with sub-nanomolar affinity (KD ~ 0.2 nM) to KRAS G12D, disrupting RAF kinase effector interaction and suppressing cell proliferation.',
      supportingCitation: 'Wang et al., J. Med. Chem. 2022',
      degree: 3,
      x: 180,
      y: 200
    },
    {
      id: 'mapk-pathway',
      label: 'MAPK / ERK Cascade',
      category: 'Pathway',
      description: 'Canonical signaling cascade consisting of RAF, MEK1/2, and ERK1/2 governing transcriptional proliferation and cellular survival programs.',
      evidenceExcerpt: 'Phosphorylated ERK1/2 translocates to the nucleus and phosphorylates transcription factors including ELK1, c-FOS, and c-MYC.',
      supportingCitation: 'Wellbrock et al., Nat Rev Mol Cell Biol 2004',
      degree: 4,
      x: 480,
      y: 240
    },
    {
      id: 'rtk-feedback',
      label: 'RTK Feedback Loop',
      category: 'Mechanism',
      description: 'Adaptive regulatory rebound mechanism wherein loss of phosphorylated ERK-dependent negative feedback promotes EGFR and HER2 dimerization.',
      evidenceExcerpt: 'ERK inactivation relieves inhibitory phosphorylation on SOS1 and Sprouty proteins, driving RTK transactivation within 24-48 hours.',
      supportingCitation: 'Lito et al., Science 2016',
      degree: 4,
      x: 430,
      y: 120
    },
    {
      id: 'sos1',
      label: 'SOS1 GEF',
      category: 'Target',
      description: 'Son of Sevenless 1, a guanine nucleotide exchange factor (GEF) that catalyzes the release of GDP to allow GTP binding on RAS GTPases.',
      evidenceExcerpt: 'Recruited to receptor tyrosine kinase complexes via Grb2 adaptors to stimulate nucleotide exchange on both wild-type and mutant KRAS.',
      supportingCitation: 'Hofmann et al., Cancer Discovery 2021',
      degree: 4,
      x: 280,
      y: 100
    },
    {
      id: 'bi-3406',
      label: 'BI-3406',
      category: 'Compound',
      description: 'Potent and selective small molecule allosteric inhibitor of the catalytic domain of SOS1.',
      evidenceExcerpt: 'Selectively binds the SOS1 catalytic pocket, preventing SOS1-KRAS protein-protein interaction without blocking SOS2.',
      supportingCitation: 'Hofmann et al., Cancer Discovery 2021',
      degree: 2,
      x: 130,
      y: 70
    },
    {
      id: 'shp2-ptpn11',
      label: 'SHP2 (PTPN11)',
      category: 'Target',
      description: 'Protein tyrosine phosphatase that acts upstream as an essential signal transducer linking activated RTKs to SOS1 recruitment.',
      evidenceExcerpt: 'Dephosphorylates negative regulatory binding sites on RTKs and scaffold proteins, indispensable for full RAS activation.',
      supportingCitation: 'Chen et al., Nature 2018',
      degree: 3,
      x: 580,
      y: 110
    },
    {
      id: 'apoptotic-arrest',
      label: 'Apoptotic Arrest',
      category: 'Phenotype',
      description: 'Programmed cell death induced by sustained loss of oncogenic survival signaling and cleavage of executioner caspases.',
      evidenceExcerpt: 'Induction of BIM and downregulation of MCL-1 triggers mitochondrial outer membrane permeabilization.',
      supportingCitation: 'Cragg et al., Nat Rev Cancer 2009',
      degree: 3,
      x: 580,
      y: 360
    },
    {
      id: 'perovskite-tandem',
      label: 'Cs/MA/FA Perovskite',
      category: 'Target',
      description: 'Wide-bandgap (1.68 eV) triple-cation metal halide perovskite absorber utilized in high-efficiency tandem solar architectures.',
      evidenceExcerpt: 'Demonstrates optical absorption coefficient >10^5 cm^-1 but exhibits susceptibility to halide phase segregation under illumination.',
      supportingCitation: 'Al-Ashouri et al., Science 2021',
      degree: 3,
      x: 740,
      y: 160
    },
    {
      id: 'halide-demixing',
      label: 'Halide Demixing',
      category: 'Mechanism',
      description: 'Photo-induced phase segregation of mixed iodide-bromide perovskites into low-bandgap iodide-rich domains and high-bandgap bromide-rich phases.',
      evidenceExcerpt: 'Hoke effect lowers device open-circuit voltage by trapping photo-generated charge carriers in iodide-rich carrier traps.',
      supportingCitation: 'Hoke et al., Chem Sci 2015',
      degree: 3,
      x: 880,
      y: 220
    },
    {
      id: '2pacz-passivator',
      label: '2PACz Monolayer',
      category: 'Compound',
      description: 'Self-assembled hole-selective carbazole phosphonic acid monolayer that passivates interface defects and establishes favorable band alignment.',
      evidenceExcerpt: 'Minimizes non-radiative surface recombination velocity to <3 cm/s and suppresses iodide ion migration channels.',
      supportingCitation: 'Al-Ashouri et al., Science 2021',
      degree: 2,
      x: 750,
      y: 310
    },
    {
      id: 'complement-c1q',
      label: 'Complement C1q',
      category: 'Biomarker',
      description: 'Initiating recognition molecule of the classical complement pathway that opsonizes vulnerable synaptic compartments in neurodegeneration.',
      evidenceExcerpt: 'Deposited onto hippocampal dendritic spines in tauopathy models, marking them for phagocytic clearance.',
      supportingCitation: 'Hong et al., Science 2020',
      degree: 3,
      x: 200,
      y: 380
    },
    {
      id: 'microglia-cr3',
      label: 'Microglial CR3',
      category: 'Target',
      description: 'Complement Receptor 3 (CD11b/CD18 heterodimer) expressed on resident microglia that binds cleaved complement C3 fragments.',
      evidenceExcerpt: 'Mediates actin-dependent phagocytic engulfment of tagged dendritic spine elements into CD68-positive lysosomes.',
      supportingCitation: 'Stevens et al., Cell 2007',
      degree: 2,
      x: 350,
      y: 430
    },
    {
      id: 'synaptic-elimination',
      label: 'Spine Elimination',
      category: 'Phenotype',
      description: 'Loss of functional post-synaptic dendritic spines in hippocampal CA1 circuits causing long-term potentiation deficits.',
      evidenceExcerpt: 'Correlates with spatial memory decline in behavioral Barnes maze and fear-conditioning trials.',
      supportingCitation: 'Hong et al., Science 2020',
      degree: 3,
      x: 480,
      y: 460
    }
  ],
  edges: [
    {
      id: 'e-1',
      source: 'mrtx1133',
      target: 'kras-g12d',
      relationship: 'Allosterically inhibits',
      mechanism: 'Occupies the switch-II pocket, preventing RAF interaction and downstream effector phosphorylation.',
      evidenceBasis: 'KD = 0.2 nM via surface plasmon resonance (J Med Chem 2022)'
    },
    {
      id: 'e-2',
      source: 'kras-g12d',
      target: 'mapk-pathway',
      relationship: 'Activates downstream',
      mechanism: 'GTP-bound state recruits RAF1/BRAF to the plasma membrane to initiate MEK phosphorylation.',
      evidenceBasis: 'Elevated baseline p-ERK1/2 in all KPC models (Nature Cancer 2023)'
    },
    {
      id: 'e-3',
      source: 'mapk-pathway',
      target: 'rtk-feedback',
      relationship: 'Exerts negative feedback on',
      mechanism: 'Active ERK phosphorylates upstream SOS1 and RTKs to limit prolonged receptor activation.',
      evidenceBasis: 'Phosphoproteomic analysis reveals loss of 4 inhibitory phosphosites upon ERK shutdown.'
    },
    {
      id: 'e-4',
      source: 'rtk-feedback',
      target: 'sos1',
      relationship: 'Recruits and triggers',
      mechanism: 'EGFR/HER2 phosphorylation creates Grb2-SH2 docking sites that localize SOS1 to the membrane.',
      evidenceBasis: 'Co-immunoprecipitation in Wang et al. 2023'
    },
    {
      id: 'e-5',
      source: 'sos1',
      target: 'kras-g12d',
      relationship: 'Catalyzes GTP-reloading onto',
      mechanism: 'Facilitates GDP dissociation, permitting GTP binding to overcome MRTX1133 inactive trap.',
      evidenceBasis: 'In vitro nucleotide exchange assay (Cancer Discov 2021)'
    },
    {
      id: 'e-6',
      source: 'bi-3406',
      target: 'sos1',
      relationship: 'Inhibits catalytic pocket of',
      mechanism: 'Blocks SOS1-RAS interaction, halting nucleotide exchange in both wild-type and mutant alleles.',
      evidenceBasis: 'IC50 = 14 nM (Hofmann et al. 2021)'
    },
    {
      id: 'e-7',
      source: 'shp2-ptpn11',
      target: 'sos1',
      relationship: 'Dephosphorylates to activate',
      mechanism: 'Removes inhibitory tyrosine phosphorylation on SOS1 adaptor docking sites.',
      evidenceBasis: 'Phosphatase assay in Chen et al. 2018'
    },
    {
      id: 'e-8',
      source: 'rtk-feedback',
      target: 'shp2-ptpn11',
      relationship: 'Phosphorylates and engages',
      mechanism: 'Activated RTK cytosolic tails bind SHP2 N-SH2 domain, releasing basal auto-inhibition.',
      evidenceBasis: 'Crystal structure (Nature 2018)'
    },
    {
      id: 'e-9',
      source: 'mapk-pathway',
      target: 'apoptotic-arrest',
      relationship: 'Suppresses execution of',
      mechanism: 'Phosphorylates pro-apoptotic BIM (targeting it for proteasomal degradation) and stabilizes MCL-1.',
      evidenceBasis: 'Western blot in Der et al. 2023'
    },
    {
      id: 'e-10',
      source: 'perovskite-tandem',
      target: 'halide-demixing',
      relationship: 'Undergoes illumination-induced',
      mechanism: 'Photoexcited polaron strain drives iodide and bromide anion migration along grain boundaries.',
      evidenceBasis: 'In situ photoluminescence peak splitting under 100 mW/cm2'
    },
    {
      id: 'e-11',
      source: '2pacz-passivator',
      target: 'perovskite-tandem',
      relationship: 'Passivates interfacial defects in',
      mechanism: 'Phosphonic acid head groups anchor to surface Pb2+ unsaturated coordination sites.',
      evidenceBasis: 'XPS and steady-state PL (Science 2021)'
    },
    {
      id: 'e-12',
      source: '2pacz-passivator',
      target: 'halide-demixing',
      relationship: 'Suppresses ion migration in',
      mechanism: 'Increases defect activation energy barrier from 0.28 eV to 0.71 eV.',
      evidenceBasis: 'Temperature-dependent impedance spectroscopy'
    },
    {
      id: 'e-13',
      source: 'complement-c1q',
      target: 'microglia-cr3',
      relationship: 'Signals through cleavage to',
      mechanism: 'C1q activates C3 convertase, generating iC3b which binds microglial CR3 receptor.',
      evidenceBasis: 'Immunofluorescence colocalization (Science 2020)'
    },
    {
      id: 'e-14',
      source: 'microglia-cr3',
      target: 'synaptic-elimination',
      relationship: 'Directly executes phagocytic',
      mechanism: 'Engulfs dendritic spine heads into CD68-positive microglial phagolysosomes.',
      evidenceBasis: '3D STED volume rendering (Hong et al. 2020)'
    },
    {
      id: 'e-15',
      source: 'complement-c1q',
      target: 'synaptic-elimination',
      relationship: 'Tags for elimination',
      mechanism: 'Binds phosphatidylserine exposure on vulnerable dendritic membranes.',
      evidenceBasis: 'Synaptosome flow cytometry'
    }
  ]
};

export const sampleResearchQuestions = [
  'How do PDAC cells rewire RTK signaling within 48 hours of KRAS G12D inhibition?',
  'Can 2D halide perovskite passivators prevent ion migration beyond 1,000 hours?',
  'Does complement C1q tagging precede dendritic spine loss in early tauopathy?',
  'What molecular chaperones prevent misfolded SOD1 aggregation in motor neurons?',
  'How does spatial hypoxia reshape the metabolic gradient in glioblastoma cores?'
];
