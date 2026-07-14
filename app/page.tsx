"use client";

import {
  Archive,
  ArrowRight,
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
import type { ComponentType, CSSProperties, ReactNode } from "react";
import { inferGoogleMapsName } from "./lib/maps";
import { DEFAULT_TRIP_ID, MY_MAPS_EMBED_URL, seedData } from "./lib/seed";
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
  TripMember,
  TripData
} from "./lib/types";

type ViewKey = "home" | "schedule" | "gallery" | "map" | "checklist" | "food" | "budget" | "onsite" | "settings";
type SaveState = "idle" | "saving" | "saved" | "error";
type DayWeather = Record<string, { label: string; rain: number; wind: number; high: number; low: number }>;
type AppTheme = "editorial-sea" | "coral-plum" | "indigo-amber" | "cherry-mint" | "graphite-citron";
type StarterCityStop = {
  id: string;
  country: string;
  customCountry: string;
  cityPreset: string;
  customCity: string;
};
type TripStarterDraft = {
  tripName: string;
  country: string;
  customCountry: string;
  cityPreset: string;
  customCity: string;
  extraCities: StarterCityStop[];
  cityTransferDates: Record<string, string>;
  startDate: string;
  endDate: string;
  outboundFlight: string;
  outboundOrigin: string;
  outboundDestination: string;
  outboundDepart: string;
  outboundArrive: string;
  returnFlight: string;
  returnOrigin: string;
  returnDestination: string;
  returnDepart: string;
  returnArrive: string;
  myMapsUrl: string;
};

const APP_THEME_STORAGE_KEY = "triplanner-theme-v1";
const appThemes: { key: AppTheme; name: string; description: string; swatches: string[] }[] = [
  { key: "editorial-sea", name: "Editorial Sea", description: "현재 4번 기준. 차분한 여행 매거진 톤", swatches: ["#152124", "#078985", "#EFF7F4", "#FFFEFA"] },
  { key: "coral-plum", name: "Coral Plum", description: "Canva 앱 목업처럼 밝고 선명한 예약 앱 톤", swatches: ["#EF6448", "#5A244D", "#FFF7F2", "#F8D9CE"] },
  { key: "indigo-amber", name: "Indigo Amber", description: "프로덕트 대시보드식 블루와 앰버 포인트", swatches: ["#21255F", "#2F68FF", "#F5B84B", "#F4F7FF"] },
  { key: "cherry-mint", name: "Cherry Mint", description: "체리 레드와 민트의 선명한 여행 기록 톤", swatches: ["#BF0426", "#88BFB0", "#C2F2E5", "#FFFDF8"] },
  { key: "graphite-citron", name: "Graphite Citron", description: "그래파이트, 파우더블루, 시트론 조합", swatches: ["#2D3047", "#93B7BE", "#E0CA3C", "#F6F6F0"] }
];

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
const countryOptions = ["일본", "한국", "대만", "태국", "베트남", "싱가포르", "홍콩", "프랑스", "이탈리아", "스페인", "포르투갈", "영국", "미국", "호주", "기타"];
const cityPresetsByCountry: Record<string, string[]> = {
  일본: ["도쿄", "오사카", "후쿠오카", "삿포로", "교토", "타카마쓰", "나오시마", "마쓰야마", "히로시마", "오키나와", "기타"],
  한국: ["서울", "부산", "제주", "강릉", "경주", "전주", "여수", "기타"],
  대만: ["타이베이", "타이중", "가오슝", "타이난", "화롄", "기타"],
  태국: ["방콕", "치앙마이", "푸켓", "끄라비", "파타야", "기타"],
  베트남: ["하노이", "호치민", "다낭", "호이안", "나트랑", "푸꾸옥", "기타"],
  싱가포르: ["싱가포르", "기타"],
  홍콩: ["홍콩", "마카오", "기타"],
  프랑스: ["파리", "니스", "리옹", "마르세유", "스트라스부르", "기타"],
  이탈리아: ["로마", "피렌체", "베네치아", "밀라노", "나폴리", "기타"],
  스페인: ["바르셀로나", "마드리드", "세비야", "그라나다", "발렌시아", "기타"],
  포르투갈: ["리스본", "포르투", "신트라", "파로", "기타"],
  영국: ["런던", "에든버러", "맨체스터", "옥스퍼드", "기타"],
  미국: ["뉴욕", "로스앤젤레스", "샌프란시스코", "라스베이거스", "시애틀", "하와이", "기타"],
  호주: ["시드니", "멜버른", "브리즈번", "퍼스", "골드코스트", "케언즈", "기타"],
  기타: ["기타"]
};

function resolveStarterCountry(country: string, customCountry: string) {
  return (country === "기타" ? customCountry : country).trim();
}

function resolveStarterCity(cityPreset: string, customCity: string) {
  return (cityPreset === "기타" ? customCity : cityPreset).trim();
}

function createStarterCityStop(country = "일본"): StarterCityStop {
  const options = cityPresetsByCountry[country] || cityPresetsByCountry["기타"];
  return {
    id: makeId("starter-city"),
    country,
    customCountry: "",
    cityPreset: options[0] || "기타",
    customCity: ""
  };
}

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

function compactDateLabel(value: string) {
  const date = new Date(`${value}T00:00:00`);
  const weekday = new Intl.DateTimeFormat("ko-KR", { weekday: "short" }).format(date);
  return `${date.getMonth() + 1}.${date.getDate()} ${weekday}`;
}

function timeToMinutes(value?: string) {
  const match = value?.match(/^(\d{1,2}):(\d{2})/);
  if (!match) return null;
  return Number(match[1]) * 60 + Number(match[2]);
}

function minutesToClock(value: number) {
  const hour = Math.floor(value / 60);
  const minute = value % 60;
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function makeId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function tripScopedData(data: TripData, tripId: string): TripData {
  const byTrip = <T extends { trip_id: string }>(items: T[]) => items.filter((item) => item.trip_id === tripId);
  return {
    ...data,
    trips: data.trips.filter((trip) => trip.id === tripId),
    trip_members: byTrip(data.trip_members),
    itinerary_items: byTrip(data.itinerary_items),
    places: byTrip(data.places),
    food_candidates: byTrip(data.food_candidates),
    checklist_items: byTrip(data.checklist_items),
    gallery_items: byTrip(data.gallery_items),
    onsite_notes: byTrip(data.onsite_notes),
    expenses: byTrip(data.expenses),
    quick_links: byTrip(data.quick_links)
  };
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
  const [appTheme, setAppThemeState] = useState<AppTheme>("editorial-sea");
  const [showLanding, setShowLanding] = useState(true);
  const [showStarter, setShowStarter] = useState(false);
  const [saveState, setSaveState] = useState<SaveState>("idle");
  const [selectedTripId, setSelectedTripId] = useState("");

  const activeTrips = useMemo(() => data.trips.filter((trip) => !trip.archived), [data.trips]);
  const selectedTrip = useMemo(() => {
    return data.trips.find((trip) => trip.id === selectedTripId) || activeTrips[0] || data.trips[0] || seedData.trips[0];
  }, [activeTrips, data.trips, selectedTripId]);
  const scopedData = useMemo(() => tripScopedData(data, selectedTrip.id), [data, selectedTrip.id]);

  function setAppTheme(theme: AppTheme) {
    setAppThemeState(theme);
    try {
      window.localStorage.setItem(APP_THEME_STORAGE_KEY, theme);
    } catch {}
  }

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
    try {
      const storedTheme = window.localStorage.getItem(APP_THEME_STORAGE_KEY) as AppTheme | null;
      if (storedTheme && appThemes.some((theme) => theme.key === storedTheme)) {
        setAppThemeState(storedTheme);
      }
    } catch {}
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

  useEffect(() => {
    if (!data.trips.length) return;
    const current = data.trips.find((trip) => trip.id === selectedTripId);
    if (current && !current.archived) return;
    const next = data.trips.find((trip) => !trip.archived) || data.trips[0];
    setSelectedTripId(next.id);
  }, [data.trips, selectedTripId]);

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

  async function createTripFromStarter(draft: TripStarterDraft) {
    const country = resolveStarterCountry(draft.country, draft.customCountry) || "국가 미정";
    const primaryCity = resolveStarterCity(draft.cityPreset, draft.customCity) || "새 도시";
    const extraCityNames = draft.extraCities
      .map((stop) => resolveStarterCity(stop.cityPreset, stop.customCity))
      .filter(Boolean);
    const cities = Array.from(new Set([primaryCity, ...extraCityNames]));
    const start = draft.startDate || todayKey();
    const end = draft.endDate || draft.startDate || start;
    const created = await mutate<Trip>("trips", "create", {
      row: {
        id: makeId("trip"),
        name: draft.tripName.trim() || `${primaryCity} 여행`,
        region: cities.join(" · "),
        start_date: start,
        end_date: end,
        hero_image: "",
        note: draft.myMapsUrl ? "Google My Maps 링크로 시작한 새 여행입니다." : "새 여행 계획입니다.",
        country,
        cities,
        accommodation: "",
        my_maps_url: draft.myMapsUrl,
        outbound_origin: draft.outboundOrigin,
        outbound_destination: draft.outboundDestination || primaryCity,
        outbound_flight: draft.outboundFlight,
        outbound_departure_time: draft.outboundDepart || undefined,
        outbound_arrival_time: draft.outboundArrive || undefined,
        return_origin: draft.returnOrigin || primaryCity,
        return_destination: draft.returnDestination,
        return_flight: draft.returnFlight,
        return_departure_time: draft.returnDepart || undefined,
        return_arrival_time: draft.returnArrive || undefined,
        budget_amount: 0,
        budget_currency: "JPY",
        archived: false
      }
    });
    if (!created) return;
    if (draft.myMapsUrl.trim()) {
      await mutate<QuickLink>("quick_links", "create", {
        row: { id: makeId("link"), trip_id: created.id, label: "공유 지도", kind: "map", url: draft.myMapsUrl.trim() }
      });
    }
    for (let index = 0; index < cities.length - 1; index += 1) {
      const transferDate = draft.cityTransferDates[String(index)];
      if (!transferDate) continue;
      await mutate<ItineraryItem>("itinerary_items", "create", {
        row: {
          id: makeId("itinerary"),
          trip_id: created.id,
          date: transferDate,
          time_label: "이동",
          start_time: "",
          end_time: "",
          title: `${cities[index]} → ${cities[index + 1]} 이동`,
          description: "도시 간 이동일입니다. 교통편과 시간을 나중에 채워주세요.",
          location: `${cities[index]} → ${cities[index + 1]}`,
          priority: "필수",
          reservation_status: "확인 필요",
          weather_impact: "날씨 확인",
          owner: "공통",
          sort_order: index + 1
        }
      });
    }
    setSelectedTripId(created.id);
    setShowStarter(false);
    setShowLanding(false);
    setActive("home");
  }

  if (authenticated === null) {
    return <main className="grid min-h-screen place-items-center"><Loader2 className="animate-spin text-sea" size={34} /></main>;
  }

  if (!authenticated) {
    return <LoginScreen onSuccess={() => loadData().catch(() => setAuthenticated(true))} />;
  }

  const trip = selectedTrip;

  if (showLanding) {
    if (showStarter) {
      return (
        <TripStarterPage
          theme={appTheme}
          onCreate={createTripFromStarter}
          onBack={() => setShowStarter(false)}
          onOpenExisting={() => {
            setShowLanding(false);
            setActive("home");
          }}
        />
      );
    }
    return (
      <LandingPage
        trip={trip}
        theme={appTheme}
        onEnter={() => setShowLanding(false)}
        onPlanNew={() => setShowStarter(true)}
        onJump={(view) => {
          setActive(view);
          setShowLanding(false);
        }}
      />
    );
  }

  return (
    <div className="app-shell" data-app-theme={appTheme}>
      <SideNav active={active} setActive={setActive} saveState={saveState} mode={mode} trip={trip} />
      <main className="mx-auto min-w-0 max-w-[92rem] px-4 py-4 lg:px-8 lg:py-6">
        <Header
          trip={trip}
          onOpenLanding={() => {
            setShowStarter(false);
            setShowLanding(true);
          }}
          onLogout={async () => {
            await fetch("/api/session", { method: "DELETE" });
            setAuthenticated(false);
          }}
        />
        {active === "home" && <HomeView data={scopedData} setActive={setActive} mutate={mutate} />}
        {active === "schedule" && <ScheduleView items={scopedData.itinerary_items} places={scopedData.places} foods={scopedData.food_candidates} trip={trip} mutate={mutate} />}
        {active === "gallery" && <GalleryView items={scopedData.gallery_items} trip={trip} mutate={mutate} />}
        {active === "map" && <MapView places={scopedData.places} foods={scopedData.food_candidates} links={scopedData.quick_links} trip={trip} mutate={mutate} />}
        {active === "checklist" && <ChecklistView items={scopedData.checklist_items} mutate={mutate} />}
        {active === "food" && <FoodView foods={scopedData.food_candidates} trip={trip} mutate={mutate} />}
        {active === "budget" && <BudgetView expenses={scopedData.expenses} members={scopedData.trip_members.map((member) => member.name)} trip={trip} mutate={mutate} />}
        {active === "onsite" && <OnsiteView notes={scopedData.onsite_notes} links={scopedData.quick_links} mutate={mutate} />}
        {active === "settings" && <SettingsView data={data} trip={trip} selectedTripId={trip.id} setSelectedTripId={setSelectedTripId} mode={mode} theme={appTheme} setTheme={setAppTheme} mutate={mutate} />}
      </main>
      <BottomNav active={active} setActive={setActive} />
    </div>
  );
}

function LandingPage({ trip, theme, onEnter, onPlanNew, onJump }: { trip: TripData["trips"][number]; theme: AppTheme; onEnter: () => void; onPlanNew: () => void; onJump: (view: ViewKey) => void }) {
  const cityOptions = trip.cities?.length ? trip.cities : trip.region.split("·").map((city) => city.trim()).filter(Boolean);
  const features = [
    { title: "Live map", body: "My Maps 링크를 기준으로 장소와 식당 후보를 계속 정리", icon: Map },
    { title: "Shared schedule", body: "날짜별 타임라인과 캘린더뷰로 가족 일정 확인", icon: CalendarDays },
    { title: "Field notes", body: "페리, 공항, 예약 정보처럼 현장에서 바로 볼 자료 보관", icon: Images }
  ];
  const itineraryPreview = seedData.itinerary_items.slice(0, 3);

  return (
    <main className="landing-shell" data-landing-theme={theme}>
      <nav className="landing-nav">
        <div className="landing-logo" aria-label="Triplanner brand">
          <span>Triplanner</span>
        </div>
        <div className="hidden items-center gap-2 md:flex">
          <button className="landing-link" type="button" onClick={() => onJump("schedule")}>Schedule</button>
          <button className="landing-link" type="button" onClick={() => onJump("map")}>Map</button>
          <button className="landing-link" type="button" onClick={() => onJump("gallery")}>Notes</button>
        </div>
        <button className="btn" type="button" onClick={onEnter}>앱 열기</button>
      </nav>

      <section className="landing-hero">
        <div className="landing-copy">
          <p className="landing-kicker">{dateLabel(trip.start_date)} - {dateLabel(trip.end_date)}</p>
          <h1>Plan the trip, share the map.</h1>
          <p className="landing-lead">
            지도, 일정, 준비물, 자료, 예산을 한 화면에서 정리하는 가족 여행 플래너입니다.
            현장에서 바로 읽히는 밀도와, 여행 전 계획하기 좋은 구조를 같이 가져갑니다.
          </p>
          <div className="landing-actions">
            <button className="btn" type="button" onClick={onPlanNew}>계획 시작</button>
            <button className="btn btn-secondary" type="button" onClick={() => onJump("map")}>지도 보기</button>
          </div>
          <div className="landing-stats">
            <span><strong>{cityOptions.length || 1}</strong> cities</span>
            <span><strong>{seedData.itinerary_items.length}</strong> schedule</span>
            <span><strong>{seedData.gallery_items.length}</strong> notes</span>
          </div>
        </div>

        <div className="landing-device" aria-label="Triplanner app preview">
          <div className="landing-device-top">
            <div>
              <p>TRIP</p>
              <h2>{trip.name}</h2>
            </div>
            <span>{cityOptions[0] || trip.region}</span>
          </div>
          <div className="landing-flight-grid">
            <div>
              <p>가는 편</p>
              <strong>{trip.outbound_flight || "RS0741"}</strong>
              <span>{trip.outbound_origin || "서울"} {trip.outbound_departure_time || "08:20"} → {trip.outbound_destination || "타카마쓰"} {trip.outbound_arrival_time || "10:30"}</span>
            </div>
            <div>
              <p>오는 편</p>
              <strong>{trip.return_flight || "RS0742"}</strong>
              <span>{trip.return_origin || "타카마쓰"} {trip.return_departure_time || "11:40"} → {trip.return_destination || "서울"} {trip.return_arrival_time || "13:30"}</span>
            </div>
          </div>
          <div className="landing-timeline">
            {itineraryPreview.map((item) => (
              <article key={item.id}>
                <time>{item.start_time || item.time_label}</time>
                <div>
                  <h3>{item.title}</h3>
                  <p>{item.description}</p>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="landing-feature-grid">
        {features.map((feature) => {
          const Icon = feature.icon;
          return (
            <article className="landing-feature-card" key={feature.title}>
              <div><Icon size={22} /></div>
              <h2>{feature.title}</h2>
              <p>{feature.body}</p>
            </article>
          );
        })}
      </section>

      <section className="landing-board">
        <div>
          <p className="landing-kicker">Built for web, phone, iPad, and Mac</p>
          <h2>여행마다 필요한 문구와 화면을 바꿀 수 있게.</h2>
        </div>
        <div className="landing-board-cards">
          {[
            ["Checklist", "가족별 준비물"],
            ["Budget", "지출과 예정 결제"],
            ["Gallery", "스크린샷 자료 묶음"],
            ["My Maps", "공유 지도 동기화"]
          ].map(([title, body]) => (
            <button className="landing-mini-card" key={title} type="button" onClick={onEnter}>
              <strong>{title}</strong>
              <span>{body}</span>
            </button>
          ))}
        </div>
      </section>
    </main>
  );
}

function TripStarterPage({ theme, onBack, onOpenExisting, onCreate }: { theme: AppTheme; onBack: () => void; onOpenExisting: () => void; onCreate: (draft: TripStarterDraft) => Promise<void> }) {
  const [draft, setDraft] = useState<TripStarterDraft>({
    tripName: "",
    country: "일본",
    customCountry: "",
    cityPreset: "타카마쓰",
    customCity: "",
    extraCities: [],
    cityTransferDates: {},
    startDate: "",
    endDate: "",
    outboundFlight: "",
    outboundOrigin: "",
    outboundDestination: "",
    outboundDepart: "",
    outboundArrive: "",
    returnFlight: "",
    returnOrigin: "",
    returnDestination: "",
    returnDepart: "",
    returnArrive: "",
    myMapsUrl: ""
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  }, []);

  const country = resolveStarterCountry(draft.country, draft.customCountry) || "직접 입력 국가";
  const cityOptions = cityPresetsByCountry[draft.country] || cityPresetsByCountry["기타"];
  const city = resolveStarterCity(draft.cityPreset, draft.customCity) || "직접 입력 도시";
  const extraCities = draft.extraCities;
  const transferStops = [
    city,
    ...extraCities.map((stop, index) => resolveStarterCity(stop.cityPreset, stop.customCity) || `도시 ${index + 2}`)
  ];
  const tripName = draft.tripName || `${city} 여행`;
  const dateRange = draft.startDate && draft.endDate ? `${dateLabel(draft.startDate)} - ${dateLabel(draft.endDate)}` : "기간은 나중에 입력 가능";
  const outboundRoute = `${draft.outboundOrigin || "출발지"} → ${draft.outboundDestination || city || "도착지"}`;
  const returnRoute = `${draft.returnOrigin || city || "출발지"} → ${draft.returnDestination || "도착지"}`;
  const saveTrip = async () => {
    setSaving(true);
    try {
      await onCreate(draft);
    } finally {
      setSaving(false);
    }
  };
  const updateExtraCity = (index: number, patch: Partial<StarterCityStop>) => {
    setDraft((current) => ({
      ...current,
      extraCities: current.extraCities.map((stop, itemIndex) => (
        itemIndex === index ? { ...stop, ...patch } : stop
      ))
    }));
  };
  const changeExtraCityCountry = (index: number, value: string) => {
    const nextCityOptions = cityPresetsByCountry[value] || cityPresetsByCountry["기타"];
    updateExtraCity(index, {
      country: value,
      cityPreset: nextCityOptions[0] || "기타",
      customCountry: value === "기타" ? extraCities[index]?.customCountry || "" : "",
      customCity: ""
    });
  };
  const addExtraCity = () => {
    setDraft((current) => ({ ...current, extraCities: [...current.extraCities, createStarterCityStop(current.country)] }));
  };
  const removeExtraCity = (index: number) => {
    const next = extraCities.filter((_, itemIndex) => itemIndex !== index);
    const nextTransferDates: Record<string, string> = {};
    Object.entries(draft.cityTransferDates).forEach(([key, value]) => {
      const numericKey = Number(key);
      if (numericKey < index) nextTransferDates[key] = value;
      if (numericKey > index) nextTransferDates[String(numericKey - 1)] = value;
    });
    setDraft((current) => ({ ...current, extraCities: next, cityTransferDates: nextTransferDates }));
  };
  const changeCountry = (value: string) => {
    const nextCityOptions = cityPresetsByCountry[value] || cityPresetsByCountry["기타"];
    setDraft((current) => ({
      ...current,
      country: value,
      cityPreset: nextCityOptions[0] || "기타",
      customCity: value === "기타" ? current.customCity : ""
    }));
  };

  return (
    <main className="landing-shell starter-shell" data-landing-theme={theme}>
      <nav className="landing-nav">
        <button className="landing-logo" type="button" onClick={onBack} aria-label="랜딩으로 돌아가기">
          <span>Triplanner</span>
        </button>
        <div className="hidden items-center gap-2 md:flex">
          <span className="starter-nav-note">새 여행 셋업 미리보기</span>
        </div>
        <button className="btn btn-secondary" type="button" onClick={onOpenExisting}>기존 여행 열기</button>
      </nav>

      <section className="starter-hero">
        <div>
          <p className="landing-kicker">Start a trip</p>
          <h1>목적지를 선택해주세요</h1>
          <p>기간, 항공편, My Maps 링크는 건너뛸 수 있고 나중에 설정에서 다시 채울 수 있습니다.</p>
        </div>
        <div className="starter-steps" aria-label="여행 셋업 단계">
          {["Destination", "Dates", "Flights", "My Maps"].map((step, index) => (
            <span key={step}><b>{index + 1}</b>{step}</span>
          ))}
        </div>
      </section>

      <section className="starter-grid">
        <form className="starter-form" onSubmit={(event) => {
          event.preventDefault();
          void saveTrip();
        }}>
          <section className="starter-panel">
            <div className="starter-section-head">
              <span>1</span>
              <div>
                <h2>Destination</h2>
                <p>국가와 첫 도시를 먼저 고릅니다. 소도시는 기타에서 직접 입력합니다.</p>
              </div>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <label className="setup-field"><span>여행 제목</span><input className="field" value={draft.tripName} onChange={(event) => setDraft({ ...draft, tripName: event.target.value })} placeholder="예: 도쿄 가족여행" /></label>
              <label className="setup-field"><span>국가 선택</span><select className="field" value={draft.country} onChange={(event) => changeCountry(event.target.value)}>{countryOptions.map((countryOption) => <option key={countryOption}>{countryOption}</option>)}</select></label>
              {draft.country === "기타" ? <label className="setup-field"><span>국가 직접 입력</span><input className="field" value={draft.customCountry} onChange={(event) => setDraft({ ...draft, customCountry: event.target.value })} placeholder="예: 뉴질랜드" /></label> : null}
              <label className="setup-field"><span>첫 도시 선택</span><select className="field" value={draft.cityPreset} onChange={(event) => setDraft({ ...draft, cityPreset: event.target.value })}>{cityOptions.map((item) => <option key={item}>{item}</option>)}</select></label>
              {draft.cityPreset === "기타" ? <label className="setup-field"><span>도시 직접 입력</span><input className="field" value={draft.customCity} onChange={(event) => setDraft({ ...draft, customCity: event.target.value })} placeholder="예: 마쓰야마" /></label> : null}
              <div className="setup-field md:col-span-2">
                <span>추가 도시</span>
                <div className="starter-city-list">
                  {extraCities.map((stop, index) => {
                    const extraCityOptions = cityPresetsByCountry[stop.country] || cityPresetsByCountry["기타"];
                    return (
                      <div className="starter-city-row" key={stop.id}>
                        <label className="setup-field">
                          <span>{index + 2}번째 국가</span>
                          <select className="field" value={stop.country} onChange={(event) => changeExtraCityCountry(index, event.target.value)}>
                            {countryOptions.map((countryOption) => <option key={countryOption}>{countryOption}</option>)}
                          </select>
                        </label>
                        {stop.country === "기타" ? (
                          <label className="setup-field">
                            <span>국가 직접 입력</span>
                            <input className="field" value={stop.customCountry} onChange={(event) => updateExtraCity(index, { customCountry: event.target.value })} placeholder="예: 체코" />
                          </label>
                        ) : null}
                        <label className="setup-field">
                          <span>{index + 2}번째 도시</span>
                          <select className="field" value={stop.cityPreset} onChange={(event) => updateExtraCity(index, { cityPreset: event.target.value, customCity: "" })}>
                            {extraCityOptions.map((item) => <option key={item}>{item}</option>)}
                          </select>
                        </label>
                        {stop.cityPreset === "기타" || stop.country === "기타" ? (
                          <label className="setup-field">
                            <span>도시 직접 입력</span>
                            <input className="field" value={stop.customCity} onChange={(event) => updateExtraCity(index, { customCity: event.target.value })} placeholder="예: 프라하" />
                          </label>
                        ) : null}
                        <button className="btn btn-secondary starter-icon-button" type="button" onClick={() => removeExtraCity(index)} aria-label={`${index + 2}번째 도시 삭제`}><X size={16} /></button>
                      </div>
                    );
                  })}
                  <button className="btn btn-secondary starter-add-city" type="button" onClick={addExtraCity}><Plus size={16} />도시 추가</button>
                </div>
              </div>
            </div>
          </section>

          <section className="starter-panel">
            <div className="starter-section-head">
              <span>2</span>
              <div>
                <h2>Dates</h2>
                <p>여행 기간과 도시 간 이동일을 넣으면 일정 탭의 Day 필터와 캘린더 기준이 됩니다.</p>
              </div>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <label className="setup-field"><span>시작일</span><input className="field" type="date" value={draft.startDate} onChange={(event) => setDraft({ ...draft, startDate: event.target.value })} /></label>
              <label className="setup-field"><span>종료일</span><input className="field" type="date" value={draft.endDate} onChange={(event) => setDraft({ ...draft, endDate: event.target.value })} /></label>
            </div>
            {extraCities.length > 0 ? (
              <div className="starter-transfer-list">
                {extraCities.map((_, index) => (
                  <label className="setup-field" key={`transfer-${index}`}>
                    <span>{transferStops[index]} → {transferStops[index + 1]} 이동일</span>
                    <input
                      className="field"
                      type="date"
                      value={draft.cityTransferDates[String(index)] || ""}
                      onChange={(event) => setDraft({
                        ...draft,
                        cityTransferDates: { ...draft.cityTransferDates, [String(index)]: event.target.value }
                      })}
                    />
                  </label>
                ))}
              </div>
            ) : null}
          </section>

          <section className="starter-panel">
            <div className="starter-section-head">
              <span>3</span>
              <div>
                <h2>Flights</h2>
                <p>편명만 먼저 넣고 시간은 나중에 채워도 됩니다.</p>
              </div>
            </div>
            <details className="starter-help">
              <summary>자동 항공편 조회는 어떻게 연결하나요?</summary>
              <p>FlightAware, Aviationstack, Amadeus 같은 항공편 API 키가 필요합니다. 서버에서 편명을 조회해 출발지, 도착지, 출발/도착 시간을 채우는 방식으로 붙입니다. 무료/저가 API는 지연·결항 정보가 제한될 수 있어 우선은 수동 입력을 기본값으로 둡니다.</p>
            </details>
            <div className="grid gap-3 md:grid-cols-2">
              <div className="setup-flight-card">
                <p>가는 편</p>
                <label className="setup-field"><span>편명</span><input className="field" value={draft.outboundFlight} onChange={(event) => setDraft({ ...draft, outboundFlight: event.target.value.toUpperCase() })} placeholder="RS0741" /></label>
                <div className="grid gap-2 md:grid-cols-2">
                  <label className="setup-field"><span>출발지</span><input className="field" value={draft.outboundOrigin} onChange={(event) => setDraft({ ...draft, outboundOrigin: event.target.value })} /></label>
                  <label className="setup-field"><span>도착지</span><input className="field" value={draft.outboundDestination} onChange={(event) => setDraft({ ...draft, outboundDestination: event.target.value })} /></label>
                  <label className="setup-field"><span>출발시간</span><input className="field" type="time" value={draft.outboundDepart} onChange={(event) => setDraft({ ...draft, outboundDepart: event.target.value })} /></label>
                  <label className="setup-field"><span>도착시간</span><input className="field" type="time" value={draft.outboundArrive} onChange={(event) => setDraft({ ...draft, outboundArrive: event.target.value })} /></label>
                </div>
              </div>
              <div className="setup-flight-card">
                <p>오는 편</p>
                <label className="setup-field"><span>편명</span><input className="field" value={draft.returnFlight} onChange={(event) => setDraft({ ...draft, returnFlight: event.target.value.toUpperCase() })} placeholder="RS0742" /></label>
                <div className="grid gap-2 md:grid-cols-2">
                  <label className="setup-field"><span>출발지</span><input className="field" value={draft.returnOrigin} onChange={(event) => setDraft({ ...draft, returnOrigin: event.target.value })} /></label>
                  <label className="setup-field"><span>도착지</span><input className="field" value={draft.returnDestination} onChange={(event) => setDraft({ ...draft, returnDestination: event.target.value })} /></label>
                  <label className="setup-field"><span>출발시간</span><input className="field" type="time" value={draft.returnDepart} onChange={(event) => setDraft({ ...draft, returnDepart: event.target.value })} /></label>
                  <label className="setup-field"><span>도착시간</span><input className="field" type="time" value={draft.returnArrive} onChange={(event) => setDraft({ ...draft, returnArrive: event.target.value })} /></label>
                </div>
              </div>
            </div>
          </section>

          <section className="starter-panel">
            <div className="starter-section-head">
              <span>4</span>
              <div>
                <h2>My Maps</h2>
                <p>공유 지도 링크를 넣으면 장소/식당 후보를 지도 탭에서 계속 동기화하는 구조로 시작합니다.</p>
              </div>
            </div>
            <label className="setup-field"><span>Google My Maps 공유 링크</span><input className="field" value={draft.myMapsUrl} onChange={(event) => setDraft({ ...draft, myMapsUrl: event.target.value })} placeholder="https://www.google.com/maps/d/..." /></label>
          </section>
          <button className="btn starter-submit" disabled={saving} type="submit">{saving ? <Loader2 className="animate-spin" size={18} /> : <Plus size={18} />}이 내용으로 여행 만들기</button>
        </form>

        <aside className="starter-preview">
          <div className="starter-phone">
            <div className="starter-phone-top">
              <span>{country}</span>
              <strong>{city}</strong>
            </div>
            <h2>{tripName}</h2>
            <p>{dateRange}</p>
            <div className="starter-preview-card">
              <small>가는 편</small>
              <strong>{draft.outboundFlight || "편명 미정"}</strong>
              <span>{outboundRoute}</span>
              <em>{draft.outboundDepart || "--:--"} 출발 · {draft.outboundArrive || "--:--"} 도착</em>
            </div>
            <div className="starter-preview-card alt">
              <small>오는 편</small>
              <strong>{draft.returnFlight || "편명 미정"}</strong>
              <span>{returnRoute}</span>
              <em>{draft.returnDepart || "--:--"} 출발 · {draft.returnArrive || "--:--"} 도착</em>
            </div>
            <div className="starter-preview-row">
              <span>Map</span>
              <b>{draft.myMapsUrl ? "연결됨" : "나중에 연결"}</b>
            </div>
            <div className="starter-preview-row">
              <span>Next</span>
              <b>일정 · Notes · 체크리스트</b>
            </div>
          </div>
          <button className="btn btn-secondary" type="button" onClick={onOpenExisting}>기존 예시 앱에서 계속 보기</button>
        </aside>
      </section>
    </main>
  );
}

function SideNav({ active, setActive, saveState, mode, trip }: { active: ViewKey; setActive: (key: ViewKey) => void; saveState: SaveState; mode: string; trip: TripData["trips"][number] }) {
  return (
    <aside className="sidebar-shell sticky top-0 hidden h-screen flex-col gap-5 p-4 lg:flex">
      <div className="sidebar-brand">
        <p className="text-xs font-black uppercase text-sea">Family trip</p>
        <h2 className="mt-1 text-2xl font-black leading-none">{trip.cities?.[0] || trip.region.split("·")[0]?.trim() || "Trip"}</h2>
        <p className="mt-1 truncate text-xs font-bold text-black/45">{dateLabel(trip.start_date)} - {dateLabel(trip.end_date)}</p>
      </div>
      <nav className="grid gap-1">
        {navItems.map((item) => <NavButton key={item.key} item={item} active={active} setActive={setActive} />)}
      </nav>
      <div className="soft-inset mt-auto rounded-lg p-3 text-sm font-bold text-black/60">
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
      className={`nav-item flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm font-black ${compact ? "min-w-[4.1rem] flex-col gap-1 px-1 text-[0.72rem]" : "justify-start"} ${selected ? "" : "text-black/58"}`}
      data-selected={selected}
      onClick={() => setActive(item.key)}
      type="button"
    >
      <Icon size={compact ? 19 : 18} />
      {item.label}
    </button>
  );
}

function Header({ trip, onOpenLanding, onLogout }: { trip: TripData["trips"][number]; onOpenLanding: () => void; onLogout: () => void }) {
  const cityOptions = trip.cities?.length ? trip.cities : trip.region.split("·").map((city) => city.trim()).filter(Boolean);
  return (
    <header className="trip-hero mb-4 rounded-lg p-4 shadow-soft lg:p-6">
      <div className="flex items-start justify-between gap-3">
        <div className="relative z-10 min-w-0">
          <p className="trip-kicker text-xs font-black">{dateLabel(trip.start_date)} - {dateLabel(trip.end_date)}</p>
          <h1 className="trip-title mt-1 text-3xl font-black leading-none lg:text-5xl">{trip.name}</h1>
          <div className="mt-3 flex flex-wrap items-center gap-2">
            <span className="trip-pill">{trip.country || "국가 미정"}</span>
            <select className="trip-pill outline-none" aria-label="도시 선택" defaultValue={cityOptions[0] || trip.region}>
              {cityOptions.map((city, index) => <option className="text-black" key={`${city}-${index}`} value={city}>도시 {index + 1} · {city}</option>)}
              <option className="text-black" value="add">+ 다음 도시 추가</option>
            </select>
          </div>
          <div className="flight-strip mt-4">
            <FlightCard
              label="가는 편"
              flight={trip.outbound_flight || "편명 미정"}
              origin={trip.outbound_origin || "출발지"}
              destination={trip.outbound_destination || "도착지"}
              departureTime={trip.outbound_departure_time || "08:20"}
              arrivalTime={trip.outbound_arrival_time || "10:30"}
            />
            <FlightCard
              label="오는 편"
              flight={trip.return_flight || "편명 미정"}
              origin={trip.return_origin || "출발지"}
              destination={trip.return_destination || "도착지"}
              departureTime={trip.return_departure_time || "11:40"}
              arrivalTime={trip.return_arrival_time || "13:30"}
            />
          </div>
        </div>
        <div className="relative z-10 flex shrink-0 items-center gap-2">
          <button className="btn btn-secondary min-h-11 px-3 text-sm" onClick={onOpenLanding} type="button">
            처음 화면
          </button>
          <button className="btn btn-secondary min-h-11 w-11 px-0" onClick={onLogout} type="button" aria-label="로그아웃">
            <LogOut size={18} />
          </button>
        </div>
      </div>
    </header>
  );
}

function FlightCard({ label, flight, origin, destination, departureTime, arrivalTime }: { label: string; flight: string; origin: string; destination: string; departureTime: string; arrivalTime: string }) {
  return (
    <span className="flight-card">
      <span className="flight-card-icon"><Plane size={16} /></span>
      <span className="flight-card-main">
        <span className="flight-card-label">{label} <strong>{flight}</strong></span>
        <span className="flight-card-route">
          <span><b>{origin}</b><time>{departureTime} 출발</time></span>
          <ArrowRight size={15} />
          <span><b>{destination}</b><time>{arrivalTime} 도착</time></span>
        </span>
      </span>
    </span>
  );
}

function HomeView({ data, setActive, mutate }: { data: TripData; setActive: (key: ViewKey) => void; mutate: PageMutate }) {
  const weather = useWeather();
  const [recommendOpen, setRecommendOpen] = useState(false);
  const trip = data.trips[0];
  const initialResearchNotes = useMemo(() => trip?.id === DEFAULT_TRIP_ID ? [
    { id: "ferry", title: "페리 시간", body: "페리 소요 약 50분, 성인 편도 520엔. 차량/자전거 선적 가능, 객실이 넓고 안정적.\n\n타카마쓰항 → 나오시마\n08:12 → 09:02\n10:14 → 11:04 (추천)\n12:40 → 13:30\n15:35 → 16:25\n18:05 → 18:55\n\n나오시마 → 타카마쓰항\n07:00 → 07:50\n09:20 → 10:10\n11:30 → 12:20\n14:20 → 15:10\n17:00 → 17:50 (추천)" },
    { id: "fast-boat", title: "고속선 시간", body: "고속선 소요 약 30분, 성인 편도 1,220엔. 승선 인원 제한, 자전거 선적 불가.\n\n타카마쓰항 → 나오시마\n07:45 → 08:15\n09:20 → 09:50\n11:35 → 12:05\n16:10 → 16:40\n19:35 → 20:05\n\n나오시마 → 타카마쓰항\n08:35 → 09:05\n10:35 → 11:05\n13:15 → 13:45\n16:55 → 17:25\n18:35 → 19:05" },
    { id: "chichu-route", title: "지중미술관 동선", body: "숙소 인근 JR 리쓰린코엔 기타구치역에서 오전 9:20 전후 열차 탑승 → 다카마쓰역/항구 이동.\n\n10:14 페리 탑승 → 11:04 나오시마 도착. 항구 앞 자전거 대여 및 점심.\n\n지중미술관은 12:00 예약 완료. 성인 3명, 각 ¥2,500.\n\n관람 후 이에 프로젝트/근처 동선을 보고 17:00 페리로 복귀하면 17:50 다카마쓰항 도착." },
    { id: "naoshima-bus", title: "나오시마 버스/셔틀", body: "미야노우라항에 내리면 재빨리 2번 정류장으로 이동.\n\n1) 시내버스: 미야노우라항 → 츠츠지소. 요금 100엔, 하차할 때 지불, 약 20분.\n2) 츠츠지소에서 베네세 구역 무료 셔틀버스 환승.\n\n셔틀 노선: 츠츠지소 → 히로시 스기모토 갤러리 → 베네세 하우스 뮤지엄 → 이우환 미술관/Valley Gallery → 지중미술관.\n\n복귀 노선: 지중미술관 → 이우환 미술관/Valley Gallery → 베네세 하우스 뮤지엄 → 히로시 스기모토 갤러리 → 츠츠지소.\n\n버스 기다리는 시간과의 싸움. 페리 도착 직후 사람 많은 시간에는 추가 버스가 붙기도 하지만, 놓치면 대기가 길어질 수 있음." },
    { id: "museum-hours", title: "나오시마 미술관 운영시간", body: "베네세 하우스 뮤지엄: 08:00-21:00, 마지막 입장 20:00.\nValley Gallery: 09:30-16:00, 마지막 입장 15:30. 베네세 하우스 티켓에 포함.\n히로시 스기모토 갤러리: 11:00-15:00, 마지막 입장 14:00, 날짜/시간 예약 필요.\n지중미술관: 10:00-17:00, 마지막 입장 16:00, 날짜/시간 예약 필요. 6/23 12:00 예약 완료.\n이우환 미술관: 10:00-17:00, 마지막 입장 16:30.\n나오시마 신미술관: 10:00-16:30, 마지막 입장 16:00." },
    { id: "museum-order", title: "나오시마 관람 순서 후보", body: "A안: 지중미술관 → 이우환미술관 + Valley Gallery → 베네세 하우스 뮤지엄.\nB안: 베네세 하우스 뮤지엄 → Valley Gallery + 이우환미술관 → 지중미술관.\n\n이번 예약은 지중미술관 12:00이라 A안을 기본으로 두고, 셔틀 대기 시간이 길면 가까운 곳 위주로 줄이기.\n\n이동 감각: 지중미술관 → 이우환미술관은 전기자전거+도보 10분 이내 또는 셔틀 5분. 이우환미술관 → 베네세 하우스는 도보 10분 또는 셔틀 3분. 베네세 하우스 → 지중미술관은 전기자전거+도보 20분 이내 또는 셔틀 5분." },
    { id: "airport-bus", title: "공항/리무진버스/티켓", body: "6/24 RS0742 11:40 출발. 마지막 날은 관광보다 체크아웃과 공항 이동 중심.\n\n타카마쓰 공항 국제선 쪽 114Bank Money Exchange, 은행 ATM에서 트래블카드 출금/환전 확인. 사진 기준 9:00-21:00.\n\n공항 도착/출발 때 리무진버스 티켓 구매 위치도 같이 확인해두기." },
    { id: "boat-experience", title: "나룻배체험", body: "선착순 성격이 강하고 원하는 시간대가 있으면 미리 예매 필요. 6/23은 12:00 지중미술관 예약이 고정이라 오전에는 무리하지 않기. 페리/버스/셔틀 대기가 길어지면 체험은 과감히 후보로만 두기." }
  ] : [
    {
      id: "starter-note-example",
      title: "예시 메모",
      body: "현장에서 다시 볼 정보가 생기면 항목명과 메모를 추가하세요. 예: 공항버스 시간, 예약 확인 방법, 숙소 체크인 규칙."
    }
  ], [trip?.id]);
  const [researchNotes, setResearchNotes] = useState(initialResearchNotes);
  useEffect(() => {
    setResearchNotes(initialResearchNotes);
  }, [initialResearchNotes]);
  const [researchDraft, setResearchDraft] = useState({ title: "", body: "" });
  const currentDate = todayKey();
  const briefingDate = data.itinerary_items.some((item) => item.date === currentDate)
    ? currentDate
    : (trip?.start_date || data.itinerary_items[0]?.date || currentDate);
  const todaysItems = data.itinerary_items.filter((item) => item.date === briefingDate);
  const pendingChecks = data.checklist_items.filter((item) => item.group_name === "여행준비" && !item.is_done && !item.is_archived);
  const totalExpense = data.expenses.reduce((sum, expense) => sum + Number(expense.amount || 0), 0);

  return (
    <section className="grid gap-4">
      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        <Metric title="날씨" value={weather.brief} icon={CloudRain} />
        <Metric title="오늘 일정" value={`${todaysItems.length}개`} icon={CalendarDays} />
        <Metric title="미완료 준비" value={`${pendingChecks.length}개`} icon={ListTodo} />
        <Metric title="지출" value={`${totalExpense.toLocaleString("ko-KR")} JPY`} icon={CreditCard} />
      </div>
      <Panel title="숙소 / 이동 기준">
        <div className="grid gap-2 md:grid-cols-3">
          <div className="soft-inset rounded-lg p-3">
            <p className="text-xs font-black text-sea">숙소</p>
            <p className="mt-1 text-xs font-black leading-relaxed md:text-sm">{data.trips[0]?.accommodation || "숙소를 설정에서 입력하세요."}</p>
          </div>
          <div className="soft-inset rounded-lg p-3">
            <p className="text-xs font-black text-sea">도착</p>
            <p className="mt-1 text-sm font-black">{data.trips[0]?.outbound_origin || "출발지"} → {data.trips[0]?.outbound_destination || "도착지"} · {data.trips[0]?.outbound_flight || "편명"} · {data.trips[0]?.outbound_arrival_time || "도착시간"} 도착</p>
          </div>
          <div className="soft-inset rounded-lg p-3">
            <p className="text-xs font-black text-sea">출발</p>
            <p className="mt-1 text-sm font-black">{data.trips[0]?.return_origin || "출발지"} → {data.trips[0]?.return_destination || "도착지"} · {data.trips[0]?.return_flight || "편명"} · {data.trips[0]?.return_departure_time || "출발시간"} 출발</p>
          </div>
        </div>
      </Panel>
      <div className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <Panel title="오늘의 브리핑" action={<button className="btn btn-secondary" onClick={() => setActive("schedule")} type="button">일정 보기</button>}>
          <p className="mb-2 text-xs font-black text-black/45">{dateLabel(briefingDate)} 일정만 표시합니다.</p>
          {todaysItems.length
            ? todaysItems.map((item) => <ItineraryCard key={item.id} item={item} compact weather={weather.byDate[item.date]} />)
            : <Empty text={`${dateLabel(briefingDate)}에 등록된 일정이 없어요.`} />}
        </Panel>
        <Panel title="여행준비" action={<button className="btn btn-secondary" onClick={() => setActive("checklist")} type="button">전체 보기</button>}>
          {pendingChecks.length ? pendingChecks.slice(0, 7).map((item) => (
            <div className="flex items-center justify-between gap-2 rounded-lg border border-black/5 bg-white/75 px-3 py-2.5 text-sm font-bold" key={item.id}>
              <label className="flex min-w-0 items-center gap-2">
                <input className="h-4 w-4 shrink-0 accent-sea" type="checkbox" checked={item.is_done} onChange={(event) => mutate<ChecklistItem>("checklist_items", "update", { id: item.id, patch: { is_done: event.target.checked } })} />
                <span className="truncate">{item.text}</span>
              </label>
              <span className="shrink-0 text-xs text-black/40">{item.owner || "공통"}</span>
            </div>
          )) : <Empty text="여행 준비가 모두 완료됐어요." />}
        </Panel>
      </div>
      <Panel title="빠른 링크" action={<button className="btn btn-secondary btn-sm" type="button" onClick={() => setRecommendOpen(true)}><Sparkles size={14} />추천 도우미</button>}>
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
          {data.quick_links.map((link) => <a className="btn btn-secondary" href={link.url} key={link.id} rel="noreferrer" target="_blank">{link.label}<ExternalLink size={16} /></a>)}
        </div>
      </Panel>
      <Panel title="Notes" titleClassName="research-title">
        <div className="grid gap-2">
          {researchNotes.map((note) => (
            <details className="rounded-lg border border-black/5 bg-white/75 p-3" key={note.id}>
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
        <ScheduleCalendar dates={allDates} items={sortedItems} onSelectDate={(date) => {
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
  const grouped = groupBy(items.filter((item) => item.start_time), (item) => item.date);
  const ranges = items
    .map((item) => {
      const start = timeToMinutes(item.start_time);
      const end = timeToMinutes(item.end_time) ?? (start !== null ? start + 60 : null);
      return start === null || end === null ? null : { start, end };
    })
    .filter(Boolean) as Array<{ start: number; end: number }>;
  const minHour = Math.max(5, Math.floor((Math.min(...ranges.map((item) => item.start), 9 * 60) - 60) / 60));
  const maxHour = Math.min(23, Math.ceil((Math.max(...ranges.map((item) => item.end), 19 * 60) + 60) / 60));
  const hours = Array.from({ length: maxHour - minHour + 1 }, (_, index) => minHour + index);
  const hourHeight = 72;
  const gridColumns = `4rem repeat(${Math.max(dates.length, 1)}, minmax(9.5rem, 1fr))`;
  const gridStyle = { gridTemplateColumns: gridColumns } as CSSProperties;
  const bodyHeight = hours.length * hourHeight;
  return (
    <Panel title="Calendar">
      <div className="week-calendar" aria-label="주간 캘린더">
        <div className="week-calendar-inner">
          <div className="week-calendar-header" style={gridStyle}>
            <div />
            {dates.map((date, index) => (
              <button className="week-day-head" key={date} type="button" onClick={() => onSelectDate(date)}>
                <span>Day {index + 1}</span>
                <strong>{compactDateLabel(date)}</strong>
              </button>
            ))}
          </div>
          <div className="week-calendar-body" style={gridStyle}>
            <div className="week-time-axis" style={{ height: bodyHeight }}>
              {hours.map((hour) => (
                <time key={hour} style={{ top: `${(hour - minHour) * hourHeight}px` }}>{hour < 12 ? `오전 ${hour}` : hour === 12 ? "오후 12" : `오후 ${hour - 12}`}</time>
              ))}
            </div>
            {dates.map((date) => {
              const dayItems = grouped[date] || [];
              return (
                <div className="week-day-column" key={date} style={{ height: bodyHeight }}>
                  {hours.map((hour) => <span className="week-hour-line" key={hour} style={{ top: `${(hour - minHour) * hourHeight}px` }} />)}
                  {dayItems.map((item) => {
                    const start = timeToMinutes(item.start_time) ?? minHour * 60;
                    const end = Math.max(timeToMinutes(item.end_time) ?? start + 60, start + 30);
                    const top = ((start - minHour * 60) / 60) * hourHeight;
                    const height = Math.max(64, ((end - start) / 60) * hourHeight - 6);
                    const kind = itineraryKind(item);
                    return (
                      <button
                        className="week-event"
                        data-kind={kind}
                        key={item.id}
                        style={{ top, height }}
                        type="button"
                        onClick={() => onSelectDate(date)}
                      >
                        <time>{minutesToClock(start)} - {minutesToClock(end)}</time>
                        <strong>{item.title}</strong>
                        {item.location ? <span>{displayPlaceText(item.location, "")}</span> : null}
                      </button>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <p className="mt-3 text-sm font-bold text-black/45">시간 블록을 누르면 해당 날짜 타임라인으로 이동합니다.</p>
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
  const [start, end] = timeRange.split(" - ");
  if (compact && !editing) {
    return (
      <article className="brief-itinerary">
        <div className="brief-time">
          <span>{start || item.time_label || "시간 미정"}</span>
          {end ? <small>{end}</small> : null}
        </div>
        <div className="brief-body">
          <p className="brief-date">{dateLabel(item.date)} · {item.time_label || kind}</p>
          <h3>{kind === "이동" ? "↔ " : ""}{item.title}</h3>
          <p>{item.description}</p>
          <div className="brief-chips">
            <span>{item.priority}</span>
            <span>{item.reservation_status}</span>
            <span>{weather ? `${weather.label} · 강수 ${weather.rain}%` : "날씨 확인"}</span>
          </div>
        </div>
      </article>
    );
  }
  return (
    <article className="schedule-itinerary" data-kind={kind}>
      <div className="schedule-time">
        <span>{start || item.time_label || "시간 미정"}</span>
        {end ? <small>{end}</small> : null}
      </div>
      <div className="schedule-body">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="schedule-date">{dateLabel(item.date)} · {item.time_label || kind}</p>
            {editing ? <input className="field mt-1 min-h-9 px-2 py-1 text-base font-black" value={draft.title} onChange={(event) => setDraft({ ...draft, title: event.target.value })} /> : <h3>{kind === "이동" ? "↔ " : ""}{item.title}</h3>}
          </div>
          <div className="schedule-actions">
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
        <div className="schedule-chips">
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
  const tagOptions = Array.from(new Set(items.map((item) => item.category).filter(Boolean))).sort((a, b) => a.localeCompare(b));
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
        <datalist id="gallery-tag-options">
          {tagOptions.map((tag) => <option key={tag} value={tag} />)}
        </datalist>
      </Panel>

      {grouped.length ? grouped.map(([group, dayItems]) => (
        <Panel title={groupMode === "date" && group !== "날짜 없음" ? dateLabel(group) : group} key={group}>
          <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
            {dayItems.map((item) => (
              <article className="gallery-card group overflow-hidden rounded-lg border border-black/5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-lg" key={item.id}>
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
                  <GalleryTagEditor item={item} mutate={mutate} />
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

function GalleryTagEditor({ item, mutate }: { item: GalleryItem; mutate: PageMutate }) {
  const [value, setValue] = useState(item.category || "");

  useEffect(() => {
    setValue(item.category || "");
  }, [item.category]);

  const save = () => {
    const next = value.trim() || "기타";
    if (next !== item.category) {
      mutate<GalleryItem>("gallery_items", "update", { id: item.id, patch: { category: next } });
    }
  };

  return (
    <label className="gallery-tag-editor">
      <span>태그</span>
      <input
        list="gallery-tag-options"
        value={value}
        onChange={(event) => setValue(event.target.value)}
        onBlur={save}
        onKeyDown={(event) => {
          if (event.key === "Enter") {
            event.preventDefault();
            event.currentTarget.blur();
          }
        }}
      />
    </label>
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
        <div className="overflow-hidden rounded-lg border border-black/10 bg-[#dfeae7] shadow-inner">
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
      <div className="grid gap-3 md:grid-cols-[repeat(2,minmax(0,1fr))] 2xl:grid-cols-[repeat(3,minmax(0,1fr))]">
        {places.map((place) => (
          <article className="map-card card grid min-w-0 gap-2 overflow-hidden p-4" key={place.id}>
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
            <div className="food-card-head">
              <div className="min-w-0"><p className="text-xs font-black text-sea">{place.category}</p><h3 className="food-card-title text-xl font-black">{place.name}</h3></div>
              <div className="food-card-actions">
                <button className="btn btn-secondary min-h-9 px-2" onClick={() => setEditingPlace({ ...editingPlace, [place.id]: { ...place } })} type="button" aria-label="수정"><Pencil size={16} /></button>
                <button className="btn btn-danger min-h-9 px-2" onClick={() => mutate<Place>("places", "delete", { id: place.id })} type="button" aria-label="삭제"><Trash2 size={16} /></button>
              </div>
            </div>
            <p className="text-sm font-semibold text-black/60">{displayPlaceText(place.address, "주소는 Google Maps에서 확인")}</p>
            <p className="text-sm font-semibold text-black/60">{place.hours} · {place.reservation_note}</p>
            {place.sensitive_note ? <p className="soft-inset rounded-lg p-3 text-sm font-bold text-black/65">{place.sensitive_note}</p> : null}
            <a className="btn btn-secondary min-h-10" href={place.map_url || googleMapsSearchUrl(place.name, displayPlaceText(place.address, ""))} target="_blank" rel="noreferrer">Google Maps<ExternalLink size={16} /></a>
            <details className="soft-inset rounded-lg p-3 text-sm font-bold"><summary>주소/지도 메모 보기</summary><p className="mt-2 text-black/60">{displayPlaceText(place.address, "주소 입력 전")}</p></details>
            <div className="soft-inset grid gap-2 rounded-lg p-2">
              <div className="food-plan-grid grid gap-2">
                <select className="field min-h-10 px-2 text-sm" value={placePlans[place.id]?.date || dates[0]} onChange={(event) => setPlacePlans({ ...placePlans, [place.id]: { ...(placePlans[place.id] || { date: dates[0], start_time: "", end_time: "" }), date: event.target.value } })}>
                  {dates.map((item) => <option key={item} value={item}>{compactDateLabel(item)}</option>)}
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
          <div className="grid gap-2 md:grid-cols-[repeat(2,minmax(0,1fr))] xl:grid-cols-[repeat(3,minmax(0,1fr))]">
            {(categoryFoods || []).map((food) => (
              <article className="map-card card grid min-w-0 gap-2 overflow-hidden p-3" key={food.id}>
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
                <div className="food-card-head">
                  <div className="min-w-0"><p className="text-xs font-black text-coral">{food.category}</p><h3 className="food-card-title text-lg font-black">{food.name}</h3></div>
                  <div className="food-card-actions">
                    <button className={`btn min-h-8 px-2 ${food.is_favorite ? "bg-sun text-ink" : "btn-secondary"}`} onClick={() => mutate<FoodCandidate>("food_candidates", "update", { id: food.id, patch: { is_favorite: !food.is_favorite } })} type="button" aria-label="별표"><Star size={15} fill={food.is_favorite ? "currentColor" : "none"} /></button>
                    <button className="btn btn-secondary min-h-8 px-2" onClick={() => setEditingFood({ ...editingFood, [food.id]: { ...food } })} type="button" aria-label="수정"><Pencil size={15} /></button>
                    <button className="btn btn-danger min-h-8 px-2" onClick={() => mutate<FoodCandidate>("food_candidates", "delete", { id: food.id })} type="button" aria-label="삭제"><Trash2 size={15} /></button>
                  </div>
                </div>
                <p className="text-xs font-semibold text-black/60">{displayPlaceText(food.location, "지도 링크 확인")} · {food.reservation || "예약 확인"}</p>
                <p className="text-xs font-semibold text-black/60">{food.wait_note || "웨이팅 확인"} · 추천 {food.recommender || "다 같이"}</p>
                {food.note ? <p className="line-clamp-2 text-sm font-bold">{food.note}</p> : null}
                <div className="food-action-grid">
                  <a className="btn btn-secondary min-h-9" href={food.map_url || googleMapsSearchUrl(food.name, displayPlaceText(food.location, ""))} target="_blank" rel="noreferrer">지도<ExternalLink size={15} /></a>
                  <details className="soft-inset min-w-0 overflow-hidden rounded-lg">
                    <summary className="grid min-h-9 cursor-pointer place-items-center px-2 text-sm font-black">일정에 넣기</summary>
                    <div className="grid gap-2 p-2">
                  <div className="food-plan-grid grid gap-2">
                    <select
                      className="field min-h-10 px-2 text-sm"
                      value={(plans[food.id]?.date) || tripDates[0]}
                      onChange={(event) => setPlans({ ...plans, [food.id]: { ...(plans[food.id] || { date: tripDates[0], start_time: "", end_time: "" }), date: event.target.value } })}
                    >
                      {tripDates.map((date) => <option value={date} key={date}>{compactDateLabel(date)}</option>)}
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
  const [budgetDraft, setBudgetDraft] = useState({ amount: String(trip.budget_amount || ""), currency: trip.budget_currency || "JPY" });
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
          <form className="mt-3 grid gap-2 md:grid-cols-[1fr_0.45fr_auto]" onSubmit={(event) => {
            event.preventDefault();
            mutate<Trip>("trips", "update", { id: trip.id, patch: { budget_amount: Number(budgetDraft.amount || 0), budget_currency: budgetDraft.currency || "JPY" } });
          }}>
            <label className="setup-field">
              <span>여행 예산</span>
              <input className="field" inputMode="numeric" placeholder="예: 150000" value={budgetDraft.amount} onChange={(event) => setBudgetDraft({ ...budgetDraft, amount: event.target.value })} />
            </label>
            <label className="setup-field">
              <span>통화</span>
              <input className="field" placeholder="JPY" value={budgetDraft.currency} onChange={(event) => setBudgetDraft({ ...budgetDraft, currency: event.target.value.toUpperCase() })} />
            </label>
            <button className="btn self-end" type="submit">예산 저장</button>
          </form>
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
          <div className="soft-inset md:col-span-5 grid gap-2 rounded-lg p-3">
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

function SettingsView({
  data,
  trip,
  selectedTripId,
  setSelectedTripId,
  mode,
  theme,
  setTheme,
  mutate
}: {
  data: TripData;
  trip: TripData["trips"][number];
  selectedTripId: string;
  setSelectedTripId: (id: string) => void;
  mode: string;
  theme: AppTheme;
  setTheme: (theme: AppTheme) => void;
  mutate: PageMutate;
}) {
  const scoped = tripScopedData(data, trip.id);
  const activeTrips = data.trips.filter((item) => !item.archived);
  const archivedTrips = data.trips.filter((item) => item.archived);
  const initialCountry = countryOptions.includes(trip.country || "") ? trip.country || "일본" : "기타";
  const [setup, setSetup] = useState({
    name: trip.name || "",
    country: initialCountry,
    customCountry: initialCountry === "기타" ? trip.country || "" : "",
    cityPreset: (trip.cities?.[0] || "타카마쓰"),
    customCity: "",
    cities: (trip.cities || trip.region.split("·").map((city) => city.trim()).filter(Boolean)).join(", "),
    start_date: trip.start_date,
    end_date: trip.end_date,
    outbound_origin: trip.outbound_origin || "",
    outbound_destination: trip.outbound_destination || "",
    outbound_flight: trip.outbound_flight || "",
    outbound_departure_time: trip.outbound_departure_time || "",
    outbound_arrival_time: trip.outbound_arrival_time || "",
    return_origin: trip.return_origin || "",
    return_destination: trip.return_destination || "",
    return_flight: trip.return_flight || "",
    return_departure_time: trip.return_departure_time || "",
    return_arrival_time: trip.return_arrival_time || "",
    accommodation: trip.accommodation || "",
    my_maps_url: trip.my_maps_url || data.quick_links.find((link) => link.kind === "map")?.url || ""
  });
  const [memberDraft, setMemberDraft] = useState({ name: "", role: "", color: "#16a3a3", avatar_url: "" });
  const [memberEdit, setMemberEdit] = useState<Record<string, Partial<TripMember>>>({});
  useEffect(() => {
    const nextCountry = countryOptions.includes(trip.country || "") ? trip.country || "일본" : "기타";
    setSetup({
      name: trip.name || "",
      country: nextCountry,
      customCountry: nextCountry === "기타" ? trip.country || "" : "",
      cityPreset: (trip.cities?.[0] || "타카마쓰"),
      customCity: "",
      cities: (trip.cities || trip.region.split("·").map((city) => city.trim()).filter(Boolean)).join(", "),
      start_date: trip.start_date,
      end_date: trip.end_date,
      outbound_origin: trip.outbound_origin || "",
      outbound_destination: trip.outbound_destination || "",
      outbound_flight: trip.outbound_flight || "",
      outbound_departure_time: trip.outbound_departure_time || "",
      outbound_arrival_time: trip.outbound_arrival_time || "",
      return_origin: trip.return_origin || "",
      return_destination: trip.return_destination || "",
      return_flight: trip.return_flight || "",
      return_departure_time: trip.return_departure_time || "",
      return_arrival_time: trip.return_arrival_time || "",
      accommodation: trip.accommodation || "",
      my_maps_url: trip.my_maps_url || scoped.quick_links.find((link) => link.kind === "map")?.url || ""
    });
  }, [trip.id]);
  const setupCityOptions = cityPresetsByCountry[setup.country] || cityPresetsByCountry["기타"];
  const resolvedCity = setup.cityPreset === "기타" ? setup.customCity : setup.cityPreset;
  const resolvedCountry = setup.country === "기타" ? setup.customCountry : setup.country;
  const changeSetupCountry = (value: string) => {
    const nextCityOptions = cityPresetsByCountry[value] || cityPresetsByCountry["기타"];
    setSetup({
      ...setup,
      country: value,
      cityPreset: nextCityOptions.includes(setup.cityPreset) ? setup.cityPreset : nextCityOptions[0] || "기타",
      customCity: value === "기타" ? setup.customCity : ""
    });
  };
  const inviteUrl = typeof window !== "undefined" ? window.location.origin : "https://project-6ok16.vercel.app";
  const readProfileImage = (file: File | undefined, callback: (value: string) => void) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => callback(String(reader.result || ""));
    reader.readAsDataURL(file);
  };
  const saveSetup = (event: FormEvent) => {
    event.preventDefault();
    const cities = Array.from(new Set([resolvedCity, ...setup.cities.split(",").map((city) => city.trim()).filter(Boolean)].filter(Boolean)));
    mutate<Trip>("trips", "update", {
      id: trip.id,
      patch: {
        name: setup.name || trip.name,
        country: resolvedCountry || setup.country,
        cities,
        region: cities.join(" · "),
        start_date: setup.start_date || trip.start_date,
        end_date: setup.end_date || setup.start_date || trip.end_date,
        outbound_origin: setup.outbound_origin,
        outbound_destination: setup.outbound_destination || resolvedCity,
        outbound_flight: setup.outbound_flight,
        outbound_departure_time: setup.outbound_departure_time || undefined,
        outbound_arrival_time: setup.outbound_arrival_time || undefined,
        return_origin: setup.return_origin || resolvedCity,
        return_destination: setup.return_destination,
        return_flight: setup.return_flight,
        return_departure_time: setup.return_departure_time || undefined,
        return_arrival_time: setup.return_arrival_time || undefined,
        accommodation: setup.accommodation,
        my_maps_url: setup.my_maps_url
      }
    });
  };
  const archiveTrip = async (target: Trip, archived: boolean) => {
    await mutate<Trip>("trips", "update", { id: target.id, patch: { archived } });
    if (target.id === selectedTripId && archived) {
      const next = data.trips.find((item) => item.id !== target.id && !item.archived);
      if (next) setSelectedTripId(next.id);
    } else {
      setSelectedTripId(target.id);
    }
  };
  return (
    <section className="grid gap-4">
      <Panel title="여행 관리">
        <div className="trip-manage-grid">
          {[...activeTrips, ...archivedTrips].map((item) => {
            const isSelected = item.id === selectedTripId;
            const isLastActive = !item.archived && activeTrips.length <= 1;
            return (
              <article className={`trip-manage-card ${isSelected ? "is-selected" : ""}`} key={item.id}>
                <div className="min-w-0">
                  <p className="text-xs font-black uppercase text-sea">{item.archived ? "Archived trip" : "Active trip"}</p>
                  <h3 className="truncate text-lg font-black">{item.name}</h3>
                  <p className="text-sm font-bold text-black/45">{dateLabel(item.start_date)} - {dateLabel(item.end_date)}</p>
                </div>
                <div className="flex shrink-0 flex-wrap justify-end gap-2">
                  <button className="btn btn-secondary min-h-9" type="button" onClick={() => setSelectedTripId(item.id)}>열기</button>
                  {item.archived ? (
                    <button className="btn min-h-9" type="button" onClick={() => archiveTrip(item, false)}>복원</button>
                  ) : (
                    <button className="btn btn-secondary min-h-9" disabled={isLastActive} title={isLastActive ? "활성 여행은 최소 1개 필요합니다." : undefined} type="button" onClick={() => archiveTrip(item, true)}>아카이브</button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
        <p className="text-sm font-bold text-black/50">아카이브한 여행은 목록에서 숨기고, 필요하면 여기서 다시 복원할 수 있습니다. 최소 1개의 활성 여행은 남겨둡니다.</p>
      </Panel>
      <Panel title="여행 설정">
        <form className="grid gap-4" onSubmit={saveSetup}>
          <div className="setup-group">
            <h3>기본 정보</h3>
            <div className="grid gap-2 md:grid-cols-2">
              <label className="setup-field md:col-span-2"><span>여행 제목</span><input className="field" value={setup.name} onChange={(event) => setSetup({ ...setup, name: event.target.value })} placeholder="예: 타카마쓰 가족여행" /></label>
              <label className="setup-field"><span>국가</span><select className="field" value={setup.country} onChange={(event) => changeSetupCountry(event.target.value)}>{countryOptions.map((country) => <option key={country}>{country}</option>)}</select></label>
              {setup.country === "기타" ? <label className="setup-field"><span>국가 직접 입력</span><input className="field" value={setup.customCountry} onChange={(event) => setSetup({ ...setup, customCountry: event.target.value })} placeholder="예: 뉴질랜드" /></label> : null}
              <label className="setup-field"><span>첫 도시</span><select className="field" value={setupCityOptions.includes(setup.cityPreset) ? setup.cityPreset : "기타"} onChange={(event) => setSetup({ ...setup, cityPreset: event.target.value })}>{setupCityOptions.map((city) => <option key={city}>{city}</option>)}</select></label>
              {setup.cityPreset === "기타" ? <label className="setup-field"><span>도시 직접 입력</span><input className="field" value={setup.customCity} onChange={(event) => setSetup({ ...setup, customCity: event.target.value })} required /></label> : null}
              <label className="setup-field"><span>여행 도시 목록</span><input className="field" value={setup.cities} onChange={(event) => setSetup({ ...setup, cities: event.target.value })} placeholder="예: 타카마쓰, 도쿄" /></label>
              <label className="setup-field"><span>시작일</span><input className="field" type="date" value={setup.start_date} onChange={(event) => setSetup({ ...setup, start_date: event.target.value })} /></label>
              <label className="setup-field"><span>종료일</span><input className="field" type="date" value={setup.end_date} onChange={(event) => setSetup({ ...setup, end_date: event.target.value })} /></label>
            </div>
          </div>
          <div className="setup-group">
            <div className="flex flex-wrap items-end justify-between gap-2">
              <h3>비행 정보</h3>
              <p className="max-w-xl text-xs font-bold text-black/45">편명 자동조회는 FlightAware, Aviationstack, Amadeus 같은 항공 API 연결이 필요합니다. 지금은 편명과 시간을 직접 저장합니다.</p>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <div className="setup-flight-card">
                <p>가는 편</p>
                <label className="setup-field"><span>편명</span><input className="field" value={setup.outbound_flight} onChange={(event) => setSetup({ ...setup, outbound_flight: event.target.value.toUpperCase() })} placeholder="RS0741" /></label>
                <div className="grid gap-2 md:grid-cols-2">
                  <label className="setup-field"><span>출발지</span><input className="field" value={setup.outbound_origin} onChange={(event) => setSetup({ ...setup, outbound_origin: event.target.value })} /></label>
                  <label className="setup-field"><span>도착지</span><input className="field" value={setup.outbound_destination} onChange={(event) => setSetup({ ...setup, outbound_destination: event.target.value })} /></label>
                  <label className="setup-field"><span>출발시간</span><input className="field" type="time" value={setup.outbound_departure_time} onChange={(event) => setSetup({ ...setup, outbound_departure_time: event.target.value })} /></label>
                  <label className="setup-field"><span>도착시간</span><input className="field" type="time" value={setup.outbound_arrival_time} onChange={(event) => setSetup({ ...setup, outbound_arrival_time: event.target.value })} /></label>
                </div>
              </div>
              <div className="setup-flight-card">
                <p>오는 편</p>
                <label className="setup-field"><span>편명</span><input className="field" value={setup.return_flight} onChange={(event) => setSetup({ ...setup, return_flight: event.target.value.toUpperCase() })} placeholder="RS0742" /></label>
                <div className="grid gap-2 md:grid-cols-2">
                  <label className="setup-field"><span>출발지</span><input className="field" value={setup.return_origin} onChange={(event) => setSetup({ ...setup, return_origin: event.target.value })} /></label>
                  <label className="setup-field"><span>도착지</span><input className="field" value={setup.return_destination} onChange={(event) => setSetup({ ...setup, return_destination: event.target.value })} /></label>
                  <label className="setup-field"><span>출발시간</span><input className="field" type="time" value={setup.return_departure_time} onChange={(event) => setSetup({ ...setup, return_departure_time: event.target.value })} /></label>
                  <label className="setup-field"><span>도착시간</span><input className="field" type="time" value={setup.return_arrival_time} onChange={(event) => setSetup({ ...setup, return_arrival_time: event.target.value })} /></label>
                </div>
              </div>
            </div>
          </div>
          <div className="setup-group">
            <h3>숙소와 지도</h3>
            <div className="grid gap-2 md:grid-cols-2">
              <label className="setup-field"><span>숙소 / 체크인 기준 메모</span><input className="field" value={setup.accommodation} onChange={(event) => setSetup({ ...setup, accommodation: event.target.value })} /></label>
              <label className="setup-field"><span>Google My Maps 공유 링크</span><input className="field" value={setup.my_maps_url} onChange={(event) => setSetup({ ...setup, my_maps_url: event.target.value })} /></label>
            </div>
          </div>
          <button className="btn md:w-fit" type="submit">여행 설정 저장</button>
        </form>
      </Panel>
      <Panel title="친구 초대">
        <div className="grid gap-3">
          <div className="grid gap-2 md:grid-cols-[1fr_auto]">
            <div className="rounded-lg bg-white p-3">
            <p className="text-xs font-black text-sea">공유 링크</p>
            <p className="break-all text-sm font-bold">{inviteUrl}</p>
            <p className="mt-1 text-xs font-bold text-black/45">링크를 보내고 가족코드는 별도로 알려주면 됩니다. 아래에서 가족 이름과 프로필 사진을 등록할 수 있습니다.</p>
            </div>
            <button className="btn" type="button" onClick={() => navigator.clipboard?.writeText(inviteUrl)}>링크 복사</button>
          </div>
          <form className="setup-member-form" onSubmit={(event) => {
            event.preventDefault();
            if (!memberDraft.name.trim()) return;
            mutate<TripMember>("trip_members", "create", { row: { id: makeId("member"), trip_id: trip.id, name: memberDraft.name.trim(), role: memberDraft.role, color: memberDraft.color, avatar_url: memberDraft.avatar_url } });
            setMemberDraft({ name: "", role: "", color: "#16a3a3", avatar_url: "" });
          }}>
            <label className="setup-field"><span>이름</span><input className="field" value={memberDraft.name} onChange={(event) => setMemberDraft({ ...memberDraft, name: event.target.value })} placeholder="예: 민지" /></label>
            <label className="setup-field"><span>역할 / 메모</span><input className="field" value={memberDraft.role} onChange={(event) => setMemberDraft({ ...memberDraft, role: event.target.value })} placeholder="예: 맛집 담당" /></label>
            <label className="setup-field"><span>색상</span><input className="field h-[2.65rem] p-1" type="color" value={memberDraft.color} onChange={(event) => setMemberDraft({ ...memberDraft, color: event.target.value })} /></label>
            <label className="setup-field"><span>프로필 사진</span><input className="field" type="file" accept="image/*" onChange={(event) => readProfileImage(event.target.files?.[0], (avatar_url) => setMemberDraft({ ...memberDraft, avatar_url }))} /></label>
            <button className="btn self-end" type="submit"><Plus size={16} />멤버 추가</button>
          </form>
          <div className="grid gap-2 md:grid-cols-2">
            {scoped.trip_members.map((member) => {
              const patch = memberEdit[member.id] || {};
              const avatar = patch.avatar_url ?? member.avatar_url;
              return (
                <div className="member-card" key={member.id}>
                  <div className="member-avatar" style={{ backgroundColor: patch.color || member.color }}>
                    {avatar ? <img alt="" src={avatar} /> : <span>{(patch.name || member.name).slice(0, 1)}</span>}
                  </div>
                  <div className="grid min-w-0 flex-1 gap-2">
                    <div className="grid gap-2 md:grid-cols-2">
                      <input className="field" value={patch.name ?? member.name} onChange={(event) => setMemberEdit({ ...memberEdit, [member.id]: { ...patch, name: event.target.value } })} aria-label={`${member.name} 이름`} />
                      <input className="field" value={patch.role ?? member.role} onChange={(event) => setMemberEdit({ ...memberEdit, [member.id]: { ...patch, role: event.target.value } })} aria-label={`${member.name} 역할`} />
                      <input className="field h-[2.65rem] p-1" type="color" value={patch.color ?? member.color} onChange={(event) => setMemberEdit({ ...memberEdit, [member.id]: { ...patch, color: event.target.value } })} aria-label={`${member.name} 색상`} />
                      <input className="field" type="file" accept="image/*" onChange={(event) => readProfileImage(event.target.files?.[0], (avatar_url) => setMemberEdit({ ...memberEdit, [member.id]: { ...patch, avatar_url } }))} aria-label={`${member.name} 프로필 사진`} />
                    </div>
                    <div className="flex gap-2">
                      <button className="btn min-h-9" type="button" onClick={() => {
                        mutate<TripMember>("trip_members", "update", { id: member.id, patch: memberEdit[member.id] || {} });
                        const next = { ...memberEdit };
                        delete next[member.id];
                        setMemberEdit(next);
                      }}>저장</button>
                      <button className="btn btn-danger min-h-9" type="button" onClick={() => mutate<TripMember>("trip_members", "delete", { id: member.id })}>삭제</button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </Panel>
      <Panel title="색상 테마">
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {appThemes.map((item) => (
            <button
              aria-pressed={theme === item.key}
              className="theme-card"
              data-theme-key={item.key}
              key={item.key}
              onClick={() => setTheme(item.key)}
              style={{
                "--theme-card-primary": item.swatches[0],
                "--theme-card-secondary": item.swatches[1],
                "--theme-card-soft": item.swatches[2],
                "--theme-card-highlight": item.swatches[3]
              } as CSSProperties}
              type="button"
            >
              <span className="theme-swatch-row" aria-hidden="true">
                {item.swatches.map((color) => <span key={color} style={{ backgroundColor: color }} />)}
              </span>
              <span className="theme-card-title">{item.name}</span>
              <span className="theme-card-body">{item.description}</span>
            </button>
          ))}
        </div>
        <p className="text-sm font-bold text-black/50">선택한 테마는 이 브라우저에 저장되고, 랜딩 화면과 앱 화면에 같이 적용됩니다.</p>
      </Panel>
      <Panel title="앱 설정">
        <div className="grid gap-3 md:grid-cols-2">
          <div className="card p-4"><p className="text-sm font-black text-sea">저장 모드</p><p className="text-xl font-black">{mode === "supabase" ? "Supabase 연결됨" : "데모 데이터"}</p><p className="mt-2 text-sm font-semibold text-black/55">Supabase 환경변수를 넣으면 서버 API가 클라우드 DB에 저장합니다.</p></div>
          <div className="card p-4"><p className="text-sm font-black text-sea">가족코드</p><p className="text-xl font-black">서버 환경변수</p><p className="mt-2 text-sm font-semibold text-black/55">`FAMILY_CODE`와 `SESSION_SECRET`을 배포 환경에 설정하세요.</p></div>
        </div>
      </Panel>
      <Panel title="데이터 현황">
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
          <Metric title="일정" value={`${scoped.itinerary_items.length}개`} icon={CalendarDays} />
          <Metric title="장소" value={`${scoped.places.length}개`} icon={MapPin} />
          <Metric title="식당" value={`${scoped.food_candidates.length}개`} icon={Soup} />
          <Metric title="체크" value={`${scoped.checklist_items.length}개`} icon={ListTodo} />
        </div>
      </Panel>
    </section>
  );
}

function Panel({ title, children, action, titleClassName = "" }: { title: string; children: ReactNode; action?: ReactNode; titleClassName?: string }) {
  return (
    <section className="panel-section rounded-lg p-4 md:p-5">
      <div className="mb-3 flex items-center justify-between gap-3">
        <h2 className={`panel-heading font-black ${titleClassName}`}>{title}</h2>
        {action}
      </div>
      <div className="grid gap-3">{children}</div>
    </section>
  );
}

function Metric({ title, value, icon: Icon, roomy = false }: { title: string; value: string; icon: ComponentType<{ size?: number; className?: string }>; roomy?: boolean }) {
  return (
    <article className={`metric-card card flex items-center gap-3 p-4 ${roomy ? "md:col-span-2" : ""}`}>
      <div className="metric-icon grid h-10 w-10 shrink-0 place-items-center rounded-lg"><Icon size={20} /></div>
      <div className="min-w-0"><p className="text-xs font-black uppercase text-black/42">{title}</p><p className={`${roomy ? "text-sm leading-snug md:text-base" : "text-lg"} break-words font-black`}>{value}</p></div>
    </article>
  );
}

function Empty({ text }: { text: string }) {
  return <div className="soft-inset rounded-lg p-5 text-center text-sm font-bold text-black/45">{text}</div>;
}
