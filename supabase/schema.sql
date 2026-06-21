create table if not exists trips (
  id text primary key,
  name text not null,
  region text not null default '',
  start_date date not null,
  end_date date not null,
  hero_image text not null default '',
  note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists trip_members (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  name text not null,
  color text not null default '#16a3a3',
  role text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists itinerary_items (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  date date not null,
  time_label text not null default '',
  start_time time,
  end_time time,
  title text not null,
  description text not null default '',
  location text not null default '',
  priority text not null default '필수',
  reservation_status text not null default '확인 필요',
  weather_impact text not null default '중간',
  owner text not null default '',
  sort_order bigint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists places (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  name text not null,
  category text not null default '',
  address text not null default '',
  map_url text not null default '',
  hours text not null default '',
  reservation_note text not null default '',
  sensitive_note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists food_candidates (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  name text not null,
  category text not null default '',
  location text not null default '',
  map_url text not null default '',
  reservation text not null default '',
  wait_note text not null default '',
  recommender text not null default '',
  note text not null default '',
  is_favorite boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists checklist_items (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  group_name text not null default '공통',
  text text not null,
  owner text not null default '',
  is_done boolean not null default false,
  sort_order bigint not null default 0,
  is_archived boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists gallery_items (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  title text not null,
  src text not null default '',
  date date not null,
  category text not null default '',
  note text not null default '',
  is_favorite boolean not null default false,
  sort_order bigint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists onsite_notes (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  title text not null,
  body text not null default '',
  tone text not null default 'note',
  sort_order bigint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists expenses (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  category text not null default '기타',
  item text not null default '',
  amount numeric not null default 0,
  currency text not null default 'JPY',
  payer text not null default '',
  note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists quick_links (
  id text primary key,
  trip_id text not null references trips(id) on delete cascade,
  label text not null,
  kind text not null default '',
  url text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists app_settings (
  id text primary key,
  default_trip_id text not null references trips(id) on delete cascade,
  public_sensitive boolean not null default false,
  created_at timestamptz not null default now()
);

-- The Next.js server uses SUPABASE_SERVICE_ROLE_KEY after family-code validation.
-- Keep Row Level Security enabled so browser anon keys cannot read/write these tables directly.
alter table trips enable row level security;
alter table trip_members enable row level security;
alter table itinerary_items enable row level security;
alter table places enable row level security;
alter table food_candidates enable row level security;
alter table checklist_items enable row level security;
alter table gallery_items enable row level security;
alter table onsite_notes enable row level security;
alter table expenses enable row level security;
alter table quick_links enable row level security;
alter table app_settings enable row level security;
