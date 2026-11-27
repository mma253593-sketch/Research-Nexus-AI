-- =====================================================================
--  PANEL VIEW (separate pane): CALL / PUT scores, regime code, decision.
--  Legend values: REGIME 1 trending, 2 ranging, 3 high vol, 4 low vol,
--  5 unstable, 0 no data. DECISION 1 CALL, -1 PUT, 0 WAIT.
--  Scores measure agreement of conditions; they are NOT probabilities.
-- =====================================================================
v2_call_s = make_series ()
v2_call_s:set (CALL_SCORE)
v2_put_s = make_series ()
v2_put_s:set (PUT_SCORE)
v2_reg_s = make_series ()
v2_reg_s:set (REGIME_CODE)
v2_dec_s = make_series ()
v2_dec_s:set (SIG_DIR)
plot (v2_call_s, "CALL Score", rgba(0,230,118,0.9), 1)
plot (v2_put_s, "PUT Score", rgba(255,23,68,0.9), 1)
plot (v2_reg_s, "Regime", rgba(0,0,0,0), 1)
plot (v2_dec_s, "Decision", rgba(0,0,0,0), 1)
hline (65, "Trend min", rgba(255,255,255,0.25), 1)
hline (70, "Range min", rgba(255,255,255,0.25), 1)
