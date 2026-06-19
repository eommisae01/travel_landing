const CONFIG = {
  tripStartDate: "2026-06-22",
  tripEndDate: "2026-06-24",
  tripDays: {
    monday: "2026-06-22",
    tuesday: "2026-06-23",
    wednesday: "2026-06-24"
  },
  myMapsEmbedUrl: "about:blank", // 여기에 Google My Maps iframe src를 붙여넣기
  calendarEmbedUrl: "about:blank",
  links: {
    myMaps: "#",
    calendar: "#",
    googleMaps: "https://www.google.com/maps",
    weather: "https://weather.com/",
    ferry: "#",
    flight: "#",
    hotel: "#",
    museum: "#"
  }
};

const CHECKLIST = {
  common: {
    label: "공통",
    items: ["여권", "항공권 확인", "호텔 예약 확인", "eSIM / 로밍", "신용카드", "현금 / 엔화", "우산", "보조배터리", "미술관 예약 확인", "페리 시간 확인"]
  },
  me: {
    label: "나",
    items: ["지도 관리", "일정 확인", "예약 확인", "가족 공유 링크 확인"]
  },
  dad: {
    label: "승환",
    items: ["상비약", "편한 신발", "얇은 겉옷", "여권 확인"]
  },
  sibling: {
    label: "민지",
    items: ["충전기", "보조배터리", "개인 준비물", "여권 확인"]
  }
};

const STORAGE_KEYS = {
  checklist: "takamatsu-family-checklist-v1",
  expenses: "takamatsu-family-expenses-v1",
  foods: "takamatsu-family-foods-v1",
  scheduleBlocks: "takamatsu-family-schedule-blocks-v1",
  scheduleBoard: "takamatsu-family-schedule-board-v1",
  checklistData: "takamatsu-family-checklist-data-v2",
  editableText: "takamatsu-family-editable-text-v1",
  settings: "takamatsu-family-settings-v1"
};

const TRIP_MEMBERS = ["나", "승환", "민지"];
const BUDGET_CATEGORIES = ["총지출", "식비", "교통비", "숙박비", "쇼핑", "간식비", "관광비", "기타"];
const TAKAMATSU_WEATHER_URL = "https://api.open-meteo.com/v1/forecast?latitude=34.3428&longitude=134.0466&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&current=temperature_2m,weather_code,wind_speed_10m&timezone=Asia%2FTokyo";
const DAY_CAUTIONS = {
  monday: ["호텔 짐 맡기기 가능 여부 확인", "리쓰린 공원 마지막 입장 시간 확인", "첫날은 저녁을 가볍게"],
  tuesday: ["페리 운항/강풍 여부 확인", "지중미술관 예약 시간 확인", "복귀 페리 시간을 먼저 고정"],
  wednesday: ["11시 비행기 기준 공항 이동 우선", "아침 식사는 짧게", "체크아웃/짐 확인"]
};
const TAG_STORAGE_KEY = "takamatsu-family-schedule-tags-v1";
const PRIORITY_OPTIONS = [
  { label: "필수", className: "must" },
  { label: "가능하면", className: "optional" },
  { label: "날씨 좋으면", className: "weather" },
  { label: "체력 남으면", className: "energy" }
];
const STATUS_OPTIONS = [
  { label: "예약 필요", className: "need" },
  { label: "예약 완료", className: "done" },
  { label: "현장 결제", className: "onsite" },
  { label: "확인 필요", className: "check" },
  { label: "해당 없음", className: "none" }
];

const DEFAULT_FOODS = [
  {
    id: "food-udon-1",
    name: "우동 후보 1",
    category: "우동",
    location: "타카마쓰 시내",
    map: "#",
    reservation: "예약 불필요",
    wait: "점심 대기 가능",
    cardPay: "확인 필요",
    owner: "다 같이",
    note: "첫날 또는 마지막 날 가볍게"
  },
  {
    id: "food-izakaya-1",
    name: "이자카야 후보 1",
    category: "이자카야",
    location: "호텔 근처",
    map: "#",
    reservation: "가능하면 예약",
    wait: "저녁 대기 가능",
    cardPay: "확인 필요",
    owner: "다 같이",
    note: "너무 시끄럽지 않은 곳 우선"
  },
  {
    id: "food-cafe-1",
    name: "비 오는 날 카페 후보",
    category: "카페",
    location: "역/상점가 근처",
    map: "#",
    reservation: "해당 없음",
    wait: "보통",
    cardPay: "확인 필요",
    owner: "다 같이",
    note: "폭우나 강풍일 때 쉬어가기"
  }
];

const quickLinkLabels = [
  ["myMaps", "공유 지도 열기"],
  ["calendar", "Google Calendar 열기"],
  ["weather", "날씨 확인"],
  ["ferry", "페리 시간 확인"],
  ["flight", "항공권 확인"],
  ["hotel", "호텔 예약 확인"],
  ["museum", "미술관 예약 확인"]
];

function getJson(key, fallback) {
  try {
    return JSON.parse(localStorage.getItem(key)) ?? fallback;
  } catch {
    return fallback;
  }
}

function setJson(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

function applySavedSettings() {
  const saved = getJson(STORAGE_KEYS.settings, null);
  if (!saved) return;
  if (saved.tripStartDate === "2026-06-15" && saved.tripEndDate === "2026-06-17") {
    localStorage.removeItem(STORAGE_KEYS.settings);
    return;
  }

  CONFIG.tripStartDate = saved.tripStartDate || CONFIG.tripStartDate;
  CONFIG.tripEndDate = saved.tripEndDate || CONFIG.tripEndDate;
  CONFIG.myMapsEmbedUrl = saved.myMapsEmbedUrl || CONFIG.myMapsEmbedUrl;
  CONFIG.calendarEmbedUrl = saved.calendarEmbedUrl || CONFIG.calendarEmbedUrl;
  CONFIG.tripDays = { ...CONFIG.tripDays, ...(saved.tripDays || {}) };
  CONFIG.links = { ...CONFIG.links, ...(saved.links || {}) };
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function formatDateRange() {
  const start = new Date(`${CONFIG.tripStartDate}T00:00:00`);
  const end = new Date(`${CONFIG.tripEndDate}T00:00:00`);
  const formatter = new Intl.DateTimeFormat("ko-KR", { month: "long", day: "numeric", weekday: "short" });
  document.querySelector("#trip-period").textContent = `${formatter.format(start)} - ${formatter.format(end)}`;
}

function setupScrollProgress() {
  const update = () => {
    const max = document.documentElement.scrollHeight - window.innerHeight;
    const progress = max > 0 ? window.scrollY / max : 0;
    document.documentElement.style.setProperty("--scroll-progress", progress.toFixed(4));
  };
  update();
  window.addEventListener("scroll", update, { passive: true });
  window.addEventListener("resize", update);
}

function setupRevealAnimation() {
  const sections = document.querySelectorAll(".section");
  if (!("IntersectionObserver" in window)) {
    sections.forEach((section) => section.classList.add("is-visible"));
    return;
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.08 });

  sections.forEach((section) => observer.observe(section));
}

function renderQuickLinks() {
  const container = document.querySelector("#quick-links");
  container.innerHTML = quickLinkLabels.map(([key, label]) => {
    const href = CONFIG.links[key] || "#";
    return `<a class="button secondary" href="${href}" target="_blank" rel="noreferrer">${label}</a>`;
  }).join("");

  document.querySelectorAll("[data-config-link]").forEach((link) => {
    const key = link.dataset.configLink;
    link.href = CONFIG.links[key] || "#";
  });

  const mapButton = document.querySelector("#open-my-maps");
  mapButton.href = CONFIG.links.myMaps || "#";

  const mapIframe = document.querySelector("#my-maps-iframe");
  mapIframe.src = CONFIG.myMapsEmbedUrl || "about:blank";

  const calendarButton = document.querySelector("#open-calendar");
  if (calendarButton) calendarButton.href = CONFIG.links.calendar || "#";
  const calendarIframe = document.querySelector("#calendar-iframe");
  if (calendarIframe) calendarIframe.src = CONFIG.calendarEmbedUrl || "about:blank";
}

function updateTodayFocus() {
  const todayKey = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).format(new Date());
  const isTripDay = Object.values(CONFIG.tripDays).includes(todayKey);
  const criteria = document.querySelector("#focus-criteria");
  if (!criteria) return;
  criteria.textContent = isTripDay
    ? "기준: 오늘 날짜와 연결된 필수 일정, 이동, 예약 확인"
    : "기준: 여행 전 준비 상태, 예약 필요 항목, 페리/날씨 리스크";
}

function setupScheduleTagSelects() {
  const saved = getJson(TAG_STORAGE_KEY, {});
  document.querySelectorAll(".schedule-item .badge, .schedule-item .status, .card-title-row .status").forEach((tag, index) => {
    const isPriority = tag.classList.contains("badge");
    const options = isPriority ? PRIORITY_OPTIONS : STATUS_OPTIONS;
    const key = `tag-${index}`;
    const current = saved[key] || tag.textContent.trim();
    const select = document.createElement("select");
    select.className = isPriority ? "tag-select priority-select" : "tag-select status-select";
    select.dataset.tagKey = key;
    select.setAttribute("aria-label", isPriority ? "우선순위 선택" : "예약/결제 상태 선택");
    select.innerHTML = options.map((option) => `<option value="${option.label}">${option.label}</option>`).join("");
    select.value = options.some((option) => option.label === current) ? current : options[0].label;
    const applyClass = () => {
      const selected = options.find((option) => option.label === select.value) || options[0];
      select.dataset.tone = selected.className;
    };
    applyClass();
    select.addEventListener("change", () => {
      const next = getJson(TAG_STORAGE_KEY, {});
      next[key] = select.value;
      setJson(TAG_STORAGE_KEY, next);
      applyClass();
    });
    tag.replaceWith(select);
  });
}

function weatherLabel(code) {
  if ([0, 1].includes(code)) return "맑음";
  if ([2, 3].includes(code)) return "구름 많음";
  if ([45, 48].includes(code)) return "안개";
  if ([51, 53, 55, 61, 63, 65, 80, 81, 82].includes(code)) return "비 가능";
  if ([71, 73, 75, 77, 85, 86].includes(code)) return "눈/진눈깨비";
  if ([95, 96, 99].includes(code)) return "뇌우 가능";
  return "날씨 확인";
}

function dayKeyForDate(dateString) {
  return Object.entries(CONFIG.tripDays).find(([, value]) => value === dateString)?.[0];
}

async function updateWeatherWidgets() {
  const brief = document.querySelector("#weather-brief");
  const focusList = document.querySelector("#focus-list");
  try {
    const response = await fetch(TAKAMATSU_WEATHER_URL);
    if (!response.ok) throw new Error("weather unavailable");
    const weather = await response.json();
    const today = new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Seoul", year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
    const tripIndex = weather.daily?.time?.findIndex((date) => Object.values(CONFIG.tripDays).includes(date));
    const todayTripIndex = weather.daily?.time?.findIndex((date) => date === today);
    const current = weather.current;
    const base = current
      ? `타카마쓰 현재 ${Math.round(current.temperature_2m)}°C · ${weatherLabel(current.weather_code)} · 바람 ${Math.round(current.wind_speed_10m)}km/h`
      : "타카마쓰 날씨 확인 중";
    const firstTripForecast = tripIndex >= 0
      ? `여행 첫날 예상 ${weatherLabel(weather.daily.weather_code[tripIndex])}, 강수확률 ${weather.daily.precipitation_probability_max[tripIndex]}%, 최대풍속 ${Math.round(weather.daily.wind_speed_10m_max[tripIndex])}km/h`
      : "여행일 예보는 가까워지면 자동 표시";
    brief.textContent = `${base}. ${firstTripForecast}. 수요일은 11시 비행기로 공항 이동 중심.`;

    const activeIndex = todayTripIndex >= 0 ? todayTripIndex : -1;
    const activeDate = activeIndex >= 0 ? weather.daily.time[activeIndex] : null;
    const activeDay = activeDate ? dayKeyForDate(activeDate) : null;
    if (!activeDay) {
      focusList.innerHTML = "<li>6월 22일 여행 시작일부터 자동 표시</li>";
      return;
    }
    const dayWeather = `${weatherLabel(weather.daily.weather_code[activeIndex])} · 강수확률 ${weather.daily.precipitation_probability_max[activeIndex]}% · 최대풍속 ${Math.round(weather.daily.wind_speed_10m_max[activeIndex])}km/h`;
    focusList.innerHTML = [`오늘 날씨: ${dayWeather}`, ...(DAY_CAUTIONS[activeDay] || [])].slice(0, 4).map((item) => `<li>${escapeHtml(item)}</li>`).join("");
  } catch {
    brief.textContent = "날씨 자동 확인이 잠시 어려워요. 빠른 링크의 날씨 확인 버튼으로 타카마쓰 예보를 확인하세요.";
    focusList.innerHTML = "<li>6월 22일 여행 시작일부터 자동 표시</li>";
  }
}

function getFoods() {
  return getJson(STORAGE_KEYS.foods, DEFAULT_FOODS);
}

function saveFoods(foods) {
  setJson(STORAGE_KEYS.foods, foods);
}

function renderFoodList() {
  const foods = getFoods();
  const container = document.querySelector("#food-list");
  container.innerHTML = foods.map((food) => `
    <article class="food-card" draggable="true" data-food-id="${escapeHtml(food.id)}">
      <div class="card-title-row">
        <div>
          <p class="eyebrow">${escapeHtml(food.category)}</p>
          <h3>${escapeHtml(food.name)}</h3>
        </div>
        <button class="button ghost delete-food" type="button" data-delete-food="${escapeHtml(food.id)}">삭제</button>
      </div>
      <p>${escapeHtml(food.location || "위치 미정")} · 예약: ${escapeHtml(food.reservation || "확인 필요")} · 웨이팅: ${escapeHtml(food.wait || "확인 필요")}</p>
      <p>카드: ${escapeHtml(food.cardPay || "확인 필요")} · 추천: ${escapeHtml(food.owner || "다 같이")}</p>
      <p>${escapeHtml(food.note || "메모 없음")}</p>
      <div class="button-row">
        <a class="button secondary" href="${escapeHtml(food.map || "#")}" target="_blank" rel="noreferrer">지도 열기</a>
        <span class="drag-hint">시간대별 계획표에도 표시</span>
      </div>
    </article>
  `).join("");
}

function getScheduleBlocks() {
  const customBlocks = getJson(STORAGE_KEYS.scheduleBlocks, [
    { id: "place-hotel", type: "위치", title: "호텔", detail: "체크인 / 짐 맡기기" },
    { id: "place-port", type: "위치", title: "타카마쓰항", detail: "페리 시간 확인" },
    { id: "move-ferry", type: "이동", title: "페리 이동", detail: "타카마쓰 ↔ 나오시마" },
    { id: "move-airport", type: "이동", title: "공항 이동", detail: "수요일 11시 비행기 기준" }
  ]);
  const foodBlocks = getFoods().map((food) => ({
    id: food.id,
    type: "식당",
    title: food.name,
    detail: `${food.category} · ${food.location || "위치 미정"}`
  }));
  return [...customBlocks, ...foodBlocks];
}

function getScheduleBoard() {
  return getJson(STORAGE_KEYS.scheduleBoard, {
    "monday-morning": [],
    "monday-afternoon": [],
    "monday-evening": [],
    "tuesday-morning": [],
    "tuesday-afternoon": [],
    "tuesday-evening": [],
    "wednesday-morning": []
  });
}

function renderScheduleBlockPalette() {
  const container = document.querySelector("#schedule-block-list");
  if (!container) return;
  container.innerHTML = getScheduleBlocks().map((block) => `
    <article class="schedule-block" draggable="true" data-block-id="${escapeHtml(block.id)}">
      <span>${escapeHtml(block.type)}</span>
      <strong>${escapeHtml(block.title)}</strong>
      <small>${escapeHtml(block.detail || "")}</small>
    </article>
  `).join("");
}

function renderScheduleBoard() {
  const blocks = getScheduleBlocks();
  const board = getScheduleBoard();
  document.querySelectorAll("[data-schedule-slot]").forEach((slot) => {
    const slotKey = slot.dataset.scheduleSlot;
    const timeLabel = slot.querySelector("time")?.outerHTML || "";
    const assigned = board[slotKey] || [];
    const cards = assigned.map((blockId) => {
      const block = blocks.find((item) => item.id === blockId);
      if (!block) return "";
      return `
        <article class="calendar-item">
          <span>${escapeHtml(block.type)}</span>
          <strong>${escapeHtml(block.title)}</strong>
          <small>${escapeHtml(block.detail || "")}</small>
          <button type="button" data-remove-slot="${slotKey}" data-remove-block="${escapeHtml(block.id)}">빼기</button>
        </article>
      `;
    }).join("");
    slot.innerHTML = `${timeLabel}<div class="slot-items">${cards || '<p class="empty-drop">블록을 여기에 놓기</p>'}</div>`;
  });
}

function setupSchedulePlanner() {
  const list = document.querySelector("#schedule-block-list");
  const board = document.querySelector("#schedule-board");
  const form = document.querySelector("#block-form");
  if (!list || !board || !form) return;

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const blocks = getJson(STORAGE_KEYS.scheduleBlocks, []);
    blocks.unshift({
      id: `block-${Date.now()}`,
      type: document.querySelector("#block-type").value,
      title: document.querySelector("#block-title").value.trim(),
      detail: document.querySelector("#block-detail").value.trim()
    });
    setJson(STORAGE_KEYS.scheduleBlocks, blocks);
    event.target.reset();
    renderScheduleBlockPalette();
  });

  list.addEventListener("dragstart", (event) => {
    const block = event.target.closest("[data-block-id]");
    if (!block) return;
    event.dataTransfer.setData("text/plain", block.dataset.blockId);
    event.dataTransfer.effectAllowed = "copy";
  });

  board.addEventListener("dragover", (event) => {
    if (!event.target.closest("[data-schedule-slot]")) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
  });

  board.addEventListener("drop", (event) => {
    const slot = event.target.closest("[data-schedule-slot]");
    if (!slot) return;
    event.preventDefault();
    const blockId = event.dataTransfer.getData("text/plain");
    const slotKey = slot.dataset.scheduleSlot;
    const boardData = getScheduleBoard();
    boardData[slotKey] ||= [];
    if (!boardData[slotKey].includes(blockId)) boardData[slotKey].push(blockId);
    setJson(STORAGE_KEYS.scheduleBoard, boardData);
    renderScheduleBoard();
  });

  board.addEventListener("click", (event) => {
    const button = event.target.closest("[data-remove-slot][data-remove-block]");
    if (!button) return;
    const boardData = getScheduleBoard();
    boardData[button.dataset.removeSlot] = (boardData[button.dataset.removeSlot] || []).filter((id) => id !== button.dataset.removeBlock);
    setJson(STORAGE_KEYS.scheduleBoard, boardData);
    renderScheduleBoard();
  });

  renderScheduleBlockPalette();
  renderScheduleBoard();
}

function setupFoodPlanner() {
  const form = document.querySelector("#food-form");
  const list = document.querySelector("#food-list");

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const foods = getFoods();
    foods.unshift({
      id: `food-${Date.now()}`,
      name: document.querySelector("#food-name").value.trim(),
      category: document.querySelector("#food-category").value,
      location: document.querySelector("#food-location").value.trim(),
      map: document.querySelector("#food-map").value.trim() || "#",
      reservation: document.querySelector("#food-reservation").value.trim(),
      wait: document.querySelector("#food-wait").value.trim(),
      cardPay: document.querySelector("#food-card-pay").value.trim(),
      owner: document.querySelector("#food-owner").value.trim(),
      note: document.querySelector("#food-note").value.trim()
    });
    saveFoods(foods);
    event.target.reset();
    renderFoodList();
    renderScheduleBlockPalette();
  });

  list.addEventListener("click", (event) => {
    const button = event.target.closest("[data-delete-food]");
    if (!button) return;
    const foodId = button.dataset.deleteFood;
    saveFoods(getFoods().filter((food) => food.id !== foodId));
    const board = getScheduleBoard();
    Object.keys(board).forEach((slot) => {
      board[slot] = board[slot].filter((id) => id !== foodId);
    });
    setJson(STORAGE_KEYS.scheduleBoard, board);
    renderFoodList();
    renderScheduleBlockPalette();
    renderScheduleBoard();
  });

  renderFoodList();
}

function renderChecklist() {
  const data = getChecklistData();
  const container = document.querySelector("#checklist-groups");

  container.innerHTML = Object.entries(data).map(([groupKey, group]) => {
    const items = group.items.map((item) => {
      const checked = item.checked ? "checked" : "";
      const doneClass = item.checked ? "is-done" : "";
      return `
        <div class="checklist-item ${doneClass}">
          <label>
            <input type="checkbox" data-check-id="${item.id}" data-group="${groupKey}" ${checked}>
            <span>${escapeHtml(item.text)}</span>
          </label>
          <button class="delete-check" type="button" data-delete-check="${item.id}" data-group="${groupKey}" aria-label="체크 항목 삭제">×</button>
        </div>
      `;
    }).join("");

    return `
      <section class="checklist-group" aria-labelledby="${groupKey}-title">
        <div class="checklist-heading">
          <div>
            <h3 id="${groupKey}-title">${group.label}</h3>
            <p class="small-note" data-group-count="${groupKey}">0 / 0 완료</p>
          </div>
          <button class="button ghost reset-group" type="button" data-reset-group="${groupKey}">초기화</button>
        </div>
        ${items}
        <form class="check-add-form" data-add-group="${groupKey}">
          <input type="text" placeholder="${group.label} 항목 추가">
          <button class="button ghost" type="submit">추가</button>
        </form>
      </section>
    `;
  }).join("");

  updateChecklistCounts();
}

function setupChecklistEvents() {
  const container = document.querySelector("#checklist-groups");

  container.addEventListener("change", (event) => {
    if (!event.target.matches("[data-check-id]")) return;
    const data = getChecklistData();
    const item = data[event.target.dataset.group].items.find((entry) => entry.id === event.target.dataset.checkId);
    if (item) item.checked = event.target.checked;
    saveChecklistData(data);
    renderChecklist();
  });

  container.addEventListener("click", (event) => {
    const deleteButton = event.target.closest("[data-delete-check]");
    if (deleteButton) {
      const data = getChecklistData();
      data[deleteButton.dataset.group].items = data[deleteButton.dataset.group].items.filter((item) => item.id !== deleteButton.dataset.deleteCheck);
      saveChecklistData(data);
      renderChecklist();
      return;
    }

    const button = event.target.closest("[data-reset-group]");
    if (!button) return;
    const groupKey = button.dataset.resetGroup;
    const data = getChecklistData();
    data[groupKey].items.forEach((item) => { item.checked = false; });
    saveChecklistData(data);
    renderChecklist();
  });

  container.addEventListener("submit", (event) => {
    const form = event.target.closest("[data-add-group]");
    if (!form) return;
    event.preventDefault();
    const input = form.querySelector("input");
    const text = input.value.trim();
    if (!text) return;
    const data = getChecklistData();
    data[form.dataset.addGroup].items.push({ id: `check-${Date.now()}`, text, checked: false });
    saveChecklistData(data);
    renderChecklist();
  });

  document.querySelector("#reset-all-checks").addEventListener("click", () => {
    localStorage.removeItem(STORAGE_KEYS.checklistData);
    localStorage.removeItem(STORAGE_KEYS.checklist);
    renderChecklist();
  });
}

function updateChecklistCounts() {
  const inputs = [...document.querySelectorAll("[data-check-id]")];
  const done = inputs.filter((input) => input.checked).length;
  document.querySelector("#checklist-total").textContent = `전체 ${done} / ${inputs.length} 완료`;

  Object.keys(CHECKLIST).forEach((groupKey) => {
    const groupInputs = inputs.filter((input) => input.dataset.group === groupKey);
    const groupDone = groupInputs.filter((input) => input.checked).length;
    document.querySelector(`[data-group-count="${groupKey}"]`).textContent = `${groupDone} / ${groupInputs.length} 완료`;
  });
}

function getChecklistData() {
  const existing = getJson(STORAGE_KEYS.checklistData, null);
  if (existing) return existing;
  const oldState = getJson(STORAGE_KEYS.checklist, {});
  const data = {};
  Object.entries(CHECKLIST).forEach(([groupKey, group]) => {
    data[groupKey] = {
      label: group.label,
      items: group.items.map((text, index) => ({
        id: `${groupKey}-${index}`,
        text,
        checked: Boolean(oldState[`${groupKey}-${index}`])
      }))
    };
  });
  return data;
}

function saveChecklistData(data) {
  setJson(STORAGE_KEYS.checklistData, data);
}

function highlightToday() {
  const today = new Date();
  const todayKey = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).format(today);

  Object.entries(CONFIG.tripDays).forEach(([dayKey, date]) => {
    const card = document.querySelector(`[data-trip-day="${dayKey}"]`);
    if (card && date === todayKey) card.classList.add("is-today");
  });
}

async function copyText(text, button) {
  try {
    await navigator.clipboard.writeText(text);
    const original = button.textContent;
    button.textContent = "복사 완료";
    setTimeout(() => { button.textContent = original; }, 1400);
  } catch {
    button.textContent = "복사 실패";
  }
}

function setupPlaceButtons() {
  document.querySelectorAll(".copy-address").forEach((button) => {
    button.addEventListener("click", () => {
      const card = button.closest(".place-card");
      const address = card.querySelector(".address").dataset.address;
      copyText(address, button);
    });
  });

  document.querySelectorAll(".reveal-address").forEach((button) => {
    button.addEventListener("click", () => {
      const address = button.closest(".place-card").querySelector(".address");
      address.hidden = false;
      address.focus?.();
    });
  });
}

function setupWeatherTabs() {
  const tabs = [...document.querySelectorAll("[role='tab']")];
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((item) => {
        const selected = item === tab;
        item.setAttribute("aria-selected", String(selected));
        document.querySelector(`#${item.getAttribute("aria-controls")}`).hidden = !selected;
      });
    });
  });
}

function renderExpenses() {
  const expenses = getJson(STORAGE_KEYS.expenses, []);
  const list = document.querySelector("#expense-list");
  const total = expenses.reduce((sum, expense) => sum + Number(expense.amount || 0), 0);
  document.querySelector("#expense-summary").textContent = `합계 ${total.toLocaleString("ko-KR")} JPY`;

  const totals = Object.fromEntries(BUDGET_CATEGORIES.map((category) => [category, 0]));
  totals["총지출"] = total;
  expenses.forEach((expense) => {
    const category = expense.category || "기타";
    totals[category] = (totals[category] || 0) + Number(expense.amount || 0);
  });

  document.querySelector("#budget-cards").innerHTML = BUDGET_CATEGORIES.map((category) => `
    <article class="budget-card">
      <span>${category}</span>
      <strong>${Number(totals[category] || 0).toLocaleString("ko-KR")} JPY</strong>
    </article>
  `).join("");

  const paidBy = Object.fromEntries(TRIP_MEMBERS.map((member) => [member, 0]));
  expenses.forEach((expense) => {
    const payer = TRIP_MEMBERS.includes(expense.payer) ? expense.payer : "나";
    paidBy[payer] += Number(expense.amount || 0);
  });
  const share = total / TRIP_MEMBERS.length;
  document.querySelector("#settlement-box").innerHTML = `
    <h3>정산 메모</h3>
    ${TRIP_MEMBERS.map((member) => {
      const balance = paidBy[member] - share;
      const label = balance >= 0 ? "받을 금액" : "보낼 금액";
      return `<p><strong>${member}</strong> 결제 ${paidBy[member].toLocaleString("ko-KR")} JPY · ${label} ${Math.abs(Math.round(balance)).toLocaleString("ko-KR")} JPY</p>`;
    }).join("")}
  `;

  list.innerHTML = expenses.map((expense, index) => `
    <article class="expense-row">
      <strong>${escapeHtml(expense.category)} · ${escapeHtml(expense.item || "항목 없음")} · ${Number(expense.amount || 0).toLocaleString("ko-KR")} JPY</strong>
      <span>결제자: ${escapeHtml(expense.payer || "placeholder")} · ${escapeHtml(expense.note || "메모 없음")}</span>
      <button class="button ghost delete-expense" type="button" data-expense-index="${index}">삭제</button>
    </article>
  `).join("");
}

function setupExpenses() {
  document.querySelector("#expense-form").addEventListener("submit", (event) => {
    event.preventDefault();
    const expenses = getJson(STORAGE_KEYS.expenses, []);
    expenses.push({
      category: document.querySelector("#expense-category").value,
      item: document.querySelector("#expense-item").value.trim(),
      amount: document.querySelector("#expense-amount").value,
      payer: document.querySelector("#expense-payer").value.trim(),
      note: document.querySelector("#expense-note").value.trim()
    });
    setJson(STORAGE_KEYS.expenses, expenses);
    event.target.reset();
    renderExpenses();
  });

  document.querySelector("#expense-list").addEventListener("click", (event) => {
    const button = event.target.closest("[data-expense-index]");
    if (!button) return;
    const expenses = getJson(STORAGE_KEYS.expenses, []);
    expenses.splice(Number(button.dataset.expenseIndex), 1);
    setJson(STORAGE_KEYS.expenses, expenses);
    renderExpenses();
  });

  renderExpenses();
}

function getEditableElements() {
  return [...document.querySelectorAll("header h1, header h2, header p, header li, main h2, main h3, main h4, main p, main li, main dt, main dd, main time, main .badge, main .status, main .day-type, footer p")]
    .filter((element) => !element.closest(".edit-dock, .settings-panel, .quick-links, .expense-list, .checklist-grid, .food-list, .calendar-board, .planner-palette, .budget-cards, .settlement-box"));
}

function assignEditableKeys() {
  getEditableElements().forEach((element, index) => {
    element.dataset.editKey = `text-${index}`;
  });
}

function applySavedTextEdits() {
  const saved = getJson(STORAGE_KEYS.editableText, {});
  getEditableElements().forEach((element) => {
    const value = saved[element.dataset.editKey];
    if (typeof value === "string") element.textContent = value;
  });
}

function setEditMode(enabled) {
  document.body.classList.toggle("edit-mode", enabled);
  document.querySelector("#edit-toggle").setAttribute("aria-pressed", String(enabled));
  document.querySelector("#edit-toggle").textContent = enabled ? "편집 끄기" : "편집 켜기";
  getEditableElements().forEach((element) => {
    element.contentEditable = String(enabled);
    element.spellcheck = false;
  });
}

function setupInlineEditing() {
  assignEditableKeys();
  applySavedTextEdits();

  document.querySelector("#edit-toggle").addEventListener("click", () => {
    const enabled = !document.body.classList.contains("edit-mode");
    setEditMode(enabled);
  });

  document.addEventListener("focusout", (event) => {
    const element = event.target;
    if (!element.dataset?.editKey) return;
    const saved = getJson(STORAGE_KEYS.editableText, {});
    saved[element.dataset.editKey] = element.textContent.trim();
    setJson(STORAGE_KEYS.editableText, saved);
  });

  document.querySelector("#reset-page-edits").addEventListener("click", () => {
    localStorage.removeItem(STORAGE_KEYS.editableText);
    window.location.reload();
  });
}

function fillSettingsForm() {
  const form = document.querySelector("#settings-form");
  form.elements.tripStartDate.value = CONFIG.tripStartDate;
  form.elements.tripEndDate.value = CONFIG.tripEndDate;
  form.elements.monday.value = CONFIG.tripDays.monday;
  form.elements.tuesday.value = CONFIG.tripDays.tuesday;
  form.elements.wednesday.value = CONFIG.tripDays.wednesday;
  form.elements.myMapsEmbedUrl.value = CONFIG.myMapsEmbedUrl === "about:blank" ? "" : CONFIG.myMapsEmbedUrl;
  form.elements.calendarEmbedUrl.value = CONFIG.calendarEmbedUrl === "about:blank" ? "" : CONFIG.calendarEmbedUrl;
  Object.keys(CONFIG.links).forEach((key) => {
    if (form.elements[key]) form.elements[key].value = CONFIG.links[key] === "#" ? "" : CONFIG.links[key];
  });
}

function setupSettingsPanel() {
  const panel = document.querySelector("#settings-panel");
  const toggle = document.querySelector("#settings-toggle");
  const close = document.querySelector("#settings-close");
  const form = document.querySelector("#settings-form");

  const setOpen = (open) => {
    panel.hidden = !open;
    toggle.setAttribute("aria-expanded", String(open));
    if (open) fillSettingsForm();
  };

  toggle.addEventListener("click", () => setOpen(panel.hidden));
  close.addEventListener("click", () => setOpen(false));

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const data = new FormData(form);
    const settings = {
      tripStartDate: data.get("tripStartDate") || CONFIG.tripStartDate,
      tripEndDate: data.get("tripEndDate") || CONFIG.tripEndDate,
      myMapsEmbedUrl: data.get("myMapsEmbedUrl") || "about:blank",
      calendarEmbedUrl: data.get("calendarEmbedUrl") || "about:blank",
      tripDays: {
        monday: data.get("monday") || CONFIG.tripDays.monday,
        tuesday: data.get("tuesday") || CONFIG.tripDays.tuesday,
        wednesday: data.get("wednesday") || CONFIG.tripDays.wednesday
      },
      links: {
        myMaps: data.get("myMaps") || "#",
        calendar: data.get("calendar") || "#",
        googleMaps: CONFIG.links.googleMaps,
        weather: data.get("weather") || CONFIG.links.weather,
        ferry: data.get("ferry") || "#",
        flight: data.get("flight") || "#",
        hotel: data.get("hotel") || "#",
        museum: data.get("museum") || "#"
      }
    };
    setJson(STORAGE_KEYS.settings, settings);
    window.location.reload();
  });

  document.querySelector("#reset-settings").addEventListener("click", () => {
    localStorage.removeItem(STORAGE_KEYS.settings);
    window.location.reload();
  });
}

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js").catch(() => {});
  });
}

applySavedSettings();
formatDateRange();
renderQuickLinks();
renderChecklist();
setupChecklistEvents();
highlightToday();
updateTodayFocus();
updateWeatherWidgets();
setupScheduleTagSelects();
setupPlaceButtons();
setupWeatherTabs();
setupExpenses();
setupFoodPlanner();
setupSchedulePlanner();
setupInlineEditing();
setupSettingsPanel();
setupScrollProgress();
setupRevealAnimation();
