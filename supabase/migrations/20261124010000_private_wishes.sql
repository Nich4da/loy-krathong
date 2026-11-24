-- คำอธิษฐานเป็นความลับ
--   * คนทั่วไปอ่านได้แค่ ชื่อ แบบกระทง และเวลา (อ่านคอลัมน์ wish ตรง ๆ ไม่ได้)
--   * เจ้าของกระทงอ่านคำอธิษฐานของตัวเองได้ผ่าน my_wishes (ยืนยันด้วยรหัสเครื่อง)
--   * เจ้าของเว็บ (เครื่องที่ลงทะเบียนผ่าน claim_owner ได้เพียงเครื่องแรก) อ่านทั้งหมดผ่าน owner_wishes และลบได้ทุกใบ
--   * ล้างเจ้าของเพื่อตั้งใหม่: รัน  delete from public.site_owner_devices;  ใน SQL Editor

-- 1) ปิดการอ่านคอลัมน์ wish จากหน้าเว็บ
revoke select on public.wishes from anon, authenticated;
grant select (id, name, base, flower, candle, created_at) on public.wishes to anon, authenticated;

-- 2) เครื่องของเจ้าของเว็บ
create table if not exists public.site_owner_devices (
  token_hash text primary key,
  created_at timestamptz not null default now()
);
alter table public.site_owner_devices enable row level security;
revoke all on public.site_owner_devices from anon, authenticated;

create or replace function public._token_hash(p_token text)
returns text language sql immutable
set search_path = public
as $$ select encode(sha256(convert_to(coalesce(p_token, ''), 'UTF8')), 'hex') $$;

create or replace function public._is_owner(p_token text)
returns boolean language sql stable security definer
set search_path = public
as $$
  select p_token is not null and char_length(p_token) >= 16
     and exists (select 1 from site_owner_devices where token_hash = _token_hash(p_token))
$$;

-- ลงทะเบียนเครื่องนี้เป็นเจ้าของ ได้เฉพาะตอนที่ยังไม่มีเจ้าของ
create or replace function public.claim_owner(p_token text)
returns text language plpgsql security definer
set search_path = public
as $$
begin
  if p_token is null or char_length(p_token) < 16 or char_length(p_token) > 128 then
    raise exception 'invalid_token';
  end if;
  if _is_owner(p_token) then return 'already'; end if;
  lock table site_owner_devices in exclusive mode;
  if exists (select 1 from site_owner_devices) then return 'taken'; end if;
  insert into site_owner_devices (token_hash) values (_token_hash(p_token));
  return 'ok';
end;
$$;

create or replace function public.is_owner(p_token text)
returns boolean language sql stable security definer
set search_path = public
as $$ select _is_owner(p_token) $$;

-- มีเจ้าของแล้วหรือยัง (ใช้ซ่อนปุ่มลงทะเบียน)
create or replace function public.owner_claimed()
returns boolean language sql stable security definer
set search_path = public
as $$ select exists (select 1 from site_owner_devices) $$;

-- คำอธิษฐานของเครื่องนี้
create or replace function public.my_wishes(p_token text)
returns table (id uuid, wish text) language sql stable security definer
set search_path = public
as $$
  select w.id, w.wish from wishes w
  where char_length(coalesce(p_token, '')) >= 16 and w.owner_hash = _token_hash(p_token)
  order by w.created_at desc limit 300
$$;

-- คำอธิษฐานทั้งหมด (เจ้าของเว็บเท่านั้น)
create or replace function public.owner_wishes(p_token text)
returns table (id uuid, wish text) language plpgsql stable security definer
set search_path = public
as $$
begin
  if not _is_owner(p_token) then raise exception 'not_owner'; end if;
  return query select w.id, w.wish from wishes w order by w.created_at desc limit 1000;
end;
$$;

-- ลบ: เจ้าของกระทงลบของตัวเองได้ เจ้าของเว็บลบได้ทุกใบ
create or replace function public.delete_wish(p_id uuid, p_token text)
returns boolean language plpgsql security definer
set search_path = public
as $$
declare v_count integer;
begin
  if _is_owner(p_token) then
    delete from wishes where id = p_id;
  else
    delete from wishes where id = p_id and owner_hash = _token_hash(p_token);
  end if;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

revoke all on function public._token_hash(text) from public, anon, authenticated;
revoke all on function public._is_owner(text) from public, anon, authenticated;
revoke all on function public.claim_owner(text) from public;
revoke all on function public.is_owner(text) from public;
revoke all on function public.owner_claimed() from public;
revoke all on function public.my_wishes(text) from public;
revoke all on function public.owner_wishes(text) from public;
revoke all on function public.delete_wish(uuid, text) from public;
grant execute on function public.claim_owner(text) to anon, authenticated;
grant execute on function public.is_owner(text) to anon, authenticated;
grant execute on function public.owner_claimed() to anon, authenticated;
grant execute on function public.my_wishes(text) to anon, authenticated;
grant execute on function public.owner_wishes(text) to anon, authenticated;
grant execute on function public.delete_wish(uuid, text) to anon, authenticated;
