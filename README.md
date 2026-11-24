# ลอยกระทงริมทะเล · Loy Krathong by the Sea

**▶ เล่นได้ที่ / Play: https://loy-krathong-nicha.netlify.app**

ประดิษฐ์กระทงของตัวเอง แล้วลอยลงทะเลยามพระอาทิตย์ตก พร้อมฝากคำอธิษฐานไว้ในสมุดเล่มเดียวกันกับทุกคน
Build your own krathong and float it onto a sunset sea, then leave your wish in a shared wish book.

| สร้างกระทง / Build | ลอยกระทง / Float | มือถือ / Mobile |
|---|---|---|
| ![Building a krathong](docs/screenshot-build.jpg) | ![A wish rising over the sea](docs/screenshot-float.jpg) | ![Mobile layout](docs/screenshot-mobile.jpg) |

## ฟีเจอร์ / Features

- **ประดิษฐ์กระทง 5 ขั้น** – ฐาน (ใบตอง ขนมปัง หยวกกล้วย ใบบัว) · ดอกไม้ 5 ชนิด · ธูปเทียน 5 แบบ · รูป 1 รูปจากแกลเลอรี · คำอธิษฐาน
  *5-step builder: base, flowers, candles & incense, one photo from your gallery, and a wish.*
- **ทะเลยามอาทิตย์ลับฟ้าแบบเคลื่อนไหว** วาดด้วย Canvas ทั้งหมด – คลื่น แสงสะท้อน เมฆ นก ดาว โคมลอย และเปลวเทียนที่ไหว
  *Fully hand-drawn animated sunset sea on `<canvas>`: waves, sun glints, clouds, birds, lanterns, flickering flames.*
- **เพลงประกอบสร้างสดในเบราว์เซอร์** – เปียโนเบา ๆ กับเสียงคลื่น ด้วย Web Audio ไม่มีไฟล์เสียง
  *Generative ambient piano and sea waves with the Web Audio API — no audio files.*
- **สมุดคำอธิษฐานรวม** – กระทงของทุกคนลอยอยู่บนทะเลเดียวกัน แตะกระทงเพื่อดูว่าเป็นของใคร
  *Shared wish book: everyone's krathong floats on the same sea; tap one to see whose it is.*
- **ความเป็นส่วนตัวระดับฐานข้อมูล** – คนอื่นเห็นแค่ชื่อ คำอธิษฐานเห็นได้เฉพาะเจ้าของกระทงและเจ้าของเว็บ
  *Privacy enforced in the database: others see only names; a wish's text is visible only to its author and the site owner.*
- **รูปไม่ออกจากเครื่อง** – รูปบนกระทงเก็บเฉพาะในเบราว์เซอร์ของคนลอย
  *Photos never leave the device (stored only in the floater's browser).*
- รองรับมือถือ แผงทำกระทงพับได้ กระทงที่ลอยแล้วยังอยู่หลังรีเฟรช
  *Responsive, foldable builder panel, krathongs persist across reloads.*

## เทคโนโลยี / Tech

| ส่วน / Part | ใช้ / Uses |
|---|---|
| หน้าเว็บ / Front end | HTML · CSS · vanilla JavaScript, Canvas 2D, Web Audio — single file, no framework or build step |
| ฐานข้อมูล / Database | [Supabase](https://supabase.com) (Postgres + REST), Row Level Security, column-level grants, `SECURITY DEFINER` functions |
| โฮสต์ / Hosting | [Netlify](https://netlify.com) |
| ฟอนต์ / Fonts | Charm, Anuphan (Google Fonts) |

## โครงสร้าง / Structure

```
public/
  index.html          หน้าเว็บทั้งหมด / the whole app
  config.js           Supabase URL + publishable key (public by design)
supabase/migrations/
  …_wishes.sql          ตาราง + ฟังก์ชันเพิ่ม/ลบ + กันสแปม / table, add/delete functions, rate limits
  …_private_wishes.sql  ความเป็นส่วนตัว + โหมดเจ้าของเว็บ / privacy rules + owner mode
docs/                 ภาพหน้าจอ / screenshots
```

## ความปลอดภัย / How the data is protected

- เขียนตรงลงตารางไม่ได้ ทุกการเพิ่ม/ลบต้องผ่านฟังก์ชันในฐานข้อมูล
  *No direct table writes; every add/delete goes through database functions.*
- อ่านได้เฉพาะคอลัมน์ ชื่อ แบบกระทง และเวลา — คอลัมน์คำอธิษฐานถูกปิดสิทธิ์
  *Visitors can only select name, krathong style and time; the wish column is not granted.*
- แต่ละเครื่องมีรหัสสุ่มของตัวเอง (เก็บแค่ค่า hash ในฐานข้อมูล) ใช้ยืนยันว่าเป็นเจ้าของคำอธิษฐาน
  *Each device has a random secret; only its SHA-256 hash is stored, proving authorship without accounts.*
- กันสแปม: 1 ใบต่อ 10 วินาทีต่อเครื่อง, ไม่เกิน 60 ใบต่อนาทีทั้งเว็บ, สูงสุด 20,000 ใบ
  *Rate limits: 1 wish / 10 s per device, 60 / min site-wide, 20,000 total.*
- คีย์ใน `config.js` เป็นคีย์ publishable ที่ออกแบบมาให้อยู่บนหน้าเว็บได้
  *The key in `config.js` is a publishable key, meant to be public.*

## รันเอง / Run it yourself

1. สร้างโปรเจกต์ Supabase แล้วรันไฟล์ใน `supabase/migrations/` ตามลำดับ (SQL Editor หรือ `supabase db query --remote --file …`)
   *Create a Supabase project and run the migration files in order.*
2. ใส่ Project URL และ publishable key ใน `public/config.js`
   *Put your project URL and publishable key in `public/config.js`.*
3. ลองบนเครื่อง / Try locally:

```bash
python3 -m http.server 8080 --directory public
```

4. ขึ้นเว็บ / Deploy:

```bash
npx netlify-cli deploy --prod --dir public
```

ถ้า `config.js` เว้นว่าง เว็บยังเล่นได้ โดยเก็บกระทงไว้แค่ในเครื่อง
*With an empty `config.js` the site still works, keeping krathongs on the device only.*

## ดูแลเว็บ / Maintaining (owner notes)

- **โหมดเจ้าของเว็บ:** เปิด `…/#owner` บนเบราว์เซอร์ที่ใช้ประจำ แล้วกด "ตั้งเครื่องนี้เป็นเจ้าของ" (ตั้งได้เครื่องเดียว) จะเห็นทุกคำอธิษฐานและลบได้ทุกใบ
- **ย้ายเครื่องเจ้าของ:** SQL Editor → `delete from public.site_owner_devices;` แล้วตั้งใหม่ผ่าน `#owner`
- **ลบรายการไม่เหมาะสม:** ในโหมดเจ้าของกดลบได้เลย หรือ Supabase → Table Editor → `wishes`
- **โปรเจกต์ถูกพัก** (ฟรีเทียร์ ไม่มีคนเข้าราว 1 สัปดาห์): Supabase → โปรเจกต์ → Restore ข้อมูลไม่หาย
- **สำรองข้อมูล:** Table Editor → `wishes` → Export CSV เป็นระยะ
