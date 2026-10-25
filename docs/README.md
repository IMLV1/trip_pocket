# เอกสารพัฒนา TripPocket

สถานะล่าสุด 26 ตุลาคม 2569: มีโค้ด Flutter และ Firebase จริงแล้ว ผลทดสอบ/ข้อจำกัดและงานค้างอยู่ใน [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) เอกสารออกแบบด้านล่างยังเป็นสัญญาของโครงการ

## เริ่มอ่าน

- [UI/UX รุ่นใหม่](UI_UX_REFRESH.md) — design system, แท็บแผน/แผนที่/เตรียมของ และการทดสอบ

- [ค้นหาทั่วไทยและหมุดแนะนำ](FEATURE_NATIONWIDE_PLACES.md) — ฐาน OSM 66,975 แห่ง/77 จังหวัด แทนชุดเชียงใหม่เดิม พร้อมผลตรวจและสิทธิ์ข้อมูล

- [คู่มือตรวจ P7](P7_TEST_GUIDE.md) — Emulator, cold restart และ native share
- [สถานะ implementation](IMPLEMENTATION_STATUS.md) — ผลตรวจจริงและงานค้าง
- [คู่มือสาธิต](DEMO_GUIDE.md) — workflow 5–7 นาที


1. [ข้อเสนอโครงงาน](PROJECT_PROPOSAL.md) — ปัญหา ผู้ใช้ และขอบเขตงาน
2. [Frontend](FRONTEND_ARCHITECTURE.md) — หน้าจอ Navigation โครงสร้าง Flutter และสถานะ UI
3. [Backend](BACKEND_ARCHITECTURE.md) — Firebase โมเดลข้อมูล สิทธิ์ และการรับส่งข้อมูล
4. [Implementation Plan](IMPLEMENTATION_PLAN.md) — ลำดับงาน ผลลัพธ์แต่ละช่วง และเกณฑ์ตรวจรับ
5. [Agent Guide](AGENT_GUIDE.md) — วิธีให้ agent ทำงานต่อและตัวอย่างคำสั่ง
6. [TripPocket Development Skill](skills/trippocket-development/SKILL.md) — skill เฉพาะโครงการสำหรับอ่านและใช้กับงานพัฒนา
7. [Database Design](DATABASE_DESIGN.md) — Collections, Data Dictionary, ตัวอย่างข้อมูล, Query, Index และข้อกำหนด Rules
8. [แชร์แผนเที่ยวเป็นข้อความ](FEATURE_SHARE_PLAN.md) — Preview, native share sheet และเกณฑ์ตรวจรับ
9. [Implementation Prompts](IMPLEMENTATION_PROMPTS.md) — คำสั่งพร้อมใช้สำหรับพัฒนา MVP และทำงานต่อเป็นช่วง

คำแนะนำที่ agent ใน repository ต้องอ่านอยู่ใน [AGENTS.md](../AGENTS.md)

## ส่วนขยายที่กำลังออกแบบ

- [แผนเที่ยวหลายจุดในประเทศไทย](FEATURE_THAILAND_TRIP_PLANNER.md) — ความต้องการใหม่ 26 ต.ค. 2569: หลายหมุด สถานที่แนะนำ ยานพาหนะ ค่าใช้จ่าย และนำทาง; V2.1 มีโค้ด/ผลตรวจแล้ว ดู V21_TEST_GUIDE.md; ไม่เปิด API เพิ่ม

- [คู่มือตรวจ V2.1](V21_TEST_GUIDE.md) — ค้นหา หลายจุด GPS และ Maps แบบฟรี

## การตัดสินใจหลัก

| เรื่อง | แนวทางที่เลือก |
|---|---|
| เป้าหมาย | แอป Android ภาษาไทยสำหรับวางแผนเที่ยวส่วนตัว |
| Frontend | Flutter / Dart, Material 3 |
| State / Navigation | Riverpod แบบไม่ใช้ code generation / go_router |
| Backend | Firebase Authentication และ Cloud Firestore ผ่าน Flutter SDK โดยตรง ไม่มี Go API |
| แผนที่ | flutter_map และ latlong2; ผู้ใช้เลือกพิกัดด้วยตนเอง |
| Tile provider | กำหนดผ่าน configuration และตรวจเงื่อนไขก่อนใช้จริง |
| Local Storage | SharedPreferences สำหรับเช็กลิสต์แยกตามบัญชีและทริป |
| การคำนวณเงิน | บาทใน UI และจำนวนเต็มสตางค์ในข้อมูล |
| เวลา | วันที่และเวลาท้องถิ่นตามที่ผู้ใช้กรอก ไม่มีการแปลงเขตเวลา |

แผนที่และ Local Storage เป็น Mobile / External Features สองประเภทของโครงงาน ไม่จำเป็นต้องเพิ่ม GPS หรือ REST API เพื่อให้ครบจำนวน

## การเชื่อมต่อที่ยืนยันแล้ว

เลือก Flutter → Firebase โดยตรง Firebase ทำหน้าที่ Backend สำเร็จรูป จึงไม่ต้องสร้างหรือดูแล Go server เพิ่ม ใช้ Auth SDK จัดการ session และ Firestore SDK สำหรับ CRUD โดยบังคับสิทธิ์ด้วย Security Rules รายละเอียดอยู่ใน [Backend Architecture](BACKEND_ARCHITECTURE.md)

## ขอบเขต

MVP มีระบบสมาชิก CRUD ทริปและกิจกรรม แผนรายวัน หมุดสถานที่ สรุปงบ เช็กลิสต์เตรียมของ และแชร์แผนเที่ยวเป็นข้อความ ข้อมูลทริปเก็บบน Firebase ส่วนเช็กลิสต์อยู่เฉพาะเครื่อง ไม่สัญญาว่าเช็กลิสต์จะตามไปยังอุปกรณ์อื่น

การจอง การชำระเงิน แชต การแก้ไขทริปร่วมกันหลายบัญชี ค้นทั่วประเทศด้วย API และจัดเส้นทางอัตโนมัติเป็นงานนอก MVP; V2.1 ที่ผู้ใช้เพิ่มขอบเขตให้มีค้นหาออฟไลน์เชียงใหม่ หลายหมุด ค่าเดินทางกรอกเอง GPS แบบกดอ่าน และเปิด Maps ภายนอกแล้ว การแชร์ข้อความไม่เปิดสิทธิ์ฐานข้อมูลให้ผู้รับ

## วิธีรักษาเอกสารให้ตรงกัน

Database Design เป็นสัญญาข้อมูลฉบับละเอียด Backend Architecture อธิบายการเชื่อมต่อและ workflow ส่วน Frontend Architecture เป็นสัญญาหน้าจอ หากตัดสินใจเปลี่ยน schema, route หรือขอบเขต ให้แก้เอกสารที่เกี่ยวข้องและข้อเสนอในงานเดียวกัน แผนงานใช้เช็กบ็อกซ์ที่ติ๊กเมื่อมีหลักฐานทดสอบแล้วเท่านั้น
