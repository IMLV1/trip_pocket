# TripPocket

แอป Flutter ภาษาไทยสำหรับวางแผนเที่ยวส่วนตัวในประเทศไทย สร้างทริป จัดจุดหมายรายวันบนแผนที่ คุมงบ เตรียมของ และแชร์แผนเป็นข้อความ ใช้ Firebase Authentication และ Cloud Firestore เป็น backend โดยตรง รองรับ Android และ iOS

อยากรู้ว่าแต่ละหน้าและแต่ละส่วนของโค้ดทำอะไร อ่าน [คู่มืออธิบายหน้าจอและโค้ด](docs/CODE_GUIDE.md)

## ความสามารถ

- **บัญชี:** สมัครและเข้าสู่ระบบด้วยอีเมลหรือ Google, ลืมรหัสผ่าน, แก้ชื่อที่แสดง, ใช้รูปจาก Google และเปลี่ยนรหัสผ่าน
- **ทริป:** สร้าง แก้ไข ลบ ค้นหาชื่อ ปักหมุดพื้นที่หลัก และกดจบทริปเพื่อแยกไปหมวดจบทริปแล้ว
- **แผนรายวัน:** เพิ่มหลายจุดหมายต่อวัน เรียงลำดับเอง แบ่งหมวด และแก้ไขจากรายการหรือหมุดบนแผนที่
- **ค้นหาทั่วไทย:** 67,074 สถานที่จาก OpenStreetMap ครบ 77 จังหวัด ค้นหาได้แบบออฟไลน์ กรองตามจังหวัด อำเภอ/เขต ตำบล/แขวง และหมวด พร้อมไอคอนแนะนำบนแผนที่
- **งบ:** ตั้งงบทริป กรอกค่ากิจกรรมและค่าเดินทางเอง แอปสรุปยอดและบอกจำนวนรายการที่ยังไม่ทราบราคา
- **แผนที่และนำทาง:** ดูหมุดรายวัน อ่านตำแหน่งของฉันเมื่อกด และเปิด Google Maps ภายนอกเพื่อนำทาง
- **เช็กลิสต์เตรียมของ:** เก็บเฉพาะเครื่อง แยกตามบัญชีและทริป ใช้ได้แม้ออฟไลน์
- **แชร์แผน:** ดูตัวอย่างข้อความก่อนส่งผ่าน share sheet ของระบบ

## เทคโนโลยี

| เรื่อง | ที่ใช้ |
|---|---|
| แอป | Flutter, Dart `^3.12.2`, Material 3 |
| State / Navigation | Riverpod แบบไม่ใช้ code generation, go_router |
| Backend | Firebase Authentication, Cloud Firestore, Firestore Security Rules |
| แผนที่ | flutter_map, latlong2, พื้นแผนที่ OpenStreetMap |
| ในเครื่อง | SharedPreferences, ฐานสถานที่ใน `assets/` |
| ความสามารถของเครื่อง | geolocator, url_launcher, share_plus, google_sign_in |

ไม่มี Go server, REST API ของตัวเอง หรือ API แบบเสียเงิน และไม่ได้เปิด Billing

## เริ่มใช้งาน

ต้องมี Flutter 3.44 ขึ้นไป ร่วมกับ Android SDK หรือ Xcode และอุปกรณ์หรือ emulator/simulator

```bash
flutter pub get
```

```bash
flutter run
```

ค่าเริ่มต้นคือโหมด `live` ซึ่งเชื่อม Firebase จริง project `trippocket-382b7` บน Spark ฟรี Firestore อยู่ที่ Bangkok (`asia-southeast3`) รหัสแอป Android และ iOS คือ `com.imlv1.trippocket`

ลำดับการใช้งานหลัก: สมัครบัญชี → สร้างทริป → เพิ่มจุดหมาย เลือกและยืนยันหมุด → ตรวจงบ → เช็กของ → ดูตัวอย่างและแชร์ → จบทริป

## โหมดการทำงาน

เลือกด้วย `--dart-define=APP_MODE=<โหมด>` ส่วน Release ยอมรับเฉพาะ `live`

| โหมด | ข้อมูลอยู่ที่ไหน | ใช้เมื่อ |
|---|---|---|
| `live` | Firebase จริง | ใช้งานจริง |
| `emulator` | Firebase Emulator project `demo-trippocket` | ทดสอบ Auth และ Firestore โดยไม่เขียน project จริง |
| `demo` | ทริปอยู่ในหน่วยความจำและหายเมื่อปิดแอป เช็กลิสต์ยังเก็บในเครื่อง | ลอง UI โดยไม่ต้องเปิด Firebase |

ลองโหมด demo:

```bash
flutter run --dart-define=APP_MODE=demo
```

ลองโหมด emulator ต้องเปิด emulator ก่อน แล้วรันแอปจากอีก terminal:

```bash
npm ci
```

```bash
npm run emulators
```

```bash
flutter run --dart-define=APP_MODE=emulator
```

ค่าเริ่มต้นของ host คือ `10.0.2.2` สำหรับ Android Emulator ส่วน iOS Simulator ให้เพิ่ม `--dart-define=EMULATOR_HOST=localhost` และมือถือจริงให้ใช้ IP เครื่องพัฒนา Port ที่ใช้คือ Auth 9099 และ Firestore 8080

## ตรวจสอบ

```bash
flutter analyze
```

```bash
flutter test
```

```bash
npm run test:rules
```

```bash
flutter test integration_test/ui_flow_test.dart -d <device-id>
```

```bash
flutter test integration_test/firebase_flow_test.dart -d <device-id> --dart-define=APP_MODE=emulator
```

Rules test ต้องมี Java 21 ใน PATH รายการชุดทดสอบทั้งหมดอยู่ใน [คู่มือโค้ด](docs/CODE_GUIDE.md#ชุดทดสอบ) ถ้าจะทดสอบกับ Firebase จริงให้ใช้เฉพาะบัญชีทดสอบ และอย่าใช้ข้อมูลส่วนตัว

## Build

```bash
flutter build apk --debug
```

APK อยู่ที่ `build/app/outputs/flutter-apk/app-debug.apk` การ build integration test ใช้ path เดียวกัน จึงต้อง build จาก `lib/main.dart` ใหม่ก่อนแจก

```bash
flutter build ios --simulator --debug
```

iOS ตั้งขั้นต่ำเป็น 15.0

## โครงสร้างโปรเจกต์

```text
lib/
├── main.dart        เริ่มแอปและเลือกโหมด
├── app/             router และ providers
├── core/            design system, validation, widget กลาง
└── features/        auth, trips, activities, places, packing, sharing
assets/              ฐานสถานที่ ขอบเขตประเทศ ฟอนต์
test/                unit และ widget tests
integration_test/    ทดสอบบนอุปกรณ์
rules-tests/         ทดสอบ Firestore Rules
tools/               สร้างฐานสถานที่ใหม่
docs/                เอกสารออกแบบ คู่มือ รายงาน และสไลด์
```

## หลักการข้อมูล

- ข้อมูล cloud แยกตาม uid และบังคับสิทธิ์ด้วย Firestore Rules ไม่ใช่แค่ฝั่งแอป
- เงินเก็บเป็นสตางค์จำนวนเต็ม วันเก็บเป็น `YYYY-MM-DD` เวลาเก็บเป็นนาทีตั้งแต่เที่ยงคืน และยอดรวมคำนวณจากกิจกรรมทุกครั้ง
- ราคาที่ไม่ทราบไม่ถือว่าฟรี ค่าเดินทางของช่วงที่จุดหรือเวลาเปลี่ยนแล้วจะไม่ถูกนับ
- ลบทริปตามลำดับ deleting → กิจกรรม → ทริป → ข้อมูลในเครื่อง และทำต่อจากหน้ารายการได้ถ้าหลุดกลางทาง
- ตำแหน่งปัจจุบันอ่านเมื่อผู้ใช้กดเท่านั้น ไม่บันทึกลงบัญชีและไม่ติดตามเบื้องหลัง
- ข้อความแชร์ไม่รวมหมายเหตุ พิกัด หรือเช็กลิสต์ และไม่ให้สิทธิ์ฐานข้อมูลแก่ผู้รับ

## ข้อจำกัด

- ผล share sheet ไม่ยืนยันว่าข้อความถึงผู้รับ
- ไม่มีเส้นทางถนนหรือค่าโดยสารในแอป ค่าเดินทางเป็นยอดรวมที่ผู้ใช้กรอกเอง
- ข้อมูลสถานที่มาจากชุมชน ไม่ยืนยันว่าร้านยังเปิด ไม่มีราคาและเวลาเปิดปิด และหมุดอาจไม่ใช่ทางเข้า
- พื้นแผนที่ต้องใช้อินเทอร์เน็ตและไม่รองรับดาวน์โหลดออฟไลน์ ใช้ OSM Standard สำหรับโครงงานขนาดเล็ก ถ้าเปลี่ยน provider ผ่าน `TILE_URL` ต้องตรวจเงื่อนไขใหม่
- การย่อวันทริปตรวจกิจกรรมจาก server แต่ไม่รับประกันการแก้พร้อมกันหลายอุปกรณ์
- เช็กลิสต์ไม่ตามไปอุปกรณ์อื่น
- Web ต้องลงทะเบียน app และสร้าง config เพิ่มก่อนใช้ live
- APK ยังใช้ debug signing ไม่ใช่ไฟล์พร้อมลง Play Store
- งานที่ยังไม่ได้ยืนยันอยู่ใน [IMPLEMENTATION_STATUS](docs/IMPLEMENTATION_STATUS.md)

## ข้อมูลและลิขสิทธิ์

แผนที่และฐานสถานที่ใช้ข้อมูล © OpenStreetMap contributors ภายใต้ ODbL และต้องแสดง attribution ตามที่แอปทำไว้ ที่มาและเงื่อนไขทั้งหมดอยู่ใน [THAILAND_POIS_LICENSE](assets/THAILAND_POIS_LICENSE.txt) ส่วนการสร้างฐานใหม่ใช้ [build_poi_catalog.py](tools/build_poi_catalog.py)

Firebase client config ใน source เป็นข้อมูลเชื่อมต่อแอป ไม่ใช่ Admin credential ห้ามใส่ service account, signing key หรือรหัสผ่านผู้ใช้ใน repo และก่อน deploy Rules ต้องผ่าน Rules tests

## เอกสาร

- [คู่มืออธิบายหน้าจอและโค้ด](docs/CODE_GUIDE.md)
- [สารบัญเอกสารออกแบบ](docs/README.md)
- [สถานะและผลทดสอบ](docs/IMPLEMENTATION_STATUS.md)
- [คู่มือสาธิต](docs/DEMO_GUIDE.md)
- [ค้นหาทั่วไทย](docs/FEATURE_NATIONWIDE_PLACES.md)
- [บัญชีและโปรไฟล์](docs/FEATURE_ACCOUNT_PROFILE.md)
- [รายงานทดสอบบน Mac และ iOS](docs/TEST_REPORT_MAC_IOS.md)
- [สไลด์นำเสนอ](docs/slides/TripPocket-slides.html)
