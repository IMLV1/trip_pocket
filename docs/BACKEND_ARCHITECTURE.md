# โครงสร้าง Backend TripPocket ด้วย Firebase

## สถาปัตยกรรมที่เลือก

Frontend ใช้ Flutter / Dart และ Backend ใช้บริการ Firebase โดยตรงผ่าน Flutter SDK จึงไม่ต้องเขียนหรือรัน Go API เพิ่ม Firebase Authentication จัดการบัญชี Cloud Firestore จัดเก็บข้อมูล และ Firestore Security Rules ตรวจสิทธิ์และข้อมูลที่ client ส่งมา

```text
Flutter Android
  ├── Firebase Authentication SDK → สมัครสมาชิก / login / logout / session
  ├── Cloud Firestore SDK         → ทริป / กิจกรรม
  │      └── Security Rules      → ตรวจ uid และ validation
  ├── Map tile provider          → ภาพพื้นแผนที่
  └── SharedPreferences          → เช็กลิสต์เฉพาะเครื่อง

Local development
  └── Firebase Emulator Suite    → Auth / Firestore / Rules tests
```

ไม่มี Go server, custom REST API, Admin SDK หรือฐานข้อมูล SQL ใน MVP การใช้ Firebase ถือเป็นการใช้ Backend สำเร็จรูป ไม่ใช่แอปที่ไม่มี Backend และตรงกับข้อกำหนด Firebase Database ของรายวิชา

## โครงสร้างที่เกี่ยวข้อง

```text
firebase.json
firestore.rules
firestore.indexes.json
.firebaserc                              # สร้างเมื่อทราบ project ID จริง
lib/firebase_options.dart                # สร้างด้วย FlutterFire CLI
lib/features/auth/data/firebase_auth_repository.dart
lib/features/trips/data/firestore_trip_repository.dart
lib/features/activities/data/firestore_activity_repository.dart
lib/features/packing/data/preferences_packing_repository.dart
tests/firestore/                         # Emulator Rules tests
```

ส่วน Flutter อยู่ที่ root repository ตามแผนเดิม ยังไม่มี source จริงจึงไม่สร้างไฟล์เปล่าล่วงหน้า เริ่ม UI ด้วย fake repository ได้เมื่อ config ไม่พร้อม แต่ต้องแยก fake, emulator และ live ให้ชัดเจน

## Authentication และ session

ใช้ email/password ผ่าน Firebase Auth SDK โดย Firebase เป็นผู้จัดการรหัสผ่าน แอปไม่เก็บ password หรือ token ใน SharedPreferences ใช้ auth state stream ให้ router และ repositories เปลี่ยนตาม uid ปัจจุบัน เมื่อ sign out ให้ dispose ข้อมูลบัญชีเดิมและล้าง navigation stack

จัดการข้อมูลเข้าสู่ระบบไม่ถูกต้อง อีเมลที่มีอยู่แล้ว รหัสผ่านไม่ผ่านเกณฑ์ และ network error ด้วยข้อความภาษาไทย ไม่ส่ง exception ดิบให้ผู้ใช้ ไม่ต้องสร้าง users document เพื่อสมัครสมาชิกให้สำเร็จหากยังไม่มีข้อมูลโปรไฟล์เพิ่มเติม เส้นทาง subcollection ใช้งานได้โดยไม่มี users parent document

## สัญญาข้อมูล

ฟีเจอร์ [แชร์แผนเที่ยวเป็นข้อความ](FEATURE_SHARE_PLAN.md) ใช้ข้อมูลที่แอปโหลดแล้ว ไม่เพิ่ม collection/field ไม่สร้าง public link และไม่เปลี่ยนสิทธิ์ Firestore ของผู้รับ

รายละเอียดฐานข้อมูลฉบับเต็มอยู่ใน [Database Design](DATABASE_DESIGN.md) รวมตัวอย่างข้อมูล Query, Index, Rules matrix และ local cleanup queue ตารางด้านล่างเป็นภาพรวมและต้องตรงกับเอกสารดังกล่าว

วันที่ท่องเที่ยวใช้ string YYYY-MM-DD และเวลานาทีในวัน เพื่อรักษาค่าที่ผู้ใช้กรอกแม้เครื่องเปลี่ยนเขตเวลา ส่วน createdAt/updatedAt เป็น Firestore Timestamp จาก server ไม่แปลงเวลาท่องเที่ยวข้ามเขตเวลาใน MVP

### ทริป

Path: `users/{uid}/trips/{tripId}`; tripId สร้างจาก Firestore auto ID

| Field | Type | ข้อกำหนด |
|---|---|---|
| title | string | trim แล้ว 1–100 ตัวอักษร |
| destination | string | trim แล้ว 1–100 ตัวอักษร |
| startDate | string | วันที่จริง YYYY-MM-DD |
| endDate | string | ไม่น้อยกว่า startDate |
| budgetSatang | integer | 0–1,000,000,000 หน่วยสตางค์ |
| status | string | active หรือ deleting |
| createdAt | Timestamp | server timestamp และคงเดิมหลังสร้าง |
| updatedAt | Timestamp | server timestamp เมื่อแก้ไข |

เพดานเงิน MVP คือ 10 ล้านบาท ใช้เกณฑ์เดียวกันกับค่าใช้จ่ายกิจกรรม ไม่ต้องเก็บ uid/tripId ซ้ำใน document เพราะอยู่ใน path แล้ว

### กิจกรรม

Path: `users/{uid}/trips/{tripId}/activities/{activityId}`; activityId สร้างจาก Firestore auto ID

| Field | Type | ข้อกำหนด |
|---|---|---|
| title | string | trim แล้ว 1–100 ตัวอักษร |
| date | string | วันที่จริงและอยู่ในช่วงทริป |
| timeMinutes | integer | 0–1439 |
| estimatedCostSatang | integer | 0–1,000,000,000 |
| latitude | number | -90 ถึง 90 |
| longitude | number | -180 ถึง 180 |
| note | string | ว่างได้ ไม่เกิน 500 ตัวอักษร |
| createdAt | Timestamp | server timestamp และคงเดิมหลังสร้าง |
| updatedAt | Timestamp | server timestamp เมื่อแก้ไข |

ไม่เก็บยอดรวมซ้ำในทริป Flutter รวม estimatedCostSatang จากกิจกรรมชุดที่โหลดสำเร็จ และแสดง planned/remaining เป็น derived state ถ้ายังโหลดกิจกรรมไม่ครบต้องไม่แสดงยอด 0 เสมือนเป็นยอดจริง

### เช็กลิสต์ของที่เตรียมไป

โหมด live/emulator เก็บใน Firestore ที่ `users/{uid}/trips/{tripId}/packing/checklist` ฟิลด์ `items` (array ของ `{id, text, checked}` ไม่เกิน 200 รายการ, text 1-100 ตัวอักษร) และ `updatedAt` (server time) เขียนผ่าน transaction ที่ต้องเห็น trip สถานะ active เท่านั้น Rules ให้เฉพาะเจ้าของอ่าน/เขียน และลบได้ตอนทริป active หรือ deleting ลบทริปจะลบเอกสารนี้ก่อน parent เช่นเดียวกับ activities ถ้าเปิดทริปครั้งแรกแล้วยังไม่มีเอกสารบนคลาวด์แต่มีเช็กลิสต์เดิมในเครื่อง จะอัปโหลดขึ้นคลาวด์แล้วล้าง key ในเครื่อง

โหมด demo และข้อมูลจากเวอร์ชันก่อนใช้ key ในเครื่อง: `packing.v1.{uid}.{tripId}` ค่าคือ JSON array ของ `{id, text, checked}` text ต้องไม่ว่างหลัง trim อ่านเขียนผ่าน PackingRepository เท่านั้น หาก JSON เสียให้แจ้งปัญหา ไม่ overwrite ทิ้งเงียบ ๆ

เช็กลิสต์อยู่เฉพาะเครื่อง ไม่ sync ข้ามอุปกรณ์ และอาจหายเมื่อล้างข้อมูลแอปหรือถอนติดตั้ง การเก็บเช็กลิสต์ในเครื่องไม่แปลว่าแผนที่หรือ CRUD บน cloud ใช้งานออฟไลน์ได้ครบ

## สัญญา repository

รายการนี้เป็น Dart operations ภายในแอป ไม่ใช่ HTTP endpoints

| Repository | Operations | ผลลัพธ์ |
|---|---|---|
| AuthRepository | watchSession, register, signIn, signOut | session หรือ AppFailure |
| TripRepository | watchTrips(uid), watchTrip(uid, tripId) | stream ข้อมูลที่มีสิทธิ์ |
| TripRepository | createTrip, updateTrip | ID หรือผลการบันทึก |
| TripRepository | deleteTrip, resumePendingDeletes | ผลลบหรือสถานะลองต่อได้ |
| ActivityRepository | watchActivities(uid, tripId) | stream กิจกรรมของทริป |
| ActivityRepository | createActivity, updateActivity, deleteActivity | ผลบันทึก |
| PackingRepository | load, save, removeForTrip | ข้อมูลเฉพาะเครื่อง |

uid มาจาก Firebase session และ Rules ต้องยืนยันซ้ำ ไม่เชื่อเพียง path ที่ client เลือก สร้าง document ID ครั้งเดียวต่อการ submit และรักษา ID เดิมเมื่อลองใหม่หลังผลเครือข่ายไม่ชัดเจน เพื่อหลีกเลี่ยงรายการซ้ำ ไม่ replay draft เก่าอัตโนมัติหลังมีการแก้ไขใหม่

## Query และ indexes

รายการทริป query ใน users/{uid}/trips ด้วย status == active และ orderBy startDate ascending บันทึก composite index ที่ใช้จริงใน firestore.indexes.json แสดงข้อมูลแบบ stream ตาม SDK

กิจกรรมอ่านเฉพาะ subcollection ของทริปนั้นแล้วเรียงใน Dart ด้วย date, timeMinutes และ ID เป็นตัวตัดสินเมื่อเวลาเท่ากัน ทริป deleting query แยกสำหรับรายการลบค้างและ retry

MVP ออกแบบสำหรับทริปส่วนตัวข้อมูลขนาดเล็ก หากต้องรองรับรายการมากขึ้นให้เพิ่ม pagination ก่อนอ้างว่ารองรับจำนวนข้อมูลไม่จำกัด

## Security Rules และ validation

- ทุก path ต้องมี request.auth และ request.auth.uid == uid ปฏิเสธ path อื่นโดยค่าเริ่มต้น
- ตรวจ required/allowed fields ด้วย hasAll/hasOnly ตรวจ type ความยาว และช่วงตัวเลข ไม่พึ่ง Form Validation อย่างเดียว
- createdAt เปลี่ยนไม่ได้หลังสร้าง และใช้ request.time ตรวจ timestamp ที่ SDK ส่งด้วย serverTimestamp
- create trip กำหนด status active; ย้าย active → deleting ได้ แต่ไม่เปิดกลับผ่าน update ปกติ
- อ่านกิจกรรมได้เฉพาะเจ้าของและ parent ที่มีอยู่ สร้าง/แก้ไขได้เมื่อ parent active เท่านั้น
- ตรวจ date กิจกรรมกับช่วงวัน parent ใน Rules; ใช้ getAfter เมื่อมี parent update ใน batch เดียวกัน
- ลบกิจกรรมได้โดยเจ้าของทั้ง active และ deleting เพื่อรองรับ cleanup
- ตรวจรูปแบบวันที่ padded YYYY-MM-DD ใน Rules และตรวจวันที่ปฏิทินจริงเพิ่มใน Dart
- parent delete ได้เมื่อ status deleting; แอปต้องลบ children ก่อน เพราะ Rules ไม่สามารถยืนยันว่า collection ทั้งหมดว่างได้

Rules ของ client SDK ใช้ป้องกัน Flutter ที่เชื่อม Firestore โดยตรง อย่าใส่ service-account private key หรือใช้ Admin SDK ในแอป Firebase client configuration ที่สร้างด้วย FlutterFire ไม่ใช่ Admin credential

## ข้อจำกัดการแก้ไขหลายอุปกรณ์

การย่อช่วงวันต้องโหลดกิจกรรมล่าสุดจาก server ก่อนบันทึก ถ้ามีกิจกรรมนอกช่วงใหม่ให้ระบุรายการและหยุด ไม่ย้ายวันให้เอง รุ่นแรกสมมติว่าทริปหนึ่งถูกแก้ไขจากหนึ่งอุปกรณ์ในขณะหนึ่ง

การตรวจ children ทุกตัวก่อน parent update เป็น business validation ฝั่งแอปใน MVP ไม่ใช่การรับประกัน transaction ข้ามหลายเครื่อง Rules ไม่สามารถวน query children ทั้งหมดเพื่อยืนยันเงื่อนไขนี้ได้ ห้ามอ้างว่ารองรับ concurrent trip date edits อย่างสมบูรณ์ หากต้องรองรับภายหลังค่อยออกแบบ trusted server operation เพิ่ม

## การลบทริปและ retry

Firestore ไม่ลบ subcollection อัตโนมัติเมื่อ parent ถูกลบ จึงใช้ workflow ใน repository ดังนี้:

1. ต้องออนไลน์และผู้ใช้ยืนยัน จากนั้นเปลี่ยน parent เป็น deleting
2. UI หยุดสร้าง/แก้ไขทริปและกิจกรรม และแสดงรายการลบค้าง
3. อ่าน children จาก server และลบทีละ batch ขนาดเล็ก เช่น 100 รายการ จน query ไม่เหลือ children
4. ลบ parent แล้วลบเช็กลิสต์ในเครื่อง
5. ถ้าสะดุดให้คง deleting และให้ retry เมื่อกลับมาเปิดหน้ารายการ ไม่ขึ้นว่าสำเร็จก่อนจบ

การลบไม่ใช่ atomic cascade และต้องรอผู้ใช้กลับมาลองใหม่หากปิดแอประหว่างทาง ไม่มี background server cleanup ใน MVP การ retry ต้องทำซ้ำได้โดยไม่เสียหาย ให้บันทึก tripId ลง packingCleanup.v1.{uid} ก่อนเริ่มลบ และนำออกหลัง cloud/local cleanup จบ หากกลับมาแล้ว parent ยัง active ห้ามล้างเช็กลิสต์เพียงเพราะมี queue หาก parent deleting ให้ลบต่อ และถ้าอ่าน server ยืนยันว่า parent ไม่มีจึงล้าง local key ได้

## Errors และ async

แปลง validation, unauthenticated, permission-denied, not-found, unavailable และ unknown เป็น AppFailure ใช้ loading/empty/error/submitting state ป้องกันกดบันทึกซ้ำ และเก็บ draft เมื่อบันทึกไม่ผ่าน

รอผลยืนยันการเขียนจาก SDK ก่อนแจ้งว่าบันทึก cloud สำเร็จ หากใช้ข้อมูลจาก cache ให้แยกสถานะให้ชัด ขั้นตอนลบทั้งทริปและตรวจการย่อช่วงวันต้องใช้ข้อมูล server; ออฟไลน์ให้ลองใหม่ ไม่สร้าง offline write queue เพิ่มใน MVP

## การตั้งค่าและทดสอบ

เริ่ม Auth/Firestore Emulator ด้วย project ทดสอบ แยก config จาก live แล้วใช้ FlutterFire CLI สร้าง firebase_options.dart เมื่อมี Firebase project จริง เปิด Email/Password และสร้าง Firestore สำหรับ environment ที่ใช้สาธิต เก็บ rules/indexes ใน source และตรวจ config ให้ตรง project

Android Emulator เชื่อม host เครื่องพัฒนาผ่าน 10.0.2.2 ตาม port ที่ตั้งไว้ มือถือจริงใช้ host ที่อุปกรณ์เข้าถึงได้ แยก debug emulator configuration ออกจาก release ไม่ส่ง release ที่ยังชี้ Emulator

ทดสอบ Rules ด้วย @firebase/rules-unit-testing แยก anonymous, owner และ user B ครบ create/read/update/delete รวม query, payload ผิด, immutable timestamp, parent ไม่มี/กำลังลบ และวันที่นอกช่วง ทดสอบ cleanup สะดุดแล้ว retry และเปลี่ยนบัญชีแล้วไม่เห็น state ของบัญชีเดิม

การทดสอบ Emulator ไม่ใช่ผล live integration และไม่จำเป็นต้องมี Go runtime การ deploy rules/indexes หรือสร้าง cloud resources ทำเมื่อมีคำร้องขอที่ครอบคลุม ไม่ใช่เพราะเอกสารนี้ระบุเป็นงานในอนาคต

## เอกสารอ้างอิง

- [Firebase สำหรับ Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [Firestore การลบเอกสารและ collections](https://firebase.google.com/docs/firestore/manage-data/delete-data)
- [ทดสอบ Firestore Rules ด้วย Emulator](https://firebase.google.com/docs/firestore/security/test-rules-emulator)

## V2.1 ฟรี — สัญญาก่อนพัฒนา 26 ตุลาคม 2569

ไม่เปิด Billing/Blaze/API คิดเงิน ใช้ OSM tiles เดิมตามนโยบาย (attribution, app user-agent, cache, ไม่ prefetch/offline download) และ Maps URLs แบบไม่ใช้ key เปิด app/browser นำทางรายช่วง ข้อมูลแนะนำ bundle มากับแอป เริ่มเชียงใหม่ ไม่เรียก Places/Routes API

Activity อ่านเอกสารเก่าเป็น schema 1 โดย costKnown=true, category=other, orderIndex=timeMinutes*1000; ยอดเก่าเท่าเดิม ไม่ bulk migrate เมื่ออ่าน เมื่อบันทึกใช้ schemaVersion=2 และเพิ่ม category (attraction/food/lodging/other), orderIndex (int 0–1000000000), costKnown (bool), travelMode (none/car/motorcycle/walk/transit), travelFromId (string), travelSignature (string), travelCostKnown (bool), travelCostSatang (int satang) ฟิลด์ใหม่ครบกลุ่ม schema 2 หรือไม่มีกลุ่มเลยสำหรับ legacy

estimatedCostSatang เป็นยอดกิจกรรมรวม ไม่ใช่ราคาต่อหน่วย; costKnown=false บังคับยอด 0 แต่ UI แสดงไม่ทราบราคา ไม่ถือว่าฟรี travelCostSatang เป็นค่าเดินทางเข้าหมุดนี้สำหรับทั้งกลุ่ม กรอกเองเท่านั้น ระยะนี้ยังไม่คำนวณน้ำมัน/เส้นทางถนน/ค่าโดยสารอัตโนมัติ

ช่วงเดินทางเก็บบนกิจกรรมปลายทาง ไม่เพิ่ม legs collection จึงไม่มี leg กำพร้าหรือเปลี่ยน delete cascade เดิม travelSignature ผูก predecessor/target id พิกัด วันและเวลา; เปลี่ยนจุด/เวลา/ลำดับแล้วลายเซ็นไม่ตรงจะไม่รวมราคาเดิมและแจ้งให้กำหนดใหม่ จุดแรกของแต่ละวันไม่มีค่าเดินทางเข้า

เรียงวัน → orderIndex (legacy fallback time) → เวลา → id; swap ใช้ transaction อ่านรายการที่ผู้ใช้เห็นทั้งหมดในวันนั้นก่อนเขียน rank ใหม่ ป้องกันทับการแก้/ลบรายการที่อ่านแล้ว ข้อจำกัด single-editor ต่อทริปยังคงอยู่: รายการที่เพิ่งเพิ่มพร้อมกันจากอีกอุปกรณ์อาจไม่อยู่ใน transaction และต้อง refresh สูงสุด 100 จุดต่อรอบเรียง

ยอดรวม = กิจกรรมที่ทราบราคา + ค่าเดินทางเฉพาะช่วงที่ signature ยังตรง รวมครั้งเดียว; แสดงจำนวนรายการ/ช่วงที่ไม่ทราบและยอดคงเหลือจากข้อมูลที่ทราบ ไม่ซ่อนความไม่ครบของงบ ข้อความแชร์ใช้ลำดับ/ยอดเดียวกับหน้าจอและยังไม่ส่ง note/coordinates/identifiers

ดู FEATURE_THAILAND_TRIP_PLANNER.md และ IMPLEMENTATION_STATUS.md สำหรับผลจริง สัญญาในส่วนนี้แทนข้อเสนอเพิ่ม legs/costItems ใน V2.1; V2.2+ ยังไม่อยู่ในรอบนี้

## เพิ่มตามคำขอ: ตำแหน่งปัจจุบัน — 26 ตุลาคม 2569

อ่าน GPS ครั้งเดียวเมื่อผู้ใช้กดปุ่ม แสดงจุดสีน้ำเงินพร้อมความแม่นยำและเวลาอ่านบนแผนที่ ปุ่มอัปเดตต้องกดเอง ไม่มี background tracking/stream หรือบันทึกตำแหน่งปัจจุบันลง Firestore/SharedPreferences ผู้ใช้ปฏิเสธสิทธิ์/ปิด Location/หมดเวลารอได้โดยยังวางแผนต่อได้

เพิ่ม geolocator จาก pub.dev และสิทธิ์ Android coarse/fine ขอตอนกดใช้งาน ไม่ขอ background location; เลือกตำแหน่งใกล้เคียงได้ บริการเป็น OS GPS ไม่ใช้ API key/บริการเสียเงิน

แยกปุ่มนำทางตามแผนจากหมุดก่อนหน้า กับนำทางจากฉัน (ไม่ระบุ origin ให้ Google Maps อ่านตำแหน่งเอง) Maps ภายนอกเป็นผู้แสดงเส้นทางถนน คำสั่งเลี้ยว/เสียงนำทาง ไม่รับผลกลับ ไม่มี turn-by-turn engine ใน TripPocket

## V2.2 Nationwide POI correction — 26 ตุลาคม 2569

ผู้ใช้ยืนยันว่าต้องค้นทั่วไทยและเห็นสถานที่แนะนำให้เลือกบนแผนที่ แทนแค็ตตาล็อกเชียงใหม่ 4 รายการ ใช้ข้อมูล OpenStreetMap Thailand extract จาก Geofabrik สร้างแค็ตตาล็อกสถานที่มีชื่อในหมวดเที่ยว/อาหาร/ที่พัก/อื่น ๆ bundle ในแอป ไม่ใช้ public Nominatim/Overpass เป็น backend และไม่ใช้ paid API

อ่านข้อมูลจาก assets ผ่าน PlaceCatalog repository แบบ async แล้วประมวลผลนอก UI isolate ค้นชื่อ/ชื่อภาษาอังกฤษ/จังหวัดที่มี metadata และเลือกจากหมุดแนะนำในพื้นที่แผนที่ที่ผู้ใช้ดูอยู่ จำกัดการวาดหมุดตาม viewport/zoom เพื่อไม่วาดทั้งประเทศพร้อมกัน แต่ค้นทั้งแค็ตตาล็อกได้ แสดงจำนวนที่พบและขอบเขตผลลัพธ์อย่างตรงไปตรงมา

แยกหมุดแนะนำจากหมุดทริป: แตะหมุดแนะนำ → รายละเอียด/แหล่งข้อมูล → เลือกเพิ่ม → ตรวจหมุดและบันทึกฟอร์มเดิม ไม่เพิ่มเข้าทริปอัตโนมัติ ข้อมูลแค็ตตาล็อกประเทศไม่มี schema/Rules cloud เปลี่ยน และไม่เปลี่ยนราคาหรือทริปเก่า

แค็ตตาล็อกเป็น community data ไม่รับประกันว่ามีทุกธุรกิจหรือเปิดอยู่ ณ ปัจจุบัน ไม่แต่งราคา/เวลาเปิดปิด และไม่อ้างว่าตรวจสถานที่ทุกแห่งด้วยมือ จุดแทนพื้นที่อาจไม่ใช่ทางเข้า ทุกหน้าที่ใช้ข้อมูลมี attribution/ลิงก์ ODbL และแจกแค็ตตาล็อกที่แปลงแล้วภายใต้ ODbL แยกจาก source แอป

## หมุดพื้นที่หลักของทริป — 26 ตุลาคม 2569

ผู้ใช้ขอให้ช่องจุดหมายเห็นตำแหน่งบนแผนที่ เพิ่มค้นจาก catalogue ทั่วไทย/เลือกแผนที่และยืนยันหมุดในฟอร์มสร้างหรือแก้ทริป พร้อม preview และหมุดพื้นที่หลักในแท็บแผนที่ แยกจากจุดแวะรายวันและไม่รวมค่าใช้จ่าย/ลำดับเส้นทาง ข้อความ destination เป็นป้ายชื่อ ไม่ได้ geocode อัตโนมัติ

Trip เพิ่ม destinationLatitude/destinationLongitude (nullable number เป็นคู่) เอกสารเก่าที่ไม่มีทั้งคู่ยังอ่านเป็น null ไม่ migration และไม่เดาตำแหน่งจากชื่อ ฟอร์มเดิมแก้แล้วคงหมุด บันทึก null ทั้งคู่เมื่อผู้ใช้เอาหมุดออก เปลี่ยนหมุดต้องยืนยัน การยกเลิกไม่ทับ draft/pin เดิม

Rules อนุญาต legacy ที่ไม่มีคู่ หรือ null ทั้งคู่ หรือ number ทั้งคู่ที่ finite/อยู่ใน bounds พิกัดโลก ปฏิเสธคู่ไม่ครบ/ชนิดผิด/นอก bounds และยังคง uid ownership, timestamps, active/deleting เดิม Boundary ประเทศไทยตรวจใน picker ฝั่งแอปตามข้อจำกัดเดิม ไม่ใช้ Rules เป็น polygon validator ไม่มี GPS tracking/บริการเสียเงิน

ไม่ export พิกัดพื้นที่หลักในข้อความแชร์ ยังใช้ allowlist เดิม และไม่เปลี่ยนยอดทริปเก่า ตรวจ Flutter/Rules, Android และ live SDK ก่อนส่ง APK ที่ใช้ Firebase จริง

## Firebase iOS configuration — 2 พฤศจิกายน 2569

เพิ่มแอป Apple ชื่อ TripPocket iOS ในโปรเจกต์เดิม trippocket-382b7 (Spark) โดยใช้ Bundle ID com.imlv1.trippocket ตรงกับ Runner Debug/Profile/Release; Firebase App ID 1:488059345725:ios:8f897289980e7264a28354

ใช้ไฟล์ที่ดาวน์โหลดจาก Firebase Console จริงที่ ios/Runner/GoogleService-Info.plist และเพิ่ม PBXFileReference / Runner group / PBXBuildFile / Runner Resources ใน ios/Runner.xcodeproj/project.pbxproj เพื่อให้ไฟล์ถูก bundle เข้าแอป Firebase.initializeApp() ใน main.dart อ่าน native config เดิม ไม่เพิ่ม FirebaseApp.configure() ฝั่ง Swift หรือ native SDK ซ้ำกับ Flutter plugins

ตรวจ plist syntax, project/bundle/app IDs, คู่ reference และ Resources target ด้วยไฟล์จริงแล้ว Windows ไม่มี Xcode จึงยังไม่ได้ build/run iOS และไม่อ้างผล Firebase บน iPhone ผ่าน ต้องตรวจบน Mac/Xcode พร้อม signing ก่อนใช้งานจริง ไม่มี Rules/schema/billing เปลี่ยน

## Strict trip dates — 2 พฤศจิกายน 2569

สร้าง/บันทึก active trip ต้อง startDate < endDate ตามคำขอผู้ใช้ กฎวันในฟอร์ม/domain/Rules ต้องตรงกัน Legacy วันเดียวกันยังอ่านและลบแบบ resumable ได้ ไม่แก้ข้อมูลเก่าเมื่ออ่าน รายละเอียด exception deleting-only และการทดสอบอยู่ใน DATABASE_DESIGN.md

## Account profile — 2 พฤศจิกายน 2569

profile ใช้ Firebase Authentication displayName/photoURL/providerData ไม่เพิ่ม Firestore profile schema ใช้ userChanges สำหรับ Session และ reauthenticate ก่อนเปลี่ยน password Google link ต้องรักษา uid/ตรวจอีเมล ห้ามสลับไปเจ้าของ credential อื่น รายละเอียด privacy/recovery/test plan: FEATURE_ACCOUNT_PROFILE.md

## ยืนยันจบทริป — 2 พฤศจิกายน 2569

ตาม DATABASE_DESIGN.md เพิ่ม completed flag แยกจาก deletion status. completeTrip transaction ต้อง owner/active, idempotent, รักษา child/local data และ saveTrip ไม่ล้าง flag เดิม รายการแยกกำลังจะไป/จบแล้วผ่าน client filter uid-scoped ไม่เพิ่ม server/API หรือ billing
