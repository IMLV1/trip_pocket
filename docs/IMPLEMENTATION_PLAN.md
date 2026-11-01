# แผนพัฒนา TripPocket

แผน ณ 20 ตุลาคม 2569 เป้าหมายนำเสนอ 3 พฤศจิกายน 2569 เวลา 09:00–12:00 น. ห้อง Com 2 ตามโจทย์รายวิชา สถานะที่ตรวจแล้วอัปเดตวันที่ 25 ตุลาคม 2569 ดูรายละเอียดและข้อจำกัดใน IMPLEMENTATION_STATUS.md

สถาปัตยกรรมที่ยืนยัน: Flutter เชื่อม Firebase โดยตรง ใช้ Firebase เป็น Backend งานในแผนนี้ไม่รวมการสร้างหรือ deploy Go server

## ลำดับและ dependency

```text
P0 Setup → P1 App Shell → P2 Authentication → P3 Trip CRUD
                                              ↓
                              P4 Activity CRUD และ Budget
                                  ↓                  ↓
                              P5 Map             P6 Packing
                                  └────────┬─────────┘
                                     P7 Integration → P8 Demo
```

P5/P6 แยกงานได้หลังสัญญาข้อมูลนิ่ง แต่แผนนี้ไม่ได้สั่งให้เปิดหลาย agent อัตโนมัติ

## P0 ตรวจสภาพแวดล้อมและเริ่มโปรเจกต์

เป้าหมาย 20 ตุลาคม

- [x] ตรวจ flutter --version, flutter doctor และ Android device/emulator
- [x] ตรวจและต่อยอด Flutter starter ที่ IdeaProjects/trip_pocket โดยรักษา docs และ AGENTS.md
- [x] เลือก Android application ID ให้คงที่ก่อนลงทะเบียน Firebase
- [x] เพิ่ม dependency ที่จำเป็นและเก็บ lockfile
- [x] เตรียม emulator configuration และระบุว่า live Firebase ยังไม่ได้ตั้งค่าหากยังไม่มี

ตรวจรับ: แอปเริ่มบน Android ได้ และระบุผลจริงของ doctor/สิ่งที่ยังขาด ไม่มีการทับเอกสารเดิม

## P1 โครงแอปและหน้าจอ

เป้าหมาย 21–22 ตุลาคม; ต้องผ่าน P0

- [x] สร้าง ThemeData, router และโครงสร้าง feature ตาม Frontend Architecture
- [x] ทำ 6 ประเภทหน้าจอ ใช้ fake repository สำหรับทดลอง UI
- [x] ทำ validator เงิน วันที่ และข้อความร่วมกัน
- [x] ทำ loading, empty, error และ submitting state

ตรวจรับ: เดิน workflow สร้างทริปและกิจกรรมด้วย fake data ได้ ฟอร์มปฏิเสธข้อมูลผิด แสดงยอดรวมถูกต้อง และมีข้อความชัดว่านี่เป็นโหมดจำลอง

## P2 ระบบสมาชิก

เป้าหมาย 23 ตุลาคม; ต้องผ่าน P1

- [x] เชื่อม Firebase Auth Emulator และ repository จริง
- [x] Register, login, logout และ session redirect
- [x] เปลี่ยน uid แล้ว dispose สถานะของผู้ใช้เดิม
- [x] แสดง error และป้องกัน submit ซ้ำ

ตรวจรับ: สมัครใหม่ เข้าสู่ระบบ ปิดเปิดแอป และออกจากระบบได้ เมื่อ logout เปิด route ของทริปไม่ได้

## P3 CRUD ทริปและกฎสิทธิ์

เป้าหมาย 24–25 ตุลาคม; ต้องผ่าน P2

- [x] Trip model และ Firestore serialization
- [x] ใช้ Data Dictionary และชุดตรวจรับจาก [Database Design](DATABASE_DESIGN.md)
- [x] Create/read/update ทริปด้วย schema ที่ตกลงไว้
- [x] Query รายการและ index ที่ต้องใช้
- [x] เขียน Rules และ Emulator tests ก่อนเชื่อมข้อมูลจริง
- [x] วาง delete workflow สถานะ deleting พร้อมรายการลบค้าง

ตรวจรับ: owner จัดการทริปได้ user B/anonymous อ่านและเขียนไม่ได้ ฟอร์มตรวจวันและงบครบ การลบทริปเปล่าทำได้

## P4 กิจกรรม แผนรายวัน และงบ

เป้าหมาย 26 ตุลาคม; ต้องผ่าน P3

- [x] CRUD กิจกรรมและ validation เทียบช่วงวันทริป
- [x] แสดงวันและเรียงเวลาแบบคงที่
- [x] รวมยอดสตางค์และแสดงคงเหลือ/เกินงบ
- [x] กันการย่อวันจนกิจกรรมอยู่นอกช่วง
- [x] ลบทริปที่มีกิจกรรมด้วย batch cleanup และ retry

ตรวจรับ: เพิ่ม/แก้ไข/ลบแล้วแผนและยอดเปลี่ยนตรงกัน ทดสอบเงิน 0 บาท ทศนิยม 2 ตำแหน่ง เกินงบ และ cleanup สะดุดแล้วเริ่มต่อได้

## P5 แผนที่เลือกสถานที่

เป้าหมาย 27 ตุลาคม; ต้องมี P4 และเลือก tile provider แล้ว

- [x] ตรวจนโยบาย tile provider และการตั้งค่า attribution/caching/app identifier
- [x] Place picker แตะแผนที่ ยืนยัน และยกเลิก
- [x] บันทึกและเปิดแก้ไขหมุดเดิม
- [x] Map error ไม่ทำให้ข้อมูลในฟอร์มหาย (widget error injection; ดูผล P7)

ตรวจรับ: เลือกหมุดจริงบน Android กลับมาเปิดหมุดเดิมได้ attribution มองเห็น และไม่มี GPS permission ที่ไม่ได้ใช้

## P6 เช็กลิสต์ในเครื่อง

เป้าหมาย 28 ตุลาคม; ต้องผ่าน P3 และใช้ uid/tripId ที่เสถียร

- [x] PackingRepository เก็บ JSON ผ่าน SharedPreferences
- [x] เพิ่ม ลบ และเช็กของพร้อม persist
- [x] แยกบัญชีและทริป รวมการจัดการ JSON เสีย
- [x] ล้าง key หลังลบทริปสำเร็จ และ retry การล้างได้
- [x] บันทึก cleanup queue ก่อนลบทริป และไม่ล้างเช็กลิสต์ของ parent ที่ยัง active

ตรวจรับ: เปิดแอปใหม่เช็กลิสต์ยังอยู่ ใช้โดยไม่มีอินเทอร์เน็ตได้ เปลี่ยนบัญชีแล้วไม่เห็นรายการของบัญชีก่อน

## P6A แชร์แผนเที่ยวเป็นข้อความ

เป้าหมาย 28–29 ตุลาคม; ต้องผ่าน P4 ใช้หน้ารายละเอียดเดิม

- [x] ทำ TripShareFormatter และ unit test ลำดับวัน/เวลา/ยอดเงิน
- [x] ทำ preview bottom sheet และ PlatformShareService ด้วย share_plus รุ่นที่เข้ากับ SDK
- [x] แชร์เฉพาะ fields ตาม [Share Plan](FEATURE_SHARE_PLAN.md) ไม่เพิ่มฐานข้อมูลหรือ public access
- [ ] ทดสอบยกเลิก error ทริปว่าง เกินงบ และ native share sheet บน Android จริง

ตรวจรับ: preview ตรงข้อความที่ส่ง แอปปลายทางที่ทดสอบรับข้อความได้ ยกเลิกแล้วไม่เปลี่ยนข้อมูล และไม่อ้างว่าส่งถึงผู้รับจากการเปิด share sheet เพียงอย่างเดียว

## P7 ทดสอบรวมและเชื่อม Firebase จริง

ขอบเขตรอบ 25 ตุลาคม 2569: ผู้ใช้มี iPhone และยืนยันให้ใช้ Android Emulator เป็นอุปกรณ์ตรวจรับรอบนี้ ดู P7_TEST_GUIDE.md มือถือ Android จริงยังไม่ผ่านการทดสอบ และไม่ถือว่าผล Emulator เป็นผล hardware จริง

เป้าหมาย 29–31 ตุลาคม; ต้องผ่าน P2–P6 และ P6A

- [x] ตั้งค่า Firebase project จริงเมื่อได้รับข้อมูลและการร้องขอที่ครอบคลุม
- [x] เปิด Auth provider และตรวจ rules/indexes บน environment ที่ใช้สาธิต
- [x] flutter analyze และ flutter test
- [x] Emulator rules tests และ integration test กระบวนการหลัก
- [x] รอบ Emulator: cold restart, native keyboard inset/ปุ่มบันทึก และ workflow หลัก; widget test จอเล็ก/ปุ่มกลับ/error states (25 ต.ค. 2569)
- [x] รอบ Emulator: Chrome รับข้อความครบและ callback success; Back ซ่อนแผงคีย์บอร์ดแบบ floating บน APK ปกติ (25 ต.ค. 2569; ดูหลักฐานในสถานะ)
- [ ] ทดสอบบน Android จริง รวม back button, keyboard และหน้าจอเล็ก (นอก scope รอบ Emulator ที่ผู้ใช้เลือก)
- [x] ทดสอบเครือข่ายขัดข้อง เปลี่ยนบัญชี และ retry delete
- [x] Build APK และติดตั้งทดสอบ

ตรวจรับ: แยกรายงานผล Emulator กับผล live Firebase ชัดเจน ไม่มี error สำคัญใน workflow หลัก หากติด environment ให้รายงานว่าอะไรยังไม่ได้ตรวจ ไม่ติ๊กว่าผ่าน

## P8 เตรียมส่งและสาธิต

เป้าหมาย 1–2 พฤศจิกายน; ต้องผ่าน P7

- [ ] เตรียมทริปเชียงใหม่ 3 วัน 2 คืน งบ 3,000 บาท
- [ ] เตรียมบัญชี A/B สำหรับสาธิตสิทธิ์
- [ ] ซ้อม workflow 5–7 นาที: login → สร้าง → เพิ่มหมุด → รวมงบ → แก้ไข/ลบ → เช็กลิสต์
- [ ] สาธิต preview และแชร์แผนเป็นข้อความผ่าน share sheet
- [ ] ทำสไลด์ปัญหา ผู้ใช้ workflow เทคโนโลยี โครงสร้างข้อมูล และข้อจำกัด
- [ ] อธิบาย async, Rules, repository และเหตุผลเลือกเทคโนโลยีได้
- [ ] เก็บ APK และ source ฉบับตรงกัน พร้อมข้อมูลตัวอย่างที่ไม่ใช่ข้อมูลส่วนตัว

## ชุดทดสอบที่มีความหมาย

| ระดับ | สิ่งที่ต้องพิสูจน์ |
|---|---|
| Unit | parse เงินไม่คลาดเคลื่อน รวมงบถูก ช่วงวันถูก เรียงกิจกรรมถูก |
| Widget | validation ข้อความผิดพลาด loading/empty/error และป้องกันกดซ้ำ |
| Rules | owner ผ่าน user B/anonymous ถูกปฏิเสธ และ payload ผิดไม่ถูกบันทึก |
| Integration | CRUD ครบ เปลี่ยนบัญชี หมุดคงเดิม เช็กลิสต์ persist และ cleanup retry |
| Device | UI แตะได้ คีย์บอร์ดไม่บัง back ทำงาน แผนที่โหลดและเลือกได้ |

## ความเสี่ยงและการปรับขอบเขต

| ความเสี่ยง | แนวทาง |
|---|---|
| Firebase จริงยังไม่พร้อม | ทำ Emulator/fake ต่อได้ แต่เก็บ live integration เป็นงานค้าง |
| Tile provider ใช้งานไม่ได้ | เปลี่ยนผ่าน config ทดสอบเงื่อนไขใหม่ก่อนใช้จริง |
| เวลาพัฒนาไม่พอ | ลด animation การตกแต่ง และแผนที่ภาพรวม แต่คง picker และ Local Storage |
| ลบข้อมูลสะดุด | ใช้ deleting + retry ไม่ลบ parent ก่อน children |
| แก้ทริปเดียวจากหลายเครื่อง | ระบุข้อจำกัด MVP และไม่เพิ่ม collaborative editing |

## Definition of Done

ต้องผ่านเกณฑ์แชร์ข้อความใน P6A เพิ่มจากข้อกำหนดหลักด้านล่าง

ครบ 6 ประเภทหน้าจอ มี Form Validation, Authentication, Firestore CRUD, async, แผนที่และ Local Storage กระบวนการหลักผ่านบน Android จริง Rules ป้องกันข้ามบัญชี และมีผลตรวจที่ระบุวัน/อุปกรณ์/ข้อจำกัดชัดเจน สถานะงานต้องสะท้อนหลักฐาน ไม่ใช่จำนวนไฟล์ที่สร้าง

หมายเหตุการติ๊ก: หลักฐาน Android ในงานนี้เป็น Emulator; live คือบริการ Firebase จริงที่ Android Emulator เชื่อมถึง ไม่ใช่มือถือจริง cold restart และ Chrome recipient ผ่านแล้ว ปิด P7 ตาม scope Emulator ที่ผู้ใช้เลือก; อุปกรณ์จริงยังไม่ได้ตรวจ จึงยังไม่อ้าง Definition of Done ที่ต้องใช้มือถือจริงทั้งหมด ดูไฟล์สถานะ


## V2.1 เพิ่มขอบเขตตามผู้ใช้ — ฟรีเท่านั้น

- [x] ออกแบบ schema2 แบบอ่าน legacy ได้และคงยอดเงิน
- [x] หลายจุดหมาย หมวด แผนที่เลขหมุดรายวัน เพิ่ม/แก้/ลบ/เรียง
- [x] วิธีเดินทางรายช่วงและราคากรอกเอง แยกยอดและตัดราคาล้าสมัย
- [x] ค้นหา/คำแนะนำออฟไลน์เชียงใหม่พร้อมแหล่งข้อมูลและยืนยันก่อนเพิ่ม
- [x] GPS เมื่อกดปุ่ม และ URL นำทางตามแผน/จากฉัน
- [x] Rules 9 กลุ่ม, Flutter tests, SDK Emulator/live และ Android UI/native tests ตามสถานะ
- [x] Build/install/run APK ปกติล่าสุดและบันทึก hash (ดูผลส่งมอบในสถานะ)

ไม่มีบริการคำนวณเส้นทางถนน/ค่าโดยสารเองหรือค้นทั่วประเทศ ไม่เปิด billing; เส้นทาง/เสียงนำทางอยู่ใน Maps ภายนอก ไม่มีผลส่งกลับ อ่านขอบเขตและผลจริงที่ V21_TEST_GUIDE.md

## V2.2 แก้ขอบเขตทั่วไทย

- [x] ฐาน POI ชุมชน OSM 66,975 แห่ง กระจายครบ 77 จังหวัด พร้อม metadata/ODbL/importer
- [x] ค้นชื่อ/จังหวัด/คำประเภท กรองจังหวัดและหมวด
- [x] ไอคอน/กลุ่มสถานที่แนะนำบนแผนที่รายวันและหน้าค้นหา แตะดูรายละเอียดและเลือกเพิ่มได้
- [x] โหลดใน isolate และใช้ spatial grid ไม่วาดทั้งประเทศเป็นหมุดเดี่ยวพร้อมกัน
- [x] Flutter tests 33 ข้อ และ Android workflow ด้วยแค็ตตาล็อกจริง กรุงเทพ/ภูเก็ต ผ่าน
- [x] APK ปกติล่าสุดและ hash ดูผลส่งมอบใน IMPLEMENTATION_STATUS.md

## หมุดพื้นที่หลักของทริป — 26 ตุลาคม 2569

- [x] ค้นหา/เลือก/ยืนยันหมุดในฟอร์มสร้างหรือแก้ทริป พร้อมแผนที่ตัวอย่าง
- [x] เก็บคู่พิกัดใน trip และอ่าน legacy ไม่มีหมุดได้ ไม่เปลี่ยนยอดงบหรือเพิ่ม activity
- [x] แสดงหมุดพื้นที่หลักแยกในแผนที่รายวัน เปลี่ยน/ล้างหมุดได้ ยกเลิกไม่ทับ draft
- [x] Flutter 38, Rules 10, Android workflow และ live Firebase SDK ผ่านตามสถานะ
- [x] Rules เผยแพร่หลังผู้ใช้ยืนยัน และ APK ปกติส่งมอบพร้อม hash ใน IMPLEMENTATION_STATUS.md

## บัญชีและการจัดการทริป — 2 พฤศจิกายน 2569

- [x] ลืมรหัสผ่านด้วย Firebase Auth, แก้ชื่อ/รูปจาก Google และเปลี่ยนรหัสผ่านด้วย reauthentication
- [x] วันเริ่มก่อนวันจบ: domain/form/Rules พร้อมอ่านและลบทริปเก่าวันเดียวกันได้
- [x] ค้นชื่อทริป และยืนยันจบทริป แยกกำลังจะไป/จบทริปแล้ว โดยไม่ลบรายละเอียด
- [x] Rules Emulator 12 กลุ่ม และ live SDK profile/password/completion/ownership ผ่านตาม IMPLEMENTATION_STATUS.md
- [x] เปิด Google provider/เพิ่ม debug SHA-1/native configs และเผยแพร่ Rules หลังผู้ใช้อนุญาต
- [ ] Google interactive ด้วยบัญชีจริง, รับ reset email จริง และ iOS build/runtime (ยังไม่ได้ทดสอบ)
