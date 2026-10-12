import { useState, useRef, useEffect, useMemo, useCallback } from 'react';
import { sampleKnowledgeGraph } from '../../data/mockData';
import { GraphNode, GraphEdge, ConceptCategory } from '../../types/research';
import { useLanguage } from '../../context/LanguageContext';
import { 
  Search, ZoomIn, ZoomOut, RotateCcw, 
  ExternalLink, ArrowRight, BookOpen, 
  SlidersHorizontal, Sparkles, X, Check
} from 'lucide-react';

interface InteractiveKnowledgeGraphProps {
  onSelectConceptForHypothesis?: (node: GraphNode) => void;
  initialSelectedNodeId?: string | null;
  compactMode?: boolean;
}

const CATEGORY_COLORS: Record<ConceptCategory, { fill: string; stroke: string; text: string; bg: string }> = {
  Target: { fill: '#0284c7', stroke: '#0369a1', text: 'text-sky-700 dark:text-sky-400', bg: 'bg-sky-50 dark:bg-sky-950/40' },
  Pathway: { fill: '#0d9488', stroke: '#0f766e', text: 'text-teal-700 dark:text-teal-400', bg: 'bg-teal-50 dark:bg-teal-950/40' },
  Compound: { fill: '#6366f1', stroke: '#4f46e5', text: 'text-indigo-700 dark:text-indigo-400', bg: 'bg-indigo-50 dark:bg-indigo-950/40' },
  Phenotype: { fill: '#e11d48', stroke: '#be123c', text: 'text-rose-700 dark:text-rose-400', bg: 'bg-rose-50 dark:bg-rose-950/40' },
  Mechanism: { fill: '#d97706', stroke: '#b45309', text: 'text-amber-700 dark:text-amber-400', bg: 'bg-amber-50 dark:bg-amber-950/40' },
  Biomarker: { fill: '#8b5cf6', stroke: '#7c3aed', text: 'text-purple-700 dark:text-purple-400', bg: 'bg-purple-50 dark:bg-purple-950/40' }
};

export function InteractiveKnowledgeGraph({
  onSelectConceptForHypothesis,
  initialSelectedNodeId,
  compactMode = false
}: InteractiveKnowledgeGraphProps) {
  const { language, t } = useLanguage();
  const isTh = language === 'th';

  const [nodes, setNodes] = useState<GraphNode[]>(sampleKnowledgeGraph.nodes);
  const [edges] = useState<GraphEdge[]>(sampleKnowledgeGraph.edges);
  
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(initialSelectedNodeId || null);
  const [selectedEdgeId, setSelectedEdgeId] = useState<string | null>(null);
  const [hoveredNodeId, setHoveredNodeId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<ConceptCategory | 'ALL'>('ALL');
  
  // Transform: pan and zoom
  const [transform, setTransform] = useState({ x: 0, y: 0, scale: 1 });
  const [isPanning, setIsPanning] = useState(false);
  const [panStart, setPanStart] = useState({ x: 0, y: 0 });
  const [draggedNodeId, setDraggedNodeId] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const svgRef = useRef<SVGSVGElement>(null);

  useEffect(() => {
    if (initialSelectedNodeId) {
      setSelectedNodeId(initialSelectedNodeId);
      const node = nodes.find(n => n.id === initialSelectedNodeId);
      if (node && node.x && node.y && containerRef.current) {
        const { width, height } = containerRef.current.getBoundingClientRect();
        setTransform({
          x: width / 2 - node.x * 1.2,
          y: height / 2 - node.y * 1.2,
          scale: 1.2
        });
      }
    }
  }, [initialSelectedNodeId, nodes]);

  // Compute connections
  const connectedNodeIds = useMemo(() => {
    if (!selectedNodeId && !hoveredNodeId) return new Set<string>();
    const targetId = hoveredNodeId || selectedNodeId;
    const set = new Set<string>();
    set.add(targetId!);
    edges.forEach((edge) => {
      if (edge.source === targetId) set.add(edge.target);
      if (edge.target === targetId) set.add(edge.source);
    });
    return set;
  }, [selectedNodeId, hoveredNodeId, edges]);

  const selectedNode = useMemo(() => {
    return nodes.find((n) => n.id === selectedNodeId) || null;
  }, [nodes, selectedNodeId]);

  const selectedEdge = useMemo(() => {
    return edges.find((e) => e.id === selectedEdgeId) || null;
  }, [edges, selectedEdgeId]);

  const nodeEdges = useMemo(() => {
    if (!selectedNodeId) return [];
    return edges.filter(
      (e) => e.source === selectedNodeId || e.target === selectedNodeId
    );
  }, [edges, selectedNodeId]);

  // Handle Dragging
  const handleMouseDownNode = (e: React.MouseEvent, nodeId: string) => {
    e.stopPropagation();
    setDraggedNodeId(nodeId);
    setSelectedNodeId(nodeId);
    setSelectedEdgeId(null);
  };

  const handleTouchStartNode = (e: React.TouchEvent, nodeId: string) => {
    e.stopPropagation();
    setDraggedNodeId(nodeId);
    setSelectedNodeId(nodeId);
    setSelectedEdgeId(null);
  };

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (draggedNodeId) {
      const svg = svgRef.current;
      if (!svg) return;
      const rect = svg.getBoundingClientRect();
      const clientX = e.clientX - rect.left;
      const clientY = e.clientY - rect.top;
      
      const graphX = (clientX - transform.x) / transform.scale;
      const graphY = (clientY - transform.y) / transform.scale;

      setNodes((prev) =>
        prev.map((node) =>
          node.id === draggedNodeId
            ? { ...node, x: Math.max(40, Math.min(1000, graphX)), y: Math.max(40, Math.min(700, graphY)) }
            : node
        )
      );
    } else if (isPanning) {
      setTransform((prev) => ({
        ...prev,
        x: e.clientX - panStart.x,
        y: e.clientY - panStart.y
      }));
    }
  }, [draggedNodeId, isPanning, panStart, transform.x, transform.y, transform.scale]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      if (draggedNodeId) {
        const svg = svgRef.current;
        if (!svg) return;
        const rect = svg.getBoundingClientRect();
        const clientX = touch.clientX - rect.left;
        const clientY = touch.clientY - rect.top;
        
        const graphX = (clientX - transform.x) / transform.scale;
        const graphY = (clientY - transform.y) / transform.scale;

        setNodes((prev) =>
          prev.map((node) =>
            node.id === draggedNodeId
              ? { ...node, x: Math.max(40, Math.min(1000, graphX)), y: Math.max(40, Math.min(700, graphY)) }
              : node
          )
        );
      } else if (isPanning) {
        setTransform((prev) => ({
          ...prev,
          x: touch.clientX - panStart.x,
          y: touch.clientY - panStart.y
        }));
      }
    }
  }, [draggedNodeId, isPanning, panStart, transform.x, transform.y, transform.scale]);

  const handleMouseUp = () => {
    setDraggedNodeId(null);
    setIsPanning(false);
  };

  const handleMouseDownCanvas = (e: React.MouseEvent) => {
    if (e.button === 0) {
      setIsPanning(true);
      setPanStart({ x: e.clientX - transform.x, y: e.clientY - transform.y });
      setSelectedEdgeId(null);
    }
  };

  const handleTouchStartCanvas = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      setIsPanning(true);
      setPanStart({ x: touch.clientX - transform.x, y: touch.clientY - transform.y });
    }
  };

  const handleZoom = (direction: 'in' | 'out') => {
    setTransform((prev) => {
      const factor = direction === 'in' ? 1.25 : 0.8;
      const newScale = Math.min(Math.max(prev.scale * factor, 0.4), 2.5);
      return {
        ...prev,
        scale: newScale
      };
    });
  };

  const handleResetView = () => {
    setTransform({ x: 0, y: 0, scale: 1 });
    setSelectedNodeId(null);
    setSelectedEdgeId(null);
    setSearchQuery('');
    setCategoryFilter('ALL');
  };

  // Node position map
  const nodePositionMap = useMemo(() => {
    const map = new Map<string, { x: number; y: number }>();
    nodes.forEach((n) => {
      map.set(n.id, { x: n.x ?? 300, y: n.y ?? 250 });
    });
    return map;
  }, [nodes]);

  // Filtered nodes
  const filteredNodes = useMemo(() => {
    return nodes.filter((node) => {
      const matchesCategory = categoryFilter === 'ALL' || node.category === categoryFilter;
      const matchesSearch = !searchQuery || 
        node.label.toLowerCase().includes(searchQuery.toLowerCase()) ||
        node.description.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [nodes, categoryFilter, searchQuery]);

  return (
    <div className={`relative flex flex-col bg-stone-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs ${compactMode ? 'h-[500px]' : 'h-[680px]'}`}>
      {/* Top Toolbar */}
      <div className="flex flex-wrap items-center justify-between gap-3 p-3 border-b border-slate-200 dark:border-slate-800 bg-white/80 dark:bg-slate-900/80 backdrop-blur-xs z-10">
        <div className="flex items-center gap-2 flex-1 min-w-[220px] max-w-sm">
          <div className="relative w-full">
            <Search className="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={isTh ? "ค้นหาแนวคิด (เช่น KRAS, SOS1, Perovskite)..." : "Filter concepts (e.g., KRAS, SOS1, C1q)..."}
              className="w-full pl-8 pr-3 py-1.5 text-xs bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-md text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-teal-500"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-2 top-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>

        {/* Category Filter Buttons */}
        <div className="flex items-center gap-1 overflow-x-auto py-0.5">
          <button
            onClick={() => setCategoryFilter('ALL')}
            className={`px-2.5 py-1 text-xs font-medium rounded-md whitespace-nowrap transition-colors cursor-pointer ${
              categoryFilter === 'ALL'
                ? 'bg-slate-900 text-white dark:bg-slate-100 dark:text-slate-900'
                : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
            }`}
          >
            {isTh ? 'ทุกโหนด' : 'All Nodes'}
          </button>
          {(['Target', 'Pathway', 'Compound', 'Mechanism', 'Biomarker', 'Phenotype'] as ConceptCategory[]).map((cat) => {
            const thaiCatNames: Record<string, string> = {
              Target: 'เป้าหมาย (Target)',
              Pathway: 'วิถีส่งสัญญาณ (Pathway)',
              Compound: 'สารประกอบ (Compound)',
              Mechanism: 'กลไก (Mechanism)',
              Biomarker: 'ตัวบ่งชี้ชีวภาพ (Biomarker)',
              Phenotype: 'ฟีโนไทป์ (Phenotype)'
            };
            return (
              <button
                key={cat}
                onClick={() => setCategoryFilter(categoryFilter === cat ? 'ALL' : cat)}
                className={`px-2.5 py-1 text-xs font-medium rounded-md whitespace-nowrap transition-colors flex items-center gap-1.5 cursor-pointer ${
                  categoryFilter === cat
                    ? 'bg-slate-900 text-white dark:bg-slate-100 dark:text-slate-900'
                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
                }`}
              >
                <span 
                  className="w-1.5 h-1.5 rounded-full" 
                  style={{ backgroundColor: CATEGORY_COLORS[cat].fill }}
                />
                <span>{isTh ? thaiCatNames[cat] || cat : cat}</span>
              </button>
            );
          })}
        </div>

        {/* Graph Controls */}
        <div className="flex items-center gap-1 ml-auto">
          <button
            onClick={() => handleZoom('in')}
            className="p-1.5 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-800"
            title="Zoom In"
            aria-label="Zoom in"
          >
            <ZoomIn className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => handleZoom('out')}
            className="p-1.5 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-800"
            title="Zoom Out"
            aria-label="Zoom out"
          >
            <ZoomOut className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={handleResetView}
            className="p-1.5 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-800"
            title="Reset View"
            aria-label="Reset view"
          >
            <RotateCcw className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* SVG Canvas Area */}
      <div
        ref={containerRef}
        className="flex-1 w-full h-full relative cursor-grab active:cursor-grabbing overflow-hidden select-none"
        onMouseDown={handleMouseDownCanvas}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onTouchStart={handleTouchStartCanvas}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleMouseUp}
      >
        <svg
          ref={svgRef}
          className="w-full h-full"
          viewBox="0 0 1050 720"
          preserveAspectRatio="xMidYMid meet"
        >
          <defs>
            {/* Arrow markers for directed edges */}
            <marker
              id="arrow-default"
              viewBox="0 0 10 10"
              refX="22"
              refY="5"
              markerWidth="6"
              markerHeight="6"
              orient="auto-start-reverse"
            >
              <path d="M 0 1 L 10 5 L 0 9 z" fill="#94a3b8" />
            </marker>
            <marker
              id="arrow-active"
              viewBox="0 0 10 10"
              refX="22"
              refY="5"
              markerWidth="7"
              markerHeight="7"
              orient="auto-start-reverse"
            >
              <path d="M 0 1 L 10 5 L 0 9 z" fill="#0d9488" />
            </marker>

            {/* Subtle grid pattern */}
            <pattern id="graph-grid" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 40" fill="none" stroke="currentColor" className="text-slate-200/40 dark:text-slate-800/40" strokeWidth="0.5" />
            </pattern>
          </defs>

          {/* Grid background */}
          <rect width="100%" height="100%" fill="url(#graph-grid)" />

          <g transform={`translate(${transform.x}, ${transform.y}) scale(${transform.scale})`}>
            {/* Edges */}
            {edges.map((edge) => {
              const srcPos = nodePositionMap.get(edge.source);
              const tgtPos = nodePositionMap.get(edge.target);
              if (!srcPos || !tgtPos) return null;

              const isHighlighted =
                selectedNodeId === edge.source ||
                selectedNodeId === edge.target ||
                hoveredNodeId === edge.source ||
                hoveredNodeId === edge.target ||
                selectedEdgeId === edge.id;

              const isConnectedToFiltered =
                filteredNodes.some((n) => n.id === edge.source) &&
                filteredNodes.some((n) => n.id === edge.target);

              if (categoryFilter !== 'ALL' && !isConnectedToFiltered) return null;

              // Compute mid point for edge label
              const midX = (srcPos.x + tgtPos.x) / 2;
              const midY = (srcPos.y + tgtPos.y) / 2;

              return (
                <g 
                  key={edge.id}
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedEdgeId(edge.id);
                  }}
                  className="cursor-pointer group"
                >
                  <line
                    x1={srcPos.x}
                    y1={srcPos.y}
                    x2={tgtPos.x}
                    y2={tgtPos.y}
                    stroke={isHighlighted ? '#0d9488' : '#cbd5e1'}
                    strokeWidth={isHighlighted ? 2.5 : 1.25}
                    strokeDasharray={edge.relationship.includes('inhibits') ? '4 3' : undefined}
                    className="transition-colors dark:stroke-slate-700 dark:group-hover:stroke-teal-400 group-hover:stroke-teal-500"
                    markerEnd={isHighlighted ? 'url(#arrow-active)' : 'url(#arrow-default)'}
                  />

                  {/* Relationship label visible when highlighted */}
                  {isHighlighted && (
                    <g transform={`translate(${midX}, ${midY})`}>
                      <rect
                        x="-60"
                        y="-10"
                        width="120"
                        height="20"
                        rx="4"
                        fill="#0f172a"
                        className="opacity-90"
                      />
                      <text
                        textAnchor="middle"
                        y="3"
                        fill="#f8fafc"
                        fontSize="9"
                        fontFamily="monospace"
                        className="font-medium pointer-events-none"
                      >
                        {edge.relationship}
                      </text>
                    </g>
                  )}
                </g>
              );
            })}

            {/* Nodes */}
            {nodes.map((node) => {
              const pos = nodePositionMap.get(node.id);
              if (!pos) return null;

              const isSelected = selectedNodeId === node.id;
              const isHovered = hoveredNodeId === node.id;
              const isConnected = connectedNodeIds.has(node.id);
              const matchesFilter = filteredNodes.some((fn) => fn.id === node.id);

              const color = CATEGORY_COLORS[node.category] || CATEGORY_COLORS.Target;
              const opacity = (selectedNodeId || hoveredNodeId)
                ? isConnected
                  ? 1
                  : 0.25
                : matchesFilter
                ? 1
                : 0.25;

              return (
                <g
                  key={node.id}
                  transform={`translate(${pos.x}, ${pos.y})`}
                  onMouseDown={(e) => handleMouseDownNode(e, node.id)}
                  onTouchStart={(e) => handleTouchStartNode(e, node.id)}
                  onMouseEnter={() => setHoveredNodeId(node.id)}
                  onMouseLeave={() => setHoveredNodeId(null)}
                  className="cursor-pointer transition-opacity duration-150"
                  style={{ opacity }}
                >
                  {/* Subtle outer halo on selection */}
                  {isSelected && (
                    <circle
                      r="26"
                      fill="none"
                      stroke={color.stroke}
                      strokeWidth="2"
                      strokeDasharray="3 2"
                      className="opacity-80"
                    />
                  )}

                  {/* Node Circle */}
                  <circle
                    r={isSelected ? 18 : 15}
                    fill={color.fill}
                    stroke={isSelected ? '#ffffff' : color.stroke}
                    strokeWidth={isSelected ? 2.5 : 1.5}
                    className="transition-transform duration-150 drop-shadow-xs"
                  />

                  {/* Label */}
                  <text
                    y={isSelected ? 30 : 27}
                    textAnchor="middle"
                    fill="currentColor"
                    fontSize="11"
                    className="font-medium text-slate-800 dark:text-slate-100 select-none pointer-events-none drop-shadow-xs"
                  >
                    {node.label}
                  </text>
                  <text
                    y={isSelected ? 42 : 38}
                    textAnchor="middle"
                    fill="currentColor"
                    fontSize="8.5"
                    className="font-mono text-slate-500 dark:text-slate-400 select-none pointer-events-none uppercase tracking-wider"
                  >
                    {node.category}
                  </text>
                </g>
              );
            })}
          </g>
        </svg>

        {/* Floating Illustrative Notice Badge */}
        <div className="absolute bottom-3 left-3 px-3 py-1.5 bg-white/90 dark:bg-slate-900/90 border border-slate-200 dark:border-slate-800 rounded-md text-[11px] text-slate-500 backdrop-blur-xs flex items-center gap-2 pointer-events-none">
          <span className="font-semibold text-slate-700 dark:text-slate-300">Model Dataset:</span>
          <span>KRAS G12D Oncology, Perovskite Photovoltaics & Synaptic Pruning</span>
        </div>

        {/* Selected Edge Tooltip Inspector */}
        {selectedEdge && (
          <div className="absolute top-4 left-4 max-w-xs bg-slate-900 text-white p-3 rounded-lg border border-slate-700 shadow-lg text-xs space-y-1.5 z-20">
            <div className="flex items-center justify-between">
              <span className="font-mono text-[10px] text-teal-400 uppercase tracking-wide">Directional Relationship</span>
              <button onClick={() => setSelectedEdgeId(null)} className="text-slate-400 hover:text-white">
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
            <p className="font-semibold text-sm text-slate-100">
              {nodes.find((n) => n.id === selectedEdge.source)?.label} → {nodes.find((n) => n.id === selectedEdge.target)?.label}
            </p>
            <p className="text-teal-300 font-medium text-xs">{selectedEdge.relationship}</p>
            <p className="text-slate-300 text-[11px] leading-relaxed">{selectedEdge.mechanism}</p>
            <div className="pt-1 border-t border-slate-800 text-[10px] text-slate-400 font-mono">
              Basis: {selectedEdge.evidenceBasis}
            </div>
          </div>
        )}

        {/* Selected Node Evidence Slide-out Drawer */}
        {selectedNode && (
          <div 
            className="absolute top-0 right-0 h-full w-full sm:w-88 bg-white dark:bg-slate-900 border-l border-slate-200 dark:border-slate-800 shadow-xl p-5 overflow-y-auto z-30 transition-transform"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
              <div>
                <span className="text-[10px] uppercase font-mono tracking-wider text-teal-600 dark:text-teal-400">
                  Concept Inspector
                </span>
                <h3 className="text-base font-bold text-slate-900 dark:text-slate-100 mt-0.5">
                  {selectedNode.label}
                </h3>
              </div>
              <button
                onClick={() => setSelectedNodeId(null)}
                className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded"
                aria-label="Close Inspector"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="py-3.5 space-y-4 text-xs">
              <div>
                <span className="text-[11px] font-medium text-slate-400 uppercase tracking-wider">Classification</span>
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-200 mt-0.5">
                  {selectedNode.category}
                </p>
              </div>

              <div>
                <span className="text-[11px] font-medium text-slate-400 uppercase tracking-wider">Functional Role</span>
                <p className="text-xs text-slate-600 dark:text-slate-300 mt-1 leading-relaxed">
                  {selectedNode.description}
                </p>
              </div>

              <div className="p-3 bg-stone-50 dark:bg-slate-800/60 rounded-lg border border-slate-200 dark:border-slate-700/60">
                <span className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider flex items-center gap-1.5">
                  <BookOpen className="w-3 h-3 text-teal-600 dark:text-teal-400" />
                  Primary Evidence Basis
                </span>
                <p className="text-xs text-slate-700 dark:text-slate-300 mt-1.5 italic leading-relaxed">
                  "{selectedNode.evidenceExcerpt}"
                </p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-2 font-mono">
                  {selectedNode.supportingCitation}
                </p>
              </div>

              <div>
                <span className="text-[11px] font-medium text-slate-400 uppercase tracking-wider">
                  Associated Intersections ({nodeEdges.length})
                </span>
                <div className="mt-2 space-y-2">
                  {nodeEdges.map((edge) => {
                    const isSource = edge.source === selectedNode.id;
                    const otherNode = nodes.find((n) => n.id === (isSource ? edge.target : edge.source));
                    return (
                      <div
                        key={edge.id}
                        onClick={() => setSelectedEdgeId(edge.id)}
                        className="p-2.5 rounded-md border border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50 cursor-pointer transition-colors"
                      >
                        <div className="flex items-center justify-between text-[11px]">
                          <span className="font-semibold text-slate-800 dark:text-slate-200">
                            {isSource ? '→ ' : '← '} {otherNode?.label}
                          </span>
                          <span className="text-[10px] text-teal-600 dark:text-teal-400 font-medium">
                            {edge.relationship}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 line-clamp-2">
                          {edge.mechanism}
                        </p>
                      </div>
                    );
                  })}
                </div>
              </div>

              {onSelectConceptForHypothesis && (
                <div className="pt-2">
                  <button
                    onClick={() => onSelectConceptForHypothesis(selectedNode)}
                    className="w-full py-2 px-3 bg-teal-600 hover:bg-teal-500 text-white rounded-md font-medium text-xs flex items-center justify-center gap-2 transition-colors shadow-xs"
                  >
                    <span>Formulate Hypothesis from Node</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
