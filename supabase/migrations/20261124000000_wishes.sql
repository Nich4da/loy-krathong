-- ลอยกระทงริมทะเล : สมุดคำอธิษฐาน
-- วางทั้งไฟล์นี้ใน Supabase > SQL Editor แล้วกด Run ครั้งเดียว (รันซ้ำได้ ไม่ทำข้อมูลหาย)
--
-- หลักการ
--   * ทุกคนอ่านคำอธิษฐานได้ (ยกเว้นคอลัมน์ owner_hash ที่ใช้ยืนยันเจ้าของ)
--   * การเพิ่ม/ลบ ทำผ่านฟังก์ชัน add_wish / delete_wish เท่านั้น
--     - เพิ่มได้ครั้งละ 1 ใบต่อ 10 วินาทีต่อเครื่อง และทั้งเว็บไม่เกิน 60 ใบต่อนาที
--     - ลบได้เฉพาะคำอธิษฐานที่เครื่องนั้นเป็นคนลอย (ยืนยันด้วยรหัสสุ่มของเครื่อง)
--   * เจ้าของเว็บลบรายการไหนก็ได้จาก Supabase > Table Editor > wishes

create table if not exists public.wishes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null default '' check (char_length(name) <= 30),
  wish        text not null check (char_length(btrim(wish)) between 1 and 140),
  base        text not null check (base   in ('leaf','bread','banana','lotusleaf')),
  flower      text not null check (flower in ('marigold','rose','lotus','orchid','jasmine')),
  candle      text not null check (candle in ('classic','twin','heart','gold','lotus')),
  owner_hash  text not null,
  created_at  timestamptz not null default now()
);

create index if not exists wishes_created_at_idx on public.wishes (created_at desc);
create index if not exists wishes_owner_idx      on public.wishes (owner_hash, created_at desc);

alter table public.wishes enable row level security;

drop policy if exists "anyone can read wishes" on public.wishes;
create policy "anyone can read wishes"
  on public.wishes for select
  to anon, authenticated
  using (true);

-- ปิดการเขียนตรง ให้อ่านได้เฉพาะคอลัมน์ที่แสดงบนหน้าเว็บ
revoke all on public.wishes from anon, authenticated;
grant select (id, name, wish, base, flower, candle, created_at) on public.wishes to anon, authenticated;

-- เพิ่มคำอธิษฐาน
create or replace function public.add_wish(
  p_id uuid, p_name text, p_wish text, p_base text, p_flower text, p_candle text, p_token text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hash text;
  v_id   uuid;
begin
  if p_token is null or char_length(p_token) < 16 or char_length(p_token) > 128 then
    raise exception 'invalid_token';
  end if;
  v_hash := encode(sha256(convert_to(p_token, 'UTF8')), 'hex');

  if exists (select 1 from wishes
             where owner_hash = v_hash and created_at > now() - interval '10 seconds') then
    raise exception 'too_fast';
  end if;
  if (select count(*) from wishes where created_at > now() - interval '1 minute') >= 60 then
    raise exception 'busy';
  end if;
  if (select count(*) from wishes) >= 20000 then
    raise exception 'full';
  end if;

  insert into wishes (id, name, wish, base, flower, candle, owner_hash)
  values (coalesce(p_id, gen_random_uuid()),
          left(btrim(coalesce(p_name, '')), 30),
          left(btrim(p_wish), 140),
          p_base, p_flower, p_candle, v_hash)
  returning id into v_id;
  return v_id;
end;
$$;

-- ลบคำอธิษฐานของตัวเอง
create or replace function public.delete_wish(p_id uuid, p_token text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  delete from wishes
  where id = p_id
    and owner_hash = encode(sha256(convert_to(coalesce(p_token, ''), 'UTF8')), 'hex');
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

revoke all on function public.add_wish(uuid, text, text, text, text, text, text) from public;
revoke all on function public.delete_wish(uuid, text) from public;
grant execute on function public.add_wish(uuid, text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.delete_wish(uuid, text) to anon, authenticated;
