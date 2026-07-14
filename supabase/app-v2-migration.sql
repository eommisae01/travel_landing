alter table trips add column if not exists country text not null default '';
alter table trips add column if not exists cities text[] not null default '{}';
alter table trips add column if not exists accommodation text not null default '';
alter table trips add column if not exists my_maps_url text not null default '';
alter table trips add column if not exists outbound_origin text not null default '';
alter table trips add column if not exists outbound_destination text not null default '';
alter table trips add column if not exists outbound_flight text not null default '';
alter table trips add column if not exists outbound_departure_time time;
alter table trips add column if not exists outbound_arrival_time time;
alter table trips add column if not exists return_origin text not null default '';
alter table trips add column if not exists return_destination text not null default '';
alter table trips add column if not exists return_flight text not null default '';
alter table trips add column if not exists return_departure_time time;
alter table trips add column if not exists return_arrival_time time;
alter table trips add column if not exists budget_amount numeric not null default 0;
alter table trips add column if not exists budget_currency text not null default 'JPY';
alter table trips add column if not exists archived boolean not null default false;

update trips
set
  country = coalesce(nullif(country, ''), '일본'),
  cities = case when cardinality(cities) = 0 then array['타카마쓰', '나오시마'] else cities end,
  accommodation = coalesce(nullif(accommodation, ''), '리쓰린코엔 기타구치역 근처 숙소 · 12:00 짐보관 기준'),
  outbound_origin = coalesce(nullif(outbound_origin, ''), '서울'),
  outbound_destination = coalesce(nullif(outbound_destination, ''), '타카마쓰'),
  outbound_flight = coalesce(nullif(outbound_flight, ''), 'RS0741'),
  outbound_arrival_time = coalesce(outbound_arrival_time, '10:30'::time),
  return_origin = coalesce(nullif(return_origin, ''), '타카마쓰'),
  return_destination = coalesce(nullif(return_destination, ''), '서울'),
  return_flight = coalesce(nullif(return_flight, ''), 'RS0742'),
  return_departure_time = coalesce(return_departure_time, '11:40'::time),
  budget_amount = case when budget_amount = 0 then 150000 else budget_amount end,
  budget_currency = coalesce(nullif(budget_currency, ''), 'JPY')
where id = 'trip-takamatsu-2026';
