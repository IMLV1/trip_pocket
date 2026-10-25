# Prompts สำหรับพัฒนา TripPocket

วันที่จัดทำ 24 ตุลาคม 2569 สำหรับโปรเจกต์ `C:\Users\GOODK\IdeaProjects\trip_pocket` ซึ่งมี Flutter starter แล้ว ชื่อ Dart package คือ `trip_pocket` และ Android applicationId / iOS bundle ID คือ `com.imlv1.trippocket`

ตรวจ Flutter analyze และ build Android debug ผ่านในวันที่จัดทำ แต่ยังเป็นแอปตัวอย่าง ไม่ใช่หลักฐานว่าฟีเจอร์ MVP หรือ Firebase ทำงานแล้ว ให้ agent ตรวจสถานะล่าสุดก่อนเริ่มทุกครั้ง

## วิธีใช้

เปิดโฟลเดอร์โปรเจกต์นี้เป็น workspace แล้วคัดลอก prompt ที่ต้องการ ใช้ prompt หลักเมื่ออยากให้ทำครบตามลำดับ หรือใช้ prompt รายช่วงเมื่อต้องการตรวจผลงานเป็นส่วน ๆ ข้อความเหล่านี้เป็นคำสั่งสำหรับการใช้งานครั้งต่อไป การบันทึกไฟล์นี้ไม่ได้เริ่ม implementation

แหล่งอ้างอิง: [แผนพัฒนา](IMPLEMENTATION_PLAN.md), [Frontend](FRONTEND_ARCHITECTURE.md), [Backend](BACKEND_ARCHITECTURE.md), [Database](DATABASE_DESIGN.md), [Sharing](FEATURE_SHARE_PLAN.md) และ [Project skill](skills/trippocket-development/SKILL.md)

## 1 Prompt หลักสำหรับทำครบ MVP

```text
ช่วย implement TripPocket ใน C:\Users\GOODK\IdeaProjects\trip_pocket จนได้ MVP ที่ทำงานครบตามเอกสาร ให้ลงมือแก้โค้ดและตรวจผลจริง ไม่หยุดแค่เสนอแผน

เริ่มจากอ่าน AGENTS.md และ docs/skills/trippocket-development/SKILL.md แล้วอ่านเอกสารที่เกี่ยวข้องใน docs ได้แก่ PROJECT_PROPOSAL.md, FRONTEND_ARCHITECTURE.md, BACKEND_ARCHITECTURE.md, DATABASE_DESIGN.md, FEATURE_SHARE_PLAN.md และ IMPLEMENTATION_PLAN.md

ตรวจสถานะไฟล์ Git และ Flutter SDK ก่อนแก้ไข ตอนนี้มี Flutter starter แล้ว ให้ต่อยอดโดยรักษา docs และงานเดิม ห้ามรันคำสั่งสร้างโปรเจกต์ทับโดยไม่ตรวจไฟล์ ชื่อ Dart package คือ trip_pocket ส่วน Android applicationId/namespace และ iOS bundle ID คือ com.imlv1.trippocket ให้คงค่าเหล่านี้ไว้

พัฒนา Android เป็นเป้าหมายหลักด้วย Flutter/Dart, UI ภาษาไทย Material 3, Riverpod แบบไม่ใช้ code generation และ go_router ใช้ Firebase Authentication และ Cloud Firestore ผ่าน client SDK โดยตรง ใช้ flutter_map/latlong2 สำหรับเลือกหมุด SharedPreferences สำหรับเช็กลิสต์ และ share_plus สำหรับแชร์ข้อความ เลือก dependency รุ่นที่เข้ากับ SDK จริงและเก็บ pubspec.lock

ทำฟีเจอร์ให้ครบ:
1. สมัครสมาชิก เข้าสู่ระบบ ออกจากระบบ และตรวจ session ก่อนเปิดหน้าที่มีข้อมูลส่วนตัว
2. CRUD ทริป: ชื่อ จุดหมาย วันเริ่ม วันสิ้นสุด และงบ
3. CRUD กิจกรรม: ชื่อ วัน เวลา หมายเหตุ ค่าใช้จ่าย และหมุดที่ผู้ใช้ยืนยัน
4. แผนรายวันเรียงเวลา พร้อมสรุปงบที่วางแผน คงเหลือ และเกินงบ
5. เช็กลิสต์เตรียมของที่เปิดแอปใหม่แล้วยังอยู่ แยก uid และ tripId
6. แชร์แผนเที่ยวเป็นข้อความผ่าน preview และ native share sheet ตาม FEATURE_SHARE_PLAN.md

ใช้ 6 ประเภทหน้าจอตามเอกสาร create/edit ใช้ฟอร์มร่วมกัน ทำ loading/empty/error/submitting state และ Form Validation ให้ครบ ป้องกันกดบันทึกซ้ำ เก็บ draft เมื่อบันทึกไม่สำเร็จ และรองรับปุ่มย้อนกลับ/คีย์บอร์ดบน Android

ทำตาม schema ใน DATABASE_DESIGN.md: เงินเป็น integer satang, วันที่ YYYY-MM-DD, เวลา timeMinutes, timestamps จาก server, ข้อมูลอยู่ใต้ users/{uid}/trips/{tripId}/activities/{activityId} และยอดรวมคำนวณจากกิจกรรม ไม่เก็บยอดซ้ำ ห้ามลด Security Rules ให้เปิดกว้างเพื่อแก้ปัญหาการเชื่อมต่อ

แยก widget, state/controller และ repository ลบทริปตาม workflow deleting → ลบ children → ลบ parent → cleanup local โดยรองรับ retry ตรวจ cleanup queue ก่อนล้างข้อมูล และ dispose user state/listeners เมื่อเปลี่ยนบัญชี ระบุข้อจำกัด concurrent edits ตามเอกสารอย่างตรงไปตรงมา

เริ่มด้วยการตรวจสิ่งที่มีแล้วและทำ milestone ที่ยังขาดตาม dependency ใน IMPLEMENTATION_PLAN.md หาก Firebase project/config ยังไม่พร้อม ให้ทำ UI ด้วย fake repository ที่ระบุโหมดชัดเจน และทำ Auth/Firestore Emulator integration ต่อได้ ถ้าจำเป็นต้องใช้ข้อมูลจากผู้ใช้ให้ถามเฉพาะสิ่งที่ขาด แล้วทำงานส่วนที่ไม่ขึ้นกับคำตอบต่อ อย่าทำ fallback ไป fake เงียบ ๆ เมื่อ live Firebase ล้มเหลว

ตรวจนโยบาย tile provider, attribution และ caching ก่อนใช้แผนที่จริง ผู้ใช้ต้องเลือกหมุดเองและการยกเลิก picker ต้องไม่เปลี่ยนหมุดเดิม การแชร์ใช้เฉพาะข้อมูลตามเอกสารและให้ผู้ใช้เลือกผู้รับเอง ผลเปิด share sheet ไม่ใช่หลักฐานว่าส่งถึงผู้รับแล้ว

ตรวจด้วย flutter analyze, flutter test, Firebase Emulator Rules tests และ Android integration ตามส่วนที่เปลี่ยน สร้าง debug APK เมื่อพร้อม ทดสอบ owner/user_B/anonymous, เงินและวันที่ผิด, ข้อมูลว่าง, เครือข่ายขัดข้อง, การเปลี่ยนบัญชี และการลบค้าง ระบุว่าอะไรทดสอบบน fake/emulator/live/อุปกรณ์จริงแล้ว ห้ามอ้างผ่านจากการอ่านโค้ดอย่างเดียว

รักษาขอบเขต MVP ไม่เพิ่มระบบจอง ชำระเงิน แชต หรือแก้ไขร่วมกัน ไม่สร้างหรือ deploy live cloud resources และไม่ commit/push อัตโนมัติจาก prompt นี้

ระหว่างทำรายงานความคืบหน้าเป็นภาษาไทย เมื่อเสร็จอัปเดต checklist เฉพาะรายการที่ตรวจผ่าน และเขียน docs/IMPLEMENTATION_STATUS.md ระบุวัน ผลงาน คำสั่งที่ตรวจ ผลทดสอบ วิธีรัน และงานค้าง สรุปสิ่งที่เปลี่ยน หลักฐานการตรวจ และสิ่งที่ยังต้องตั้งค่าหรือทดสอบ
```

## 2 เริ่มเฉพาะโครงแอปและ UI

```text
อ่าน AGENTS.md, docs/skills/trippocket-development/SKILL.md และ FRONTEND_ARCHITECTURE.md แล้วทำ P0–P1 ของ TripPocket ใน workspace ปัจจุบันให้เสร็จตามเกณฑ์ตรวจรับ

มี Flutter starter อยู่แล้ว ให้ตรวจไฟล์และต่อยอด คง Dart package trip_pocket และ applicationId com.imlv1.trippocket สร้างธีม Material 3 ภาษาไทย โครง feature, Riverpod, router และ 6 ประเภทหน้าจอ ใช้ fake repository แบบเลือกโหมดชัดเจนสำหรับทดลอง workflow โดยออกแบบ interface ให้ต่อ Firebase ได้ภายหลัง

ทำฟอร์ม ตรวจข้อมูล state โหลด/ว่าง/ผิดพลาด และตัวอย่างทริปเชียงใหม่ให้เดิน workflow ได้จริง เพิ่ม/แก้ไข/ลบใน fake แล้ว timeline และงบต้องเปลี่ยนตาม ไม่มีปุ่มหลักที่กดแล้วไม่ทำงานโดยไม่บอกเหตุผล ใช้ mock ของแผนที่และ share service เฉพาะช่วงนี้พร้อมระบุว่า native integration ยังไม่เสร็จ

ตรวจ Flutter analyze และ tests ที่มีความหมาย Build Android debug และรายงานผลจริง อัปเดตสถานะ P0–P1 โดยไม่ติ๊กงานที่ยังต้องทดสอบบนอุปกรณ์ ไม่มีการสร้าง cloud resources หรือ push ในงานนี้
```

## 3 ระบบสมาชิกและ Firestore

```text
ทำ P2–P4 ของ TripPocket โดยอ่าน AGENTS.md, Project skill, BACKEND_ARCHITECTURE.md และ DATABASE_DESIGN.md ก่อน ตรวจ UI/repository ที่มีแล้วและเติมส่วนที่ขาดโดยไม่เปลี่ยนสัญญาข้อมูลเงียบ ๆ

เชื่อม Firebase Auth และ Firestore Emulator สำหรับ register/login/logout และ CRUD ทริป/กิจกรรม เขียน Security Rules, indexes และ Emulator tests ตรวจ owner/user_B/anonymous และ payload ที่ไม่ถูกต้องให้ครบ เพิ่ม typed models และ Firestore serialization ที่รองรับ server timestamp ที่ยัง pending

แสดงแผนรายวันและยอดงบจากกิจกรรมจริง ทำ resumable deletion และป้องกันการเปลี่ยนช่วงวันจนกิจกรรมนอกช่วงตามข้อจำกัดในเอกสาร ปรับ provider ให้ผูก uid และยกเลิกข้อมูลเก่าเมื่อ logout

หาก config live ยังไม่มี ให้รายงานสิ่งที่ต้องตั้งค่าและใช้ emulator ต่อ ห้ามอ้างว่า live ผ่านหรือเปลี่ยน Rules เป็น allow-all ทดสอบ analyze/tests, Rules tests และ integration ที่ทำได้ อัปเดต IMPLEMENTATION_STATUS.md พร้อมหลักฐานและงานค้าง ไม่ deploy หรือ push จาก prompt นี้
```

## 4 แผนที่ เช็กลิสต์ และการแชร์

```text
ทำ P5–P6 และ P6A ของ TripPocket ตาม AGENTS.md, Project skill, FRONTEND_ARCHITECTURE.md, DATABASE_DESIGN.md และ FEATURE_SHARE_PLAN.md ตรวจ dependency กับโค้ดเดิมก่อนลงมือ

เชื่อม flutter_map/latlong2 ให้เลือกและยืนยันหมุดได้จริง เปิดแก้ไขได้พิกัดเดิม ยกเลิกแล้วค่าคงเดิม ตรวจนโยบาย tile provider และ attribution ทำ SharedPreferences packing repository แยก uid/tripId พร้อม JSON error handling และ cleanup queue ที่ไม่ล้างของทริป active

ทำ TripShareFormatter, preview bottom sheet และ share_plus ให้ข้อความตรงข้อมูลที่แสดง ไม่ส่ง notes/packing/พิกัด/internal IDs ตามข้อกำหนด ไม่เปิดสิทธิ์ Firestore ให้คนอื่น และไม่อ้างว่าข้อความส่งถึงผู้รับจากการเปิด share sheet

เขียน tests สำหรับ formatter/persistence และทดสอบ native features บน Android ที่มี ระบุกรณีที่ยังไม่มีอุปกรณ์หรือแอปปลายทางให้ตรวจจริง Build debug APK และอัปเดต IMPLEMENTATION_STATUS.md ไม่ส่งข้อความให้คนอื่นหรือ push โค้ดแทนผู้ใช้
```

## 5 ตรวจความพร้อมก่อนนำเสนอ

```text
ตรวจ TripPocket เทียบ Definition of Done ใน docs/IMPLEMENTATION_PLAN.md และ acceptance cases ใน DATABASE_DESIGN.md กับ FEATURE_SHARE_PLAN.md อ่าน AGENTS.md ก่อนเริ่ม แล้วตรวจและแก้บั๊กที่อยู่ในขอบเขต MVP ให้ครบ

รัน analysis/tests/Rules tests ที่เกี่ยวข้องและ Android build เดิน workflow register/login → สร้างทริป → เพิ่มกิจกรรมและหมุด → แก้ไข/ลบ → ตรวจงบ → เช็กลิสต์ → preview/share sheet → logout และตรวจการแยกบัญชี

ตรวจการกดซ้ำ การย้อนกลับ คีย์บอร์ด วันหรือเงินผิด เน็ตขัดข้อง ทริปว่าง การลบสะดุด และ stale user state หากทดสอบบนอุปกรณ์ไม่ได้ให้รายงานชัดเจนพร้อมรายการที่ต้องตรวจต่อ

เขียน docs/DEMO_GUIDE.md สำหรับสาธิต 5–7 นาที และอัปเดต IMPLEMENTATION_STATUS.md แยกส่วนที่ผ่านจริงกับสิ่งที่ยังขาด ไม่ติ๊ก checklist จากการคาดเดา ไม่เพิ่มฟีเจอร์ใหม่ ไม่ deploy และไม่ push อัตโนมัติ
```

## 6 ใช้ต่อเมื่อจบแชตหรือเปลี่ยน agent

```text
ทำ TripPocket ต่อจากสถานะปัจจุบัน อ่าน AGENTS.md, Project skill, IMPLEMENTATION_STATUS.md ถ้ามี และ IMPLEMENTATION_PLAN.md แล้วตรวจ source/working tree จริง

สรุปสั้น ๆ ว่า milestone ไหนเสร็จแล้วจากหลักฐานและอะไรยังค้าง จากนั้นลงมือทำงานที่ยังขาดตาม dependency โดยรักษางานเดิมและ schema ไม่รื้อเริ่มใหม่ ไม่ถือว่ารายการที่ยังไม่ติ๊กแปลว่ายังไม่มีโค้ด และไม่ถือว่ารายการที่ติ๊กแล้วผ่านกับโค้ดล่าสุดโดยไม่ตรวจส่วนที่เปลี่ยน

ถ้าขาดข้อมูลที่จำเป็นให้ถามเฉพาะจุดและทำส่วนที่ไม่ติดขัดต่อ ปิดงานด้วยผลที่ตรวจจริงและอัปเดตไฟล์สถานะ ไม่ deploy หรือ push เว้นแต่มีคำสั่งจากผู้ใช้เพิ่มเติม
```
