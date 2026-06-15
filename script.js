const CONFIG = {
  tripStartDate: "2026-06-15",
  tripEndDate: "2026-06-17",
  tripDays: {
    monday: "2026-06-15",
    tuesday: "2026-06-16",
    wednesday: "2026-06-17"
  },
  myMapsEmbedUrl: "about:blank", // 여기에 Google My Maps iframe src를 붙여넣기
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
    label: "아빠",
    items: ["상비약", "편한 신발", "얇은 겉옷", "여권 확인"]
  },
  sibling: {
    label: "동생",
    items: ["충전기", "보조배터리", "개인 준비물", "여권 확인"]
  }
};

const STORAGE_KEYS = {
  checklist: "takamatsu-family-checklist-v1",
  expenses: "takamatsu-family-expenses-v1",
  editableText: "takamatsu-family-editable-text-v1",
  settings: "takamatsu-family-settings-v1"
};

const quickLinkLabels = [
  ["myMaps", "Google My Maps 열기"],
  ["calendar", "Google Calendar 열기"],
  ["googleMaps", "Google Maps 열기"],
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

  CONFIG.tripStartDate = saved.tripStartDate || CONFIG.tripStartDate;
  CONFIG.tripEndDate = saved.tripEndDate || CONFIG.tripEndDate;
  CONFIG.myMapsEmbedUrl = saved.myMapsEmbedUrl || CONFIG.myMapsEmbedUrl;
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
}

function renderChecklist() {
  const saved = getJson(STORAGE_KEYS.checklist, {});
  const container = document.querySelector("#checklist-groups");

  container.innerHTML = Object.entries(CHECKLIST).map(([groupKey, group]) => {
    const items = group.items.map((item, index) => {
      const id = `${groupKey}-${index}`;
      const checked = saved[id] ? "checked" : "";
      return `
        <label class="checklist-item">
          <input type="checkbox" data-check-id="${id}" data-group="${groupKey}" ${checked}>
          <span>${item}</span>
        </label>
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
      </section>
    `;
  }).join("");

  updateChecklistCounts();
}

function setupChecklistEvents() {
  const container = document.querySelector("#checklist-groups");

  container.addEventListener("change", (event) => {
    if (!event.target.matches("[data-check-id]")) return;
    const state = getJson(STORAGE_KEYS.checklist, {});
    state[event.target.dataset.checkId] = event.target.checked;
    setJson(STORAGE_KEYS.checklist, state);
    updateChecklistCounts();
  });

  container.addEventListener("click", (event) => {
    const button = event.target.closest("[data-reset-group]");
    if (!button) return;
    const groupKey = button.dataset.resetGroup;
    const state = getJson(STORAGE_KEYS.checklist, {});
    Object.keys(state).forEach((key) => {
      if (key.startsWith(`${groupKey}-`)) delete state[key];
    });
    setJson(STORAGE_KEYS.checklist, state);
    renderChecklist();
  });

  document.querySelector("#reset-all-checks").addEventListener("click", () => {
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
    .filter((element) => !element.closest(".edit-dock, .settings-panel, .quick-links, .expense-list, .checklist-grid"));
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
setupPlaceButtons();
setupWeatherTabs();
setupExpenses();
setupInlineEditing();
setupSettingsPanel();
setupScrollProgress();
setupRevealAnimation();
