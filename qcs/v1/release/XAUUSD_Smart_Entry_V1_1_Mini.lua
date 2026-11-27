instrument{name="XAUUSD Smart Entry V1.1",short_name="XAU-SE1.1",overlay=true}
--Generated from qcs/v1/src(core.lua+view_main.lua). Edit the sources,then run qcs/build.sh.
input_group{"Trend (EMA)",
ema_fast_len=input(9,"EMA Fast",input.integer,1,200),ema_mid_len=input(21,"EMA Mid",input.integer,1,300),
ema_slow_len=input(50,"EMA Slow",input.integer,1,500)
}
input_group{"Momentum (RSI / MACD)",
rsi_len=input(14,"RSI Period",input.integer,2,100),rsi_ext_high=input(78,"RSI too high - block CALL",input.double,55,100,1),
rsi_ext_low=input(22,"RSI too low - block PUT",input.double,0,45,1),macd_fast_len=input(12,"MACD Fast",input.integer,1,100),
macd_slow_len=input(26,"MACD Slow",input.integer,2,200),
macd_sig_len=input(9,"MACD Signal",input.integer,1,100)
}
input_group{"Volatility (Bollinger / ATR)",
bb_len=input(20,"BB Period",input.integer,2,200),bb_mult=input(2.0,"BB Deviation",input.double,0.5,5,0.1),
atr_len=input(14,"ATR Period",input.integer,1,100),atr_base_len=input(100,"ATR Baseline Period",input.integer,10,500),
squeeze_ratio=input(0.75,"Squeeze: BB width < avg x",input.double,0.1,1.5,0.05),flat_atr=input(0.25,"Flat: EMA Mid slope < ATR x",input.double,0,2,0.05),
spike_mult=input(2.8,"Spike: candle range > ATR x",input.double,1,10,0.1),
hot_ratio=input(1.9,"Hot: ATR > baseline x",input.double,1,5,0.1)
}
input_group{"Support / Resistance",
pivot_len=input(5,"Pivot strength (bars each side)",input.integer,2,20),range_len=input(50,"Range lookback (bars)",input.integer,10,300),
min_room_atr=input(0.8,"Min room to next level (ATR x)",input.double,0,5,0.1)
}
input_group{"Signal Filter",
min_score=input(70,"Min confidence to signal (60-100)",input.integer,60,100),cooldown_bars=input(3,"Cooldown after a signal (bars)",input.integer,0,50),
late_body_atr=input(1.8,"Late: candle body > ATR x",input.double,0.5,10,0.1),max_ext_atr=input(2.2,"Late: distance from EMA Mid > ATR x",input.double,0.5,10,0.1),
chase_atr=input(0.35,"No chase: live move > ATR x",input.double,0.05,5,0.05)
}
ema_f=ema(close,ema_fast_len);ema_m=ema(close,ema_mid_len);ema_s=ema(close,ema_slow_len)
rsi_val=rsi(close,rsi_len);macd_fast_ma=ema(close,macd_fast_len);macd_slow_ma=ema(close,macd_slow_len)
macd_line=macd_fast_ma-macd_slow_ma;macd_sig=ema(macd_line,macd_sig_len);macd_hist=macd_line-macd_sig
bb_mid=sma(close,bb_len);bb_dev=stdev(close,bb_len)*bb_mult;bb_up=bb_mid+bb_dev
bb_lo=bb_mid-bb_dev;bb_width=(bb_up-bb_lo)/bb_mid;bb_width_avg=sma(bb_width,bb_len*3)
atr_val=rma(tr,atr_len);atr_base=sma(atr_val,atr_base_len);clv=(close-low)/max(high-low,0.0000001)
clv_avg=sma(clv,5);piv_win_hi=highest(high,pivot_len);piv_win_lo=lowest(low,pivot_len)
rng_hi=highest(high,range_len);rng_lo=lowest(low,range_len)
local function num(s,d)
local v=get_value(s)
if v==nil or v~=v then
return d
end
return v
end
local function clamp(x,a,b)
if x<a then return a end
if x>b then return b end
return x
end
local function pivot(ser,w,sgn)
local x,left,right=num(ser[pivot_len+1]),num(w[pivot_len+2]),num(w[1])
if x~=nil and left~=nil and right~=nil and sgn*x>sgn*left and sgn*x>=sgn*right then
return x
end
end
local function remember(s1,s2,new)
local p1,p2=num(s1[1]),num(s2[1])
if new~=nil then
s1:set(new)
if p1~=nil then s2:set(p1)end
else
if p1~=nil then s1:set(p1)end
if p2~=nil then s2:set(p2)end
end
end
res_lvl=make_series();res_lvl2=make_series();sup_lvl=make_series()
sup_lvl2=make_series();remember(res_lvl,res_lvl2,pivot(high,piv_win_hi,1));remember(sup_lvl,sup_lvl2,pivot(low,piv_win_lo,-1))
bar_count=make_series();bar_count:set(num(bar_count[1],0)+1);sig_age=make_series()
local O1,H1,L1,C1=num(open[1]),num(high[1]),num(low[1]),num(close[1])
local O2,H2,L2,C2=num(open[2]),num(high[2]),num(low[2]),num(close[2])
local EF1,EM1,ES1=num(ema_f[1]),num(ema_m[1]),num(ema_s[1]);local EM4,ES4=num(ema_m[4]),num(ema_s[4])
local R1,R2=num(rsi_val[1]),num(rsi_val[2]);local HI1,HI2=num(macd_hist[1]),num(macd_hist[2])
local ML1=num(macd_line[1]);local ATR1,ATR2=num(atr_val[1]),num(atr_val[2]);local ATRB1=num(atr_base[1])
local BW1,BWA1=num(bb_width[1]),num(bb_width_avg[1]);local CLV1=num(clv_avg[1],0.5)
local RES1,RES2=num(res_lvl),num(res_lvl2);local SUP1,SUP2=num(sup_lvl),num(sup_lvl2)
local RHI2,RLO2=num(rng_hi[2]),num(rng_lo[2])
local warm_need=math.max(ema_slow_len,range_len,atr_base_len,bb_len*3)+2*pivot_len+5
local data_ok=num(bar_count,0)>warm_need
and O1 and H1 and L1 and C1 and O2 and H2 and L2 and C2
and EF1 and EM1 and ES1 and EM4 and ES4 and R1 and R2
and HI1 and HI2 and ML1 and ATR1 and ATR2 and ATRB1 and BW1 and BWA1
and ATR1>0 and ATR2>0 and ATRB1>0
SIG_DIR=0;SIG_SCORE=0;SIG_TRIG=""
BULL_SCORE=0;BEAR_SCORE=0;TREND_DIR=0
WAIT_REASON="";WAIT_SIDE=0;BUY_PRESS=50
SELL_PRESS=50;NO_CHASE=false
local function make_view(s)
local v={}
if s==1 then
v.o1,v.h1,v.l1,v.c1=O1,H1,L1,C1;v.o2,v.h2,v.l2,v.c2=O2,H2,L2,C2;v.ext=rsi_ext_high
else
v.o1,v.h1,v.l1,v.c1=-O1,-L1,-H1,-C1;v.o2,v.h2,v.l2,v.c2=-O2,-L2,-H2,-C2;v.ext=100-rsi_ext_low
end
v.ef1,v.em1,v.es1=s*EF1,s*EM1,s*ES1;v.em4,v.es4=s*EM4,s*ES4;v.r1=(s==1)and R1 or(100-R1)
v.r2=(s==1)and R2 or(100-R2);v.hi1,v.hi2,v.ml1=s*HI1,s*HI2,s*ML1;local obst,supp={},{}
local function add(t,x)if x~=nil then t[#t+1]=x end end
if s==1 then
add(obst,RES1)add(obst,RES2)add(obst,RHI2)
add(supp,SUP1)add(supp,SUP2)add(supp,RLO2)
v.brk_lvl=RES1;v.sweep_lvl=SUP1
else
add(obst,SUP1 and-SUP1)add(obst,SUP2 and-SUP2)add(obst,RLO2 and-RLO2)
add(supp,RES1 and-RES1)add(supp,RES2 and-RES2)add(supp,RHI2 and-RHI2)
v.brk_lvl=SUP1 and-SUP1;v.sweep_lvl=RES1 and-RES1
end
v.obst,v.supp=obst,supp
return v
end
local sideways,abnormal,squeeze=false,false,false
local function evaluate(v)
local r={score=0,trig="",reason="",bias=false};local atr=ATR1;local rng1=math.max(v.h1-v.l1,0.0000001)
local body1=math.abs(v.c1-v.o1);local body2=math.abs(v.c2-v.o2);local upw1=v.h1-math.max(v.c1,v.o1)
local loww1=math.min(v.c1,v.o1)-v.l1;local close_pos=(v.c1-v.l1)/rng1;local room=99
for _,x in ipairs(v.obst)do
if x>v.c1 then room=math.min(room,(x-v.c1)/atr)end
end
local near_sup=nil
for _,x in ipairs(v.supp)do
if x<v.c1 and(near_sup==nil or x>near_sup)then near_sup=x end
end
local trend_ok=v.em1>v.es1 and v.c1>v.es1 and v.es1>v.es4;local stack=v.ef1>v.em1 and v.em1>v.es1;local ts=0
if stack then ts=ts+12 elseif v.ef1>v.em1 then ts=ts+5 end
if v.c1>v.em1 then ts=ts+4 end
if v.es1>v.es4 then ts=ts+5 end
if(v.ef1-v.es1)>=0.5*atr then ts=ts+4 end
local rs=0
if v.r1>52 and v.r1<=70 and v.r1>=v.r2 then rs=15
elseif v.r1>50 then rs=10
elseif v.r1>=45 and v.r1>v.r2 then rs=4 end
local ms=0
if v.hi1>0 then ms=ms+6 end
if v.hi1>v.hi2 then ms=ms+5 end
if v.ml1>0 then ms=ms+4 end
local pa,trig=0,""
local function take(p,t)if p>pa then pa,trig=p,t end end
if v.c1>v.o1 and v.c2<v.o2 and v.c1>=v.o2 and v.o1<=v.c2
and body1>body2 and body1>=0.3*atr then
take(20,"ENGULF")
end
if v.sweep_lvl~=nil and v.l1<v.sweep_lvl and v.c1>v.sweep_lvl
and loww1>=0.4*rng1 and close_pos>=0.5 then
take(18,"FALSE-BRK")
end
if loww1>=2*body1 and loww1>=0.6*rng1 and upw1<=0.25*rng1
and rng1>=0.5*atr then
take(16,"PIN")
end
local touched=(v.l1<=v.em1+0.15*atr)
or(near_sup~=nil and v.l1<=near_sup+0.25*atr)
if v.c1>v.o1 and loww1>=0.4*rng1 and touched and v.c1>v.em1 then
take(15,"REJECT")
end
if v.brk_lvl~=nil and v.c1>v.brk_lvl+0.1*atr and v.c2<=v.brk_lvl
and v.c1>v.o1 and body1>=0.5*rng1 then
take(14,"BREAKOUT")
end
if v.c1>v.o1 and body1>=0.5*rng1 and close_pos>=0.7 then
take(8,"MOMENTUM")
end
local rm=0
if room>=2.0 then rm=15
elseif room>=1.5 then rm=12
elseif room>=1.0 then rm=8
elseif room>=min_room_atr then rm=4 end
local vs=0;local atr_ratio=ATR1/ATRB1
if not squeeze and not abnormal and atr_ratio>=0.6 and atr_ratio<=1.6 then
vs=10
elseif not abnormal then
vs=5
end
r.score=clamp(ts+rs+ms+pa+rm+vs,0,100);r.trig=trig;r.bias=trend_ok
local late=body1>late_body_atr*atr or(v.c1-v.em1)>max_ext_atr*atr
if abnormal then
r.reason="VOLATILE"
elseif sideways then
r.reason="SIDEWAYS"
elseif not trend_ok or not(v.ef1>v.em1)then
r.reason="NO-TREND"
elseif v.r1<=50 or v.hi1<=0 then
r.reason="CONFLICT"
elseif v.r1>v.ext then
r.reason="OVEREXT"
elseif pa<8 or close_pos<0.5 then
r.reason="NO-PA"
elseif late then
r.reason="LATE"
elseif room<min_room_atr then
r.reason="NEAR-SR"
elseif r.score<min_score then
r.reason="LOW-SCORE"
end
return r
end
local prev_age=num(sig_age[1],999)
if data_ok then
squeeze=BW1<BWA1*squeeze_ratio;local flat=math.abs(EM1-EM4)<flat_atr*ATR1
local tangled=math.abs(EF1-ES1)<0.3*ATR1;sideways=flat and(squeeze or tangled)
abnormal=(H1-L1)>spike_mult*ATR2 or ATR1>hot_ratio*ATRB1;local bull=evaluate(make_view(1))
local bear=evaluate(make_view(-1));BULL_SCORE=bull.score;BEAR_SCORE=bear.score
if bull.bias and not sideways then TREND_DIR=1
elseif bear.bias and not sideways then TREND_DIR=-1 end
BUY_PRESS=clamp(CLV1*100,0,100);SELL_PRESS=100-BUY_PRESS;local cooled=prev_age>=cooldown_bars
local best,side=nil,0
if bull.reason=="" then best,side=bull,1
elseif bear.reason=="" then best,side=bear,-1 end
if best~=nil and not cooled then
WAIT_REASON,WAIT_SIDE="COOLDOWN",side;best=nil
end
if best~=nil then
SIG_DIR=side;SIG_SCORE=best.score;SIG_TRIG=best.trig
else
local function setup(x)return x.bias and x.trig~="" and x.score>=min_score end
local cand,cside=nil,0
if setup(bull)then cand,cside=bull,1
elseif setup(bear)then cand,cside=bear,-1 end
if cand~=nil and WAIT_REASON=="" then
WAIT_REASON,WAIT_SIDE=cand.reason,cside
end
end
if SIG_DIR~=0 then
local o0,c0=num(open),num(close)
if o0~=nil and c0~=nil and SIG_DIR*(c0-o0)>chase_atr*ATR1 then
NO_CHASE=true
end
end
end
sig_age:set(SIG_DIR~=0 and 0 or prev_age+1)
local REASON_CODE={["NEAR-SR"]=1,SIDEWAYS=2,VOLATILE=3,LATE=4,OVEREXT=5,
CONFLICT=6,["NO-PA"]=7,["LOW-SCORE"]=8,COOLDOWN=9,["NO-TREND"]=10}
wait_code=make_series();local wcode=(REASON_CODE[WAIT_REASON]or 0)*WAIT_SIDE;wait_code:set(wcode)
WAIT_NEW=wcode~=0 and wcode~=num(wait_code[1],0)
input_group{"Display - Lines",
show_ema=input{default=true,type=input.plot_visibility},ema_f_color=input{default="#FFD54F",type=input.color},
ema_m_color=input{default="#29B6F6",type=input.color},ema_s_color=input{default="#AB47BC",type=input.color},
show_sr=input{default=true,type=input.plot_visibility},res_color=input{default=rgba(255,82,82,0.85),type=input.color},
sup_color=input{default=rgba(0,230,118,0.85),type=input.color},show_range=input{default=false,type=input.plot_visibility},
range_color=input{default=rgba(255,255,255,0.35),type=input.color},show_bb=input{default=false,type=input.plot_visibility},
bb_color=input{default=rgba(120,144,156,0.6),type=input.color}
}
input_group{"Display - Signals",
call_color=input{default="#00E676",type=input.color},put_color=input{default="#FF1744",type=input.color},
show_trigger=input{default=true,type=input.plot_visibility},show_cancel=input{default=true,type=input.plot_visibility},
show_cancel_m=input{default=false,type=input.plot_visibility},cancel_color=input{default=rgba(255,193,7,0.9),type=input.color},
chase_color=input{default="#FF9100",type=input.color}
}
if show_ema then
plot(ema_f,"EMA 9",ema_f_color,1);plot(ema_m,"EMA 21",ema_m_color,2);plot(ema_s,"EMA 50",ema_s_color,2)
end
if show_sr then
plot(res_lvl,"Resistance",res_color,2);plot(sup_lvl,"Support",sup_color,2)
end
if show_range then
plot(rng_hi,"Range High",range_color,1);plot(rng_lo,"Range Low",range_color,1)
end
if show_bb then
plot(bb_up,"BB Upper",bb_color,1);plot(bb_lo,"BB Lower",bb_color,1)
end
local call_on=SIG_DIR==1;local put_on=SIG_DIR==-1
plot_shape(call_on and SIG_SCORE>=85,"CALL Strong",shape_style.arrowup,shape_size.huge,call_color,shape_location.belowbar,0,"CALL 85+",call_color)
plot_shape(call_on and SIG_SCORE>=70 and SIG_SCORE<85,"CALL Good",shape_style.arrowup,shape_size.large,call_color,shape_location.belowbar,0,"CALL 70+",call_color)
plot_shape(call_on and SIG_SCORE<70,"CALL Weak",shape_style.arrowup,shape_size.normal,call_color,shape_location.belowbar,0,"CALL 60+",call_color)
plot_shape(put_on and SIG_SCORE>=85,"PUT Strong",shape_style.arrowdown,shape_size.huge,put_color,shape_location.abovebar,0,"PUT 85+",put_color)
plot_shape(put_on and SIG_SCORE>=70 and SIG_SCORE<85,"PUT Good",shape_style.arrowdown,shape_size.large,put_color,shape_location.abovebar,0,"PUT 70+",put_color)
plot_shape(put_on and SIG_SCORE<70,"PUT Weak",shape_style.arrowdown,shape_size.normal,put_color,shape_location.abovebar,0,"PUT 60+",put_color)
if show_trigger then
plot_shape(call_on and SIG_TRIG=="ENGULF","CALL Engulfing",shape_style.circle,shape_size.tiny,call_color,shape_location.belowbar,-1,"ENGULF",call_color)
plot_shape(call_on and SIG_TRIG=="FALSE-BRK","CALL False BO",shape_style.circle,shape_size.tiny,call_color,shape_location.belowbar,-1,"FALSE-BRK",call_color)
plot_shape(call_on and SIG_TRIG=="PIN","CALL Pin Bar",shape_style.circle,shape_size.tiny,call_color,shape_location.belowbar,-1,"PIN",call_color)
plot_shape(call_on and SIG_TRIG=="REJECT","CALL Rejection",shape_style.circle,shape_size.tiny,call_color,shape_location.belowbar,-1,"REJECT",call_color)
plot_shape(call_on and SIG_TRIG=="BREAKOUT","CALL Breakout",shape_style.circle,shape_size.tiny,call_color,shape_location.belowbar,-1,"BREAKOUT",call_color)
plot_shape(call_on and SIG_TRIG=="MOMENTUM","CALL Momentum",shape_style.circle,shape_size.tiny,call_color,shape_location.belowbar,-1,"MOMENTUM",call_color)
plot_shape(put_on and SIG_TRIG=="ENGULF","PUT Engulfing",shape_style.circle,shape_size.tiny,put_color,shape_location.abovebar,-1,"ENGULF",put_color)
plot_shape(put_on and SIG_TRIG=="FALSE-BRK","PUT False BO",shape_style.circle,shape_size.tiny,put_color,shape_location.abovebar,-1,"FALSE-BRK",put_color)
plot_shape(put_on and SIG_TRIG=="PIN","PUT Pin Bar",shape_style.circle,shape_size.tiny,put_color,shape_location.abovebar,-1,"PIN",put_color)
plot_shape(put_on and SIG_TRIG=="REJECT","PUT Rejection",shape_style.circle,shape_size.tiny,put_color,shape_location.abovebar,-1,"REJECT",put_color)
plot_shape(put_on and SIG_TRIG=="BREAKOUT","PUT Breakout",shape_style.circle,shape_size.tiny,put_color,shape_location.abovebar,-1,"BREAKOUT",put_color)
plot_shape(put_on and SIG_TRIG=="MOMENTUM","PUT Momentum",shape_style.circle,shape_size.tiny,put_color,shape_location.abovebar,-1,"MOMENTUM",put_color)
end
plot_shape(call_on and NO_CHASE,"CALL No Chase",shape_style.xcross,shape_size.small,chase_color,shape_location.abovebar,0,"NO CHASE",chase_color)
plot_shape(put_on and NO_CHASE,"PUT No Chase",shape_style.xcross,shape_size.small,chase_color,shape_location.belowbar,0,"NO CHASE",chase_color)
local cb=WAIT_NEW and WAIT_SIDE==1;local cs=WAIT_NEW and WAIT_SIDE==-1
if show_cancel_m then
plot_shape(cb and WAIT_REASON=="OVEREXT","WAIT CALL overextended",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.belowbar,0,"X:RSI",cancel_color)
plot_shape(cb and WAIT_REASON=="CONFLICT","WAIT CALL conflict",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.belowbar,0,"X:CONF",cancel_color)
plot_shape(cs and WAIT_REASON=="OVEREXT","WAIT PUT overextended",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.abovebar,0,"X:RSI",cancel_color)
plot_shape(cs and WAIT_REASON=="CONFLICT","WAIT PUT conflict",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.abovebar,0,"X:CONF",cancel_color)
end
if show_cancel then
plot_shape(cb and WAIT_REASON=="NEAR-SR","WAIT CALL near S/R",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.belowbar,0,"X:SR",cancel_color)
plot_shape(cb and WAIT_REASON=="SIDEWAYS","WAIT CALL sideways",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.belowbar,0,"X:SIDE",cancel_color)
plot_shape(cb and WAIT_REASON=="VOLATILE","WAIT CALL volatility",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.belowbar,0,"X:VOL",cancel_color)
plot_shape(cb and WAIT_REASON=="LATE","WAIT CALL late",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.belowbar,0,"X:LATE",cancel_color)
plot_shape(cs and WAIT_REASON=="NEAR-SR","WAIT PUT near S/R",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.abovebar,0,"X:SR",cancel_color)
plot_shape(cs and WAIT_REASON=="SIDEWAYS","WAIT PUT sideways",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.abovebar,0,"X:SIDE",cancel_color)
plot_shape(cs and WAIT_REASON=="VOLATILE","WAIT PUT volatility",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.abovebar,0,"X:VOL",cancel_color)
plot_shape(cs and WAIT_REASON=="LATE","WAIT PUT late",shape_style.xcross,shape_size.tiny,cancel_color,shape_location.abovebar,0,"X:LATE",cancel_color)
end
