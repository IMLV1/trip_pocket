# ตรวจไฟล์และประวัติ Git ก่อนเผยแพร่

ตรวจวันที่ 2 พฤศจิกายน 2569 ณ commit `67aac50` (ก่อนเพิ่มรายงานนี้)

## ขอบเขตที่ตรวจจริง

- fetch ทุก remote และ tags แล้ว: 26 commits ใน refs ของ repo และ 1 commit เพิ่มจาก reflog ในเครื่อง
- 194 ไฟล์ปัจจุบัน / 194 ชื่อไฟล์ทั้งหมดที่เคยอยู่ใน commits ที่ตรวจ ไม่มีชื่อไฟล์ที่ถูกลบเหลือเฉพาะในประวัติ
- 330 blobs ไม่ซ้ำใน refs/reflog และ 11 blobs เพิ่มที่ `git fsck` พบในเครื่องแต่ไม่อยู่ใน commits เหล่านั้น รวม 341 blobs
- สแกนข้อความ 284 เวอร์ชันด้วย Gitleaks 8.30.1 และตรวจรูปแบบ private keys, service accounts, tokens, JWT, session URLs เพิ่ม พร้อม recursive decoding สูงสุด 3 ชั้น
- สแกน commit messages/metadata แยก ตรวจภาพ 56 เวอร์ชันด้วยสายตา รวม metadata ของ PNG/EXIF/XMP; binary ที่เหลือเป็น Noto Sans Thai font
- ตรวจ `.gitignore` ด้วยชื่อไฟล์ตัวอย่าง ไม่สร้างหรืออัปโหลดไฟล์ลับ และไม่ได้ส่งเนื้อหา repo ให้บริการสแกนภายนอก
- ดาวน์โหลด Gitleaks จาก official GitHub release และตรวจ SHA256 ตรงกับ checksums ของ release ใช้รายงานที่ redact ค่า 100%

## ผลตรวจ

ไม่พบ private key, Admin Service Account, access/refresh token, session JWT หรือรหัสผ่านบัญชีจริงจากการสแกนที่ระบุ ไม่ใช่การรับประกันว่าจะไม่มีข้อมูลลับทุกชนิด

| รายการ | ผลและสิ่งที่ควรทำ |
|---|---|
| Firebase API keys ใน Android/iOS config | พบ client keys 2 ค่าในไฟล์ platform config; Gitleaks รายงาน gcp-api-key 1 รายการที่ Android ตั้งแต่ commit `5b169ee` และยังอยู่ปัจจุบัน เป็น client config ตามเอกสาร Firebase ไม่ใช่ Admin credential ไม่แสดงค่าจริงในรายงานนี้ |
| รหัสผ่านใน integration tests | เป็นสตริงสร้างตามรอบทดสอบและอีเมล example.com ไม่ใช่รหัสผ่านบัญชีผู้ใช้ ห้ามแทนด้วยข้อมูลจริง |
| รูป `docs/evidence/firebase-trip-pin-rules.png` | มีภาพบัญชี Google มุมขวาบน ควรครอป/ปิดรูปบัญชีก่อนเปิด repo เป็น Public |
| เอกสาร `IMPLEMENTATION_PROMPTS.md`, `IMPLEMENTATION_STATUS.md` | มี path เครื่องพัฒนาและชื่อ user ใน path ข้อมูลส่วนตัวระดับต่ำ ไม่ใช่ secret ถ้าจะเผยแพร่สาธารณะควรเปลี่ยนเป็น path ตัวอย่าง |
| Git author/committer metadata | มี email identities 3 รายการในประวัติ เป็น Git metadata ปกติ ตรวจ privacy ของอีเมลก่อนเปิด Public การลบข้อความจากไฟล์ไม่ลบ Git metadata เดิม |
| ภาพอื่นและ EXIF/XMP | ไม่พบ password/token หรือ GPS metadata จากภาพที่ตรวจ พิกัดในภาพแผนที่เป็นสถานที่ทดสอบ/ข้อมูลสาธารณะ ภาพ GPS ระบุ Emulator จำลอง; XMP มี toolkit/orientation/dimensions/color space ไม่พบ creator/email/user path |
| ไฟล์ใหญ่ | `assets/thailand_pois.json` ประมาณ 11.85 MB เป็นข้อมูลจำเป็นสำหรับค้นหาออฟไลน์ มี ODbL/license ไม่ควรลบเพียงเพราะเป็น JSON ขนาดใหญ่; รูป screenshot รุ่นเก่าใหญ่สุดประมาณ 3.29 MB |
| build/cache/signing ที่อยู่ในประวัติ | ไม่พบ `.env`, Service Account, private key, APK/IPA, build, node_modules, local.properties, keystore หรือ logs ถูก track ใน refs/reflog ที่ตรวจ |

## ช่องว่างของ .gitignore

กัน `.env`, `*.jks`, `*.keystore`, `key.properties`, ชื่อแบบ service-account/serviceAccount, build/cache/logs และ Xcode userdata แล้ว แต่ชื่อเหล่านี้ยังไม่ถูกกันจาก root rules:

- `credentials/admin.json`, `firebase-adminsdk.json` (ชื่อไม่ตรง service-account pattern)
- `signing.p12`, `AuthKey.p8`, private key ที่ใช้ `.pem`, `id_rsa`/`id_ed25519`
- signing profiles `*.mobileprovision`

ปัจจุบันไม่พบไฟล์เหล่านี้บน GitHub ที่ตรวจ เป็นข้อเสนอป้องกันในอนาคต ยังไม่ได้แก้ `.gitignore`, ลบไฟล์, หมุนคีย์ หรือ rewrite ประวัติโดยคำสั่งตรวจนี้

## สิ่งที่ควรเก็บใน repo

ซอร์ส, tests, Firestore Rules/indexes, `.firebaserc`, `firebase.json`, `pubspec.lock`, `package-lock.json`, client Firebase config, ข้อมูล POI พร้อม license, ฟอนต์พร้อม OFL และเอกสาร/สไลด์ของโครงการ

Firebase อธิบายว่า config ฝั่ง client เป็นข้อมูล public ไม่ใช่การอนุญาตเข้าฐานข้อมูล: https://firebase.google.com/docs/projects/learn-more และ https://firebase.google.com/docs/projects/api-keys ข้อจำกัด API key ฝั่ง Google Cloud ไม่สามารถยืนยันจากไฟล์ repo เพียงอย่างเดียว

## ข้อจำกัด

ครอบคลุม refs ที่ fetch ได้, reflog และ unreachable objects ที่ยังมีอยู่ในเครื่องนี้ ไม่รวม objects ที่ถูก garbage collect ไปแล้ว, forks/clones อื่น, GitHub Actions logs/artifacts, release attachments, issues/PR attachments หรือค่าฝั่ง Cloud Console ไม่ได้ทำ malware analysis ของฟอนต์/ไบนารีหรือ penetration test ของแอป ภาพตรวจด้วยสายตา ไม่ใช่การรับรอง OCR ทุกตัวอักษร

ไม่ commit รายงานเครื่องมือดิบ, extracted blobs หรือ contact sheets เพราะอาจเพิ่มข้อมูลที่ไม่จำเป็นและซ้ำจากประวัติ เก็บเพียงรายงานสรุปที่ไม่เปิดเผยค่า secret
