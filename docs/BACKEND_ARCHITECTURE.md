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

### เช็กลิสต์ในเครื่อง

Key: `packing.v1.{uid}.{tripId}` ค่าคือ JSON array ของ `{id, text, checked}` text ต้องไม่ว่างหลัง trim อ่านเขียนผ่าน PackingRepository เท่านั้น หาก JSON เสียให้แจ้งปัญหา ไม่ overwrite ทิ้งเงียบ ๆ

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
