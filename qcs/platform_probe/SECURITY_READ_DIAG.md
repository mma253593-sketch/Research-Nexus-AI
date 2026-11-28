# Security Read Diagnostic (TASK 03B)

`security_read_diag.lua` เป็นสคริปต์แยกสำหรับหาว่าทำไม `security()` ของ M5/M15 จึงคืนค่า NaN บน IQ Option และมีวิธีอ่านราคาจริงที่รองรับหรือไม่
**ไม่ใช่ Indicator สำหรับเทรด** ไม่มีข้อมูลจำลอง ไม่สร้าง M5/M15 จาก M1 และไม่ใช้ `resolution` ตัดสินผล

## 1. API และ field ที่ตรวจ

| สิ่งที่ตรวจ | วิธีตรวจ | ที่มา |
|---|---|---|
| `security(current_ticker_id, "1m"/"5m"/"15m")` | เรียกใน `pcall` แล้วบันทึก `type()` ของผล (ไม่สมมติว่าเป็น table) | เอกสาร: security |
| field `close, open, high, low, volume, open_time, close_time` | อ่าน `result[field]` ใน `pcall` และบันทึก `type()` ทีละ field | เอกสาร: security (รายการ field) |
| เป็น series หรือไม่ | `is_series(field)` | เอกสาร: is_series |
| ค่าปัจจุบัน | `get_value(field)` แล้วแยกเป็น NUM / NAN / NIL / OTH / ERR | เอกสาร: get_value |
| ค่าย้อนหลัง 1 | `get_value(field[1])` แยกแบบเดียวกัน | เอกสาร: series indexing |
| เปลี่ยนเมื่อขึ้นแท่งใหม่หรือไม่ | เทียบ close[0] และ open_time[0] กับค่าของแท่ง M1 ก่อนหน้า (เก็บใน `make_series`) | เอกสาร: make_series |
| จำนวนแท่งที่อ่าน close ได้ | นับแท่งที่ close[0] เป็นตัวเลข เทียบกับจำนวนแท่งทั้งหมด | — |

## 2. ผลตรวจในเครื่องพัฒนา (แยกจากผลบน IQ Option)

| การตรวจ | ผล |
|---|---|
| `luac5.3 -p security_read_diag.lua` | ผ่าน |
| ขนาดไฟล์ | ดูในข้อความส่งงาน (ต่ำกว่า 25,000 ตัวอักษร) |
| Mock runtime (Lua stub ไม่ใช่ QCS, จำลอง 120–330 แท่ง) 5 กรณี: security คืน table ตัวเลขปกติ / คืน series ที่เป็น NaN และขาดบาง field / คืน nil / error / คืนตัวเลข | ทุกกรณีรันจบไม่มี Lua error และข้อความบนกราฟออกมาตรงกับกรณี เช่น `5M R=TBL C:TBL/Y/NAN/NAN O:NIL/NA/NIL/NIL` |

**Mock ตรวจได้แค่ว่าโค้ดของสคริปต์ไม่พังและแสดงผลตรงกับข้อมูลที่ป้อนเข้าไป ไม่ได้บอกพฤติกรรมของ IQ Option**

## 3. วิธีตั้งค่าบน IQ Option Mobile

1. บัญชี Demo, สินทรัพย์ ทองคำ DIGITAL, กราฟ **1m**
2. ลบสคริปต์ทดสอบตัวเก่าออกจากกราฟ แล้วเพิ่ม `security_read_diag.lua` (วางโค้ดทั้งไฟล์)
3. ข้อความจะเขียนบนหน้าต่างล่างทีละตัวอักษร ห่างกัน `Bars per character` แท่ง (ค่าเริ่มต้น 2) หนึ่งบรรทัดวนซ้ำทุก 200 แท่ง ถ้าตัวอักษรซ้อนกันให้ซูมกราฟเข้า หรือเพิ่มค่านี้เป็น 3–4
4. Settings:
   - `TF`: 1 = 1m, 2 = 5m, 3 = 15m
   - `Show`: 1 = Types A, 2 = Types B, 3 = Prices, 4 = Times, 5 = Lines
5. ถ่ายภาพให้อ่านบรรทัดเต็มได้ สำหรับ **TF = 2 และ TF = 3 ทุกโหมด 1–4** (รวม 8 ภาพ) ถ้ามีเวลา ให้ถ่าย TF = 1 ไว้เทียบด้วย

## 4. วิธีอ่านผล

| โหมด | ตัวอย่างบรรทัด | ความหมาย |
|---|---|---|
| 1 Types A | `5M R=TBL C:TBL/Y/NAN/NAN O:... H:... L:...` | `R=` ชนิดของผลจาก security; `C:` = close → ชนิด field / is_series / ค่า [0] / ค่า [1] |
| 2 Types B | `5M V:... OT:... CT:... OK=0/200` | volume, open_time, close_time แบบเดียวกัน; `OK=` แท่งที่อ่าน close ได้ / แท่งทั้งหมด |
| 3 Prices | `5M C0=3673.66250 C1=... H0=... L0=...` | ราคาดิบ ถ้าอ่านไม่ได้จะเป็น NAN / NIL / OTH / ERR |
| 4 Times | `5M OT0=... OT1=... CT0=... CC=Y OTC=N` | เวลาเปิด/ปิดดิบ; `CC` close[0] เปลี่ยนจากแท่งก่อน; `OTC` open_time[0] เปลี่ยน |
| 5 Lines | เส้นราคา | close[0], close[1], high[0], low[0] ของ TF ที่เลือก เทียบกับ close ของกราฟ (เส้นขาดหาย = ไม่ใช่ตัวเลข) |

รหัส: ชนิด `TBL` table, `UD` userdata, `NIL`, `NUM`, `STR`, `FN`, `BOOL`, `OTH`, `ERR`; ค่า `NUM`, `NAN`, `NIL`, `OTH`, `ERR`; is_series `Y`, `N`, `ERR`, `NA` (ไม่มี field ให้ตรวจ)

ตัวช่วยตีความ (ยังไม่ใช่ข้อสรุป):
- `R=NIL` หรือ `R=ERR`: security ใช้กับ TF นี้ไม่ได้
- `C:NIL/...`: ไม่มี field close
- `C:TBL/Y/NAN/NAN` และ `OK=0/...`: มี series แต่ไม่มีข้อมูลเลยทุกแท่ง (ข้อมูล TF นี้ไม่ถูกโหลด หรือไม่รองรับ)
- `OK=` มากกว่า 0 แต่น้อยกว่าทั้งหมด: มีข้อมูลบางช่วง (เช่น เฉพาะแท่งล่าสุด หรือเฉพาะช่วงที่โหลดแล้ว)
- 1m เป็น NUM แต่ 5m/15m เป็น NAN: ปัญหาเฉพาะ TF ที่ต่างจากกราฟ

ผลที่ได้จะนำไปปิดตารางด้านล่าง

## 5. ตารางสรุป M1/M5/M15 (ผลจริงบน IQ Option, 2026-11-27/28)

ทดสอบบนแอปมือถือ (ทองคำ DIGITAL, XAUUSD OTC) และเว็บบนคอมพิวเตอร์ (XAUUSD OTC, Google OTC) บัญชี Demo

| Field | M1 | M5 | M15 |
|---|---|---|---|
| ผลของ security (`R=`) | ไม่ได้ถ่ายภาพ | TBL (ไม่ error) | ไม่ error (จาก resolution_diag) |
| close: ชนิด / is_series / [0] / [1] | table (จาก Show 6) / ไม่ได้ตรวจ | TBL / N / NIL / NIL | table (จาก Show 6) / ไม่ได้ตรวจ |
| open, high, low | ไม่ได้ตรวจ | TBL / N / NIL / NIL ทุกตัว | ไม่ได้ตรวจ |
| volume, open_time, close_time | ไม่ได้ตรวจ | ไม่ได้ตรวจ (resolution_diag: close หรือ open_time ไม่ใช่ตัวเลข) | เหมือน M5 |
| ข้างใน close (Show 6) | N=1, MT=Y, K=NUM, [1]=OTH | N=1, MT=Y, K=NUM/STR, [1]=OTH | N=1, MT=Y, K=STR, [1]=OTH |
| metatable ของ close (Show 9) | — | `__le __index __tostring __lt __sub __call __eq __unm` (ฟังก์ชัน) และอื่น ๆ | — |

**close ของกราฟเอง (Show 11)**: table, `is_series` = **N**, `#` = 0, มี key `resolution`, `data_provider` (ฟังก์ชัน), `get_current_...` (ฟังก์ชัน) แต่ `get_value(close)` อ่านราคาได้ปกติ

**ข้อสรุปจากหลักฐาน**
1. `is_series()` ตอบ N แม้กับ series ของกราฟที่ใช้งานได้ จึงใช้แยก series ไม่ได้บนแพลตฟอร์มนี้
2. `security()` คืนวัตถุ series แบบเดียวกับของกราฟ แต่ `get_value` ได้ nil ทั้ง [0] และ [1] คือ **ไม่มีข้อมูลราคา M5/M15 ให้อ่านด้วยวิธีที่มีในเอกสาร**
3. `resolution` เป็นตัวเลข ไม่ใช่ข้อความตามเอกสาร
4. ราคาและเวลาของกราฟ (M1) อ่านได้เป็นตัวเลข

**ห้ามสรุปว่า MTF ผ่าน** จนกว่า M5/M15 close จะเป็น NUM จริงบน IQ Option และผ่าน Test Plan เดิม (T1–T6)
