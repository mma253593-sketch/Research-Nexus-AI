# QCS `security()` Platform Probe (TASK 03)

สคริปต์ทดสอบขนาดเล็กสำหรับพิสูจน์ว่า `security()` ของ Quadcode Script (QCS) ทำงานอย่างไรบน IQ Option จริง
ใช้เป็นหลักฐานก่อนออกแบบ Weighted Multi-Timeframe ใน XAUUSD Intelligence Engine V2

> **ไม่ใช่ Indicator สำหรับเทรด** ไม่มีสัญญาณ CALL/PUT และไม่ใช่ส่วนหนึ่งของ V2
> ห้ามนำผลจาก mock หรือข้อมูลจำลองมาสรุปว่า Anti-Repaint ผ่าน ต้องใช้ผลจาก IQ Option จริงเท่านั้น

## ไฟล์

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `security_probe_main.lua` | สคริปต์ Probe สำหรับวางใน IQ Option (15,016 ตัวอักษร, เพดาน 25,000) |
| `README.md` | ไฟล์นี้: วิธีติดตั้ง, วิธีอ่านค่า, ตาราง API Verification, สิ่งที่ยังยืนยันไม่ได้ |
| `SECURITY_PROBE_TEST_PLAN.md` | ขั้นตอนทดสอบ 7 ชุด (T0–T6) พร้อมวิธีบันทึกภาพหน้าจอและเวลา |

ไม่มีการแก้ไข `qcs/v1`, `qcs/archive/v2`, `qcs/v2_rebuild` หรือไฟล์อื่นนอกโฟลเดอร์นี้

---

## 1. ติดตั้งบน IQ Option

1. ใช้ **บัญชี Demo** เปิดกราฟ **XAUUSD** และตั้ง Timeframe ของกราฟเป็น **1 นาที (M1)**
2. เปิดเมนู Indicators → Scripts แล้วเลือก **Add manually** (หรือ **Import Script** แล้วเลือกไฟล์ `.lua`/`.txt` ตามหน้า Script Options ในเอกสาร QCS)
3. ลบโค้ดตัวอย่างในหน้าต่าง editor ออกทั้งหมด แล้ววางโค้ดจาก `security_probe_main.lua` ทั้งไฟล์
4. กด Save แล้วเพิ่มลงกราฟ (Add to chart) Probe จะแสดงในหน้าต่างแยกด้านล่างกราฟ (`overlay = false`)
5. ถ้าเห็นข้อความ error ตอน Save หรือตอนเพิ่มลงกราฟ ให้ถ่ายภาพหน้าจอทั้งข้อความ นี่คือผลการทดสอบ T0 (ดู Test Plan) ห้ามแก้โค้ดเองเพื่อให้ผ่าน

> ชื่อเมนูข้างบนมาจาก README เดิมของโปรเจกต์และหน้า Script Options ในเอกสาร QCS ชื่อจริงบนหน้าจออาจต่างเล็กน้อย

## 2. Settings

| Setting | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `View 1=Price 2=Timing 3=Status 4=RSI 5=RawTime` | 1 | เลือกชุดเส้นที่จะแสดง (สเกลต่างกันมาก จึงแยกเป็นมุมมอง) |
| `EMA length on HTF series` | 21 | ความยาว EMA ที่คำนวณบน `security(...).close` |
| `RSI length on HTF series` | 14 | ความยาว RSI ที่คำนวณบน `security(...).close` |
| `Print log 1=on 0=off` | 0 | เขียนค่าลง script log ด้วย `print()` ทุกครั้งที่สคริปต์รัน (ทุกแท่งและอาจทุก tick) เปิดเฉพาะตอนต้องการคัดลอกค่า |

การเปลี่ยน View ไม่เปลี่ยนการคำนวณ ทุกค่าคำนวณทุกครั้ง แค่เลือกว่าจะ plot เส้นไหน
ค่าในแต่ละแท่งอ่านได้จาก legend/ค่าที่แสดงตอนเลื่อน crosshair ไปที่แท่งนั้น (การแสดง legend ของ IQ Option ยังไม่ยืนยัน ดู §6)

## 3. สิ่งที่ Probe อ่าน

Probe เรียก `security(current_ticker_id, res)` 3 ครั้งทุกครั้งที่สคริปต์รัน: `"1m"`, `"5m"`, `"15m"` แล้วอ่าน field `close`, `open_time`, `close_time` ที่ index `[0]` (ค่าปัจจุบันผ่าน `get_value(series)`) และ `[1]` (ผ่าน `get_value(series[1])`)

**index ในที่นี้คือ index ที่สคริปต์ได้รับบนแท่ง M1 ของกราฟ** ยังไม่รู้ว่า `[1]` ของ series จาก `security()` หมายถึง "แท่ง M1 ก่อนหน้า" หรือ "แท่ง M5 ก่อนหน้า" นี่คือคำถามหลักที่ต้องทดสอบ (T3)

### View 1 — Price

| เส้น | ที่มา |
|---|---|
| `Chart M1 Close` | `close` ของกราฟเอง (built-in series) |
| `SEC 1m Close[0]` | `security(current_ticker_id,"1m").close` (ควรเท่ากับเส้นบน) |
| `M5 Close[0]`, `M5 Close[1]` | `security(current_ticker_id,"5m").close` ที่ `[0]`, `[1]` |
| `M15 Close[0]`, `M15 Close[1]` | `security(current_ticker_id,"15m").close` ที่ `[0]`, `[1]` |
| `EMA on M5`, `EMA on M15` | `ema(security(...).close, EMA length)` ถ้า `ema` เรียกใช้ได้ |

### View 2 — Timing (หน่วยเดียวกับ timestamp ถ้าเป็นวินาทีจะเป็นตัวเลขด้านล่าง)

| เส้น | สูตร | ค่าที่คาดถ้า M5/M15 ตรงกับกรอบเวลาจริงและ timestamp เป็นวินาที |
|---|---|---|
| `M5 phase` | `open_time(กราฟ) − M5 open_time[0]` | 0, 60, 120, 180, 240 วนซ้ำ (ติดลบ = ข้อมูลอนาคต) |
| `M5 dur` | `M5 close_time[0] − M5 open_time[0]` | 300 (หรือ 299 ถ้า close_time เป็นวินาทีสุดท้าย) |
| `M5 step` | `M5 open_time[0] − M5 open_time[1]` | **0** ถ้า `[1]` = แท่ง M1 ก่อนหน้า (ยกเว้นตอนขึ้นแท่ง M5 ใหม่ = 300) / **300 ทุกแท่ง** ถ้า `[1]` = แท่ง M5 ก่อนหน้า |
| `M5 ot0 mod 300` | `M5 open_time[0] % 300` | 0 |
| `M15 ...` | เหมือนกันแต่เป็น 900 | phase 0–840, dur 900, step 0/900, mod 0 |

### View 3 — Status และ Flags

รหัสสถานะ (`ST ...`): `1` OK, `0` NOT READY (เรียกได้แต่ไม่มีค่าบนแท่งนี้), `-1` ERROR (เรียกแล้ว error หรือคืน nil), `-2` UNSUPPORTED (ไม่มีฟังก์ชันหรือ field นั้น) — เมื่อไม่ใช่ 1 เส้นค่าที่เกี่ยวข้องใน View อื่นจะเว้นว่าง (NaN) ไม่ใช่ค่าแทน

Flags (`F ...`) มีค่า 1/0 (ว่าง = อ่านค่าไม่ได้):

| Flag | หมายถึง |
|---|---|
| `F 1m C0=Chart` | close จาก `security("1m")` เท่ากับ close ของกราฟ |
| `F M5 C0=Chart`, `F M15 C0=Chart` | close[0] ของ HTF เท่ากับ close ของแท่ง M1 นี้ ใช้ตรวจ repaint ของข้อมูลย้อนหลัง (T5) |
| `F M5 lookahead`, `F M15 lookahead` | open_time[0] ของ HTF มากกว่า open_time ของแท่ง M1 = แท่งนี้เห็นข้อมูลอนาคต **ต้องเป็น 0 เสมอ** |
| `F M5 new bar`, `F M15 new bar` | open_time[0] ของ HTF ต่างจากแท่ง M1 ก่อนหน้า = เริ่มแท่ง HTF ใหม่ |
| `F M5 C1 changed`, `F M15 C1 changed` | close[1] ต่างจากแท่ง M1 ก่อนหน้า ทั้งที่ยังไม่ขึ้นแท่ง HTF ใหม่ |

### View 4 — RSI

`RSI on M5`, `RSI on M15` = `rsi(security(...).close, RSI length)` ถ้า `rsi` เรียกใช้ได้

### View 5 — Raw Time

timestamp ดิบ: open/close_time ของกราฟ, M5 open_time[0], open_time[1], close_time[0] และ M15 เช่นเดียวกัน ใช้แปลงเป็นเวลาจริงด้วยเครื่องมือ UNIX time เพื่อยืนยันหน่วย (วินาทีหรือมิลลิวินาที) และ timezone

### Markers (แสดงทุก View)

| ข้อความ | ตำแหน่ง | ความหมาย |
|---|---|---|
| `NOT M1` | บน | ตัวแปร `resolution` ไม่ใช่ `"1m"` (หรือไม่ใช่ string) |
| `M5 ERR`, `M5 UNSUP`, `M15 ERR`, `M15 UNSUP` | บน | `security()` ของ TF นั้นใช้ไม่ได้ |
| `EMA5 X` | บน | `ema` บน M5 error หรือไม่มีฟังก์ชัน |
| `LA5`, `LA15` | บน | lookahead (ข้อมูลอนาคต) |
| `C1CHG5`, `C1CHG15` | บน | close[1] เปลี่ยนโดยไม่ขึ้นแท่ง HTF ใหม่ |
| `N5`, `N15` | ล่าง | ขึ้นแท่ง M5 / M15 ใหม่ |

---

## 4. ตาราง API Verification

แหล่ง: https://quadcode-tech.github.io/quadcodescript-docs (อ่านเมื่อ 2026-11-27) และไฟล์ตัวอย่างใน quadcodescript-library

สถานะ:
- **ยืนยันจากเอกสาร** = มีหน้าเอกสารระบุ syntax/ความหมายนี้
- **ยังไม่ยืนยัน** = เอกสารพูดถึงไม่ครบหรือไม่พูดถึง
- **ต้องทดสอบบน IQ Option** = ตอบได้จากการรัน Probe บนแพลตฟอร์มจริงเท่านั้น (Test ที่ใช้อยู่ในวงเล็บ)

| API / พฤติกรรม | เอกสารบอกอะไร | สถานะ |
|---|---|---|
| `security(ticker_id, resolution)` | คืน "a table with series": `close, open, high, low, volume, open_time, close_time` ตัวอย่าง `security(current_ticker_id, "5s")` | ยืนยันจากเอกสาร (syntax และ field) |
| `security` รับ `"5m"`, `"15m"` | หน้า `resolution` ให้รายการ `"1m","5m","15m",...`; หน้า `security` บอกว่า parameter เป็น "timeframe resolution" แต่ตัวอย่างใช้แค่ `"5s"` | ยังไม่ยืนยัน → ต้องทดสอบ (T0) |
| `current_ticker_id` | ตัวแปร integer ID ของ asset ที่ indicator รันอยู่ | ยืนยันจากเอกสาร |
| `get_ticker_id(ticker)` | คืน ID หรือ nil (Probe ไม่ใช้) | ยืนยันจากเอกสาร |
| `resolution` | ตัวแปร string เช่น `"1m"` (แต่ Syntax Format เขียนเป็น `resolution("10m")` ขัดกันเอง) | ยังไม่ยืนยันว่าเป็นตัวแปรหรือฟังก์ชัน → Probe ตรวจ `type(resolution)=="string"` (T0) |
| Series indexing `x[1]` | `close[1]` = แท่งที่ปิดก่อนหน้า, `close[2]` = 2 แท่งก่อน (หน้า built-in types) | ยืนยันจากเอกสาร **สำหรับ series ของกราฟ** |
| index ของ series จาก `security()` | เอกสารไม่บอกว่า `[1]` นับตามแท่งของกราฟหรือแท่งของ resolution ที่ขอ | ต้องทดสอบ (T3) |
| `[0]` ของแท่ง HTF ที่ยังไม่ปิด | เอกสารไม่บอกว่าเป็นค่ากำลังก่อตัว (live) หรือค่าแท่งที่ปิดล่าสุด | ต้องทดสอบ (T1, T2, T4) |
| `open_time`, `close_time` | built-in series "UNIX time" (series int) ของกราฟ; field เดียวกันมีใน table ของ `security` | ยืนยันจากเอกสาร (ชื่อและความหมาย) |
| หน่วยและ timezone ของ timestamp | "UNIX time"; ตัวอย่าง `date(1740574860)` เป็นวินาที | หน่วยวินาที **น่าจะใช่** แต่ต้องทดสอบ (T6) |
| `close_time` = เริ่มแท่งถัดไป หรือ วินาทีสุดท้าย | ไม่ระบุ | ต้องทดสอบ (T6) |
| HTF แท่งตรงกับกรอบเวลาจริง (:00/:05/:15) | ไม่ระบุ | ต้องทดสอบ (T6) |
| ข้อมูลย้อนหลังเปลี่ยน (repaint) | ไม่ระบุ | ต้องทดสอบ (T4, T5) |
| `get_value(x[, default])` | คืนค่า x ที่แท่งปัจจุบัน | ยืนยันจากเอกสาร |
| `make_series()` + `:set()` | สร้าง series และตั้งค่าแท่งปัจจุบัน | ยืนยันจากเอกสาร |
| `conditional(x)` | แปลง boolean เป็น series[boolean] | ยืนยันจากเอกสาร |
| `ema(source, period)` | อยู่ใน Popular Indicators Library ตัวอย่างเรียก `ema(sourceSeries, period)` ตรง ๆ | ยืนยัน syntax; **การใช้กับ series จาก `security()` ยังไม่ยืนยัน** → ต้องทดสอบ (T0) |
| `rsi(series, period)` | อยู่ใน Library แต่ตัวอย่างคำนวณเองจาก `averages[fn]` ไม่ได้เรียก `rsi()` | ยังไม่ยืนยันว่าเป็น built-in → ต้องทดสอบ (T0) |
| ความหมายของ EMA บน series จาก `security()` | ถ้า series เรียงตามแท่ง M1 (ดู T3) EMA จะนับทุกแท่ง M1 ไม่ใช่ EMA ของ M5 จริง | ต้องทดสอบ (T3) แล้วตีความ |
| `plot(series, name, color, width)` | ยืนยันจากเอกสาร | ยืนยันจากเอกสาร |
| `plot_shape(series, name, style, size, color, location, offset, text, text_color)` | ตารางพารามิเตอร์ตามลำดับนี้ | ยืนยันจากเอกสาร (บรรทัด "Syntax Format" ในหน้าเขียนต่างไป) |
| `input(default, name, input.integer, min, max)` ใน `input_group{}` | ตัวอย่างใน RMA/RSI/EMA | ยืนยันจากตัวอย่างในเอกสาร |
| `instrument{ name, short_name, overlay }` | ยืนยันจากเอกสาร (`short_name` มาจากตัวอย่าง EMA) | ยืนยันจากเอกสาร |
| `print(...)` | เขียนลง "script log" | ยืนยันจากเอกสาร; **ตำแหน่งของ log บน IQ Option ยังไม่ยืนยัน** |
| `pcall`, `tostring`, `math.abs`, `%` | Lua 5.3 มาตรฐาน; เอกสารบอกว่า QCS "supports most of the Lua language features" | ยังไม่ยืนยันว่าทุกตัวเปิดให้ใช้ → ต้องทดสอบ (T0) |
| `security` เรียกได้กี่ครั้ง / ใช้ CPU เท่าไร | ไม่ระบุ | ต้องทดสอบ (T0) |

## 5. วิธีที่ Probe จัดการกรณีใช้ไม่ได้

- ไม่มี `security` → `UNSUPPORTED (-2)`; `current_ticker_id` เป็น nil หรือ `security()` error/คืน nil → `ERROR (-1)`
- ไม่มี field `close`/`open_time`/`close_time` → `UNSUPPORTED (-2)`
- ค่าบนแท่งเป็น nil หรือ NaN → `NOT READY (0)` และเส้นเว้นว่าง
- ไม่มี `ema`/`rsi` → `UNSUPPORTED`; เรียกแล้ว error → `ERROR`
- ถ้าแพลตฟอร์มไม่มี `pcall` Probe จะเรียกฟังก์ชันตรง ๆ และ error ใด ๆ จะหยุดสคริปต์ทั้งตัว ให้บันทึกข้อความ error นั้นเป็นผล T0
- Probe **ไม่เคย**แทนค่าที่หายด้วยตัวเลขอื่น

## 6. สิ่งที่ยังยืนยันไม่ได้ (ต้องได้ผลจาก IQ Option จริง)

1. `security()` รับ `"5m"` และ `"15m"` ได้หรือไม่ (เอกสารมีตัวอย่างแค่ `"5s"`)
2. index `[1]` ของ series จาก `security()` นับตามแท่ง M1 ของกราฟหรือแท่ง M5/M15
3. `[0]` ของ M5/M15 ระหว่างแท่งยังไม่ปิด เป็นค่ากำลังก่อตัว (เปลี่ยนทุก tick) หรือค่าแท่งที่ปิดล่าสุด
4. แท่ง HTF ที่ปิดแล้ว (`[1]`) คงที่จริงหรือไม่ ทั้งระหว่าง tick และหลัง reload
5. ข้อมูลย้อนหลังที่โหลดใหม่ ตรงกับค่าที่เห็นตอน real-time หรือไม่ (repaint ย้อนหลัง)
6. หน่วย (วินาที/มิลลิวินาที) และ timezone ของ `open_time`/`close_time`; `close_time` คือวินาทีสุดท้ายหรือเริ่มแท่งถัดไป
7. แท่ง M5/M15 เริ่มที่นาที :00/:05/:10/:15 ตามนาฬิกาจริงหรือไม่ และตรงกับกราฟ M5/M15 ของ IQ Option หรือไม่
8. `ema()` / `rsi()` ใช้กับ series จาก `security()` ได้หรือไม่ และผลเป็น EMA ของแท่ง HTF หรือของแท่ง M1
9. ตัวแปร `resolution` เป็น string หรือเป็นฟังก์ชัน
10. `pcall` ใช้ได้ใน QCS หรือไม่
11. IQ Option แสดงค่า plot ใน legend/crosshair ให้อ่านรายแท่งได้หรือไม่ และ `print()` ไปแสดงที่ไหน
12. ขีดจำกัด: จำนวน plot (Probe ใช้สูงสุด 16 เส้นใน View 3 + 12 markers), จำนวนการเรียก `security()`, CPU ต่อแท่ง, ความยาว history ของ M5/M15
13. พฤติกรรมเมื่อตลาดปิด/มี gap (เช่น ช่วงปิดตลาดทองคำ) — แท่ง HTF หายหรือซ้ำหรือไม่

## 7. การตรวจที่ทำแล้วในเครื่องพัฒนา

| การตรวจ | ผล | ความหมาย |
|---|---|---|
| `luac5.3 -p security_probe_main.lua` | ผ่าน | Syntax ของ Lua 5.3 ถูกต้อง |
| ขนาดไฟล์ (`utf8` characters) | ดูตัวเลขในตาราง §ไฟล์ | ต่ำกว่า 25,000 |
| รันกับ stub Lua ชั่วคราว (ไม่ได้ commit) 4 กรณี: ทุก API คืนค่า, ไม่มี `security`/`ema`, `security` error, `security` คืน table ว่าง | ไม่มี Lua error, รหัสสถานะออกมาเป็น NOT READY / UNSUPPORTED / ERROR ตามกรณี | **ตรวจแค่ว่าโค้ด Lua ของ Probe ไม่พังเอง** ไม่ได้บอกอะไรเกี่ยวกับพฤติกรรมของ QCS หรือ IQ Option |

**ยังไม่เคยรันบน IQ Option** ทุกข้อใน §6 จึงยังเปิดอยู่ ห้ามเปิดใช้ MTF ในระบบเทรดจริงจนกว่าผล Test Plan จะผ่าน
