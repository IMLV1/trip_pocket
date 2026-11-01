# รายงานทดสอบบน Mac และ iOS

ทดสอบวันที่ 1–2 พฤศจิกายน 2569 บน Mac ด้วย Flutter 3.44.4, Xcode 26.6 และ iPhone 16 Pro Simulator (iOS 26.2)

## ผลการทดสอบ

| รายการ | ผล |
|---|---|
| `flutter pub get` | ผ่าน |
| `flutter analyze lib test integration_test test_driver` | ผ่าน ไม่มี issue |
| `flutter test` | ผ่าน 38/38 |
| `flutter build ios --simulator --debug` | ผ่าน หลังแก้ deployment target |
| Workflow หลักบน Simulator โหมด demo | ผ่าน: ล็อกอิน สร้างทริป เพิ่มจุดหมาย เลือกหมุด ดูงบ เช็กลิสต์ และดูตัวอย่างแชร์ |
| เปิดแอปโหมดจริงบน Simulator | ผ่าน ขึ้นหน้าเข้าสู่ระบบ ไม่มี error ตอนเริ่ม |

## Bug ที่แก้แล้ว

### กลุ่มสถานที่แนะนำบังแผนที่

- **อาการ:** วงกลมสีน้ำเงินซ้อนกันจนมองไม่เห็นแผนที่และหมุดของทริป
- **สาเหตุ:** ช่องจัดกลุ่มกว้างราว 29 logical px แต่ marker กว้าง 48 px
- **แก้:** ขยายช่องจัดกลุ่มเป็นราว 58 logical px ใน `lib/features/places/place_catalog.dart`
- **commit:** `c0f447a`
- **ตรวจแล้ว:** ดูจาก screenshot บน Simulator ยังไม่มี regression test เฉพาะจุดนี้

### Build iOS ไม่ผ่าน

- **อาการ:** Xcode แจ้งว่า `cloud-firestore`, `firebase-auth` และ `firebase-core` ต้องการ iOS 15.0 แต่ target เป็น 13.0
- **แก้:** เปลี่ยน `IPHONEOS_DEPLOYMENT_TARGET` เป็น 15.0
- **commit:** `73a37c4`

### แอป iOS ไม่มี Firebase config

- **อาการ:** repo ไม่มี `ios/Runner/GoogleService-Info.plist` จึงใช้โหมดจริงบน iOS ไม่ได้
- **แก้:** เพิ่มไฟล์ config ของ `com.imlv1.trippocket` และผูกกับ target Runner ใน Xcode
- **commit:** `4379674`
- **ตรวจแล้ว:** build และเปิดแอปโหมดจริงบน Simulator ผ่านบน Mac

## ปัญหาสภาพแวดล้อม (ไม่ใช่ bug ของแอป)

- **`flutter analyze` ทั้งโปรเจกต์รายงาน 385 issues:** ทั้งหมดอยู่ใน `build/ios/SourcePackages/` ซึ่งเป็นไฟล์ที่ระบบสร้างขึ้น ให้รันเฉพาะโฟลเดอร์ซอร์สตามตารางด้านบน หรือเพิ่ม `build/**` ใน `analyzer.exclude`
- **Mac เครื่องที่ทดสอบไม่มี Android SDK:** จึงไม่ได้รันบน Android
- **พิมพ์ภาษาไทยผ่านเครื่องมือควบคุม Simulator แล้วตัวอักษรเพี้ยน:** เกิดจากการวางข้อความผ่านเครื่องมือ เมื่อกรอกผ่าน integration test ภาษาไทยแสดงถูกต้อง
- **การแตะผ่านเครื่องมือควบคุม Simulator บางครั้งไม่ติดหรือไปโดนตัวเลือกวันที่:** ไม่พบใน integration test แต่ยังไม่ทราบสาเหตุแน่ชัด

## พฤติกรรมที่ถูกต้องอยู่แล้ว

- แตะแผนที่นอกเขตไทยแล้วไม่ได้หมุด เพราะแอปจำกัดพื้นที่เลือกไว้เฉพาะในไทย
- เช็กลิสต์เพิ่มได้หลายรายการ ผ่านทั้ง widget test และบน Simulator

## ยังไม่ได้ทดสอบ

- สมัคร ล็อกอิน และบันทึกทริปกับ Firebase จริงบน iOS
- การเปิด share sheet ของ iOS (ทดสอบถึงหน้าตัวอย่างข้อความ)
- การนำทางด้วย Google Maps
- มือถือเครื่องจริง
- Android บนเครื่อง Mac นี้
- `npm run test:rules`

## สไลด์นำเสนอ

- ไฟล์สไลด์: [docs/slides/TripPocket-slides.html](slides/TripPocket-slides.html)
- โลโก้: [docs/slides/images/logo.svg](slides/images/logo.svg) ใช้ในสไลด์เท่านั้น ไอคอนของแอปยังเป็นไอคอนมาตรฐานของ Flutter
- รูปในสไลด์ถ่ายจากโหมด demo และครอปแถบแจ้งเตือนด้านบนออก
