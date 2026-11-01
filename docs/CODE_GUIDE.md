# คู่มืออธิบายหน้าจอและโค้ด TripPocket

เอกสารนี้อธิบายว่าแต่ละหน้าในแอปทำอะไร และโค้ดแต่ละส่วนรับผิดชอบเรื่องใด เขียนจากโค้ดที่ commit `a09604a` ถ้าสัญญาข้อมูลหรือพฤติกรรมในเอกสารออกแบบต่างจากที่นี่ ให้ตรวจโค้ดจริงก่อน แล้วแก้เอกสารให้ตรงกัน

สัญญาฉบับละเอียดอยู่ใน [Frontend](FRONTEND_ARCHITECTURE.md), [Backend](BACKEND_ARCHITECTURE.md) และ [Database Design](DATABASE_DESIGN.md)

## ภาพรวมการทำงาน

```text
หน้าจอ (Widget)
   │ ref.watch / ref.read
   ▼
Riverpod providers (lib/app/providers.dart)
   │
   ▼
Repository interface ──► ของจริง: Firebase Auth / Cloud Firestore
                    ├──► ของจำลอง: เก็บในหน่วยความจำ (โหมด demo)
                    └──► PackingRepository: SharedPreferences ในเครื่อง
```

หน้าจอไม่เรียก Firebase โดยตรง แต่เรียกผ่าน repository ทำให้สลับโหมด live, emulator และ demo หรือใส่ fake ในการทดสอบได้ ไม่มี Go server หรือ REST API เพราะแอปคุยกับ Firebase โดยตรงและบังคับสิทธิ์ด้วย Firestore Rules

ลำดับตอนเปิดแอป:

1. `main()` เรียก `bootstrap()` ถ้าเริ่มไม่สำเร็จจะแสดงหน้าข้อความ error
2. `bootstrap()` อ่าน `APP_MODE` แล้วสร้าง repository ตามโหมด โดย Release ยอมรับเฉพาะ `live`
3. `ProviderScope` ใส่ repository ที่สร้างแล้วเข้าไปใน provider ด้วย override
4. `TripPocketApp` ฟังสถานะล็อกอินจาก `sessionProvider`
5. `SessionApp` สร้าง `GoRouter` ใหม่ทุกครั้งที่ uid เปลี่ยน เพราะใช้ `ValueKey(uid)` ประวัติหน้าจอและ state ของบัญชีเก่าจึงถูกทิ้งทั้งหมด

## หน้าจอทั้งหมด

| Route | หน้าจอ | ไฟล์ |
|---|---|---|
| `/login` | เข้าสู่ระบบ | `lib/features/auth/auth_screen.dart` |
| `/register` | สมัครสมาชิก | `lib/features/auth/auth_screen.dart` |
| `/forgot-password` | ลืมรหัสผ่าน | `lib/features/auth/forgot_password_screen.dart` |
| `/trips` | รายการทริป | `lib/features/trips/presentation/trip_list_screen.dart` |
| `/trips/new` | สร้างทริป | `lib/features/trips/presentation/trip_form_screen.dart` |
| `/trips/:tripId` | รายละเอียดทริป 3 แท็บ | `lib/features/trips/presentation/trip_detail_screen.dart` |
| `/trips/:tripId/edit` | แก้ไขทริป | `lib/features/trips/presentation/trip_form_screen.dart` |
| `/trips/:tripId/activities/new` | เพิ่มจุดหมาย | `lib/features/activities/presentation/activity_form_screen.dart` |
| `/trips/:tripId/activities/:activityId/edit` | แก้ไขจุดหมาย | `lib/features/activities/presentation/activity_form_screen.dart` |
| `/profile` | โปรไฟล์ | `lib/features/auth/profile_screen.dart` |
| `/change-password` | เปลี่ยนรหัสผ่าน | `lib/features/auth/change_password_screen.dart` |

Router บังคับเส้นทางตามสถานะล็อกอิน: ยังไม่ล็อกอินจะถูกส่งไป `/login` ส่วนคนที่ล็อกอินแล้วจะเข้าหน้า login, register และลืมรหัสผ่านไม่ได้ และถูกส่งไป `/trips`

### เข้าสู่ระบบและสมัครสมาชิก

`AuthScreen` เป็นหน้าเดียวที่ใช้ทั้งสองแบบ โดยดูจาก `register` แบบสมัครจะมีช่องยืนยันรหัสผ่านเพิ่ม ส่วนแบบเข้าสู่ระบบจะมีลิงก์ลืมรหัสผ่าน ทั้งสองแบบมีปุ่ม Google เมื่อล็อกอินสำเร็จ `sessionProvider` จะเปลี่ยนค่าแล้วแอปสร้าง router ใหม่เอง หน้านี้จึงไม่ต้องสั่งเปลี่ยนหน้า

### ลืมรหัสผ่าน

กรอกอีเมลเพื่อให้ Firebase ส่งลิงก์ตั้งรหัสใหม่ ข้อความผลลัพธ์เหมือนกันไม่ว่าอีเมลนี้มีบัญชีหรือไม่ เพราะ repository กลืน error `user-not-found` ไว้ เพื่อไม่ให้ใช้หน้านี้ตรวจว่าใครมีบัญชี

### รายการทริป

หน้าแรกหลังล็อกอิน ทำหน้าที่:

- แยกทริปเป็น "กำลังจะไป" และ "จบทริปแล้ว" ด้วย chip
- ค้นหาชื่อทริปจากปุ่มแว่นขยาย โดยกรองในเครื่องจากรายการที่โหลดแล้ว
- ปุ่มไปโปรไฟล์ ออกจากระบบ และสร้างทริป
- ตอนเปิดหน้าจะเรียก `resumePendingDeletes` เพื่อลบทริปที่ค้างอยู่ต่อ ถ้ายังมีทริปสถานะ `deleting` จะแสดงการ์ดพร้อมปุ่ม "ลองต่อ"

### สร้างและแก้ไขทริป

`TripFormScreen` โหลดทริปเดิมและจัดการกรณีหาไม่พบ ส่วน `TripEditor` คือฟอร์มจริง มีชื่อทริป จุดหมาย วันเริ่ม วันสิ้นสุด งบประมาณ และหมุดพื้นที่หลัก

- วันสิ้นสุดต้องอยู่หลังวันเริ่มอย่างน้อย 1 วัน ตัวเลือกวันจึงเริ่มที่ วันเริ่ม + 1 และถ้าเปลี่ยนวันเริ่มจนเลยวันจบ วันจบจะขยับตาม
- หมุดพื้นที่หลักเลือกได้สองทาง: ค้นหาสถานที่แล้วยืนยันบนแผนที่ หรือแตะบนแผนที่เอง
- หมุดนี้ไม่บังคับ และแยกจากจุดหมายรายวัน
- ชื่อจุดหมายเป็นแค่ป้าย เปลี่ยนชื่อแล้วหมุดไม่ย้าย
- ตอนแก้วันทริป repository ตรวจกิจกรรมจาก server ก่อน ถ้ามีกิจกรรมอยู่นอกช่วงวันใหม่จะไม่ให้บันทึก

### รายละเอียดทริป

`TripDetailScreen` มีแถบล่าง 3 แท็บ และเมนูมุมขวาบนสำหรับแก้ไขหรือลบทริป แท็บเก็บอยู่ใน `IndexedStack` และสร้างเมื่อเปิดครั้งแรกเท่านั้น (`visited`) แผนที่จึงไม่โหลดจนกว่าจะเปิดแท็บแผนที่ และ state ของแท็บไม่หายตอนสลับ

**แท็บแผนเที่ยว**

- แสดงหมุดพื้นที่หลัก (ถ้ามี) และปุ่มจบทริป ซึ่งต้องยืนยันก่อน
- การ์ดงบแสดงงบทริป ยอดวางแผน แยกค่ากิจกรรมกับค่าเดินทาง และจำนวนรายการที่ไม่ทราบราคา
- ปุ่มแชร์แผนเที่ยว
- เลือกวัน แล้วดูจุดหมายของวันนั้นผ่าน `DayPlan`: เรียงขึ้นลง กำหนดการเดินทางและค่าเดินทาง นำทาง แก้ไข และลบ

**แท็บแผนที่**

แสดง `DailyMap` ของวันที่เลือก มีหมุดเลขลำดับ หมุดพื้นที่หลัก และไอคอนสถานที่แนะนำ แตะพื้นแผนที่เพื่อเพิ่มจุดหมาย (ต้องอยู่ในไทยและยืนยันก่อน) แตะเลขหมุดเพื่อแก้ไข ปุ่ม "ตำแหน่งของฉัน" อ่านพิกัดเมื่อกดเท่านั้น และแอปไม่วาดเส้นทางถนน

**แท็บเตรียมของ**

`PackingChecklist` เพิ่ม ติ๊ก และลบของที่ต้องเตรียม พร้อมแถบความคืบหน้า เก็บเฉพาะเครื่องนี้และใช้ได้แม้ออฟไลน์

ปุ่มแก้ไขจะถูกปิดระหว่างที่ `busy` หรือมีการเขียนรอยืนยันจาก server เพื่อกันการกดซ้ำ ทริปที่จบแล้วยังเปิดดูและแก้รายละเอียดได้ แต่ย้อนกลับเป็นยังไม่จบไม่ได้

### เพิ่มและแก้ไขจุดหมาย

`ActivityFormScreen` โหลดทริปและกิจกรรมเดิม ส่วน `ActivityEditor` คือฟอร์มจริง รับ `ActivitySeed` เพื่อใส่ค่าตั้งต้นได้ 2 แบบ:

- มาจากการเลือกสถานที่ (`ActivitySeed`): กรอกชื่อและหมวดให้ แต่ยังไม่มีพิกัด ผู้ใช้ต้องเปิดแผนที่แล้วยืนยันตำแหน่งก่อนบันทึก
- มาจากการแตะแผนที่ (`ActivitySeed.pin`): มีพิกัดแล้ว ผู้ใช้กรอกชื่อและรายละเอียดต่อ

กฎสำคัญตอนบันทึก:

- ต้องมีพิกัด และพิกัดใหม่ต้องอยู่ในขอบเขตไทย ถ้าพิกัดไม่เปลี่ยนจะไม่ตรวจซ้ำ
- ค่าใช้จ่ายเว้นว่างหมายถึง "ยังไม่ทราบราคา" ไม่ใช่ 0 บาท
- จุดหมายใหม่หรือที่ย้ายวันจะไปต่อท้ายวันนั้น โดยเพิ่ม `orderIndex` ทีละ 1000
- หมายเหตุไม่ถูกรวมในข้อความแชร์

### ค้นหาและแนะนำสถานที่

`RecommendationsSheet` เป็น bottom sheet ไม่ใช่ route ถูกเปิดจากแท็บแผนเที่ยว แท็บแผนที่ ฟอร์มทริป และฟอร์มจุดหมาย ค้นหาได้จากชื่อสถานที่ จังหวัด อำเภอ ตำบล หรือคำพ้อง กรองตามจังหวัด อำเภอ/เขต ตำบล/แขวง และหมวด สลับดูเป็นรายการหรือแผนที่ได้ และแสดงผลสูงสุด 100 แห่งแรก

เมื่อเลือกสถานที่ `chooseSuggestedPlace` จะเปิดหน้ารายละเอียด ซึ่งบอกแหล่งข้อมูลและเตือนว่าไม่ทราบราคาหรือเวลาเปิดปิด ผู้ใช้ต้องกด "เพิ่มจุดหมายนี้" ก่อนจึงจะไปขั้นถัดไป

### เลือกตำแหน่งบนแผนที่

`PlacePickerSheet` (เรียกผ่าน `pickPlace`) เปิดแผนที่เต็มสำหรับแตะหมุด รับเฉพาะจุดในไทย และคืนพิกัดเมื่อกดยืนยันเท่านั้น ถ้าโหลดพื้นแผนที่ไม่ได้จะมีปุ่มลองใหม่

### แชร์แผนเที่ยว

`SharePlanSheet` แสดงข้อความตัวอย่างก่อน แล้วจึงเปิด share sheet ของระบบ ข้อความมีชื่อทริป จุดหมาย วันที่ กิจกรรมรายวัน และสรุปงบ ไม่มีหมายเหตุ พิกัด หรือเช็กลิสต์ ถ้าข้อมูลมาจาก cache จะมีคำเตือน ผู้รับได้แค่ข้อความ ไม่ได้สิทธิ์เข้าถึงฐานข้อมูล

### โปรไฟล์และเปลี่ยนรหัสผ่าน

`ProfileScreen` แก้ชื่อที่แสดง เชื่อมบัญชี Google ที่ใช้อีเมลเดียวกันเพื่อใช้รูปโปรไฟล์ และเปิดหน้าเปลี่ยนรหัสผ่าน ชื่อที่ผู้ใช้ตั้งไว้เองจะไม่ถูกทับด้วยชื่อจาก Google

`ChangePasswordScreen` ต้องกรอกรหัสปัจจุบันเพื่อยืนยันตัวตนใหม่ และรหัสใหม่ต้องไม่ซ้ำรหัสเดิม บัญชีที่ใช้ Google อย่างเดียวจะไม่เห็นฟอร์ม แต่เห็นลิงก์ไปหน้าความปลอดภัยของบัญชี Google แทน

## โครงสร้างโค้ดใน lib

```text
lib/
├── main.dart            จุดเริ่มแอปและการเลือกโหมด
├── app/                 router, theme ของแอป, providers
├── core/                ของกลางที่ทุก feature ใช้
└── features/
    ├── auth/            บัญชีผู้ใช้
    ├── trips/           ทริป (domain, data, presentation)
    ├── activities/      จุดหมายและการคำนวณงบ
    ├── places/          แผนที่ ค้นหา ตำแหน่ง นำทาง
    ├── packing/         เช็กลิสต์ในเครื่อง
    └── sharing/         แชร์ข้อความ
```

### lib/app และ lib/core

| ไฟล์ | หน้าที่ |
|---|---|
| `main.dart` | `bootstrap()` เลือกโหมด เริ่ม Firebase ต่อ emulator และสร้าง repository |
| `app/app.dart` | `TripPocketApp` ฟัง session, `SessionApp` สร้าง router ตั้ง locale ไทย และแสดงแถบเตือนเมื่อไม่ใช่โหมด live |
| `app/providers.dart` | รวม provider ของ repository, session, ทริป, กิจกรรม และเช็กลิสต์ ค่า repository จะ throw ถ้าไม่ถูก override |
| `core/design_system.dart` | สี `TripColors`, theme `buildTripTheme`, `prettyDate` และ widget กลาง: `SoftBadge`, `SectionTitle`, `EmptyPanel`, `FormIntro`, `RouteMotif` |
| `core/widgets.dart` | `AsyncContent` จัดการ loading/error/ลองใหม่, `confirmDelete`, `showError`, `PageBody`, `UnavailablePage` |
| `core/validation.dart` | แปลงและตรวจเงิน วันที่ เวลา อีเมล รหัสผ่าน และ `requireValid` |
| `core/errors.dart` | `errorText` แปลง error จาก Firebase เป็นข้อความไทย |

### features/auth

| ไฟล์ | หน้าที่ |
|---|---|
| `auth_repository.dart` | `Session`, interface `AuthRepository`, `FirebaseAuthRepository` และ `DemoAuthRepository` |
| `google_identity_client.dart` | ห่อ `google_sign_in` ไว้หลัง interface เพื่อให้ทดสอบด้วย fake ได้ |
| `auth_screen.dart`, `forgot_password_screen.dart`, `profile_screen.dart`, `change_password_screen.dart` | หน้าจอตามหัวข้อด้านบน |

หลังทำงานที่รอผล เช่น เชื่อม Google โค้ดจะเรียก `sameUser` เพื่อเช็กว่าบัญชียังเป็นคนเดิม กันการเขียนข้อมูลผิดบัญชี

### features/trips

| ไฟล์ | หน้าที่ |
|---|---|
| `domain/trip.dart` | โมเดล `Trip`, การตรวจค่า, การแปลงเป็น field และ `DataSnapshot` ที่บอกว่าข้อมูลมาจาก cache หรือรอเขียนอยู่ |
| `domain/travel_repository.dart` | interface ของงานทริปและกิจกรรมทั้งหมด |
| `data/firestore_travel_repository.dart` | ของจริงบน Firestore |
| `data/demo_travel_repository.dart` | ของจำลองในหน่วยความจำ ข้อมูลหายเมื่อปิดแอป |
| `presentation/` | รายการทริป ฟอร์มทริป และรายละเอียดทริป |

งานสำคัญใน `FirestoreTravelRepository`:

- บันทึกทริปและกิจกรรมผ่าน transaction และสร้าง id ด้วย UUID ฝั่งแอป ถ้าลองซ้ำหลังผลไม่แน่นอนจะเขียนทับเอกสารเดิม ไม่เกิดรายการซ้ำ
- `reorderActivities` ตรวจว่ากิจกรรมยังตรงกับที่ผู้ใช้เห็น แล้วเขียน `orderIndex` ใหม่เป็น 0, 1000, 2000 ครั้งละไม่เกิน 100 จุด
- `completeTrip` ตั้ง `completed` เป็น true และเรียกซ้ำได้โดยไม่เกิดผลเพิ่ม
- `deleteTrip` ลบเป็นขั้นตอนตามหัวข้อด้านล่าง

**ขั้นตอนลบทริปแบบทำต่อได้**

1. บันทึก tripId ลงคิวในเครื่อง
2. เปลี่ยนสถานะทริปเป็น `deleting`
3. ลบกิจกรรมทีละชุด ชุดละไม่เกิน 100 รายการ จนหมด
4. ลบเอกสารทริป
5. ล้างเช็กลิสต์ในเครื่องและเอาออกจากคิว

ถ้าหลุดกลางทาง `resumePendingDeletes` จะทำต่อจากหน้ารายการทริป ห้ามลบทริปก่อนกิจกรรม และ tripId ที่อยู่ในคิวเพียงอย่างเดียวจะไม่ทำให้ทริปที่ยัง `active` ถูกลบ

### features/activities

| ไฟล์ | หน้าที่ |
|---|---|
| `domain/trip_activity.dart` | โมเดล `TripActivity`, หมวด, วิธีเดินทาง, การเรียงลำดับ และการคำนวณงบ |
| `presentation/activity_form_screen.dart` | ฟอร์มจุดหมาย |

เรื่องที่ควรรู้ก่อนแก้:

- **ลำดับ:** `sortedActivities` เรียงตามวัน, `rank`, เวลา แล้วจึง id ถ้าไม่มี `orderIndex` จะใช้ `rank = timeMinutes * 1000` ข้อมูลรุ่นเก่าจึงอ่านได้โดยไม่ต้อง migrate และจะเป็น `schemaVersion: 2` เมื่อบันทึกครั้งถัดไป
- **ค่าเดินทาง:** เก็บบนกิจกรรมปลายทางของแต่ละช่วง พร้อม `travelFromId` และ `travelSignature`
- **ค่าเดินทางที่หมดอายุ:** `validSegment` เทียบ signature จาก id, วัน, เวลา และพิกัดของทั้งสองจุด ถ้าจุดเปลี่ยนหรือลำดับเปลี่ยน ค่านี้จะไม่ถูกนับ และถือเป็น "ยังไม่ทราบราคา"
- **งบ:** `planBudget` คำนวณจากกิจกรรมทุกครั้ง ไม่เก็บยอดรวมในฐานข้อมูล และนับจำนวนรายการที่ไม่ทราบราคาแยกไว้

### features/places

| ไฟล์ | หน้าที่ |
|---|---|
| `curated_places.dart` | โมเดล `CuratedPlace`, `ActivitySeed` และ `placeArea` ส่วน `chiangMaiPlaces` กับ `suggestPlaces` เหลือไว้ให้ test เท่านั้น |
| `place_catalog.dart` | โหลด `assets/thailand_pois.json` ใน isolate, ทำดัชนี, `search` สำหรับรายการ และ `window` สำหรับไอคอนบนแผนที่ |
| `poi_map_layer.dart` | วาดไอคอนหรือกลุ่มสถานที่ตามมุมมองแผนที่ และมี `chooseSuggestedPlace` |
| `recommendations_sheet.dart` | หน้าค้นหา ตัวกรอง `AreaDropdown` และแผนที่ `DiscoveryMap` |
| `daily_map.dart` | แผนที่รายวัน หมุด การเพิ่มจุด ตำแหน่งของฉัน และ `categoryColor` |
| `day_plan.dart` | รายการจุดหมายรายวัน และ `TravelEditor` สำหรับค่าเดินทาง |
| `destination_preview.dart` | แผนที่ขนาดเล็กแบบดูอย่างเดียวของหมุดพื้นที่หลัก |
| `place_picker_sheet.dart` | ตัวเลือกพิกัดบนแผนที่ |
| `thailand_boundary.dart` | โหลด `assets/thailand.geojson` และตรวจว่าจุดอยู่ในไทย เป็นขอบเขตโดยประมาณ เกาะเล็กหรือจุดริมแดนอาจอยู่นอกข้อมูล |
| `location_service.dart` | ขอสิทธิ์และอ่านพิกัดครั้งเดียว ไม่บันทึกและไม่ติดตามเบื้องหลัง |
| `navigation_service.dart` | สร้าง URL Google Maps Directions และเปิดแอปภายนอก ถ้าไม่ได้จะเปิดในเบราว์เซอร์ |

วิธีที่แผนที่รับข้อมูล 67,074 แห่งได้โดยไม่หน่วง: `PlaceCatalog` แบ่งสถานที่เป็นตารางช่องละ 0.25 องศา แล้วดูเฉพาะช่องที่อยู่ในมุมมอง ตอนซูมระดับ 12 ขึ้นไปจะแสดงไอคอนไม่เกิน 100 แห่งที่ใกล้กลางจอ ถ้าซูมต่ำกว่านั้นจะรวมเป็นกลุ่มพร้อมตัวเลข และ `PoiMapLayer` รอ 140 มิลลิวินาทีหลังแผนที่หยุดขยับก่อนคำนวณใหม่

พื้นแผนที่ใช้ OpenStreetMap เปลี่ยนได้ด้วย `--dart-define=TILE_URL=...` ไม่มี API แบบเสียเงินและไม่เรียก Nominatim หรือ Overpass ต้องคงข้อความ attribution ของ OSM ไว้

### features/packing และ features/sharing

| ไฟล์ | หน้าที่ |
|---|---|
| `packing/packing_repository.dart` | อ่านเขียนเช็กลิสต์ที่คีย์ `packing.v1.<uid>.<tripId>` และเก็บคิวล้างข้อมูลตอนลบทริป ถ้า JSON เสียจะแจ้ง error และไม่เขียนทับ |
| `packing/packing_checklist.dart` | UI เช็กลิสต์ |
| `sharing/trip_share_formatter.dart` | `formatTripShare` สร้างข้อความจากทริปและกิจกรรม ส่วนนี้ไม่มี UI จึงทดสอบง่าย |
| `sharing/share_plan_sheet.dart` | หน้าตัวอย่างและ `PlatformShareService` ที่เรียก `share_plus` |

## ข้อมูลและความปลอดภัย

ข้อมูล cloud อยู่ที่ `users/{uid}/trips/{tripId}` และ `users/{uid}/trips/{tripId}/activities/{activityId}` รายละเอียด field ดู [Database Design](DATABASE_DESIGN.md)

| ข้อมูล | รูปแบบเก็บ |
|---|---|
| เงิน | จำนวนเต็มหน่วยสตางค์ เช่น 100 บาท เก็บเป็น 10000 |
| วันเดินทาง | ข้อความ `YYYY-MM-DD` |
| เวลา | จำนวนนาทีตั้งแต่เที่ยงคืน เช่น 09:00 เก็บเป็น 540 |

`firestore.rules` คือด่านบังคับจริง เพราะโค้ดฝั่งแอปถูกข้ามได้:

- เข้าถึงได้เฉพาะเจ้าของ uid
- ตรวจชนิดและช่วงของทุก field, จำกัด field ที่อนุญาต และบังคับ `updatedAt` เป็นเวลา server
- กิจกรรมต้องอยู่ในช่วงวันของทริป
- สร้างหรือแก้กิจกรรมได้เฉพาะตอนทริปเป็น `active`
- `completed` เปลี่ยนจาก true กลับเป็น false ไม่ได้
- ลบเอกสารทริปได้เฉพาะตอนสถานะเป็น `deleting`

ข้อจำกัดที่รู้แล้ว: การตรวจตอนย่อวันทริปทำฝั่งแอป จึงไม่รับประกันเมื่อแก้พร้อมกันหลายอุปกรณ์

## ไฟล์อื่นในโปรเจกต์

| ที่อยู่ | หน้าที่ |
|---|---|
| `assets/thailand_pois.json` | ฐานสถานที่จาก OpenStreetMap พร้อมจังหวัด อำเภอ ตำบล |
| `assets/thailand.geojson` | ขอบเขตประเทศไทยโดยประมาณ |
| `assets/THAILAND_POIS_LICENSE.txt` | เงื่อนไขและที่มาของข้อมูล ต้องคงไว้ |
| `assets/fonts/` | ฟอนต์ Noto Sans Thai และสัญญาอนุญาต |
| `tools/build_poi_catalog.py` | สร้าง `thailand_pois.json` ใหม่จากไฟล์ OSM และเขตปกครอง |
| `firestore.rules`, `firestore.indexes.json`, `firebase.json` | กฎ ดัชนี และการตั้งค่า emulator |
| `rules-tests/firestore.test.mjs` | ทดสอบ Firestore Rules |
| `android/`, `ios/` | โปรเจกต์ native รวมสิทธิ์ตำแหน่งและไฟล์ตั้งค่า Firebase |
| `web/` | โครง Flutter Web ยังไม่ได้ลงทะเบียน Firebase |
| `docs/` | เอกสารออกแบบ คู่มือตรวจ รายงาน หลักฐาน และสไลด์ |

## ชุดทดสอบ

**`test/`** รันด้วย `flutter test` ใช้ fake ไม่ต้องมีอุปกรณ์หรือ Firebase

| ไฟล์ | สิ่งที่ตรวจ |
|---|---|
| `domain_test.dart`, `v21_domain_test.dart` | เงิน วันที่ งบ ลำดับ และช่วงเดินทางที่หมดอายุ |
| `strict_trip_dates_test.dart` | วันจบต้องหลังวันเริ่ม |
| `widget_test.dart`, `v21_widget_test.dart`, `ux_responsive_test.dart` | การทำงานของหน้าจอและการแสดงผลตามขนาดจอ |
| `account_and_trip_management_test.dart` | บัญชี ค้นหาทริป และจบทริป |
| `editor_recovery_test.dart`, `map_failure_draft_test.dart` | ฟอร์มไม่เสียเมื่อบันทึกล้มเหลวหรือแผนที่โหลดไม่ได้ |
| `nationwide_catalog_test.dart`, `poi_map_layer_test.dart` | ฐานสถานที่ ตัวกรอง และไอคอนบนแผนที่ |
| `trip_destination_test.dart` | หมุดพื้นที่หลัก |
| `location_service_test.dart` | สิทธิ์และการอ่านตำแหน่ง |
| `share_refresh_test.dart`, `share_sheet_test.dart` | ข้อความแชร์และหน้าตัวอย่าง |

**`integration_test/`** รันบนอุปกรณ์หรือ emulator

| ไฟล์ | สิ่งที่ตรวจ |
|---|---|
| `ui_flow_test.dart`, `v21_ui_test.dart`, `nationwide_ui_test.dart`, `trip_destination_ui_test.dart`, `account_management_ui_test.dart` | ขั้นตอนใช้งานบนอุปกรณ์จริงหรือ emulator |
| `firebase_flow_test.dart`, `v21_firebase_test.dart`, `account_management_firebase_test.dart` | งานที่ผ่าน Firebase |
| `persistence_restart_test.dart` | ข้อมูลยังอยู่หลังเปิดแอปใหม่ |
| `native_share_test.dart`, `v21_native_navigation_test.dart` | share sheet และการเปิด Maps ของระบบ |

`test_driver/integration_test.dart` เป็นตัวเรียก integration test ผ่าน `flutter drive` คำสั่งรันอยู่ใน [README](../README.md) และผลทดสอบจริงอยู่ใน [IMPLEMENTATION_STATUS](IMPLEMENTATION_STATUS.md)

## ถ้าจะแก้เรื่องนี้ ให้เริ่มที่ไหน

| อยากแก้ | เริ่มที่ |
|---|---|
| เพิ่มหน้าจอใหม่ | เพิ่ม route ใน `lib/app/app.dart` แล้วสร้างหน้าใน `presentation/` ของ feature นั้น |
| เพิ่ม field ทริปหรือกิจกรรม | โมเดลใน `domain/`, `firestore.rules`, repository ทั้งของจริงและ demo, `rules-tests` และเอกสาร Database Design |
| เปลี่ยนสูตรงบ | `planBudget` ใน `trip_activity.dart` |
| เปลี่ยนข้อความแชร์ | `trip_share_formatter.dart` และตรวจว่าไม่รั่วหมายเหตุหรือพิกัด |
| เปลี่ยนสีหรือรูปแบบ UI | `core/design_system.dart` |
| เปลี่ยนข้อความ error ของ Firebase | `core/errors.dart` |
| อัปเดตฐานสถานที่ | `tools/build_poi_catalog.py` แล้วตรวจ `nationwide_catalog_test.dart` |
| เพิ่มตัวกรองสถานที่ | `place_catalog.dart`, `recommendations_sheet.dart` และ `poi_map_layer.dart` |
