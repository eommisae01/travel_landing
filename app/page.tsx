"use client";

import {
  Archive,
  CalendarDays,
  CheckCircle2,
  CloudRain,
  CreditCard,
  GripVertical,
  ExternalLink,
  Home,
  Images,
  ListTodo,
  Loader2,
  Lock,
  LogOut,
  Map,
  MapPin,
  Pencil,
  Plane,
  Plus,
  Settings,
  Sparkles,
  Soup,
  Star,
  Trash2,
  X
} from "lucide-react";
import { FormEvent, useEffect, useMemo, useState } from "react";
import type { ComponentType, ReactNode } from "react";
import { inferGoogleMapsName } from "./lib/maps";
import { MY_MAPS_EMBED_URL, seedData } from "./lib/seed";
import {
  ChecklistItem,
  Expense,
  FoodCandidate,
  GalleryItem,
  ItineraryItem,
  OnsiteNote,
  Place,
  QuickLink,
  TableName,
  Trip,
  TripData
} from "./lib/types";

type ViewKey = "home" | "schedule" | "gallery" | "map" | "checklist" | "food" | "budget" | "onsite" | "settings";
type SaveState = "idle" | "saving" | "saved" | "error";
type DayWeather = Record<string, { label: string; rain: number; wind: number; high: number; low: number }>;

const navItems: Array<{ key: ViewKey; label: string; icon: ComponentType<{ size?: number }> }> = [
  { key: "home", label: "홈", icon: Home },
  { key: "schedule", label: "일정", icon: CalendarDays },
  { key: "gallery", label: "자료", icon: Images },
  { key: "map", label: "지도/식당", icon: Map },
  { key: "checklist", label: "체크리스트", icon: ListTodo },
  { key: "budget", label: "예산", icon: CreditCard },
  { key: "onsite", label: "현장", icon: MapPin },
  { key: "settings", label: "설정", icon: Settings }
];

const weatherUrl = "https://api.open-meteo.com/v1/forecast?latitude=34.3428&longitude=134.0466&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&current=temperature_2m,weather_code,wind_speed_10m&timezone=Asia%2FTokyo";

const recommendationTopics = ["식당", "카페", "관광지", "비 오는 날", "나오시마 동선", "현장 리스크"];

function labelWeather(code?: number) {
  if (code === undefined) return "예보 확인";
  if ([0, 1].includes(code)) return "맑음";
  if ([2, 3].includes(code)) return "구름 많음";
  if ([45, 48].includes(code)) return "안개";
  if ([51, 53, 55, 61, 63, 65, 80, 81, 82].includes(code)) return "비 가능";
  if ([95, 96, 99].includes(code)) return "뇌우 가능";
  return "날씨 확인";
}

function todayKey() {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Seoul", year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
}

function dateLabel(value: string) {
  return new Intl.DateTimeFormat("ko-KR", { month: "long", day: "numeric", weekday: "short" }).format(new Date(`${value}T00:00:00`));
}

function makeId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function itineraryKind(item: Pick<ItineraryItem, "title" | "location">) {
  const text = `${item.title} ${item.location}`;
  if (/이동|공항|항|페리|버스|택시|→/.test(text)) return "이동";
  if (/식당|우동|카페|이자카야|저녁|점심|아침/.test(text)) return "식사";
  return "장소";
}

function looksLikeCoords(value?: string) {
  return Boolean(value && /^-?\d+(\.\d+)?,-?\d+(\.\d+)?(,0)?$/.test(value.trim()));
}

function displayPlaceText(value?: string, fallback = "지도 링크 확인") {
  if (!value || looksLikeCoords(value)) return fallback;
  return value;
}

function groupBy<T>(items: T[], getKey: (item: T) => string) {
  return items.reduce<Record<string, T[]>>((groups, item) => {
    const key = getKey(item);
    groups[key] ||= [];
    groups[key].push(item);
    return groups;
  }, {});
}

function useWeather() {
  const [brief, setBrief] = useState("타카마쓰 날씨를 확인하는 중");
  const [byDate, setByDate] = useState<DayWeather>({});
  useEffect(() => {
    let mounted = true;
    fetch(weatherUrl)
      .then((res) => {
        if (!res.ok) throw new Error("weather");
        return res.json();
      })
      .then((weather) => {
        if (!mounted) return;
        const current = weather.current;
        const text = current
          ? `현재 ${Math.round(current.temperature_2m)}°C · ${labelWeather(current.weather_code)} · 바람 ${Math.round(current.wind_speed_10m)}km/h`
          : "날씨 링크에서 예보 확인";
        const daily: DayWeather = {};
        weather.daily?.time?.forEach((date: string, index: number) => {
          daily[date] = {
            label: labelWeather(weather.daily.weather_code?.[index]),
            rain: weather.daily.precipitation_probability_max?.[index] ?? 0,
            wind: Math.round(weather.daily.wind_speed_10m_max?.[index] ?? 0),
            high: Math.round(weather.daily.temperature_2m_max?.[index] ?? 0),
            low: Math.round(weather.daily.temperature_2m_min?.[index] ?? 0)
          };
        });
        setByDate(daily);
        setBrief(text);
      })
      .catch(() => {
        if (mounted) setBrief("날씨 자동 확인이 어려워요. 빠른 링크에서 예보를 확인하세요.");
      });
    return () => {
      mounted = false;
    };
  }, []);
  return { brief, byDate };
}

function LoginScreen({ onSuccess }: { onSuccess: () => void }) {
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const response = await fetch("/api/verify-code", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ code })
    });
    setBusy(false);
    if (!response.ok) {
      setError("가족코드가 맞지 않아요.");
      return;
    }
    onSuccess();
  }

  return (
    <main className="grid min-h-screen place-items-center p-4">
      <section className="glass grid w-full max-w-md gap-5 rounded-lg p-5">
        <div className="hero-photo min-h-56 rounded-lg p-5 text-white">
          <div className="inline-flex items-center gap-2 rounded-full bg-white/18 px-3 py-1 text-sm font-bold backdrop-blur">
            <Lock size={16} /> Family only
          </div>
          <h1 className="mt-10 text-4xl font-black leading-none">타카마쓰 가족여행</h1>
          <p className="mt-3 text-white/85">일정, 지도, 준비물, 예산을 가족끼리 함께 정리하는 여행 앱입니다.</p>
        </div>
        <form className="grid gap-3" onSubmit={submit}>
          <label className="grid gap-2 text-sm font-black">
            가족코드
            <input className="field" value={code} onChange={(event) => setCode(event.target.value)} placeholder="가족코드를 입력하세요" />
          </label>
          {error ? <p className="text-sm font-bold text-coral">{error}</p> : null}
          <button className="btn" disabled={busy} type="submit">
            {busy ? <Loader2 className="animate-spin" size={18} /> : <Lock size={18} />} 들어가기
          </button>
        </form>
        <p className="text-xs font-semibold text-black/50">개발 기본 코드는 `.env.example`에 있습니다. 배포 전에는 반드시 바꾸세요.</p>
      </section>
    </main>
  );
}

export default function Page() {
  const [authenticated, setAuthenticated] = useState<boolean | null>(null);
  const [data, setData] = useState<TripData>(seedData);
  const [mode, setMode] = useState<"supabase" | "demo">("demo");
  const [active, setActive] = useState<ViewKey>("home");
  const [saveState, setSaveState] = useState<SaveState>("idle");

  async function loadData() {
    const response = await fetch("/api/data", { cache: "no-store" });
    if (response.status === 401) {
      setAuthenticated(false);
      return;
    }
    if (!response.ok) throw new Error("data");
    const payload = await response.json();
    setData(payload.data);
    setMode(payload.mode);
    setAuthenticated(true);
  }

  useEffect(() => {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/sw.js").catch(() => {});
    }
    fetch("/api/session", { cache: "no-store" })
      .then((res) => res.json())
      .then((session) => {
        if (session.authRequired === false) {
          setAuthenticated(true);
          loadData().catch(() => setAuthenticated(true));
          return;
        }
        setAuthenticated(Boolean(session.authenticated));
        if (session.authenticated) loadData().catch(() => setAuthenticated(true));
      })
      .catch(() => setAuthenticated(false));
  }, []);

  useEffect(() => {
    if (!authenticated || mode !== "supabase") return;
    const timer = window.setInterval(() => loadData().catch(() => {}), 9000);
    return () => window.clearInterval(timer);
  }, [authenticated, mode]);

  async function mutate<T extends { id: string }>(table: TableName, action: "create" | "update" | "delete", payload: { row?: Partial<T>; id?: string; patch?: Partial<T> }) {
    setSaveState("saving");
    const previous = data;
    if (action === "update" && payload.id && payload.patch) {
      setData((current) => {
        const list = current[table] as unknown as T[];
        return {
          ...current,
          [table]: list.map((item) => (item.id === payload.id ? { ...item, ...payload.patch } : item))
        };
      });
    }
    if (action === "delete" && payload.id) {
      setData((current) => {
        const list = current[table] as unknown as T[];
        return { ...current, [table]: list.filter((item) => item.id !== payload.id) };
      });
    }
    const response = await fetch("/api/data", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ table, action, ...payload })
    });
    if (!response.ok) {
      setData(previous);
      setSaveState("error");
      return null;
    }
    const { row } = await response.json();
    setData((current) => {
      const list = current[table] as unknown as T[];
      const next = action === "create"
        ? [row as T, ...list]
        : action === "update"
          ? list.map((item) => (item.id === payload.id ? { ...item, ...row } : item))
          : list;
      return { ...current, [table]: next };
    });
    setSaveState("saved");
    window.setTimeout(() => setSaveState("idle"), 1200);
    return row as T;
  }

  if (authenticated === null) {
    return <main className="grid min-h-screen place-items-center"><Loader2 className="animate-spin text-sea" size={34} /></main>;
  }

  if (!authenticated) {
    return <LoginScreen onSuccess={() => loadData().catch(() => setAuthenticated(true))} />;
  }

  const trip = data.trips[0] || seedData.trips[0];

  return (
    <div className="app-shell">
      <SideNav active={active} setActive={setActive} saveState={saveState} mode={mode} />
      <main className="min-w-0 px-4 py-4 lg:px-8 lg:py-6">
        <Header trip={trip} onLogout={async () => {
          await fetch("/api/session", { method: "DELETE" });
          setAuthenticated(false);
        }} />
        {active === "home" && <HomeView data={data} setActive={setActive} mutate={mutate} />}
        {active === "schedule" && <ScheduleView items={data.itinerary_items} places={data.places} foods={data.food_candidates} trip={trip} mutate={mutate} />}
        {active === "gallery" && <GalleryView items={data.gallery_items} trip={trip} mutate={mutate} />}
        {active === "map" && <MapView places={data.places} foods={data.food_candidates} links={data.quick_links} trip={trip} mutate={mutate} />}
        {active === "checklist" && <ChecklistView items={data.checklist_items} mutate={mutate} />}
        {active === "food" && <FoodView foods={data.food_candidates} trip={trip} mutate={mutate} />}
        {active === "budget" && <BudgetView expenses={data.expenses} members={data.trip_members.map((member) => member.name)} trip={trip} mutate={mutate} />}
        {active === "onsite" && <OnsiteView notes={data.onsite_notes} links={data.quick_links} mutate={mutate} />}
        {active === "settings" && <SettingsView data={data} mode={mode} mutate={mutate} />}
      </main>
      <BottomNav active={active} setActive={setActive} />
    </div>
  );
}

function SideNav({ active, setActive, saveState, mode }: { active: ViewKey; setActive: (key: ViewKey) => void; saveState: SaveState; mode: string }) {
  return (
    <aside className="glass sticky top-0 hidden h-screen flex-col gap-5 p-4 lg:flex">
      <div>
        <p className="text-xs font-black uppercase text-sea">Family trip</p>
        <h2 className="text-2xl font-black">Takamatsu</h2>
      </div>
      <nav className="grid gap-1">
        {navItems.map((item) => <NavButton key={item.key} item={item} active={active} setActive={setActive} />)}
      </nav>
      <div className="mt-auto rounded-lg bg-white p-3 text-sm font-bold text-black/60">
        <p>저장: {saveState === "saving" ? "저장 중" : saveState === "saved" ? "완료" : saveState === "error" ? "오류" : "대기"}</p>
        <p>모드: {mode === "supabase" ? "Supabase" : "데모"}</p>
      </div>
    </aside>
  );
}

function BottomNav({ active, setActive }: { active: ViewKey; setActive: (key: ViewKey) => void }) {
  return (
    <nav className="bottom-nav glass fixed inset-x-0 bottom-0 z-20 flex gap-1 overflow-x-auto rounded-t-lg px-2 pt-2 lg:hidden">
      {navItems.map((item) => <NavButton key={item.key} item={item} active={active} setActive={setActive} compact />)}
    </nav>
  );
}

function NavButton({ item, active, setActive, compact = false }: { item: (typeof navItems)[number]; active: ViewKey; setActive: (key: ViewKey) => void; compact?: boolean }) {
  const Icon = item.icon;
  const selected = active === item.key;
  return (
    <button
      className={`flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm font-black ${compact ? "min-w-[4.1rem] flex-col gap-1 px-1 text-[0.72rem]" : "justify-start"} ${selected ? "bg-ink text-white" : "text-black/58 hover:bg-white"}`}
      onClick={() => setActive(item.key)}
      type="button"
    >
      <Icon size={compact ? 19 : 18} />
      {item.label}
    </button>
  );
}

function Header({ trip, onLogout }: { trip: TripData["trips"][number]; onLogout: () => void }) {
  const cityOptions = trip.cities?.length ? trip.cities : trip.region.split("·").map((city) => city.trim()).filter(Boolean);
  return (
    <header className="hero-photo mb-4 rounded-lg p-4 text-white shadow-soft lg:p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-black text-white/70">{dateLabel(trip.start_date)} - {dateLabel(trip.end_date)}</p>
          <h1 className="mt-1 text-3xl font-black leading-none lg:text-5xl">{trip.name}</h1>
          <div className="mt-2 flex flex-wrap items-center gap-2 text-xs font-bold text-white/78">
            <span className="rounded-full bg-white/12 px-2.5 py-1">{trip.country || "국가 미정"}</span>
            <select className="rounded-full border border-white/15 bg-white/12 px-2.5 py-1 font-black text-white outline-none" aria-label="도시 선택" defaultValue={cityOptions[0] || trip.region}>
              {cityOptions.map((city, index) => <option className="text-black" key={`${city}-${index}`} value={city}>도시 {index + 1} · {city}</option>)}
              <option className="text-black" value="add">+ 다음 도시 추가</option>
            </select>
          </div>
          <div className="mt-3 flex flex-wrap gap-2 text-xs font-bold text-white/82">
            <span className="inline-flex items-center gap-1 rounded-full bg-white/12 px-2.5 py-1"><Plane size={14} />가는 편 {trip.outbound_flight || "편명 미정"} · {trip.outbound_origin || "출발지"} → {trip.outbound_destination || "도착지"} · {trip.outbound_arrival_time || "도착시간 미정"} 도착</span>
            <span className="inline-flex items-center gap-1 rounded-full bg-white/12 px-2.5 py-1"><Plane size={14} />오는 편 {trip.return_flight || "편명 미정"} · {trip.return_origin || "출발지"} → {trip.return_destination || "도착지"} · {trip.return_departure_time || "출발시간 미정"} 출발</span>
          </div>
        </div>
        <button className="btn bg-white/16 px-3 text-white backdrop-blur" onClick={onLogout} type="button" aria-label="로그아웃">
          <LogOut size={18} />
        </button>
      </div>
    </header>
  );
}

function HomeView({ data, setActive, mutate }: { data: TripData; setActive: (key: ViewKey) => void; mutate: PageMutate }) {
  const weather = useWeather();
  const [recommendOpen, setRecommendOpen] = useState(false);
  const [researchNotes, setResearchNotes] = useState([
    { id: "ferry", title: "페리 시간", body: "페리 소요 약 50분, 성인 편도 520엔. 차량/자전거 선적 가능, 객실이 넓고 안정적.\n\n타카마쓰항 → 나오시마\n08:12 → 09:02\n10:14 → 11:04 (추천)\n12:40 → 13:30\n15:35 → 16:25\n18:05 → 18:55\n\n나오시마 → 타카마쓰항\n07:00 → 07:50\n09:20 → 10:10\n11:30 → 12:20\n14:20 → 15:10\n17:00 → 17:50 (추천)" },
    { id: "fast-boat", title: "고속선 시간", body: "고속선 소요 약 30분, 성인 편도 1,220엔. 승선 인원 제한, 자전거 선적 불가.\n\n타카마쓰항 → 나오시마\n07:45 → 08:15\n09:20 → 09:50\n11:35 → 12:05\n16:10 → 16:40\n19:35 → 20:05\n\n나오시마 → 타카마쓰항\n08:35 → 09:05\n10:35 → 11:05\n13:15 → 13:45\n16:55 → 17:25\n18:35 → 19:05" },
    { id: "chichu-route", title: "지중미술관 동선", body: "숙소 인근 JR 리쓰린코엔 기타구치역에서 오전 9:20 전후 열차 탑승 → 다카마쓰역/항구 이동.\n\n10:14 페리 탑승 → 11:04 나오시마 도착. 항구 앞 자전거 대여 및 점심.\n\n지중미술관은 12:00 예약 완료. 성인 3명, 각 ¥2,500.\n\n관람 후 이에 프로젝트/근처 동선을 보고 17:00 페리로 복귀하면 17:50 다카마쓰항 도착." },
    { id: "naoshima-bus", title: "나오시마 버스/셔틀", body: "미야노우라항에 내리면 재빨리 2번 정류장으로 이동.\n\n1) 시내버스: 미야노우라항 → 츠츠지소. 요금 100엔, 하차할 때 지불, 약 20분.\n2) 츠츠지소에서 베네세 구역 무료 셔틀버스 환승.\n\n셔틀 노선: 츠츠지소 → 히로시 스기모토 갤러리 → 베네세 하우스 뮤지엄 → 이우환 미술관/Valley Gallery → 지중미술관.\n\n복귀 노선: 지중미술관 → 이우환 미술관/Valley Gallery → 베네세 하우스 뮤지엄 → 히로시 스기모토 갤러리 → 츠츠지소.\n\n버스 기다리는 시간과의 싸움. 페리 도착 직후 사람 많은 시간에는 추가 버스가 붙기도 하지만, 놓치면 대기가 길어질 수 있음." },
    { id: "museum-hours", title: "나오시마 미술관 운영시간", body: "베네세 하우스 뮤지엄: 08:00-21:00, 마지막 입장 20:00.\nValley Gallery: 09:30-16:00, 마지막 입장 15:30. 베네세 하우스 티켓에 포함.\n히로시 스기모토 갤러리: 11:00-15:00, 마지막 입장 14:00, 날짜/시간 예약 필요.\n지중미술관: 10:00-17:00, 마지막 입장 16:00, 날짜/시간 예약 필요. 6/23 12:00 예약 완료.\n이우환 미술관: 10:00-17:00, 마지막 입장 16:30.\n나오시마 신미술관: 10:00-16:30, 마지막 입장 16:00." },
    { id: "museum-order", title: "나오시마 관람 순서 후보", body: "A안: 지중미술관 → 이우환미술관 + Valley Gallery → 베네세 하우스 뮤지엄.\nB안: 베네세 하우스 뮤지엄 → Valley Gallery + 이우환미술관 → 지중미술관.\n\n이번 예약은 지중미술관 12:00이라 A안을 기본으로 두고, 셔틀 대기 시간이 길면 가까운 곳 위주로 줄이기.\n\n이동 감각: 지중미술관 → 이우환미술관은 전기자전거+도보 10분 이내 또는 셔틀 5분. 이우환미술관 → 베네세 하우스는 도보 10분 또는 셔틀 3분. 베네세 하우스 → 지중미술관은 전기자전거+도보 20분 이내 또는 셔틀 5분." },
    { id: "airport-bus", title: "공항/리무진버스/티켓", body: "6/24 RS0742 11:40 출발. 마지막 날은 관광보다 체크아웃과 공항 이동 중심.\n\n타카마쓰 공항 국제선 쪽 114Bank Money Exchange, 은행 ATM에서 트래블카드 출금/환전 확인. 사진 기준 9:00-21:00.\n\n공항 도착/출발 때 리무진버스 티켓 구매 위치도 같이 확인해두기." },
    { id: "boat-experience", title: "나룻배체험", body: "선착순 성격이 강하고 원하는 시간대가 있으면 미리 예매 필요. 6/23은 12:00 지중미술관 예약이 고정이라 오전에는 무리하지 않기. 페리/버스/셔틀 대기가 길어지면 체험은 과감히 후보로만 두기." }
  ]);
  const [researchDraft, setResearchDraft] = useState({ title: "", body: "" });
  const today = todayKey();
  const todaysItems = data.itinerary_items.filter((item) => item.date === today);
  const pendingChecks = data.checklist_items.filter((item) => item.group_name === "여행준비" && !item.is_done && !item.is_archived);
  const totalExpense = data.expenses.reduce((sum, expense) => sum + Number(expense.amount || 0), 0);

  return (
    <section className="grid gap-4">
      <div className="grid gap-3 md:grid-cols-4">
        <Metric title="날씨" value={weather.brief} icon={CloudRain} />
        <Metric title="오늘 일정" value={`${todaysItems.length || data.itinerary_items.length}개`} icon={CalendarDays} />
        <Metric title="미완료 준비" value={`${pendingChecks.length}개`} icon={ListTodo} />
        <Metric title="지출" value={`${totalExpense.toLocaleString("ko-KR")} JPY`} icon={CreditCard} />
      </div>
      <Panel title="숙소 / 이동 기준">
        <div className="grid gap-2 md:grid-cols-3">
          <div className="rounded-lg bg-white p-3">
            <p className="text-xs font-black text-sea">숙소</p>
            <p className="mt-1 text-sm font-black">{data.trips[0]?.accommodation || "숙소를 설정에서 입력하세요."}</p>
          </div>
          <div className="rounded-lg bg-white p-3">
            <p className="text-xs font-black text-sea">도착</p>
            <p className="mt-1 text-sm font-black">{data.trips[0]?.outbound_origin || "출발지"} → {data.trips[0]?.outbound_destination || "도착지"} · {data.trips[0]?.outbound_flight || "편명"} · {data.trips[0]?.outbound_arrival_time || "도착시간"} 도착</p>
          </div>
          <div className="rounded-lg bg-white p-3">
            <p className="text-xs font-black text-sea">출발</p>
            <p className="mt-1 text-sm font-black">{data.trips[0]?.return_origin || "출발지"} → {data.trips[0]?.return_destination || "도착지"} · {data.trips[0]?.return_flight || "편명"} · {data.trips[0]?.return_departure_time || "출발시간"} 출발</p>
          </div>
        </div>
      </Panel>
      <div className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <Panel title="오늘의 브리핑" action={<button className="btn btn-secondary" onClick={() => setActive("schedule")} type="button">일정 보기</button>}>
          {(todaysItems.length ? todaysItems : data.itinerary_items.slice(0, 4)).map((item) => <ItineraryCard key={item.id} item={item} compact weather={weather.byDate[item.date]} />)}
        </Panel>
        <Panel title="여행준비" action={<button className="btn btn-secondary" onClick={() => setActive("checklist")} type="button">전체 보기</button>}>
          {pendingChecks.length ? pendingChecks.slice(0, 7).map((item) => (
            <div className="flex items-center justify-between gap-2 rounded-lg bg-white px-3 py-2 text-sm font-bold" key={item.id}>
              <label className="flex min-w-0 items-center gap-2">
                <input className="h-4 w-4 shrink-0 accent-sea" type="checkbox" checked={item.is_done} onChange={(event) => mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { is_done: event.target.checked } })} />
                <span className="truncate">{item.text}</span>
              </label>
              <span className="shrink-0 text-xs text-black/40">{item.owner || "공통"}</span>
            </div>
          )) : <Empty text="여행 준비가 모두 완료됐어요." />}
        </Panel>
      </div>
      <Panel title="빠른 링크" action={<button className="btn btn-secondary" type="button" onClick={() => setRecommendOpen(true)}><Sparkles size={16} />추천 도우미</button>}>
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
          {data.quick_links.map((link) => <a className="btn btn-secondary" href={link.url} key={link.id} rel="noreferrer" target="_blank">{link.label}<ExternalLink size={16} /></a>)}
        </div>
      </Panel>
      <Panel title="Notes" titleClassName="research-title">
        <div className="grid gap-2">
          {researchNotes.map((note) => (
            <details className="rounded-lg bg-white p-3" key={note.id}>
              <summary className="cursor-pointer text-sm font-black">{note.title}</summary>
              <textarea
                className="field research-textarea mt-2"
                rows={Math.max(5, note.body.split("\n").length + 1)}
                value={note.body}
                onChange={(event) => setResearchNotes(researchNotes.map((item) => item.id === note.id ? { ...item, body: event.target.value } : item))}
              />
            </details>
          ))}
          <form className="grid gap-2 md:grid-cols-[12rem_1fr_auto]" onSubmit={(event) => {
            event.preventDefault();
            setResearchNotes([{ id: makeId("research"), ...researchDraft }, ...researchNotes]);
            setResearchDraft({ title: "", body: "" });
          }}>
            <input className="field" placeholder="항목명" value={researchDraft.title} onChange={(event) => setResearchDraft({ ...researchDraft, title: event.target.value })} required />
            <textarea className="field min-h-20" placeholder="메모" value={researchDraft.body} onChange={(event) => setResearchDraft({ ...researchDraft, body: event.target.value })} />
            <button className="btn" type="submit"><Plus size={16} />추가</button>
          </form>
        </div>
      </Panel>
      {recommendOpen ? <RecommendationModal onClose={() => setRecommendOpen(false)} /> : null}
    </section>
  );
}

function RecommendationModal({ onClose }: { onClose: () => void }) {
  const [topic, setTopic] = useState(recommendationTopics[0]);
  const [customPrompt, setCustomPrompt] = useState("");
  const [result, setResult] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const suggestions = [
    { type: "우동", title: "숙소 근처 우동 후보", query: "Takamatsu udon near Ritsurin Koen Kitaguchi" },
    { type: "카페", title: "비 오는 날 카페 후보", query: "Takamatsu cafe rainy day near station" },
    { type: "관광지", title: "나오시마 보조 장소", query: "Naoshima art museum nearby spots" },
    { type: "저녁", title: "가족 저녁 후보", query: "Takamatsu dinner family restaurant" }
  ];

  const generate = async () => {
    setBusy(true);
    setError("");
    setResult("");
    try {
      const response = await fetch("/api/recommendations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic, prompt: customPrompt })
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(body.message || "추천을 만들지 못했어요.");
      setResult(body.text || "");
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "추천을 만들지 못했어요.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="fixed inset-0 z-30 grid place-items-center bg-black/35 p-3">
      <section className="glass max-h-[82vh] w-full max-w-xl overflow-auto rounded-lg p-4">
        <div className="mb-3 flex items-center justify-between">
          <div>
            <p className="text-xs font-black text-sea">숨겨진 추천</p>
            <h2 className="text-xl font-black">AI 추천 도우미</h2>
          </div>
          <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={onClose}>닫기</button>
        </div>
        <div className="mb-3 grid gap-3 rounded-lg bg-white p-3">
          <div className="flex gap-2 overflow-x-auto pb-1">
            {recommendationTopics.map((item) => (
              <button className={`chip shrink-0 border ${topic === item ? "bg-sea text-white" : "bg-white text-black"}`} key={item} type="button" onClick={() => setTopic(item)}>
                {item}
              </button>
            ))}
          </div>
          <textarea
            className="field min-h-20"
            placeholder="원하는 조건이 있으면 추가로 적기. 예: 어른 3명, 짐 적게 들고 이동, 12:00 지중미술관 예약, 웨이팅 적은 곳"
            value={customPrompt}
            onChange={(event) => setCustomPrompt(event.target.value)}
          />
          <button className="btn justify-center" type="button" onClick={generate} disabled={busy}>
            {busy ? <Loader2 className="animate-spin" size={16} /> : <Sparkles size={16} />}
            추천 생성
          </button>
          {error ? <p className="rounded-lg bg-coral/10 p-3 text-sm font-bold text-coral">{error}</p> : null}
          {result ? (
            <div className="grid gap-2 rounded-lg bg-sea/5 p-3">
              {result.split(/\n{2,}/).filter(Boolean).map((paragraph, index) => (
                <p className="whitespace-pre-wrap text-sm font-semibold leading-relaxed text-black/68" key={`${paragraph}-${index}`}>{paragraph}</p>
              ))}
            </div>
          ) : null}
        </div>
        <p className="mb-2 text-sm font-bold text-black/55">빠르게 지도에서 직접 확인할 후보 검색도 남겨둘게요.</p>
        <div className="grid gap-2">
          {suggestions.map((item) => (
            <article className="card grid gap-1 p-3" key={item.title}>
              <p className="text-xs font-black text-coral">{item.type}</p>
              <h3 className="font-black">{item.title}</h3>
              <a className="btn btn-secondary mt-1 min-h-9 justify-self-start" href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(item.query)}`} target="_blank" rel="noreferrer">Google Maps에서 보기<ExternalLink size={15} /></a>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}

function ScheduleView({ items, places, foods, trip, mutate }: { items: ItineraryItem[]; places: Place[]; foods: FoodCandidate[]; trip: TripData["trips"][number]; mutate: PageMutate }) {
  const weather = useWeather();
  const [openDate, setOpenDate] = useState("");
  const [pickerDate, setPickerDate] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState("all");
  const [viewMode, setViewMode] = useState<"timeline" | "calendar">("timeline");
  const [draft, setDraft] = useState({ date: "2026-06-22", time_label: "", start_time: "", end_time: "", title: "", description: "", location: "", priority: "필수", reservation_status: "확인 필요", weather_impact: "중간", owner: "다 같이" });
  const sortedItems = useMemo(() => [...items].sort((a, b) => a.date.localeCompare(b.date) || (a.start_time || "99:99").localeCompare(b.start_time || "99:99") || a.sort_order - b.sort_order), [items]);
  const tripDates = tripDateOptions(trip);
  const allDates = Array.from(new Set([...tripDates, ...sortedItems.map((item) => item.date)])).sort();
  const visibleItems = selectedDate === "all" ? sortedItems : sortedItems.filter((item) => item.date === selectedDate);
  const grouped = useMemo(() => Object.entries(groupBy(visibleItems, (item) => item.date)), [visibleItems]);
  const dates = allDates;
  if (!dates.includes(draft.date) && dates[0]) draft.date = dates[0];
  const submitDraft = (date = draft.date) => {
    mutate<ItineraryItem>("itinerary_items", "create", { row: { id: makeId("iti"), ...draft, date, sort_order: Date.now() } });
    setDraft({ ...draft, date, time_label: "", start_time: "", end_time: "", title: "", description: "", location: "" });
    setOpenDate("");
  };
  return (
    <section className="grid gap-4">
      <Panel title="다음에 정할 것">
        <div className="grid gap-2 md:grid-cols-3">
          <Metric title="예약 확인" value={`${items.filter((item) => item.reservation_status.includes("확인") || item.reservation_status.includes("필요")).length}개`} icon={CheckCircle2} />
          <Metric title="이동 일정" value={`${items.filter((item) => itineraryKind(item) === "이동").length}개`} icon={MapPin} />
          <Metric title="비 예보" value={`${Object.values(weather.byDate).filter((day) => day.rain >= 40).length ? "확인 필요" : "낮음"}`} icon={CloudRain} />
        </div>
      </Panel>
      <Panel title="일정 추가">
        <ScheduleForm draft={draft} setDraft={setDraft} dates={dates} onSubmit={(event) => {
          event.preventDefault();
          submitDraft();
        }} />
      </Panel>
      <Panel title="보기">
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button className={`btn shrink-0 ${selectedDate === "all" ? "" : "btn-secondary"}`} type="button" onClick={() => setSelectedDate("all")}>전체</button>
          {allDates.map((date, index) => (
            <button className={`btn shrink-0 ${selectedDate === date ? "" : "btn-secondary"}`} key={date} type="button" onClick={() => setSelectedDate(date)}>Day {index + 1} · {dateLabel(date)}</button>
          ))}
        </div>
        <div className="grid grid-cols-2 gap-2 md:w-80">
          <button className={`btn ${viewMode === "timeline" ? "" : "btn-secondary"}`} type="button" onClick={() => setViewMode("timeline")}>타임라인</button>
          <button className={`btn ${viewMode === "calendar" ? "" : "btn-secondary"}`} type="button" onClick={() => setViewMode("calendar")}>Calendar</button>
        </div>
      </Panel>
      {viewMode === "calendar" ? (
        <ScheduleCalendar dates={allDates} items={visibleItems} onSelectDate={(date) => {
          setSelectedDate(date);
          setViewMode("timeline");
        }} />
      ) : grouped.length ? grouped.map(([date, dayItems]) => (
        <Panel title={dateLabel(date)} key={date} action={<div className="flex gap-2"><button className="btn btn-secondary" type="button" onClick={() => setPickerDate(date)}><Plus size={17} />장소/식당</button><button className="btn btn-secondary" type="button" onClick={() => {
          setDraft({ ...draft, date });
          setOpenDate(openDate === date ? "" : date);
        }}><Plus size={17} />직접 입력</button></div>}>
          {openDate === date ? (
            <ScheduleForm compact draft={{ ...draft, date }} setDraft={setDraft} dates={[date]} onSubmit={(event) => {
              event.preventDefault();
              submitDraft(date);
            }} />
          ) : null}
          {(dayItems || []).map((item) => (
            <ItineraryCard key={item.id} item={item} weather={weather.byDate[item.date]} onDelete={() => mutate<ItineraryItem>("itinerary_items", "delete", { id: item.id })} onStatus={(reservation_status) => mutate<ItineraryItem>("itinerary_items", "update", { id: item.id, patch: { reservation_status } })} onPatch={(patch) => mutate<ItineraryItem>("itinerary_items", "update", { id: item.id, patch })} />
          ))}
        </Panel>
      )) : <Panel title="일정"><Empty text="이 날짜에는 아직 일정이 없어요." /></Panel>}
      {pickerDate ? (
        <SchedulePickerModal
          date={pickerDate}
          trip={trip}
          places={places}
          foods={foods}
          onClose={() => setPickerDate(null)}
          onAdd={(row) => {
            mutate<ItineraryItem>("itinerary_items", "create", { row });
            setPickerDate(null);
          }}
        />
      ) : null}
    </section>
  );
}

type PageMutate = <T extends { id: string }>(table: TableName, action: "create" | "update" | "delete", payload: { row?: Partial<T>; id?: string; patch?: Partial<T> }) => Promise<T | null>;

function ScheduleCalendar({ dates, items, onSelectDate }: { dates: string[]; items: ItineraryItem[]; onSelectDate: (date: string) => void }) {
  const grouped = groupBy(items, (item) => item.date);
  return (
    <Panel title="Calendar view">
      <div className="grid gap-2 md:grid-cols-3 xl:grid-cols-4">
        {dates.map((date, index) => {
          const dayItems = grouped[date] || [];
          return (
            <button className="card grid min-h-36 gap-2 p-3 text-left" key={date} type="button" onClick={() => onSelectDate(date)}>
              <div>
                <p className="text-xs font-black text-sea">Day {index + 1}</p>
                <h3 className="font-black">{dateLabel(date)}</h3>
              </div>
              <div className="grid gap-1">
                {dayItems.slice(0, 4).map((item) => (
                  <p className="truncate rounded bg-black/[0.035] px-2 py-1 text-xs font-bold" key={item.id}>{item.start_time ? `${item.start_time} ` : ""}{item.title}</p>
                ))}
                {dayItems.length > 4 ? <p className="text-xs font-black text-black/40">+ {dayItems.length - 4}개 더</p> : null}
                {!dayItems.length ? <p className="text-xs font-bold text-black/40">일정 없음</p> : null}
              </div>
            </button>
          );
        })}
      </div>
    </Panel>
  );
}

function ScheduleForm({ draft, setDraft, dates, onSubmit, compact = false }: { draft: Partial<ItineraryItem>; setDraft: (draft: any) => void; dates: string[]; onSubmit: (event: FormEvent) => void; compact?: boolean }) {
  return (
    <form className={`grid gap-2 ${compact ? "rounded-lg bg-white p-3" : ""} md:grid-cols-6`} onSubmit={onSubmit}>
      {dates.length > 1 ? (
        <select className="field" value={draft.date || dates[0]} onChange={(event) => setDraft({ ...draft, date: event.target.value })}>{dates.map((date) => <option value={date} key={date}>{dateLabel(date)}</option>)}</select>
      ) : <input className="field" readOnly value={dateLabel(dates[0] || draft.date || "")} />}
      <input className="field" type="time" value={draft.start_time || ""} onChange={(event) => setDraft({ ...draft, start_time: event.target.value })} aria-label="시작 시간" />
      <input className="field" type="time" value={draft.end_time || ""} onChange={(event) => setDraft({ ...draft, end_time: event.target.value })} aria-label="종료 시간" />
      <input className="field md:col-span-2" placeholder="일정 제목" value={draft.title || ""} onChange={(event) => setDraft({ ...draft, title: event.target.value })} required />
      <button className="btn" type="submit"><Plus size={18} />추가</button>
      <input className="field md:col-span-3" placeholder="설명" value={draft.description || ""} onChange={(event) => setDraft({ ...draft, description: event.target.value })} />
      <input className="field md:col-span-3" placeholder="장소" value={draft.location || ""} onChange={(event) => setDraft({ ...draft, location: event.target.value })} />
    </form>
  );
}

function SchedulePickerModal({ date, trip, places, foods, onClose, onAdd }: { date: string; trip: TripData["trips"][number]; places: Place[]; foods: FoodCandidate[]; onClose: () => void; onAdd: (row: Partial<ItineraryItem>) => void }) {
  const [tab, setTab] = useState<"places" | "foods">("places");
  const [plan, setPlan] = useState({ date, start_time: "", end_time: "" });
  const dates = tripDateOptions(trip);
  return (
    <div className="fixed inset-0 z-30 grid place-items-center bg-black/35 p-3">
      <section className="glass max-h-[84vh] w-full max-w-2xl overflow-auto rounded-lg p-4">
        <div className="mb-3 flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black text-sea">{dateLabel(plan.date)}</p>
            <h2 className="text-xl font-black">일정에 바로 추가</h2>
          </div>
          <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={onClose}>닫기</button>
        </div>
        <div className="mb-3 grid gap-2 md:grid-cols-3">
          <select className="field" value={plan.date} onChange={(event) => setPlan({ ...plan, date: event.target.value })}>{dates.map((item) => <option key={item} value={item}>{dateLabel(item)}</option>)}</select>
          <input className="field" type="time" value={plan.start_time} onChange={(event) => setPlan({ ...plan, start_time: event.target.value })} aria-label="시작 시간" />
          <input className="field" type="time" value={plan.end_time} onChange={(event) => setPlan({ ...plan, end_time: event.target.value })} aria-label="종료 시간" />
        </div>
        <div className="mb-3 grid grid-cols-2 gap-2">
          <button className={`btn ${tab === "places" ? "" : "btn-secondary"}`} type="button" onClick={() => setTab("places")}>지도/장소</button>
          <button className={`btn ${tab === "foods" ? "" : "btn-secondary"}`} type="button" onClick={() => setTab("foods")}>식당</button>
        </div>
        <div className="grid gap-2">
          {tab === "places" ? places.map((place) => (
            <article className="card flex items-center justify-between gap-3 p-3" key={place.id}>
              <div className="min-w-0">
                <p className="text-xs font-black text-sea">{place.category || "장소"}</p>
                <h3 className="truncate font-black">{place.name}</h3>
                <p className="truncate text-xs font-semibold text-black/50">{place.sensitive_note || place.reservation_note || displayPlaceText(place.address)}</p>
              </div>
              <button className="btn min-h-9 shrink-0 px-3" type="button" onClick={() => onAdd(itineraryFromPlace(place, plan))}>추가</button>
            </article>
          )) : foods.map((food) => (
            <article className="card flex items-center justify-between gap-3 p-3" key={food.id}>
              <div className="min-w-0">
                <p className="text-xs font-black text-coral">{food.category || "식당"}</p>
                <h3 className="truncate font-black">{food.name}</h3>
                <p className="truncate text-xs font-semibold text-black/50">{food.note || displayPlaceText(food.location)}</p>
              </div>
              <button className="btn min-h-9 shrink-0 px-3" type="button" onClick={() => onAdd(itineraryFromFood(food, plan))}>추가</button>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}

function ItineraryCard({ item, compact = false, weather, onDelete, onStatus, onPatch }: { item: ItineraryItem; compact?: boolean; weather?: DayWeather[string]; onDelete?: () => void; onStatus?: (value: string) => void; onPatch?: (patch: Partial<ItineraryItem>) => void }) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState({ title: item.title, description: item.description, location: item.location });
  const timeRange = item.start_time ? `${item.start_time.slice(0, 5)}${item.end_time ? ` - ${item.end_time.slice(0, 5)}` : ""}` : item.time_label;
  const kind = itineraryKind(item);
  const tone = kind === "이동" ? "bg-[#eef7ff] border-sky-200" : kind === "식사" ? "bg-[#fff7ed] border-orange-100" : "bg-white/82 border-black/5";
  return (
    <article className={`grid grid-cols-[5.75rem_minmax(0,1fr)] gap-5 rounded-lg border p-3 shadow-sm ${tone}`}>
      <div className="relative pr-5 text-right">
        <div className="absolute right-1 top-8 h-[calc(100%+1rem)] w-px bg-black/10" />
        <div className={`relative z-10 ml-auto mr-[-0.15rem] mt-2 h-3 w-3 rounded-full ring-4 ${kind === "이동" ? "bg-sky-500 ring-sky-100" : kind === "식사" ? "bg-orange-400 ring-orange-100" : "bg-sea ring-sea/15"}`} />
        <p className="mt-2 text-xs font-black leading-tight text-sea">{timeRange}</p>
      </div>
      <div className="min-w-0">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="text-xs font-black text-black/40">{dateLabel(item.date)} · {item.time_label || kind}</p>
            {editing ? <input className="field mt-1 min-h-9 px-2 py-1 text-base font-black" value={draft.title} onChange={(event) => setDraft({ ...draft, title: event.target.value })} /> : <h3 className="text-base font-black md:text-lg">{kind === "이동" ? "↔ " : ""}{item.title}</h3>}
          </div>
          <div className="flex shrink-0 gap-1">
            {onPatch ? editing ? (
              <button className="btn btn-secondary min-h-9 px-3 text-sm" onClick={() => {
                onPatch(draft);
                setEditing(false);
              }} type="button">저장</button>
            ) : <button className="btn btn-secondary min-h-9 px-2" onClick={() => {
              setDraft({ title: item.title, description: item.description, location: item.location });
              setEditing(true);
            }} type="button" aria-label="수정"><Pencil size={16} /></button> : null}
            {onDelete ? <button className="btn btn-danger min-h-9 px-2" onClick={onDelete} type="button" aria-label="삭제"><Trash2 size={16} /></button> : null}
          </div>
        </div>
        {editing ? (
          <div className="mt-2 grid gap-2">
            <textarea className="field min-h-20" value={draft.description} onChange={(event) => setDraft({ ...draft, description: event.target.value })} />
            <input className="field" value={draft.location} onChange={(event) => setDraft({ ...draft, location: event.target.value })} placeholder="일정 안 장소/메모" />
          </div>
        ) : (
          <>
            <p className="mt-1 text-sm font-semibold text-black/62">{item.description}</p>
            {!compact ? <p className="mt-1 text-sm font-bold text-black/48">{displayPlaceText(item.location, "장소는 지도 링크로 확인")}</p> : null}
          </>
        )}
        <div className="mt-2 flex flex-wrap gap-2">
          <span className="chip bg-sea/10 text-sea">{item.priority}</span>
          {onStatus ? (
            <select className="chip border-0 bg-sun/20 text-black" value={item.reservation_status} onChange={(event) => onStatus(event.target.value)}>
              {["확인 필요", "예약 필요", "예약 완료", "현장 결제", "해당 없음"].map((option) => <option key={option}>{option}</option>)}
            </select>
          ) : <span className="chip bg-sun/20 text-black">{item.reservation_status}</span>}
          <span className="chip bg-coral/10 text-coral">{weather ? `${weather.label} · 강수 ${weather.rain}%` : "날씨 확인"}</span>
        </div>
      </div>
    </article>
  );
}

function GalleryView({ items, trip, mutate }: { items: GalleryItem[]; trip: TripData["trips"][number]; mutate: PageMutate }) {
  const [selectedDate, setSelectedDate] = useState("all");
  const [groupMode, setGroupMode] = useState<"date" | "category">("date");
  const [favoriteOnly, setFavoriteOnly] = useState(false);
  const [selected, setSelected] = useState<GalleryItem | null>(null);
  const [slideIndex, setSlideIndex] = useState(0);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [uploadDraft, setUploadDraft] = useState({ title: "", date: trip.start_date, category: "자료", note: "" });
  const [uploading, setUploading] = useState(false);
  const dates = ["all", ...tripDateOptions(trip)];
  const filtered = items
    .filter((item) => selectedDate === "all" || item.date === selectedDate)
    .filter((item) => !favoriteOnly || item.is_favorite)
    .sort((a, b) => (b.is_favorite ? 1 : 0) - (a.is_favorite ? 1 : 0) || (a.date || "").localeCompare(b.date || "") || (a.sort_order || 0) - (b.sort_order || 0));
  const grouped = Object.entries(groupBy(filtered, (item) => groupMode === "date" ? item.date || "날짜 없음" : item.category || "기타"));
  const selectedSlides = selected ? items
    .filter((item) => item.date === selected.date && item.category === selected.category)
    .sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0)) : [];
  const activeSlide = selectedSlides[slideIndex] || selected;
  const uploadFiles = async (files: FileList | null) => {
    if (!files?.length) return;
    setUploading(true);
    const selectedFiles = Array.from(files).filter((file) => file.type.startsWith("image/"));
    for (let index = 0; index < selectedFiles.length; index += 1) {
      const file = selectedFiles[index];
      const src = await fileToDataUrl(file);
      await mutate<GalleryItem>("gallery_items", "create", {
        row: {
          id: makeId("gallery"),
          title: uploadDraft.title || file.name.replace(/\.[^.]+$/, ""),
          src,
          date: uploadDraft.date,
          category: uploadDraft.category || "자료",
          note: uploadDraft.note,
          is_favorite: false,
          sort_order: Date.now() + index
        }
      });
    }
    setUploading(false);
    setUploadOpen(false);
    setUploadDraft({ title: "", date: trip.start_date, category: "자료", note: "" });
  };

  return (
    <section className="grid gap-4">
      <Panel
        title="자료보드"
        action={
          <div className="flex gap-2">
            <button className="btn btn-secondary" type="button" onClick={() => setUploadOpen(true)}><Plus size={16} />자료 추가</button>
            <button className={`btn btn-secondary ${favoriteOnly ? "bg-sun/30" : ""}`} type="button" onClick={() => setFavoriteOnly(!favoriteOnly)}>
              <Star size={16} className={favoriteOnly ? "fill-current" : ""} />별표만
            </button>
          </div>
        }
      >
        <div className="grid gap-2">
          <div className="flex rounded-lg bg-white p-1">
            {[
              { key: "date", label: "날짜별" },
              { key: "category", label: "주제별" }
            ].map((item) => (
              <button
                className={`min-h-9 flex-1 rounded-md text-sm font-black ${groupMode === item.key ? "bg-ink text-white" : "text-black/55"}`}
                key={item.key}
                type="button"
                onClick={() => setGroupMode(item.key as "date" | "category")}
              >
                {item.label}
              </button>
            ))}
          </div>
          <div className="flex gap-2 overflow-x-auto pb-1">
            {dates.map((date) => (
              <button
                className={`chip shrink-0 border ${selectedDate === date ? "bg-sea text-white" : "bg-white text-black"}`}
                key={date}
                type="button"
                onClick={() => setSelectedDate(date)}
              >
                {date === "all" ? "전체" : dateLabel(date)}
              </button>
            ))}
          </div>
        </div>
        <p className="text-sm font-semibold text-black/55">페리, 버스, 미술관, 공항 환전/ATM처럼 현장에서 다시 볼 스크린샷을 날짜나 주제별로 모아둔 보드입니다.</p>
      </Panel>

      {grouped.length ? grouped.map(([group, dayItems]) => (
        <Panel title={groupMode === "date" && group !== "날짜 없음" ? dateLabel(group) : group} key={group}>
          <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
            {dayItems.map((item) => (
              <article className="group overflow-hidden rounded-lg border border-black/5 bg-white shadow-sm" key={item.id}>
                <button className="block w-full text-left" type="button" onClick={() => {
                  const slides = items.filter((candidate) => candidate.date === item.date && candidate.category === item.category).sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0));
                  setSlideIndex(Math.max(0, slides.findIndex((slide) => slide.id === item.id)));
                  setSelected(item);
                }}>
                  <div className="relative aspect-[4/3] bg-black/[0.04]">
                    <img className="h-full w-full object-cover transition group-hover:scale-[1.02]" src={item.src} alt={item.title} loading="lazy" />
                    <span className="absolute left-2 top-2 rounded-full bg-white/90 px-2 py-1 text-[11px] font-black text-black shadow-sm">{item.category}</span>
                    <span className="absolute bottom-2 right-2 rounded-full bg-black/65 px-2 py-1 text-[11px] font-black text-white">{items.filter((candidate) => candidate.date === item.date && candidate.category === item.category).length}장</span>
                  </div>
                </button>
                <div className="grid gap-1 p-3">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="min-w-0 text-sm font-black leading-tight">{item.title}</h3>
                    <button
                      className={`grid h-8 w-8 shrink-0 place-items-center rounded-lg ${item.is_favorite ? "bg-sun/35 text-black" : "bg-black/[0.04] text-black/45"}`}
                      type="button"
                      onClick={() => mutate<GalleryItem>("gallery_items", "update", { id: item.id, patch: { is_favorite: !item.is_favorite } })}
                      aria-label="별표"
                    >
                      <Star size={16} className={item.is_favorite ? "fill-current" : ""} />
                    </button>
                  </div>
                  <p className="line-clamp-2 text-xs font-semibold text-black/55">{item.note}</p>
                </div>
              </article>
            ))}
          </div>
        </Panel>
      )) : <Panel title="자료 없음"><Empty text="이 조건에 맞는 자료가 없어요." /></Panel>}

      {uploadOpen ? (
        <div className="fixed inset-0 z-40 grid place-items-center bg-black/45 p-3">
          <section className="glass w-full max-w-md rounded-lg p-4">
            <div className="mb-3 flex items-center justify-between gap-3">
              <h2 className="text-lg font-black">자료 추가</h2>
              <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={() => setUploadOpen(false)}>닫기</button>
            </div>
            <div className="grid gap-2">
              <input className="field" placeholder="제목" value={uploadDraft.title} onChange={(event) => setUploadDraft({ ...uploadDraft, title: event.target.value })} />
              <div className="grid grid-cols-2 gap-2">
                <select className="field" value={uploadDraft.date} onChange={(event) => setUploadDraft({ ...uploadDraft, date: event.target.value })}>{tripDateOptions(trip).map((date) => <option key={date} value={date}>{dateLabel(date)}</option>)}</select>
                <input className="field" placeholder="주제" value={uploadDraft.category} onChange={(event) => setUploadDraft({ ...uploadDraft, category: event.target.value })} />
              </div>
              <textarea className="field min-h-20" placeholder="메모" value={uploadDraft.note} onChange={(event) => setUploadDraft({ ...uploadDraft, note: event.target.value })} />
              <label className="btn cursor-pointer">
                {uploading ? <Loader2 className="animate-spin" size={16} /> : <Images size={16} />}
                {uploading ? "추가 중" : "사진 선택"}
                <input className="sr-only" type="file" accept="image/*" multiple onChange={(event) => uploadFiles(event.target.files)} />
              </label>
              <p className="text-xs font-bold text-black/45">휴대폰에서는 사진 선택 화면에서 선택한 사진만 허용할 수 있어요. 지금 버전은 이미지를 데이터로 저장하므로 아주 큰 사진은 느려질 수 있습니다.</p>
            </div>
          </section>
        </div>
      ) : null}

      {selected ? (
        <div className="fixed inset-0 z-40 grid place-items-center bg-black/72 p-3" onClick={() => setSelected(null)}>
          <section className="max-h-[92vh] w-full max-w-5xl overflow-hidden rounded-lg bg-white shadow-soft" onClick={(event) => event.stopPropagation()}>
            <div className="flex items-center justify-between gap-3 border-b border-black/8 p-3">
              <div className="min-w-0">
                <p className="text-xs font-black text-sea">{dateLabel(activeSlide.date)} · {activeSlide.category} · {slideIndex + 1}/{selectedSlides.length || 1}</p>
                <h2 className="truncate text-lg font-black">{activeSlide.title}</h2>
              </div>
              <div className="flex gap-2">
                <button
                  className={`btn btn-secondary min-h-9 px-3 ${activeSlide.is_favorite ? "bg-sun/30" : ""}`}
                  type="button"
                  onClick={() => {
                    mutate<GalleryItem>("gallery_items", "update", { id: activeSlide.id, patch: { is_favorite: !activeSlide.is_favorite } });
                    setSelected({ ...activeSlide, is_favorite: !activeSlide.is_favorite });
                  }}
                >
                  <Star size={16} className={activeSlide.is_favorite ? "fill-current" : ""} />
                </button>
                <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={() => setSelected(null)}><X size={16} /></button>
              </div>
            </div>
            <div className="grid max-h-[calc(92vh-4.5rem)] gap-3 overflow-auto p-3 lg:grid-cols-[1fr_18rem]">
              <div className="relative grid place-items-center rounded-lg bg-black/[0.04]">
                <img className="max-h-[74vh] w-auto max-w-full object-contain" src={activeSlide.src} alt={activeSlide.title} />
                {selectedSlides.length > 1 ? (
                  <>
                    <button className="btn btn-secondary absolute left-3 top-1/2 min-h-10 px-3" type="button" onClick={() => setSlideIndex((slideIndex - 1 + selectedSlides.length) % selectedSlides.length)}>이전</button>
                    <button className="btn btn-secondary absolute right-3 top-1/2 min-h-10 px-3" type="button" onClick={() => setSlideIndex((slideIndex + 1) % selectedSlides.length)}>다음</button>
                  </>
                ) : null}
              </div>
              <aside className="rounded-lg bg-black/[0.035] p-4">
                <p className="text-sm font-bold text-black/60">{activeSlide.note}</p>
                {selectedSlides.length > 1 ? (
                  <div className="mt-4 grid grid-cols-4 gap-2">
                    {selectedSlides.map((item, index) => (
                      <button className={`aspect-square overflow-hidden rounded-md border ${index === slideIndex ? "border-sea" : "border-transparent"}`} key={item.id} type="button" onClick={() => setSlideIndex(index)}>
                        <img className="h-full w-full object-cover" src={item.src} alt={item.title} />
                      </button>
                    ))}
                  </div>
                ) : null}
                <p className="mt-4 text-xs font-black text-black/40">자료 경로</p>
                <p className="mt-1 break-all text-xs font-semibold text-black/45">{activeSlide.src}</p>
              </aside>
            </div>
          </section>
        </div>
      ) : null}
    </section>
  );
}

function MapView({ places, foods, links, trip, mutate }: { places: Place[]; foods: FoodCandidate[]; links: QuickLink[]; trip: TripData["trips"][number]; mutate: PageMutate }) {
  const [draft, setDraft] = useState({ name: "", category: "", address: "", map_url: "", hours: "", reservation_note: "", sensitive_note: "" });
  const [urlModal, setUrlModal] = useState(false);
  const [mapUrlInput, setMapUrlInput] = useState("");
  const [mapUrlError, setMapUrlError] = useState("");
  const [mapUrlBusy, setMapUrlBusy] = useState(false);
  const [editingPlace, setEditingPlace] = useState<Record<string, Partial<Place>>>({});
  const [placePlans, setPlacePlans] = useState<Record<string, { date: string; start_time: string; end_time: string }>>({});
  const mapLink = links.find((link) => link.kind === "map")?.url || "https://www.google.com/maps";
  const dates = tripDateOptions(trip);
  const addPlaceFromUrl = async () => {
    setMapUrlBusy(true);
    setMapUrlError("");
    const response = await fetch("/api/resolve-map-url", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: mapUrlInput })
    });
    setMapUrlBusy(false);
    if (!response.ok) {
      setMapUrlError("Google Maps 링크만 넣을 수 있어요.");
      return;
    }
    const resolved = await response.json();
    mutate<Place>("places", "create", {
      row: {
        id: makeId("place"),
        name: resolved.name || "Google Maps 장소",
        category: "장소",
        address: "",
        map_url: resolved.finalUrl || mapUrlInput,
        hours: "",
        reservation_note: "지도 링크로 추가",
        sensitive_note: ""
      }
    });
    setMapUrlInput("");
    setUrlModal(false);
  };
  return (
    <section className="grid gap-4">
      <Panel title="공유 지도" action={<a className="btn" href={mapLink} target="_blank" rel="noreferrer">지도 열기<ExternalLink size={16} /></a>}>
        <div className="overflow-hidden rounded-lg border border-black/10 bg-[#dfeae7]">
          <iframe
            className="h-[22rem] w-full border-0"
            src={MY_MAPS_EMBED_URL}
            title="타카마쓰 Google My Maps"
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
          />
        </div>
        <p className="text-xs font-bold text-black/45">Google My Maps 공유 권한이 열려 있으면 지도는 이 칸에 바로 표시됩니다. 장소/식당 목록은 페이지를 새로 열 때 My Maps KML을 다시 읽어 분류하고, 실패하면 마지막 내장 목록을 보여줍니다.</p>
      </Panel>
      <Panel title="장소 추가" action={<button className="btn btn-secondary" type="button" onClick={() => setUrlModal(true)}>URL로 추가</button>}>
        <form className="grid gap-2 md:grid-cols-3" onSubmit={(event) => {
          event.preventDefault();
          mutate<Place>("places", "create", { row: { id: makeId("place"), ...draft } });
          setDraft({ name: "", category: "", address: "", map_url: "", hours: "", reservation_note: "", sensitive_note: "" });
        }}>
          <input className="field" placeholder="장소명" value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} required />
          <input className="field" placeholder="종류" value={draft.category} onChange={(event) => setDraft({ ...draft, category: event.target.value })} />
          <input className="field" placeholder="Google Maps 링크" value={draft.map_url} onChange={(event) => {
            const mapUrl = event.target.value;
            const inferred = inferGoogleMapsName(mapUrl);
            setDraft({ ...draft, map_url: mapUrl, name: draft.name || inferred });
          }} />
          <input className="field md:col-span-2" placeholder="주소" value={draft.address} onChange={(event) => setDraft({ ...draft, address: event.target.value })} />
          <input className="field" placeholder="영업/예약 메모" value={draft.reservation_note} onChange={(event) => setDraft({ ...draft, reservation_note: event.target.value })} />
          <input className="field md:col-span-2" placeholder="메모" value={draft.sensitive_note} onChange={(event) => setDraft({ ...draft, sensitive_note: event.target.value })} />
          <button className="btn" type="submit"><Plus size={18} />추가</button>
        </form>
      </Panel>
      <div className="grid gap-3 md:grid-cols-2">
        {places.map((place) => (
          <article className="card grid gap-2 p-4" key={place.id}>
            {editingPlace[place.id] ? (
              <form className="grid gap-2" onSubmit={(event) => {
                event.preventDefault();
                mutate<Place>("places", "update", { id: place.id, patch: editingPlace[place.id] });
                const next = { ...editingPlace };
                delete next[place.id];
                setEditingPlace(next);
              }}>
                <input className="field" value={editingPlace[place.id].name || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], name: event.target.value } })} placeholder="장소명" />
                <input className="field" value={editingPlace[place.id].category || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], category: event.target.value } })} placeholder="종류" />
                <input className="field" value={editingPlace[place.id].map_url || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], map_url: event.target.value } })} placeholder="Google Maps 링크" />
                <input className="field" value={editingPlace[place.id].address || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], address: event.target.value } })} placeholder="주소" />
                <input className="field" value={editingPlace[place.id].hours || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], hours: event.target.value } })} placeholder="영업시간" />
                <input className="field" value={editingPlace[place.id].reservation_note || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], reservation_note: event.target.value } })} placeholder="예약/메모" />
                <textarea className="field min-h-24" value={editingPlace[place.id].sensitive_note || ""} onChange={(event) => setEditingPlace({ ...editingPlace, [place.id]: { ...editingPlace[place.id], sensitive_note: event.target.value } })} placeholder="메모" />
                <div className="flex gap-2">
                  <button className="btn" type="submit">저장</button>
                  <button className="btn btn-secondary" type="button" onClick={() => {
                    const next = { ...editingPlace };
                    delete next[place.id];
                    setEditingPlace(next);
                  }}>취소</button>
                </div>
              </form>
            ) : (
              <>
            <div className="flex justify-between gap-3">
              <div><p className="text-xs font-black text-sea">{place.category}</p><h3 className="text-xl font-black">{place.name}</h3></div>
              <div className="flex gap-1">
                <button className="btn btn-secondary min-h-9 px-2" onClick={() => setEditingPlace({ ...editingPlace, [place.id]: { ...place } })} type="button" aria-label="수정"><Pencil size={16} /></button>
                <button className="btn btn-danger min-h-9 px-2" onClick={() => mutate<Place>("places", "delete", { id: place.id })} type="button" aria-label="삭제"><Trash2 size={16} /></button>
              </div>
            </div>
            <p className="text-sm font-semibold text-black/60">{displayPlaceText(place.address, "주소는 Google Maps에서 확인")}</p>
            <p className="text-sm font-semibold text-black/60">{place.hours} · {place.reservation_note}</p>
            {place.sensitive_note ? <p className="rounded-lg bg-black/[0.035] p-3 text-sm font-bold text-black/65">{place.sensitive_note}</p> : null}
            <a className="btn btn-secondary min-h-10" href={place.map_url || googleMapsSearchUrl(place.name, displayPlaceText(place.address, ""))} target="_blank" rel="noreferrer">Google Maps<ExternalLink size={16} /></a>
            <details className="rounded-lg bg-black/[0.04] p-3 text-sm font-bold"><summary>주소/지도 메모 보기</summary><p className="mt-2 text-black/60">{displayPlaceText(place.address, "주소 입력 전")}</p></details>
            <div className="grid gap-2 rounded-lg bg-black/[0.035] p-2">
              <div className="grid grid-cols-[1fr_0.8fr_0.8fr] gap-2">
                <select className="field min-h-10 px-2 text-sm" value={placePlans[place.id]?.date || dates[0]} onChange={(event) => setPlacePlans({ ...placePlans, [place.id]: { ...(placePlans[place.id] || { date: dates[0], start_time: "", end_time: "" }), date: event.target.value } })}>
                  {dates.map((item) => <option key={item} value={item}>{dateLabel(item)}</option>)}
                </select>
                <input className="field min-h-10 px-2 text-sm" type="time" value={placePlans[place.id]?.start_time || ""} onChange={(event) => setPlacePlans({ ...placePlans, [place.id]: { ...(placePlans[place.id] || { date: dates[0], start_time: "", end_time: "" }), start_time: event.target.value } })} aria-label={`${place.name} 시작 시간`} />
                <input className="field min-h-10 px-2 text-sm" type="time" value={placePlans[place.id]?.end_time || ""} onChange={(event) => setPlacePlans({ ...placePlans, [place.id]: { ...(placePlans[place.id] || { date: dates[0], start_time: "", end_time: "" }), end_time: event.target.value } })} aria-label={`${place.name} 종료 시간`} />
              </div>
              <button className="btn min-h-10" type="button" onClick={() => mutate<ItineraryItem>("itinerary_items", "create", { row: itineraryFromPlace(place, placePlans[place.id] || { date: dates[0], start_time: "", end_time: "" }) })}><Plus size={16} />일정에 넣기</button>
            </div>
              </>
            )}
          </article>
        ))}
      </div>
      <FoodView foods={foods} trip={trip} mutate={mutate} />
      {urlModal ? (
        <div className="fixed inset-0 z-30 grid place-items-center bg-black/35 p-3">
          <section className="glass w-full max-w-md rounded-lg p-4">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-xl font-black">Google Maps URL로 추가</h2>
              <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={() => setUrlModal(false)}>닫기</button>
            </div>
            <div className="grid gap-2">
              <input className="field" placeholder="Google Maps 링크 붙여넣기" value={mapUrlInput} onChange={(event) => setMapUrlInput(event.target.value)} />
              {mapUrlError ? <p className="text-sm font-bold text-coral">{mapUrlError}</p> : null}
              <button className="btn" type="button" disabled={!mapUrlInput.trim() || mapUrlBusy} onClick={addPlaceFromUrl}>{mapUrlBusy ? "확인 중" : "장소로 추가"}</button>
              <p className="text-xs font-bold text-black/45">브라우저만으로는 영업시간/사진을 자동 수집하기 어렵고, 이름은 링크 구조에서 가능한 만큼만 추정합니다.</p>
            </div>
          </section>
        </div>
      ) : null}
    </section>
  );
}

function ChecklistView({ items, mutate }: { items: ChecklistItem[]; mutate: PageMutate }) {
  const [text, setText] = useState("");
  const [owner, setOwner] = useState("여행준비");
  const [activeOwner, setActiveOwner] = useState<string | null>(null);
  const [editing, setEditing] = useState<Record<string, string>>({});
  const [draggedCheckId, setDraggedCheckId] = useState<string | null>(null);
  const visibleItems = items.filter((item) => !item.is_archived);
  const done = visibleItems.filter((item) => item.is_done).length;
  const familyNames = ["승환", "예지", "민지"];
  const sortChecks = (list: ChecklistItem[]) => [...list].sort((a, b) => Number(a.is_done) - Number(b.is_done) || Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0) || a.text.localeCompare(b.text, "ko"));
  const travelItems = sortChecks(visibleItems.filter((item) => item.group_name === "여행준비" || !familyNames.includes(item.group_name || "")));
  const ownerItems = (name: string) => sortChecks(visibleItems.filter((item) => item.group_name === name || item.owner === name));
  const moveDraggedItem = (list: ChecklistItem[], target: ChecklistItem) => {
    if (!draggedCheckId || draggedCheckId === target.id) return;
    const dragged = list.find((item) => item.id === draggedCheckId);
    if (!dragged) return;
    const reordered = list.filter((item) => item.id !== draggedCheckId);
    const targetIndex = reordered.findIndex((item) => item.id === target.id);
    reordered.splice(targetIndex, 0, dragged);
    reordered.forEach((item, index) => {
      mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { sort_order: index } });
    });
    setDraggedCheckId(null);
  };
  const renderItem = (item: ChecklistItem, list: ChecklistItem[]) => (
    <div
      className="check-row"
      draggable
      key={item.id}
      onContextMenu={(event) => {
        event.preventDefault();
        mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { is_archived: true } });
      }}
      onDragStart={() => setDraggedCheckId(item.id)}
      onDragOver={(event) => event.preventDefault()}
      onDrop={() => moveDraggedItem(list, item)}
      title="잡고 끌어서 순서 변경. 우클릭하면 보관."
    >
      <label className="check-label">
        <GripVertical className="text-black/25" size={14} />
        <input checked={item.is_done} className="check-box accent-sea" onChange={(event) => mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { is_done: event.target.checked } })} type="checkbox" />
        {editing[item.id] !== undefined ? (
          <input className="check-edit-field" value={editing[item.id]} onChange={(event) => setEditing({ ...editing, [item.id]: event.target.value })} />
        ) : (
          <span className={`check-text ${item.is_done ? "text-black/38 line-through" : ""}`}>{item.text}</span>
        )}
      </label>
      <div className="check-actions">
        {editing[item.id] !== undefined ? (
          <button className="check-action check-action-secondary text-xs" type="button" onClick={() => {
            mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { text: editing[item.id] } });
            const next = { ...editing };
            delete next[item.id];
            setEditing(next);
          }}>저장</button>
        ) : (
          <button className="check-action check-action-secondary" onClick={() => setEditing({ ...editing, [item.id]: item.text })} type="button" aria-label="수정"><Pencil size={13} /></button>
        )}
        <button className="check-action check-action-secondary" onClick={() => mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { is_archived: true } })} type="button" aria-label="보관"><Archive size={13} /></button>
        <button className="check-action check-action-danger" onClick={() => mutate<ChecklistItem>("checklist_items", "delete", { id: item.id })} type="button" aria-label="삭제"><Trash2 size={13} /></button>
      </div>
    </div>
  );

  return (
    <section className="grid gap-4">
      <Metric title="준비 완료율" value={`${done} / ${visibleItems.length}`} icon={CheckCircle2} />
      <Panel title="체크 항목 추가">
        <form className="grid gap-2 md:grid-cols-[10rem_1fr_auto]" onSubmit={(event) => {
          event.preventDefault();
          mutate<ChecklistItem>("checklist_items", "create", { row: { id: makeId("check"), group_name: owner, text, owner, is_done: false, sort_order: Date.now() } });
          setText("");
        }}>
          <select className="field" value={owner} onChange={(event) => setOwner(event.target.value)}>
            {["여행준비", "승환", "예지", "민지"].map((name) => <option key={name}>{name}</option>)}
          </select>
          <input className="field" value={text} onChange={(event) => setText(event.target.value)} placeholder="추가할 준비물" required />
          <button className="btn" type="submit"><Plus size={18} />추가</button>
        </form>
      </Panel>
      <Panel title="여행준비">
        {travelItems.length ? travelItems.map((item) => renderItem(item, travelItems)) : <Empty text="여행준비 항목을 추가하세요." />}
      </Panel>
      <Panel title="사람별 준비물">
        <div className="grid grid-cols-3 gap-2">
          {familyNames.map((name) => {
            const list = ownerItems(name);
            const open = list.filter((item) => !item.is_done).length;
            return (
              <button className="card p-3 text-left" key={name} type="button" onClick={() => setActiveOwner(name)}>
                <p className="text-lg font-black">{name}</p>
                <p className="text-sm font-bold text-black/50">남은 항목 {open}개</p>
              </button>
            );
          })}
        </div>
      </Panel>
      {activeOwner ? (
        <div className="fixed inset-0 z-30 grid place-items-center bg-black/35 p-3">
          <section className="glass max-h-[82vh] w-full max-w-lg overflow-auto rounded-lg p-4">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-xl font-black">{activeOwner} 준비물</h2>
              <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={() => setActiveOwner(null)}>닫기</button>
            </div>
            <p className="mb-2 text-xs font-bold text-black/45">항목을 잡고 끌어 순서를 바꿀 수 있어요. 우클릭하면 보관됩니다.</p>
            <div className="grid gap-1">{ownerItems(activeOwner).length ? ownerItems(activeOwner).map((item) => renderItem(item, ownerItems(activeOwner))) : <Empty text="아직 항목이 없어요." />}</div>
          </section>
        </div>
      ) : null}
    </section>
  );
}

function googleMapsSearchUrl(name: string, location: string) {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${name} ${location}`.trim())}`;
}

function fileToDataUrl(file: File) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

function onsiteToneClass(tone: string) {
  if (tone === "urgent") return "border-l-coral bg-coral/5";
  if (tone === "move") return "border-l-sea bg-sea/5";
  if (tone === "money") return "border-l-sun bg-sun/10";
  return "border-l-black/20";
}

function tripDateOptions(trip: TripData["trips"][number]) {
  const dates: string[] = [];
  const cursor = new Date(`${trip.start_date}T00:00:00`);
  const end = new Date(`${trip.end_date}T00:00:00`);
  while (cursor <= end) {
    dates.push(new Intl.DateTimeFormat("en-CA", { year: "numeric", month: "2-digit", day: "2-digit" }).format(cursor));
    cursor.setDate(cursor.getDate() + 1);
  }
  return dates;
}

function itineraryFromPlace(place: Place, plan: { date: string; start_time: string; end_time: string }): Partial<ItineraryItem> {
  return {
    id: makeId("iti"),
    date: plan.date,
    time_label: plan.start_time ? "" : "장소",
    start_time: plan.start_time,
    end_time: plan.end_time,
    title: place.name,
    description: `${place.category || "장소"} · ${place.reservation_note || place.hours || "메모 없음"}`,
    location: displayPlaceText(place.address, place.name),
    priority: "가능하면",
    reservation_status: place.reservation_note || "확인 필요",
    weather_impact: "중간",
    owner: "다 같이",
    sort_order: Date.now()
  };
}

function itineraryFromFood(food: FoodCandidate, plan: { date: string; start_time: string; end_time: string }): Partial<ItineraryItem> {
  return {
    id: makeId("iti"),
    date: plan.date,
    time_label: plan.start_time ? "" : "식사",
    start_time: plan.start_time,
    end_time: plan.end_time,
    title: food.name,
    description: `${food.category} · ${food.reservation || "예약 확인"} · ${food.note || ""}`,
    location: displayPlaceText(food.location, food.name),
    priority: "가능하면",
    reservation_status: food.reservation || "확인 필요",
    weather_impact: "중간",
    owner: food.recommender || "다 같이",
    sort_order: Date.now()
  };
}

function FoodView({ foods, trip, mutate }: { foods: FoodCandidate[]; trip: TripData["trips"][number]; mutate: PageMutate }) {
  const [draft, setDraft] = useState({ name: "", category: "우동", location: "", map_url: "", reservation: "", wait_note: "", recommender: "", note: "" });
  const [plans, setPlans] = useState<Record<string, { date: string; start_time: string; end_time: string }>>({});
  const [editingFood, setEditingFood] = useState<Record<string, Partial<FoodCandidate>>>({});
  const groupedFoods = useMemo(() => Object.entries(groupBy([...foods].sort((a, b) => Number(Boolean(b.is_favorite)) - Number(Boolean(a.is_favorite)) || a.name.localeCompare(b.name, "ko")), (food) => food.category || "기타")), [foods]);
  const tripDates = useMemo(() => {
    const dates: string[] = [];
    const cursor = new Date(`${trip.start_date}T00:00:00`);
    const end = new Date(`${trip.end_date}T00:00:00`);
    while (cursor <= end) {
      dates.push(new Intl.DateTimeFormat("en-CA", { year: "numeric", month: "2-digit", day: "2-digit" }).format(cursor));
      cursor.setDate(cursor.getDate() + 1);
    }
    return dates;
  }, [trip.start_date, trip.end_date]);
  const addFoodToSchedule = (food: FoodCandidate) => {
    const plan = plans[food.id] || { date: tripDates[0], start_time: "", end_time: "" };
    mutate<ItineraryItem>("itinerary_items", "create", {
      row: {
        id: makeId("iti"),
        date: plan.date,
        time_label: plan.start_time ? "" : "식사",
        start_time: plan.start_time,
        end_time: plan.end_time,
        title: food.name,
        description: `${food.category} · ${food.reservation || "예약 확인"} · ${food.note || ""}`,
        location: food.location,
        priority: "가능하면",
        reservation_status: food.reservation || "확인 필요",
        weather_impact: "중간",
        owner: food.recommender || "다 같이",
        sort_order: Date.now()
      }
    });
  };
  return (
    <section className="grid gap-4">
      <Panel title="식당 후보 추가">
        <form className="grid gap-2 md:grid-cols-4" onSubmit={(event) => {
          event.preventDefault();
          mutate<FoodCandidate>("food_candidates", "create", { row: { id: makeId("food"), ...draft } });
          setDraft({ name: "", category: "우동", location: "", map_url: "", reservation: "", wait_note: "", recommender: "", note: "" });
        }}>
          <input className="field" placeholder="식당명" value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} required />
          <select className="field" value={draft.category} onChange={(event) => setDraft({ ...draft, category: event.target.value })}>{["우동", "이자카야", "카페", "비 오는 날", "기타"].map((item) => <option key={item}>{item}</option>)}</select>
          <input className="field" placeholder="위치/동네" value={draft.location} onChange={(event) => setDraft({ ...draft, location: event.target.value })} />
          <input className="field" placeholder="Google Maps 링크" value={draft.map_url} onChange={(event) => {
            const mapUrl = event.target.value;
            const inferred = inferGoogleMapsName(mapUrl);
            setDraft({ ...draft, map_url: mapUrl, name: draft.name || inferred });
          }} />
          <input className="field" placeholder="예약 메모" value={draft.reservation} onChange={(event) => setDraft({ ...draft, reservation: event.target.value })} />
          <input className="field" placeholder="웨이팅/영업 메모" value={draft.wait_note} onChange={(event) => setDraft({ ...draft, wait_note: event.target.value })} />
          <input className="field" placeholder="추천한 사람" value={draft.recommender} onChange={(event) => setDraft({ ...draft, recommender: event.target.value })} />
          <input className="field" placeholder="메모" value={draft.note} onChange={(event) => setDraft({ ...draft, note: event.target.value })} />
          <button className="btn" type="submit"><Plus size={18} />추가</button>
        </form>
      </Panel>
      {groupedFoods.map(([category, categoryFoods]) => (
        <Panel title={category} key={category}>
          <div className="grid gap-2 md:grid-cols-2 xl:grid-cols-3">
            {(categoryFoods || []).map((food) => (
              <article className="card grid gap-1.5 p-3" key={food.id}>
                {editingFood[food.id] ? (
                  <form className="grid gap-2" onSubmit={(event) => {
                    event.preventDefault();
                    mutate<FoodCandidate>("food_candidates", "update", { id: food.id, patch: editingFood[food.id] });
                    const next = { ...editingFood };
                    delete next[food.id];
                    setEditingFood(next);
                  }}>
                    <input className="field" value={editingFood[food.id].name || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], name: event.target.value } })} placeholder="식당명" />
                    <select className="field" value={editingFood[food.id].category || "우동"} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], category: event.target.value } })}>{["우동", "이자카야", "카페", "비 오는 날", "기타"].map((item) => <option key={item}>{item}</option>)}</select>
                    <input className="field" value={editingFood[food.id].location || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], location: event.target.value } })} placeholder="위치/동네" />
                    <input className="field" value={editingFood[food.id].map_url || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], map_url: event.target.value } })} placeholder="Google Maps 링크" />
                    <input className="field" value={editingFood[food.id].reservation || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], reservation: event.target.value } })} placeholder="예약 메모" />
                    <input className="field" value={editingFood[food.id].wait_note || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], wait_note: event.target.value } })} placeholder="웨이팅/영업 메모" />
                    <input className="field" value={editingFood[food.id].recommender || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], recommender: event.target.value } })} placeholder="추천한 사람" />
                    <textarea className="field min-h-20" value={editingFood[food.id].note || ""} onChange={(event) => setEditingFood({ ...editingFood, [food.id]: { ...editingFood[food.id], note: event.target.value } })} placeholder="메모" />
                    <div className="flex gap-2">
                      <button className="btn" type="submit">저장</button>
                      <button className="btn btn-secondary" type="button" onClick={() => {
                        const next = { ...editingFood };
                        delete next[food.id];
                        setEditingFood(next);
                      }}>취소</button>
                    </div>
                  </form>
                ) : (
                  <>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0"><p className="text-xs font-black text-coral">{food.category}</p><h3 className="truncate text-lg font-black">{food.name}</h3></div>
                  <div className="flex shrink-0 gap-1">
                    <button className={`btn min-h-8 px-2 ${food.is_favorite ? "bg-sun text-ink" : "btn-secondary"}`} onClick={() => mutate<FoodCandidate>("food_candidates", "update", { id: food.id, patch: { is_favorite: !food.is_favorite } })} type="button" aria-label="별표"><Star size={15} fill={food.is_favorite ? "currentColor" : "none"} /></button>
                    <button className="btn btn-secondary min-h-8 px-2" onClick={() => setEditingFood({ ...editingFood, [food.id]: { ...food } })} type="button" aria-label="수정"><Pencil size={15} /></button>
                    <button className="btn btn-danger min-h-8 px-2" onClick={() => mutate<FoodCandidate>("food_candidates", "delete", { id: food.id })} type="button" aria-label="삭제"><Trash2 size={15} /></button>
                  </div>
                </div>
                <p className="text-xs font-semibold text-black/60">{displayPlaceText(food.location, "지도 링크 확인")} · {food.reservation || "예약 확인"}</p>
                <p className="text-xs font-semibold text-black/60">{food.wait_note || "웨이팅 확인"} · 추천 {food.recommender || "다 같이"}</p>
                {food.note ? <p className="line-clamp-2 text-sm font-bold">{food.note}</p> : null}
                <div className="grid grid-cols-2 gap-2">
                  <a className="btn btn-secondary min-h-9" href={food.map_url || googleMapsSearchUrl(food.name, displayPlaceText(food.location, ""))} target="_blank" rel="noreferrer">지도<ExternalLink size={15} /></a>
                  <details className="rounded-lg bg-black/[0.035]">
                    <summary className="grid min-h-9 cursor-pointer place-items-center px-2 text-sm font-black">일정에 넣기</summary>
                    <div className="grid gap-2 p-2">
                  <div className="grid grid-cols-[1fr_0.8fr_0.8fr] gap-2">
                    <select
                      className="field min-h-10 px-2 text-sm"
                      value={(plans[food.id]?.date) || tripDates[0]}
                      onChange={(event) => setPlans({ ...plans, [food.id]: { ...(plans[food.id] || { date: tripDates[0], start_time: "", end_time: "" }), date: event.target.value } })}
                    >
                      {tripDates.map((date) => <option value={date} key={date}>{dateLabel(date)}</option>)}
                    </select>
                    <input
                      aria-label={`${food.name} 시작 시간`}
                      className="field min-h-10 px-2 text-sm"
                      type="time"
                      value={plans[food.id]?.start_time || ""}
                      onChange={(event) => setPlans({ ...plans, [food.id]: { ...(plans[food.id] || { date: tripDates[0], start_time: "", end_time: "" }), start_time: event.target.value } })}
                    />
                    <input
                      aria-label={`${food.name} 종료 시간`}
                      className="field min-h-10 px-2 text-sm"
                      type="time"
                      value={plans[food.id]?.end_time || ""}
                      onChange={(event) => setPlans({ ...plans, [food.id]: { ...(plans[food.id] || { date: tripDates[0], start_time: "", end_time: "" }), end_time: event.target.value } })}
                    />
                  </div>
                  <button className="btn min-h-9" type="button" onClick={() => addFoodToSchedule(food)}><Plus size={16} />추가</button>
                  </div>
                  </details>
                </div>
                  </>
                )}
              </article>
            ))}
          </div>
        </Panel>
      ))}
    </section>
  );
}

function BudgetView({ expenses, members, trip, mutate }: { expenses: Expense[]; members: string[]; trip: TripData["trips"][number]; mutate: PageMutate }) {
  const [draft, setDraft] = useState({ category: "식비", item: "", amount: "", currency: trip.budget_currency || "JPY", payer: members[0] || "나", intended_payer: members[0] || "나", participants: members, note: "" });
  const total = expenses.reduce((sum, expense) => sum + Number(expense.amount || 0), 0);
  const share = members.length ? total / members.length : 0;
  const budget = Number(trip.budget_amount || 0);
  const percent = budget ? Math.min(100, Math.round((total / budget) * 100)) : 0;
  const toggleParticipant = (name: string) => {
    const has = draft.participants.includes(name);
    setDraft({ ...draft, participants: has ? draft.participants.filter((item) => item !== name) : [...draft.participants, name] });
  };
  return (
    <section className="grid gap-4">
      <div className="grid gap-3 md:grid-cols-3">
        <Metric title="총 지출" value={`${total.toLocaleString("ko-KR")} JPY`} icon={CreditCard} />
        <Metric title="1인 기준" value={`${Math.round(share).toLocaleString("ko-KR")} JPY`} icon={CheckCircle2} />
        <Metric title="항목 수" value={`${expenses.length}개`} icon={ListTodo} />
      </div>
      <Panel title="예산 진행">
        <div className="grid gap-2">
          <div className="flex items-center justify-between text-sm font-black">
            <span>{budget ? `${budget.toLocaleString("ko-KR")} ${trip.budget_currency || "JPY"} 중 ${percent}%` : "예산을 설정하면 진행률이 보여요"}</span>
            <span>{total.toLocaleString("ko-KR")} {trip.budget_currency || "JPY"}</span>
          </div>
          <div className="h-3 overflow-hidden rounded-full bg-black/8">
            <div className="h-full rounded-full bg-sea transition-all" style={{ width: `${percent}%` }} />
          </div>
        </div>
      </Panel>
      <Panel title="지출 추가">
        <form className="grid gap-2 md:grid-cols-5" onSubmit={(event) => {
          event.preventDefault();
          const settlementNote = [`정산 예정: ${draft.intended_payer}`, `사용자: ${draft.participants.join(", ")}`, draft.note].filter(Boolean).join("\n");
          mutate<Expense>("expenses", "create", { row: { id: makeId("expense"), category: draft.category, item: draft.item, amount: Number(draft.amount || 0), currency: draft.currency, payer: draft.payer, note: settlementNote } });
          setDraft({ ...draft, item: "", amount: "", note: "", participants: members });
        }}>
          <select className="field" value={draft.category} onChange={(event) => setDraft({ ...draft, category: event.target.value })}>{["식비", "교통비", "숙박비", "쇼핑", "간식비", "관광비", "기타"].map((item) => <option key={item}>{item}</option>)}</select>
          <input className="field" placeholder="항목" value={draft.item} onChange={(event) => setDraft({ ...draft, item: event.target.value })} />
          <input className="field" inputMode="numeric" placeholder="금액" value={draft.amount} onChange={(event) => setDraft({ ...draft, amount: event.target.value })} />
          <select className="field" value={draft.payer} onChange={(event) => setDraft({ ...draft, payer: event.target.value })}>{members.map((member) => <option key={member}>{member}</option>)}</select>
          <select className="field" value={draft.intended_payer} onChange={(event) => setDraft({ ...draft, intended_payer: event.target.value })}>{members.map((member) => <option key={member} value={member}>{member}가 낼 예정</option>)}</select>
          <button className="btn" type="submit"><Plus size={18} />추가</button>
          <div className="md:col-span-5 grid gap-2 rounded-lg bg-white p-3">
            <p className="text-xs font-black text-black/45">누구누구가 사용한 항목인지</p>
            <div className="flex flex-wrap gap-2">
              {members.map((member) => (
                <label className="chip cursor-pointer bg-black/[0.045] text-black" key={member}>
                  <input className="mr-1 accent-sea" type="checkbox" checked={draft.participants.includes(member)} onChange={() => toggleParticipant(member)} />
                  {member}
                </label>
              ))}
            </div>
          </div>
        </form>
      </Panel>
      <Panel title="지출 목록">
        {expenses.map((expense) => (
          <div className="flex items-center justify-between gap-3 border-t border-black/5 py-3 first:border-t-0" key={expense.id}>
            <div><p className="font-black">{expense.category} · {expense.item || "항목 없음"}</p><p className="text-sm font-bold text-black/55">{Number(expense.amount || 0).toLocaleString("ko-KR")} {expense.currency} · 결제 {expense.payer}</p>{expense.note ? <p className="mt-1 whitespace-pre-line text-xs font-bold text-black/45">{expense.note}</p> : null}</div>
            <button className="btn btn-danger min-h-8 px-2" onClick={() => mutate<Expense>("expenses", "delete", { id: expense.id })} type="button"><Trash2 size={15} /></button>
          </div>
        ))}
      </Panel>
    </section>
  );
}

function OnsiteView({ notes, links, mutate }: { notes: OnsiteNote[]; links: QuickLink[]; mutate: PageMutate }) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editingNote, setEditingNote] = useState<OnsiteNote | null>(null);
  const [draft, setDraft] = useState({ title: "", body: "", tone: "note" });
  const sortedNotes = [...notes].sort((a, b) => Number(a.sort_order || 0) - Number(b.sort_order || 0));
  const openEditor = (note?: OnsiteNote) => {
    if (note) {
      setEditingNote(note);
      setDraft({ title: note.title, body: note.body, tone: note.tone || "note" });
    } else {
      setEditingNote(null);
      setDraft({ title: "", body: "", tone: "note" });
    }
    setModalOpen(true);
  };
  const saveNote = () => {
    if (editingNote) {
      mutate<OnsiteNote>("onsite_notes", "update", { id: editingNote.id, patch: draft });
    } else {
      mutate<OnsiteNote>("onsite_notes", "create", { row: { id: makeId("onsite"), ...draft, sort_order: Date.now() } });
    }
    setModalOpen(false);
  };
  return (
    <section className="grid gap-4">
      <Panel title="현장에서 바로 보기" action={<button className="btn btn-secondary" type="button" onClick={() => openEditor()}><Plus size={16} />추가</button>}>
        <div className="grid gap-3 md:grid-cols-2">
          {sortedNotes.map((note) => (
            <article className={`card border-l-4 p-4 ${onsiteToneClass(note.tone)}`} key={note.id}>
              <div className="flex items-start justify-between gap-3">
                <h3 className="font-black">{note.title}</h3>
                <div className="flex shrink-0 gap-1">
                  <button className="btn btn-secondary min-h-8 px-2" type="button" onClick={() => openEditor(note)} aria-label="수정"><Pencil size={14} /></button>
                  <button className="btn btn-danger min-h-8 px-2" type="button" onClick={() => mutate<OnsiteNote>("onsite_notes", "delete", { id: note.id })} aria-label="삭제"><Trash2 size={14} /></button>
                </div>
              </div>
              <p className="mt-2 whitespace-pre-line text-sm font-semibold leading-relaxed text-black/62">{note.body}</p>
            </article>
          ))}
        </div>
      </Panel>
      <Panel title="링크">
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">{links.map((link) => <a className="btn btn-secondary" href={link.url} key={link.id} rel="noreferrer" target="_blank">{link.label}<ExternalLink size={16} /></a>)}</div>
      </Panel>
      {modalOpen ? (
        <div className="fixed inset-0 z-40 grid place-items-center bg-black/40 p-3">
          <section className="glass w-full max-w-lg rounded-lg p-4">
            <div className="mb-3 flex items-center justify-between gap-3">
              <h2 className="text-lg font-black">{editingNote ? "현장정보 수정" : "현장정보 추가"}</h2>
              <button className="btn btn-secondary min-h-9 px-3" type="button" onClick={() => setModalOpen(false)}>닫기</button>
            </div>
            <form className="grid gap-2" onSubmit={(event) => {
              event.preventDefault();
              saveNote();
            }}>
              <input className="field" placeholder="제목" value={draft.title} onChange={(event) => setDraft({ ...draft, title: event.target.value })} required />
              <select className="field" value={draft.tone} onChange={(event) => setDraft({ ...draft, tone: event.target.value })}>
                <option value="urgent">긴급</option>
                <option value="move">이동</option>
                <option value="money">결제/환전</option>
                <option value="note">일반</option>
              </select>
              <textarea className="field min-h-40" placeholder="현장에서 바로 읽을 내용" value={draft.body} onChange={(event) => setDraft({ ...draft, body: event.target.value })} />
              <button className="btn" type="submit">저장</button>
            </form>
          </section>
        </div>
      ) : null}
    </section>
  );
}

function SettingsView({ data, mode, mutate }: { data: TripData; mode: string; mutate: PageMutate }) {
  const trip = data.trips[0] || seedData.trips[0];
  const [setup, setSetup] = useState({
    country: trip.country || "일본",
    cityPreset: "타카마쓰",
    customCity: "",
    cities: (trip.cities || trip.region.split("·").map((city) => city.trim()).filter(Boolean)).join(", "),
    start_date: trip.start_date,
    end_date: trip.end_date,
    outbound_origin: trip.outbound_origin || "",
    outbound_destination: trip.outbound_destination || "",
    outbound_flight: trip.outbound_flight || "",
    outbound_arrival_time: trip.outbound_arrival_time || "",
    return_origin: trip.return_origin || "",
    return_destination: trip.return_destination || "",
    return_flight: trip.return_flight || "",
    return_departure_time: trip.return_departure_time || "",
    accommodation: trip.accommodation || "",
    my_maps_url: trip.my_maps_url || data.quick_links.find((link) => link.kind === "map")?.url || "",
    budget_amount: String(trip.budget_amount || ""),
    budget_currency: trip.budget_currency || "JPY"
  });
  const cityPresets = ["도쿄", "오사카", "후쿠오카", "삿포로", "교토", "타카마쓰", "기타"];
  const resolvedCity = setup.cityPreset === "기타" ? setup.customCity : setup.cityPreset;
  const inviteUrl = typeof window !== "undefined" ? window.location.origin : "https://project-6ok16.vercel.app";
  return (
    <section className="grid gap-4">
      <Panel title="처음 셋업">
        <form className="grid gap-2 md:grid-cols-4" onSubmit={(event) => {
          event.preventDefault();
          const cities = Array.from(new Set([resolvedCity, ...setup.cities.split(",").map((city) => city.trim()).filter(Boolean)].filter(Boolean)));
          mutate<Trip>("trips", "update", {
            id: trip.id,
            patch: {
              country: setup.country,
              cities,
              region: cities.join(" · "),
              start_date: setup.start_date || trip.start_date,
              end_date: setup.end_date || setup.start_date || trip.end_date,
              outbound_origin: setup.outbound_origin,
              outbound_destination: setup.outbound_destination || resolvedCity,
              outbound_flight: setup.outbound_flight,
              outbound_arrival_time: setup.outbound_arrival_time,
              return_origin: setup.return_origin || resolvedCity,
              return_destination: setup.return_destination,
              return_flight: setup.return_flight,
              return_departure_time: setup.return_departure_time,
              accommodation: setup.accommodation,
              my_maps_url: setup.my_maps_url,
              budget_amount: Number(setup.budget_amount || 0),
              budget_currency: setup.budget_currency
            }
          });
        }}>
          <select className="field" value={setup.country} onChange={(event) => setSetup({ ...setup, country: event.target.value })}>
            {["일본", "한국", "대만", "태국", "프랑스", "이탈리아", "미국", "기타"].map((country) => <option key={country}>{country}</option>)}
          </select>
          <select className="field" value={setup.cityPreset} onChange={(event) => setSetup({ ...setup, cityPreset: event.target.value })}>
            {cityPresets.map((city) => <option key={city}>{city}</option>)}
          </select>
          {setup.cityPreset === "기타" ? <input className="field" placeholder="도시 직접 입력" value={setup.customCity} onChange={(event) => setSetup({ ...setup, customCity: event.target.value })} required /> : null}
          <input className="field" placeholder="경유 도시들 쉼표로 추가" value={setup.cities} onChange={(event) => setSetup({ ...setup, cities: event.target.value })} />
          <input className="field" type="date" value={setup.start_date} onChange={(event) => setSetup({ ...setup, start_date: event.target.value })} />
          <input className="field" type="date" value={setup.end_date} onChange={(event) => setSetup({ ...setup, end_date: event.target.value })} />
          <input className="field" placeholder="가는 편명" value={setup.outbound_flight} onChange={(event) => setSetup({ ...setup, outbound_flight: event.target.value })} />
          <input className="field" placeholder="가는 편 출발지" value={setup.outbound_origin} onChange={(event) => setSetup({ ...setup, outbound_origin: event.target.value })} />
          <input className="field" placeholder="가는 편 현지 도착지" value={setup.outbound_destination} onChange={(event) => setSetup({ ...setup, outbound_destination: event.target.value })} />
          <input className="field" type="time" value={setup.outbound_arrival_time} onChange={(event) => setSetup({ ...setup, outbound_arrival_time: event.target.value })} aria-label="가는 편 현지 도착시간" />
          <input className="field" placeholder="오는 편명" value={setup.return_flight} onChange={(event) => setSetup({ ...setup, return_flight: event.target.value })} />
          <input className="field" placeholder="오는 편 현지 출발지" value={setup.return_origin} onChange={(event) => setSetup({ ...setup, return_origin: event.target.value })} />
          <input className="field" placeholder="오는 편 도착지" value={setup.return_destination} onChange={(event) => setSetup({ ...setup, return_destination: event.target.value })} />
          <input className="field" type="time" value={setup.return_departure_time} onChange={(event) => setSetup({ ...setup, return_departure_time: event.target.value })} aria-label="오는 편 현지 출발시간" />
          <input className="field md:col-span-2" placeholder="숙소 / 체크인 기준 메모" value={setup.accommodation} onChange={(event) => setSetup({ ...setup, accommodation: event.target.value })} />
          <input className="field md:col-span-2" placeholder="Google My Maps 공유 링크" value={setup.my_maps_url} onChange={(event) => setSetup({ ...setup, my_maps_url: event.target.value })} />
          <input className="field" inputMode="numeric" placeholder="예산" value={setup.budget_amount} onChange={(event) => setSetup({ ...setup, budget_amount: event.target.value })} />
          <input className="field" placeholder="통화" value={setup.budget_currency} onChange={(event) => setSetup({ ...setup, budget_currency: event.target.value })} />
          <button className="btn md:col-span-2" type="submit">셋업 저장</button>
        </form>
      </Panel>
      <Panel title="친구 초대">
        <div className="grid gap-2 md:grid-cols-[1fr_auto]">
          <div className="rounded-lg bg-white p-3">
            <p className="text-xs font-black text-sea">공유 링크</p>
            <p className="break-all text-sm font-bold">{inviteUrl}</p>
            <p className="mt-1 text-xs font-bold text-black/45">트리플처럼 링크를 보내고, 가족코드는 별도로 알려주면 됩니다. 나중에는 멤버별 권한/이름 선택까지 붙일 수 있어요.</p>
          </div>
          <button className="btn" type="button" onClick={() => navigator.clipboard?.writeText(inviteUrl)}>링크 복사</button>
        </div>
      </Panel>
      <Panel title="앱 설정">
        <div className="grid gap-3 md:grid-cols-2">
          <div className="card p-4"><p className="text-sm font-black text-sea">저장 모드</p><p className="text-xl font-black">{mode === "supabase" ? "Supabase 연결됨" : "데모 데이터"}</p><p className="mt-2 text-sm font-semibold text-black/55">Supabase 환경변수를 넣으면 서버 API가 클라우드 DB에 저장합니다.</p></div>
          <div className="card p-4"><p className="text-sm font-black text-sea">가족코드</p><p className="text-xl font-black">서버 환경변수</p><p className="mt-2 text-sm font-semibold text-black/55">`FAMILY_CODE`와 `SESSION_SECRET`을 배포 환경에 설정하세요.</p></div>
        </div>
      </Panel>
      <Panel title="데이터 현황">
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
          <Metric title="일정" value={`${data.itinerary_items.length}개`} icon={CalendarDays} />
          <Metric title="장소" value={`${data.places.length}개`} icon={MapPin} />
          <Metric title="식당" value={`${data.food_candidates.length}개`} icon={Soup} />
          <Metric title="체크" value={`${data.checklist_items.length}개`} icon={ListTodo} />
        </div>
      </Panel>
    </section>
  );
}

function Panel({ title, children, action, titleClassName = "" }: { title: string; children: ReactNode; action?: ReactNode; titleClassName?: string }) {
  return (
    <section className="glass rounded-lg p-4">
      <div className="mb-3 flex items-center justify-between gap-3">
        <h2 className={`text-xl font-black ${titleClassName}`}>{title}</h2>
        {action}
      </div>
      <div className="grid gap-3">{children}</div>
    </section>
  );
}

function Metric({ title, value, icon: Icon, roomy = false }: { title: string; value: string; icon: ComponentType<{ size?: number; className?: string }>; roomy?: boolean }) {
  return (
    <article className={`card flex items-center gap-3 p-4 ${roomy ? "md:col-span-2" : ""}`}>
      <div className="grid h-10 w-10 place-items-center rounded-lg bg-sea/10 text-sea"><Icon size={20} /></div>
      <div className="min-w-0"><p className="text-xs font-black uppercase text-black/42">{title}</p><p className={`${roomy ? "text-sm leading-snug md:text-base" : "text-lg"} break-words font-black`}>{value}</p></div>
    </article>
  );
}

function Empty({ text }: { text: string }) {
  return <div className="rounded-lg bg-white p-5 text-center text-sm font-bold text-black/45">{text}</div>;
}
