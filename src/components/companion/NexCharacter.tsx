import React from 'react';
import { NexState } from './types';

interface NexCharacterProps {
  state: NexState;
  scale?: number;
  direction?: 'left' | 'right';
  isInteracting?: boolean;
}

export function NexCharacter({
  state,
  scale = 1.0,
  direction = 'right',
  isInteracting = false
}: NexCharacterProps) {
  const isWalking = state === 'walking';
  const isWaving = state === 'waving';
  const isThinking = state === 'thinking';
  const isTalking = state === 'talking';
  const isHappy = state === 'happy';
  const isSurprised = state === 'surprised';
  const isSleeping = state === 'sleeping';
  const isBlinking = state === 'blinking';
  const isLooking = state === 'looking_at_user';

  // Flip horizontally if walking left or facing left
  const flipX = direction === 'left' ? -1 : 1;

  return (
    <div 
      className="relative select-none pointer-events-none transition-transform duration-200"
      style={{
        width: `${84 * scale}px`,
        height: `${110 * scale}px`,
      }}
      aria-label={`NEX Companion Robot in ${state} state`}
      role="img"
    >
      <svg
        viewBox="0 0 100 130"
        className="w-full h-full overflow-visible"
        style={{
          transform: `scaleX(${flipX})`,
          transition: 'transform 0.3s ease-out'
        }}
      >
        <defs>
          {/* Gradients for 3D Stylized Depth */}
          <radialGradient id="nex-body-grad" cx="40%" cy="30%" r="70%">
            <stop offset="0%" stopColor="#FFFFFF" />
            <stop offset="65%" stopColor="#F1F5F9" />
            <stop offset="100%" stopColor="#CBD5E1" />
          </radialGradient>

          <radialGradient id="nex-head-grad" cx="35%" cy="30%" r="75%">
            <stop offset="0%" stopColor="#FFFFFF" />
            <stop offset="70%" stopColor="#F8FAFC" />
            <stop offset="100%" stopColor="#CBD5E1" />
          </radialGradient>

          <linearGradient id="nex-visor-grad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#0F172A" />
            <stop offset="60%" stopColor="#1E293B" />
            <stop offset="100%" stopColor="#0B0F19" />
          </linearGradient>

          <linearGradient id="nex-visor-specular" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="rgba(56, 189, 248, 0.4)" />
            <stop offset="40%" stopColor="rgba(255, 255, 255, 0.15)" />
            <stop offset="100%" stopColor="rgba(255, 255, 255, 0)" />
          </linearGradient>

          <linearGradient id="nex-navy-trim" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#334155" />
            <stop offset="100%" stopColor="#0F172A" />
          </linearGradient>

          <radialGradient id="nex-teal-glow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#5EEAD4" />
            <stop offset="70%" stopColor="#14B8A6" />
            <stop offset="100%" stopColor="#0D9488" />
          </radialGradient>

          <radialGradient id="nex-shadow-grad" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="rgba(15, 23, 42, 0.35)" />
            <stop offset="100%" stopColor="rgba(15, 23, 42, 0)" />
          </radialGradient>

          {/* SVG Glow Filter for Eyes */}
          <filter id="eye-glow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="1.2" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>
        </defs>

        <style>{`
          @keyframes nex-hover {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-3.5px); }
          }
          @keyframes nex-shadow-pulse {
            0%, 100% { transform: scale(1); opacity: 0.8; }
            50% { transform: scale(0.85); opacity: 0.55; }
          }
          @keyframes nex-walk-body {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            25% { transform: translateY(-2px) rotate(2deg); }
            50% { transform: translateY(0px) rotate(0deg); }
            75% { transform: translateY(-2px) rotate(-2deg); }
          }
          @keyframes nex-leg-l {
            0%, 100% { transform: rotate(-12deg); }
            50% { transform: rotate(16deg); }
          }
          @keyframes nex-leg-r {
            0%, 100% { transform: rotate(16deg); }
            50% { transform: rotate(-12deg); }
          }
          @keyframes nex-arm-walk-l {
            0%, 100% { transform: rotate(15deg); }
            50% { transform: rotate(-15deg); }
          }
          @keyframes nex-arm-walk-r {
            0%, 100% { transform: rotate(-15deg); }
            50% { transform: rotate(15deg); }
          }
          @keyframes nex-wave {
            0%, 100% { transform: rotate(-10deg); }
            50% { transform: rotate(25deg); }
          }
          @keyframes nex-breathe {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.02); }
          }
          @keyframes nex-antenna-sway {
            0%, 100% { transform: rotate(-3deg); }
            50% { transform: rotate(3deg); }
          }
          @keyframes nex-pulse-talk {
            0%, 100% { transform: scaleY(1); }
            50% { transform: scaleY(1.35); }
          }
          @keyframes nex-sleep-z {
            0% { opacity: 0; transform: translate(65px, 25px) scale(0.6); }
            50% { opacity: 0.9; }
            100% { opacity: 0; transform: translate(78px, 8px) scale(1.1); }
          }

          .nex-root-hover {
            animation: ${isWalking ? 'none' : 'nex-hover 3.2s ease-in-out infinite'};
          }
          .nex-root-shadow {
            transform-origin: 50px 122px;
            animation: ${isWalking ? 'none' : 'nex-shadow-pulse 3.2s ease-in-out infinite'};
          }
          .nex-walking-body {
            transform-origin: 50px 70px;
            animation: ${isWalking ? 'nex-walk-body 0.65s linear infinite' : 'none'};
          }
          .nex-walking-leg-l {
            transform-origin: 40px 92px;
            animation: ${isWalking ? 'nex-leg-l 0.65s ease-in-out infinite' : 'none'};
          }
          .nex-walking-leg-r {
            transform-origin: 60px 92px;
            animation: ${isWalking ? 'nex-leg-r 0.65s ease-in-out infinite' : 'none'};
          }
          .nex-walking-arm-l {
            transform-origin: 26px 66px;
            animation: ${isWalking ? 'nex-arm-walk-l 0.65s ease-in-out infinite' : 'none'};
          }
          .nex-walking-arm-r {
            transform-origin: 74px 66px;
            animation: ${isWalking ? 'nex-arm-walk-r 0.65s ease-in-out infinite' : 'none'};
          }
          .nex-waving-arm {
            transform-origin: 76px 60px;
            animation: ${isWaving ? 'nex-wave 0.5s ease-in-out infinite' : 'none'};
          }
          .nex-antenna {
            transform-origin: 50px 22px;
            animation: nex-antenna-sway 2.6s ease-in-out infinite;
          }
          .nex-talk-eye {
            transform-origin: 50% 50%;
            animation: ${isTalking ? 'nex-pulse-talk 0.3s ease-in-out infinite' : 'none'};
          }
          .nex-sleep-bubble {
            animation: nex-sleep-z 2.2s ease-in-out infinite;
          }
        `}</style>

        {/* Dynamic Ground Shadow */}
        <ellipse
          cx="50"
          cy="122"
          rx={isWalking ? '22' : '20'}
          ry="5.5"
          fill="url(#nex-shadow-grad)"
          className="nex-root-shadow"
        />

        {/* Main Character Body & Limbs Container */}
        <g className="nex-root-hover">
          <g className="nex-walking-body">
            
            {/* LEGS & FEET */}
            {/* Left Leg */}
            <g className="nex-walking-leg-l">
              {/* Joint pod */}
              <circle cx="40" cy="94" r="4.5" fill="url(#nex-navy-trim)" />
              {/* Shin strut */}
              <rect x="38" y="94" width="4" height="12" rx="2" fill="url(#nex-body-grad)" stroke="#CBD5E1" strokeWidth="0.5" />
              {/* Foot sole */}
              <path
                d="M 33 108 C 33 105, 47 105, 47 108 L 46 112 C 46 114, 34 114, 34 112 Z"
                fill="url(#nex-navy-trim)"
              />
              <ellipse cx="40" cy="111" rx="5" ry="1.5" fill="#14B8A6" opacity="0.8" />
            </g>

            {/* Right Leg */}
            <g className="nex-walking-leg-r">
              <circle cx="60" cy="94" r="4.5" fill="url(#nex-navy-trim)" />
              <rect x="58" y="94" width="4" height="12" rx="2" fill="url(#nex-body-grad)" stroke="#CBD5E1" strokeWidth="0.5" />
              <path
                d="M 53 108 C 53 105, 67 105, 67 108 L 66 112 C 66 114, 54 114, 54 112 Z"
                fill="url(#nex-navy-trim)"
              />
              <ellipse cx="60" cy="111" rx="5" ry="1.5" fill="#14B8A6" opacity="0.8" />
            </g>

            {/* TORSO / LOWER CHASSIS */}
            <g id="torso">
              {/* Spherical research chassis */}
              <rect
                x="32"
                y="62"
                width="36"
                height="34"
                rx="14"
                fill="url(#nex-body-grad)"
                stroke="#E2E8F0"
                strokeWidth="1"
              />
              {/* Inner chest panel with research nexus emblem */}
              <rect
                x="38"
                y="68"
                width="24"
                height="18"
                rx="7"
                fill="url(#nex-navy-trim)"
              />
              {/* Chest LED nexus symbol (Teal research ring) */}
              <circle cx="50" cy="77" r="4.5" fill="none" stroke="#14B8A6" strokeWidth="1.5" />
              <circle cx="50" cy="77" r="2" fill="#5EEAD4" filter="url(#eye-glow)" />
              {/* Collar trim */}
              <path d="M 39 63 Q 50 67 61 63" stroke="#CBD5E1" strokeWidth="1.5" fill="none" />
            </g>

            {/* HEAD MODULE */}
            <g id="head" style={{ transformOrigin: '50px 42px' }}>
              {/* Floating Top Antenna Probe */}
              <g className="nex-antenna">
                <line x1="50" y1="21" x2="50" y2="10" stroke="#475569" strokeWidth="2" strokeLinecap="round" />
                <circle cx="50" cy="9" r="3.5" fill="url(#nex-teal-glow)" filter="url(#eye-glow)" />
                <circle cx="50" cy="9" r="1.5" fill="#FFFFFF" />
              </g>

              {/* Head Shell: Smooth egg capsule */}
              <path
                d="M 24 40 C 24 23, 76 23, 76 40 C 76 56, 24 56, 24 40 Z"
                fill="url(#nex-head-grad)"
                stroke="#E2E8F0"
                strokeWidth="1.2"
              />

              {/* Outer Visor Bezel (Deep Navy) */}
              <path
                d="M 28 39 C 28 27, 72 27, 72 39 C 72 51, 28 51, 28 39 Z"
                fill="url(#nex-navy-trim)"
              />

              {/* Inner Glass Visor Display */}
              <path
                d="M 30 39 C 30 29, 70 29, 70 39 C 70 49, 30 49, 30 39 Z"
                fill="url(#nex-visor-grad)"
              />

              {/* Specular curved reflection on glass */}
              <path
                d="M 32 35 Q 50 31 68 35 Q 50 37 32 35 Z"
                fill="url(#nex-visor-specular)"
              />

              {/* OCULAR LED EYES SYSTEM */}
              <g id="eyes" filter="url(#eye-glow)" className={isTalking ? 'nex-talk-eye' : ''}>
                {isSleeping ? (
                  // Sleeping eyes: relaxed horizontal lines
                  <>
                    <path d="M 39 42 Q 44 42 47 42" stroke="#14B8A6" strokeWidth="2.5" strokeLinecap="round" fill="none" />
                    <path d="M 53 42 Q 56 42 61 42" stroke="#14B8A6" strokeWidth="2.5" strokeLinecap="round" fill="none" />
                    <text x="66" y="24" fill="#14B8A6" fontSize="8" fontWeight="bold" className="nex-sleep-bubble">Z</text>
                  </>
                ) : isHappy ? (
                  // Happy eyes: cheerful upward arcs ^ ^
                  <>
                    <path d="M 38 43 Q 43 36 48 43" stroke="#2DD4BF" strokeWidth="2.5" strokeLinecap="round" fill="none" />
                    <path d="M 52 43 Q 57 36 62 43" stroke="#2DD4BF" strokeWidth="2.5" strokeLinecap="round" fill="none" />
                  </>
                ) : isSurprised ? (
                  // Surprised eyes: wide circular apertures
                  <>
                    <circle cx="43" cy="39" r="5" fill="#5EEAD4" />
                    <circle cx="43" cy="39" r="2" fill="#0F172A" />
                    <circle cx="57" cy="39" r="5" fill="#5EEAD4" />
                    <circle cx="57" cy="39" r="2" fill="#0F172A" />
                  </>
                ) : isBlinking ? (
                  // Blinking: thin slits
                  <>
                    <line x1="39" y1="39" x2="47" y2="39" stroke="#14B8A6" strokeWidth="1.8" strokeLinecap="round" />
                    <line x1="53" y1="39" x2="61" y2="39" stroke="#14B8A6" strokeWidth="1.8" strokeLinecap="round" />
                  </>
                ) : isThinking ? (
                  // Thinking: eyes drifted up-right with glint
                  <>
                    <ellipse cx="45" cy="36" rx="4" ry="4.5" fill="#2DD4BF" />
                    <circle cx="46" cy="35" r="1.5" fill="#FFFFFF" />
                    <ellipse cx="59" cy="36" rx="4" ry="4.5" fill="#2DD4BF" />
                    <circle cx="60" cy="35" r="1.5" fill="#FFFFFF" />
                  </>
                ) : isLooking ? (
                  // Looking directly at user: wide, warm round pupils with friendly glint
                  <>
                    <ellipse cx="43" cy="39" rx="4.5" ry="5.5" fill="#5EEAD4" />
                    <circle cx="44.5" cy="37.5" r="1.8" fill="#FFFFFF" />
                    <ellipse cx="57" cy="39" rx="4.5" ry="5.5" fill="#5EEAD4" />
                    <circle cx="58.5" cy="37.5" r="1.8" fill="#FFFFFF" />
                  </>
                ) : (
                  // Default / Idle / Talking / Walking eyes: Friendly curved ovals
                  <>
                    <ellipse cx="43" cy="39" rx="4.2" ry="5" fill="#2DD4BF" />
                    <circle cx="44.2" cy="37.5" r="1.5" fill="#FFFFFF" />
                    <ellipse cx="57" cy="39" rx="4.2" ry="5" fill="#2DD4BF" />
                    <circle cx="58.2" cy="37.5" r="1.5" fill="#FFFFFF" />
                  </>
                )}
              </g>

              {/* Subtle Ear Pivot Caps */}
              <circle cx="24" cy="40" r="3" fill="url(#nex-navy-trim)" />
              <circle cx="76" cy="40" r="3" fill="url(#nex-navy-trim)" />
            </g>

            {/* ARTICULATED ARMS */}
            {/* Left Arm */}
            <g className={isWalking ? 'nex-walking-arm-l' : ''}>
              <circle cx="28" cy="67" r="4" fill="url(#nex-navy-trim)" />
              {isHappy ? (
                // Happy: raised arm
                <path d="M 28 67 Q 18 55 16 45" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
              ) : isSurprised ? (
                // Surprised: arm splayed out
                <path d="M 28 67 Q 15 68 12 70" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
              ) : (
                // Default: relaxed resting arm
                <path d="M 28 67 Q 22 76 22 83" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
              )}
              {/* Hand clasp */}
              <circle cx={isHappy ? 16 : isSurprised ? 12 : 22} cy={isHappy ? 45 : isSurprised ? 70 : 83} r="3" fill="url(#nex-navy-trim)" />
            </g>

            {/* Right Arm */}
            {isWaving ? (
              // Waving Arm (Articulated hand waving back and forth)
              <g className="nex-waving-arm">
                <circle cx="72" cy="67" r="4" fill="url(#nex-navy-trim)" />
                <path d="M 72 67 Q 82 52 86 42" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
                <circle cx="86" cy="42" r="3.5" fill="url(#nex-navy-trim)" />
                {/* Waving hand fingers/paw */}
                <ellipse cx="88" cy="39" rx="2.5" ry="3.5" fill="#14B8A6" transform="rotate(25 88 39)" />
              </g>
            ) : isThinking ? (
              // Thinking Arm (Hand touching chin)
              <g>
                <circle cx="72" cy="67" r="4" fill="url(#nex-navy-trim)" />
                <path d="M 72 67 Q 78 60 68 53" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
                <circle cx="68" cy="53" r="3.5" fill="url(#nex-navy-trim)" />
              </g>
            ) : isHappy ? (
              // Happy: both arms raised!
              <g>
                <circle cx="72" cy="67" r="4" fill="url(#nex-navy-trim)" />
                <path d="M 72 67 Q 82 55 84 45" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
                <circle cx="84" cy="45" r="3" fill="url(#nex-navy-trim)" />
              </g>
            ) : (
              // Normal resting / walking arm
              <g className={isWalking ? 'nex-walking-arm-r' : ''}>
                <circle cx="72" cy="67" r="4" fill="url(#nex-navy-trim)" />
                <path d="M 72 67 Q 78 76 78 83" stroke="url(#nex-body-grad)" strokeWidth="4.5" strokeLinecap="round" fill="none" />
                <circle cx="78" cy="83" r="3" fill="url(#nex-navy-trim)" />
              </g>
            )}

          </g>
        </g>
      </svg>
    </div>
  );
}
