# แนวทางใช้ Agent พัฒนา TripPocket

## ขอบเขต

เอกสารนี้ช่วยให้ agent ทำงานต่อจากแผนเดียวกัน งานปัจจุบันเป็นการออกแบบเอกสาร ยังไม่ได้สั่ง deploy Firebase หรือเพิ่มระบบนอก MVP

ตัวเลือกที่ผู้ใช้ยืนยันคือ Flutter → Firebase โดยตรง ไม่ต้องสร้าง Go API ให้ Frontend ใช้ Firebase client SDK และตรวจสิทธิ์ด้วย Firestore Rules

อ่าน [AGENTS.md](../AGENTS.md) ก่อน แล้วเลือกเอกสารเฉพาะส่วนจาก [สารบัญ](README.md) ไม่ต้องโหลดทุกไฟล์ทุกครั้ง skill ของโปรเจกต์อยู่ที่ [SKILL.md](skills/trippocket-development/SKILL.md) สามารถสั่งให้อ่านจาก path นี้ได้โดยตรง ไฟล์นี้เก็บอยู่ใน docs ตามที่ผู้ใช้ต้องการ ยังไม่ได้ติดตั้งเป็น global skill หรือรับประกันว่าจะถูกค้นพบอัตโนมัติ

## แบ่งความรับผิดชอบตามงาน

| บทบาทของงาน | พื้นที่หลัก | สิ่งที่ส่งต่อ |
|---|---|---|
| Frontend | app, core/widgets, feature presentation | หน้าจอและ state ที่ต่อกับ repository contract |
| Backend | data repositories, Firebase config, Rules | schema ที่ตรงกันและผล Emulator tests |
| Integration | map, packing, Android configuration | feature ใช้งานจริงและผลบนอุปกรณ์ |
| Review | code, tests, docs | ข้อผิดพลาดที่ทำซ้ำได้และสิ่งที่ยังไม่ตรวจ |

นี่เป็นประเภทงาน ไม่ใช่คำสั่งให้เปิด agent หลายตัว เริ่มด้วย agent เดียวและทำตาม dependency ในแผน หากผู้ใช้ขอทำหลาย agent จึงค่อยแยกไฟล์รับผิดชอบ โดยมีเจ้าของ schema/router/pubspec เพียงหนึ่งงานต่อช่วง

## รูปแบบการรับและส่งต่องาน

ก่อนแก้โค้ดระบุ milestone เป้าหมายและเกณฑ์ตรวจรับ ตรวจว่ามีไฟล์หรือ dependency จริงแล้วหรือไม่ งาน UI อาจใช้ fake ได้ แต่ต้องบอกชัดเมื่อส่วนใดยังไม่ได้ต่อ Firebase

เมื่อจบรายงาน: สิ่งที่เปลี่ยน ไฟล์สำคัญ วิธีตรวจ ผลที่ได้ และสิ่งที่ติดอยู่ อัปเดตเช็กบ็อกซ์เฉพาะงานที่ผ่าน ไม่เขียนว่าแอปพร้อมส่งจากการตรวจ static อย่างเดียว

## ตัวอย่างคำสั่งใช้งาน

### เริ่มโครงแอป

> อ่าน AGENTS.md และ docs/skills/trippocket-development/SKILL.md แล้วทำ P0–P1 จาก docs/IMPLEMENTATION_PLAN.md รักษาเอกสารเดิม ใช้ fake repository สำหรับ UI และรายงานว่าอะไรยังไม่ได้เชื่อมต่อจริง

### ทำระบบสมาชิกและข้อมูล

> ทำ P2–P3 ตาม docs/IMPLEMENTATION_PLAN.md ใช้ schema ใน docs/BACKEND_ARCHITECTURE.md ทดสอบ Rules ด้วย Emulator และพิสูจน์ว่าบัญชี B เข้าถึงทริปของบัญชี A ไม่ได้

### ทำแผนที่และเช็กลิสต์

> ทำ P5–P6 หลังตรวจ dependency ใช้ place picker ในฟอร์มและ packing key แยก uid/tripId ตรวจเงื่อนไข tile provider แล้วทดสอบพิกัดกับ persistence บน Android

### ตรวจพร้อมนำเสนอ

> ตรวจ TripPocket เทียบ Definition of Done ใน docs/IMPLEMENTATION_PLAN.md รัน checks ที่ทำได้ สาธิต CRUD และรายงานบั๊กพร้อมขั้นตอนทำซ้ำ แยกผล Emulator ออกจาก live Firebase และห้ามอ้างผลที่ยังไม่ได้ทดสอบ

## เงื่อนไขที่ต้องรักษา

ฟีเจอร์เพิ่มที่อนุมัติคือ [แชร์แผนเที่ยวเป็นข้อความ](FEATURE_SHARE_PLAN.md) ให้ผู้ใช้เลือกแอปและผู้รับเอง ไม่เพิ่ม collaborative editing หรือ public Firestore access

อ่าน schema และชุดตรวจรับใน [Database Design](DATABASE_DESIGN.md) ก่อนเปลี่ยน model, serialization, query หรือ Rules

เงินใช้สตางค์ วันที่ใช้ YYYY-MM-DD เวลาใช้ timeMinutes พิกัดต้องยืนยัน การลบทริปต้อง cleanup children การเปลี่ยนบัญชีต้อง invalidate state และเช็กลิสต์เป็นข้อมูลเฉพาะเครื่อง หากแก้สัญญาเหล่านี้ให้แก้เอกสารและผู้ใช้งาน contract ที่เกี่ยวข้องพร้อมกัน
