# โครงสร้าง Frontend TripPocket

## เป้าหมายและเทคโนโลยี

ใช้ Flutter / Dart สำหรับ Android เป็นเป้าหมายแรก UI ภาษาไทยและ Material 3 แยกโค้ดตาม feature เพื่อให้ผู้พัฒนาอธิบายการทำงานได้ง่าย ใช้ Riverpod จัดการ dependency และสถานะ async โดยไม่ใช้ code generation ใน MVP และใช้ go_router สำหรับ Navigation และตรวจ session

Frontend เชื่อม Firebase Authentication และ Cloud Firestore ผ่าน SDK โดยตรง Firebase เป็น Backend ของโครงการ ไม่ต้องมี Go API หรือ HTTP client สำหรับ CRUD ใน MVP

แพ็กเกจที่วางแผนใช้: flutter_riverpod, go_router, firebase_core, firebase_auth, cloud_firestore, flutter_map, latlong2, shared_preferences, share_plus และ intl เลือกเวอร์ชันที่เข้ากับ Flutter SDK ตอนเริ่มงานและเก็บ pubspec.lock สำหรับแอป ไม่กำหนดเลขเวอร์ชันจากการคาดเดา

## โครงสร้างไฟล์ที่เสนอ

```text
lib/
  main.dart
  bootstrap.dart
  firebase_options.dart             # สร้างจาก FlutterFire เมื่อมี project จริง
  app/
    app.dart
    router.dart
    theme.dart
  core/
    config/app_config.dart           # emulator, tile URL, attribution
    errors/app_failure.dart
    formatting/money_formatter.dart
    validation/input_validators.dart
    widgets/async_content.dart
    widgets/confirm_delete_dialog.dart
  features/
    auth/
      data/firebase_auth_repository.dart
      domain/auth_repository.dart
      presentation/auth_providers.dart
      presentation/login_screen.dart
      presentation/register_screen.dart
    trips/
      domain/trip.dart
      domain/trip_repository.dart
      data/firestore_trip_repository.dart
      presentation/trip_providers.dart
      presentation/trip_list_screen.dart
      presentation/trip_form_screen.dart
      presentation/trip_detail_screen.dart
      presentation/widgets/budget_summary.dart
    activities/
      domain/trip_activity.dart
      domain/activity_repository.dart
      data/firestore_activity_repository.dart
      presentation/activity_providers.dart
      presentation/activity_form_screen.dart
      presentation/widgets/daily_itinerary.dart
    places/
      domain/place_coordinate.dart
      presentation/widgets/place_picker_sheet.dart
      presentation/widgets/place_map.dart
    packing/
      domain/packing_item.dart
      domain/packing_repository.dart
      data/preferences_packing_repository.dart
      presentation/packing_providers.dart
      presentation/widgets/packing_checklist.dart
test/
  core/
  features/
integration_test/
```

สร้างไฟล์เมื่อมีงานที่ใช้จริง ไม่ต้องสร้าง class เปล่าทุกตำแหน่งล่วงหน้า Model เป็น Dart immutable class แบบเขียนเอง การ serialize อยู่ฝั่ง data ไม่ส่ง DocumentSnapshot เข้า widget

## เส้นทางและหน้าจอ

| Route | หน้าจอ | งานหลัก |
|---|---|---|
| /login | เข้าสู่ระบบ | ตรวจอีเมลและรหัสผ่าน แสดงข้อผิดพลาดที่เข้าใจง่าย |
| /register | สมัครสมาชิก | อีเมล รหัสผ่าน และยืนยันรหัสผ่าน |
| /trips | ทริปของฉัน | แสดงทริป เริ่มสร้าง และออกจากระบบ |
| /trips/new | สร้างทริป | กรอกข้อมูลและงบ |
| /trips/:tripId | รายละเอียดทริป | แผนรายวัน งบ และเช็กลิสต์ |
| /trips/:tripId/edit | แก้ไขทริป | โหลดข้อมูลเดิมและตรวจช่วงวันใหม่ |
| /trips/:tripId/activities/new | เพิ่มกิจกรรม | วัน เวลา พิกัด และค่าใช้จ่าย |
| /trips/:tripId/activities/:activityId/edit | แก้ไขกิจกรรม | โหลดและแก้ไขรายการเดิม |

รวมเป็น 6 ประเภทหน้าจอ โดย create/edit ใช้ฟอร์มร่วมกัน แผนที่เลือกหมุดเป็น bottom sheet ภายในฟอร์มกิจกรรม ไม่ต้องเพิ่มหน้าจอหลัก

ระหว่างตรวจ session ให้แสดง loading ก่อน redirect ผู้ที่ยังไม่ login กลับ /login และผู้ที่ login แล้วออกจากหน้าสมาชิกไป /trips เมื่อ sign out ให้ยกเลิก provider ของบัญชีเดิมและล้าง navigation stack การเปิด tripId ที่ไม่มีหรือไม่มีสิทธิ์ต้องแสดงหน้าไม่พบข้อมูลโดยไม่เผยข้อมูลของบัญชีอื่น

## โครงสร้างหน้ารายละเอียด

- ส่วนหัว: ชื่อทริป จุดหมาย ช่วงวัน เมนูแก้ไขและลบ
- ปุ่มแชร์แผนเที่ยว: เปิด preview bottom sheet แล้วให้ผู้ใช้เลือกแอปผ่าน native share sheet ตาม [Share Plan](FEATURE_SHARE_PLAN.md) โดยยังมี 6 ประเภทหน้าจอเดิม
- ส่วนงบ: งบทั้งหมด ยอดวางแผน และคงเหลือหรือเกินงบ พร้อมข้อความ ไม่ใช้สีอย่างเดียว
- ส่วนแผน: เลือกวัน แสดงกิจกรรมเรียงตามเวลา และกดรายการเพื่อแก้ไข
- ส่วนเตรียมของ: เพิ่ม ลบ และเช็กของ อ่านจากเครื่องโดยแยก uid/tripId
- แผนที่: แสดงหมุดของกิจกรรมที่เลือกหรือกิจกรรมในวันนั้น โดยไม่มีการคำนวณเส้นทาง

วันที่ไม่มีรายการแสดงข้อความพร้อมปุ่มเพิ่มกิจกรรม เลือกวันแรกของทริปเป็นค่าเริ่มต้น และรักษาวันที่เลือกไว้เมื่อกลับจากฟอร์ม

## การไหลของข้อมูลและสถานะ

```text
ผู้ใช้ → Screen / Form
             ↓
       Provider / Controller
             ↓
       Repository interface
             ↓
      Firebase SDK หรือ SharedPreferences
             ↓
       Domain model → UI
```

ใช้ StreamProvider สำหรับ session รายการทริป และกิจกรรม ใช้ provider แบบ family ตาม tripId และ autoDispose เมื่อเลิกใช้ การเขียนข้อมูลผ่าน controller ที่มีสถานะ idle/submitting/success/error ยอดงบเป็น derived state จากกิจกรรม ไม่เขียนยอดซ้ำลงฐานข้อมูล

Provider ที่มีข้อมูลผู้ใช้ต้องขึ้นกับ uid ปัจจุบัน และห้ามใช้ค่าที่ค้างจากบัญชีก่อน ตอนบันทึกให้ปิดปุ่มซ้ำ รอผล write ก่อนปิดฟอร์ม หากผิดพลาดให้เก็บข้อมูลที่กรอกไว้และลองใหม่ได้

## Form และค่าข้อมูล

- ชื่อทริป จุดหมาย และชื่อกิจกรรม trim แล้วมี 1–100 ตัวอักษร หมายเหตุไม่เกิน 500 ตัวอักษร
- เงินรับทศนิยมไม่เกิน 2 ตำแหน่ง ไม่ติดลบ แปลงข้อความเป็นสตางค์ด้วยการแยกส่วนจำนวนเต็มและเศษ หลีกเลี่ยง double × 100
- วันใช้ DatePicker; วันสิ้นสุดไม่น้อยกว่าวันเริ่ม วันกิจกรรมต้องอยู่ในช่วงทริป
- เวลาใช้ TimePicker และแปลงเป็นนาทีตั้งแต่เที่ยงคืน 0–1439
- พิกัดต้องเลือกเองก่อนบันทึก ไม่ใช้พิกัดเริ่มต้นของกล้องแผนที่เป็นค่าที่ผู้ใช้ยืนยัน
- ตรวจข้อมูลร่วมใน controller/repository ด้วย ไม่พึ่ง validator บน widget อย่างเดียว

## แผนที่

PlacePickerSheet คืนค่า latitude/longitude เมื่อกดยืนยัน และคืน null เมื่อยกเลิก การแก้ไขต้องเริ่มที่หมุดเดิม ฟอร์มต้องรักษาหมุดเดิมเมื่อยกเลิก แสดงชื่อสถานที่จากข้อความที่ผู้ใช้กรอก ไม่เรียก geocoding หรือ GPS ในรุ่นแรก

กำหนด tile provider, attribution และ app identifier ผ่าน AppConfig ตรวจข้อกำหนดการใช้งานก่อนเชื่อมต่อจริง เมื่อโหลดแผนที่ไม่ได้ให้แสดงข้อความและลองใหม่ โดยไม่ทำให้ฟอร์มหรือรายการที่บันทึกไว้หาย

หากใช้ OSM Standard tiles ต้องระบุ attribution และตัวตนแอป รวมถึงทำ caching ตามนโยบาย ห้ามออกแบบดาวน์โหลดแผนที่ออฟไลน์หรือดึง tiles ล่วงหน้าจากบริการนี้

## รูปแบบ UI

ฟีเจอร์แชร์เพิ่ม lib/features/sharing/domain/trip_share_formatter.dart, data/platform_share_service.dart และ presentation/share_plan_sheet.dart เพื่อแยกการจัดข้อความที่ทดสอบได้ออกจาก native plugin ไม่ต้องมี repository บน cloud สำหรับการแชร์

ใช้พื้นหลังสว่าง สีหลักเขียวอมฟ้า และสีเตือนสำหรับเกินงบ กำหนดสีและ typography ผ่าน ThemeData ใช้ไอคอนมาตรฐานแทนภาพตกแต่งใน MVP รองรับข้อความยาว การขยายตัวอักษร คีย์บอร์ด และหน้าจอ Android ขนาดเล็ก ปุ่มแตะหลักตั้งเป้าไม่น้อยกว่า 48 logical pixels

## สิ่งที่ต้องทดสอบ

Unit test: เงินและการรวมงบ ช่วงวันที่ และการเรียงกิจกรรม Widget test: validation, loading/error, ปุ่มบันทึกซ้ำ และ redirect ตาม session Integration test: สร้างทริปถึงลบกิจกรรม เปลี่ยนบัญชี และเปิดเช็กลิสต์หลังเปิดแอปใหม่ ทดสอบ gesture บนแผนที่จริงอย่างน้อยหนึ่งอุปกรณ์

## เอกสารอ้างอิง

- [Riverpod package](https://pub.dev/packages/flutter_riverpod)
- [go_router package](https://pub.dev/packages/go_router)
- [flutter_map Tile Layer](https://docs.fleaflet.dev/layers/tile-layer)
- [OSM Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/)

## โค้ดที่ลงมือทำ ณ 25 ตุลาคม 2569

โครงด้านบนเป็นข้อเสนอ ชื่อไฟล์จริงใช้ app/providers.dart รวม dependency/StreamProvider และแยกหน้าจอภายใต้ features โดย auth/auth_screen.dart ใช้ร่วม login/register, core/validation.dart รวม validation/formatting และ features/trips/domain/travel_repository.dart เป็น interface รวม trip/activity operations เพื่อใช้ deletion flow ร่วมกัน FirestoreTravelRepository และ DemoTravelRepository อยู่ใน trips/data ส่วน controller ของฟอร์มใช้ TextEditingController และสถานะ submitting ภายใน ConsumerState แยกจาก data repository ไม่มี code generation

SessionApp ถูกสร้างใหม่ด้วย key ตาม uid ทำให้ navigation stack และฟอร์มเดิมถูก dispose ข้อมูล streams ใช้ autoDispose family ที่รวม uid/tripId; กฎสิทธิ์ยังตรวจซ้ำที่ Firestore
