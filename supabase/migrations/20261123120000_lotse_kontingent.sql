-- Kontingent des Lotsen: Anfragen je Nutzer (anonyme Geräte-ID) und Tag. Keine Fragen, keine Inhalte.
create table if not exists public.lotse_kontingent (
  nutzer text not null,
  tag date not null,
  anzahl integer not null default 0,
  primary key (nutzer, tag)
);

alter table public.lotse_kontingent enable row level security;
-- kein Zugriff für anon/authenticated – nur die Edge Function mit Service-Role

create or replace function public.lotse_zaehlen(p_nutzer text, p_tag date)
returns integer language sql security definer as $$
  insert into public.lotse_kontingent (nutzer, tag, anzahl) values (p_nutzer, p_tag, 1)
  on conflict (nutzer, tag) do update set anzahl = lotse_kontingent.anzahl + 1
  returning anzahl;
$$;

create or replace function public.lotse_stand(p_nutzer text, p_tag date)
returns integer language sql security definer stable as $$
  select coalesce((select anzahl from public.lotse_kontingent where nutzer = p_nutzer and tag = p_tag), 0);
$$;

revoke all on function public.lotse_zaehlen(text, date) from public, anon, authenticated;
revoke all on function public.lotse_stand(text, date) from public, anon, authenticated;
-- Nur die Edge Function (service_role) darf zählen
grant execute on function public.lotse_zaehlen(text, date) to service_role;
grant execute on function public.lotse_stand(text, date) to service_role;
grant select, insert, update on table public.lotse_kontingent to service_role;

-- Aufräumen: Zähler älter als 60 Tage löschen (per Cron oder von Hand)
-- delete from public.lotse_kontingent where tag < current_date - 60;
