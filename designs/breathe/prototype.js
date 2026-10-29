"use strict";
const $ = (id) => document.getElementById(id);
const presets = {
  morning: { inhale: 5, exhale: 5, minutes: 10 },
  midday: { inhale: 4, exhale: 6, minutes: 20 },
  evening: { inhale: 4, exhale: 6, minutes: 15 },
  night: { inhale: 3, exhale: 7, minutes: 20 }
};
// 内部值沿用英文 preset id；界面显示用 presetLabel 转中文。
const presetLabels = {
  auto: "自动",
  morning: "晨间",
  midday: "午间",
  evening: "晚间",
  night: "深夜",
  custom: "自定义",
  balanced: "晨间",
  extended: "午间",
  calm: "晚间",
  unknown: "未知"
};
const presetLabel = (name) => presetLabels[name] || name;
const state = { preset: "auto", custom: { inhale: 5, exhale: 5, minutes: 10 }, sound: true, logging: true, launch: false, scene: "settings", active: false, paused: false, phase: "idle", phaseElapsed: 0, countdown: 3, breaths: 0, remaining: 0, config: null, started: null, quit: false };
// Fixture records only. No filesystem access, import, or real session data.
// preset 列保留 CSV 的英文 id，renderHistory 显示中文。
const records = [
  ["2026-10-29", "07:30:12", "morning", "5-5", "10:00", "10:00", 60, 100, true],
  ["2026-10-28", "22:15:08", "night", "3-7", "20:00", "20:00", 120, 100, true],
  ["2026-10-28", "18:42:36", "evening", "4-6", "15:00", "08:24", 50, 56, false],
  ["2026-10-28", "13:05:20", "midday", "4-6", "20:00", "20:00", 120, 100, true],
  ["2026-10-28", "07:12:45", "morning", "5-5", "10:00", "10:00", 60, 100, true],
  ["2026-10-27", "21:08:03", "evening", "4-6", "15:00", "15:00", 90, 100, true],
  ["2026-10-27", "06:50:16", "morning", "5-5", "10:00", "10:00", 60, 100, true]
];
const formatTime = (seconds) => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
const localHour = () => Number(new Intl.DateTimeFormat("en-GB", { hour: "numeric", hourCycle: "h23", timeZone: "Asia/Shanghai" }).format(new Date()));
function autoPreset() {
  const hour = localHour();
  return hour >= 6 && hour < 12 ? "morning" : hour >= 12 && hour < 17 ? "midday" : hour >= 17 && hour < 22 ? "evening" : "night";
}
function selectedConfig() {
  const name = state.preset === "auto" ? autoPreset() : state.preset;
  const config = { ...(name === "custom" ? state.custom : presets[name]), name };
  config.cycle = config.inhale + config.exhale;
  config.total = Math.ceil(config.minutes * 60 / config.cycle) * config.cycle;
  return config;
}
function validationError() {
  const { inhale, exhale, minutes } = state.custom;
  if (![inhale, exhale, minutes].every(Number.isInteger)) return "请输入完整的整数时长。";
  if (inhale + exhale < 8) return `总呼吸周期须 ≥ 8 秒，当前 ${inhale + exhale} 秒`;
  if (inhale < 3 || inhale > 10) return "吸气时长须在 3–10 秒";
  if (exhale < 3 || exhale > 10) return "呼气时长须在 3–10 秒";
  if (minutes < 1 || minutes > 60) return "练习时长须在 1–60 分钟";
  return "";
}
let toastTimer;
function toast(message) {
  $("toast").textContent = message;
  $("toast").hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { $("toast").hidden = true; }, 3800);
}
function setMenu(open) {
  $("app-menu").hidden = !open || state.quit;
  $("status-button").setAttribute("aria-expanded", String(open && !state.quit));
  if (!open) {
    $("preset-menu").hidden = true;
    $("preset-button").setAttribute("aria-expanded", "false");
  }
}
function showScene(scene) {
  if (state.quit) return;
  state.scene = scene;
  $("settings-window").hidden = scene !== "settings";
  $("history-window").hidden = scene !== "history";
  $("desktop-hint").hidden = scene !== "desktop" || state.active;
  document.querySelectorAll("[data-scene]").forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.scene === scene)));
  if (scene === "history") renderHistory();
}
function renderSettings() {
  const config = selectedConfig();
  const custom = state.preset === "custom";
  const error = custom ? validationError() : "";
  $("preset-select").value = state.preset;
  const displayPreset = custom ? "自定义" : presetLabel(config.name);
  $("preset-name").textContent = state.preset === "auto" ? "自动" : displayPreset;
  $("custom-settings").hidden = !custom;
  $("time-mapping").hidden = state.preset !== "auto";
  const currentAuto = autoPreset();
  document.querySelectorAll(".mapping-row").forEach((row) => {
    row.classList.toggle("current", row.dataset.period === currentAuto);
  });
  $("preset-summary").hidden = !!error;
  $("preset-summary").innerHTML = `<div><small>${state.preset === "auto" ? "当前预设" : "所选预设"}</small><strong style="font-size:15px">${displayPreset}</strong></div><div><small>吸气 / 呼气</small><strong>${config.inhale} / ${config.exhale}</strong><span class="unit">秒</span></div><div><small>练习时长</small><strong>${config.minutes}</strong><span class="unit">分钟</span></div>`;
  $("validation").classList.toggle("error", !!error);
  $("validation").textContent = error || `周期 ${config.cycle} 秒，实际时长 ${Math.floor(config.total / 60)} 分 ${config.total % 60} 秒`;
  $("start-button").disabled = !state.active && !!error;
  $("sound").checked = state.sound;
  $("logging").checked = state.logging;
  $("launch").checked = state.launch;
  $("log-path").hidden = !state.logging;
  $("mute-label").textContent = state.sound ? "静音" : "取消静音";
  document.querySelectorAll("[data-preset]").forEach((button) => button.classList.toggle("selected", button.dataset.preset === state.preset));
}
function selectPreset(value) {
  state.preset = value;
  $("preset-menu").hidden = true;
  $("preset-button").setAttribute("aria-expanded", "false");
  renderSettings();
  if (value === "custom") { showScene("settings"); selectTab("preset"); }
}
function selectTab(tab) {
  for (const name of ["preset", "general"]) {
    $(`${name}-tab`).setAttribute("aria-selected", String(name === tab));
    $(`${name}-panel`).hidden = name !== tab;
  }
}
function renderHistory() {
  $("record-count").textContent = `${records.length} 条记录`;
  $("empty-history").hidden = records.length > 0;
  document.querySelector(".table-scroll").hidden = records.length === 0;
  $("history-body").replaceChildren(...records.map((record) => {
    const row = document.createElement("tr");
    record.slice(0, 8).forEach((value, index) => {
      const cell = document.createElement("td");
      cell.textContent = index === 2 ? presetLabel(value) : index === 7 ? `${value}%` : value;
      row.appendChild(cell);
    });
    const cell = document.createElement("td");
    const badge = document.createElement("span");
    badge.className = `status-badge${record[8] ? "" : " early"}`;
    badge.textContent = record[8] ? "已完成" : "提前结束";
    cell.appendChild(badge); row.appendChild(cell);
    return row;
  }));
}
let audioContext;
function enableAudio() {
  if (!state.sound) return;
  try {
    audioContext ??= new (window.AudioContext || window.webkitAudioContext)();
    audioContext.resume().catch(() => {});
  } catch { /* Audio can be unavailable in embedded browsers. */ }
}
function cue() {
  if (!state.sound) return;
  try {
    audioContext ??= new (window.AudioContext || window.webkitAudioContext)();
    if (audioContext.state !== "running") return;
    const oscillator = audioContext.createOscillator();
    const gain = audioContext.createGain();
    oscillator.frequency.value = state.phase === "inhale" ? 660 : 440;
    gain.gain.setValueAtTime(0, audioContext.currentTime);
    gain.gain.linearRampToValueAtTime(.035, audioContext.currentTime + .03);
    gain.gain.exponentialRampToValueAtTime(.001, audioContext.currentTime + .32);
    oscillator.connect(gain); gain.connect(audioContext.destination);
    oscillator.start(); oscillator.stop(audioContext.currentTime + .35);
  } catch { /* Sound is optional in the browser demo. */ }
}
function startSession() {
  if (state.quit || (state.preset === "custom" && validationError())) return;
  state.config = selectedConfig();
  state.active = true; state.paused = false; state.phase = "countdown";
  state.phaseElapsed = 0; state.countdown = 3; state.breaths = 0;
  state.remaining = state.config.total; state.started = new Date();
  // Audio is initialized in a user gesture, never on page load.
  enableAudio();
  showScene("desktop"); setMenu(false); renderSession();
}
function finishSession(completed) {
  if (!state.active) return;
  const config = state.config;
  const elapsed = completed ? config.total : Math.floor((Date.now() - state.started.getTime()) / 1000);
  if (state.logging) {
    const parts = new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Shanghai", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit", hourCycle: "h23" }).format(state.started).split(" ");
    records.push([parts[0], parts[1], config.name, `${config.inhale}-${config.exhale}`, formatTime(config.total), formatTime(elapsed), state.breaths, completed ? 100 : Math.min(100, Math.floor(elapsed * 100 / config.total)), completed]);
  }
  state.active = false; state.paused = false; state.phase = "idle";
  renderSession(); showScene(state.scene); renderHistory();
  toast(completed ? "呼吸练习已完成。" : "呼吸练习已结束。");
}
function togglePause() {
  if (!state.active || state.phase === "countdown") return;
  state.paused = !state.paused;
  if (!state.paused) {
    // Native engine resumes from inhale, discarding the partial cycle.
    state.phase = "inhale"; state.phaseElapsed = 0;
    state.remaining = state.config.total - state.breaths * state.config.cycle;
    cue();
  }
  renderSession();
}
function renderSession() {
  $("orb-container").hidden = !state.active;
  $("remaining").textContent = state.active ? formatTime(state.remaining) : "";
  $("status-button").style.color = state.active ? "#26734f" : "";
  $("start-label").textContent = state.active ? "停止呼吸" : "开始呼吸";
  $("pause-button").hidden = !state.active;
  $("pause-button").disabled = state.phase === "countdown";
  $("pause-label").textContent = state.paused ? "继续" : "暂停";
  $("menu-state").textContent = !state.active ? "准备就绪" : state.paused ? "已暂停" : state.phase === "countdown" ? "准备开始" : state.phase === "inhale" ? "吸气" : "呼气";
  if (!state.active) { renderSettings(); return; }
  const phase = state.paused ? "paused" : state.phase;
  const seconds = phase === "countdown" ? state.countdown - Math.floor(state.phaseElapsed) : phase === "paused" ? 0 : Math.ceil(state.config[phase] - state.phaseElapsed);
  $("orb-text").textContent = phase === "paused" ? "Ⅱ" : Math.max(0, seconds);
  const progress = phase === "inhale" || phase === "exhale" ? Math.min(1, state.phaseElapsed / state.config[phase]) : 0;
  const scale = phase === "inhale" ? .3 + .7 * progress : phase === "exhale" ? 1 - .7 * progress : .5;
  $("orb").style.transform = `scale(${scale})`;
  const colors = phase === "inhale" ? ["#4bc984", "#6cc5ad88"] : phase === "exhale" ? ["#ea8c6f", "#e8ab7988"] : phase === "paused" ? ["#dda44f", "#e9cb7888"] : ["#71a8d9", "#8fc0dc88"];
  $("orb").style.background = `radial-gradient(circle at 42% 36%,${colors[0]},${colors[1]} 75%)`;
  $("orb-container").setAttribute("aria-label", `可拖动的呼吸球：${$("menu-state").textContent}，${phase === "paused" ? "" : seconds + " 秒"}`);
}
let previousTick = performance.now();
setInterval(() => {
  const now = performance.now(); const delta = (now - previousTick) / 1000; previousTick = now;
  if (!state.active || state.paused) return;
  state.phaseElapsed += delta;
  while (state.active) {
    const duration = state.phase === "countdown" ? 3 : state.config[state.phase];
    if (state.phaseElapsed < duration) break;
    state.phaseElapsed -= duration;
    if (state.phase === "exhale") {
      state.breaths++;
      if (state.breaths * state.config.cycle >= state.config.total) { finishSession(true); return; }
    }
    state.phase = state.phase === "inhale" ? "exhale" : "inhale";
    // Avoid a burst of tones after returning from a background tab.
    if (delta < 1) cue();
  }
  const elapsed = state.phase === "countdown" ? 0 : state.breaths * state.config.cycle + (state.phase === "exhale" ? state.config.inhale : 0) + Math.floor(state.phaseElapsed);
  state.remaining = Math.max(0, state.config.total - elapsed);
  renderSession();
}, 50);
$("status-button").addEventListener("click", () => setMenu($("app-menu").hidden));
$("status-button").addEventListener("contextmenu", (event) => { event.preventDefault(); setMenu(true); });
$("start-button").addEventListener("click", () => state.active ? finishSession(false) : startSession());
$("pause-button").addEventListener("click", togglePause);
$("preset-button").addEventListener("click", () => { $("preset-menu").hidden = !$("preset-menu").hidden; $("preset-button").setAttribute("aria-expanded", String(!$("preset-menu").hidden)); });
document.querySelectorAll("[data-preset]").forEach((button) => button.addEventListener("click", () => selectPreset(button.dataset.preset)));
document.querySelectorAll("[data-scene]").forEach((button) => button.addEventListener("click", () => { showScene(button.dataset.scene); setMenu(button.dataset.scene === "desktop"); }));
document.querySelectorAll("[data-open]").forEach((button) => button.addEventListener("click", () => { showScene(button.dataset.open); setMenu(false); }));
document.querySelectorAll("[data-close]").forEach((button) => button.addEventListener("click", () => showScene("desktop")));
$("preset-tab").addEventListener("click", () => selectTab("preset"));
$("general-tab").addEventListener("click", () => selectTab("general"));
$("preset-select").addEventListener("change", (event) => selectPreset(event.target.value));
for (const [id, property] of [["inhale", "inhale"], ["exhale", "exhale"], ["duration", "minutes"]]) {
  $(id).addEventListener("input", (event) => { state.custom[property] = event.target.value === "" ? NaN : Number(event.target.value); renderSettings(); });
}
$("mute-button").addEventListener("click", () => { state.sound = !state.sound; enableAudio(); renderSettings(); });
for (const [id, property] of [["sound", "sound"], ["logging", "logging"], ["launch", "launch"]]) {
  $(id).addEventListener("change", (event) => { state[property] = event.target.checked; if (property === "sound") enableAudio(); renderSettings(); });
}
$("refresh-button").addEventListener("click", () => { renderHistory(); toast("演示记录已刷新。"); });
$("import-button").addEventListener("click", () => { records.push(["2026-10-26", "08:10:00", "morning", "5-5", "10:00", "10:00", 60, 100, true]); renderHistory(); toast("已加入 1 条旧版日志示例；未读取本地文件。"); });
$("quit-button").addEventListener("click", () => {
  // Quitting the native app does not call the stop action or write a record.
  state.active = false; state.quit = true; state.phase = "idle"; setMenu(false);
  $("status-button").hidden = true; $("settings-window").hidden = true; $("history-window").hidden = true;
  $("orb-container").hidden = true; $("desktop-hint").hidden = true; $("quit-message").hidden = false;
});
$("restart-button").addEventListener("click", () => { state.quit = false; $("status-button").hidden = false; $("quit-message").hidden = true; renderSession(); showScene("desktop"); setMenu(true); });
$("desktop").addEventListener("pointerdown", (event) => { if (event.target === $("desktop") || event.target.closest(".window")) setMenu(false); });
document.addEventListener("keydown", (event) => {
  if (state.quit || event.target.closest("input,select,textarea")) return;
  if (event.key === "Escape") { setMenu(false); return; }
  if (event.code === "Space" && event.target.tagName !== "BUTTON") { event.preventDefault(); togglePause(); }
  if (event.key.toLowerCase() === "s" && !event.metaKey && !event.ctrlKey) { state.sound = !state.sound; enableAudio(); renderSettings(); }
  if (event.metaKey || event.ctrlKey) {
    if (event.key.toLowerCase() === "b") { event.preventDefault(); state.active ? finishSession(false) : startSession(); }
    if (event.key === ",") { event.preventDefault(); showScene("settings"); setMenu(false); }
    if (event.key.toLowerCase() === "h") { event.preventDefault(); showScene("history"); setMenu(false); }
  }
});
let drag = null;
$("orb-container").addEventListener("pointerdown", (event) => {
  const rect = $("orb-container").getBoundingClientRect();
  drag = { x: event.clientX - rect.left, y: event.clientY - rect.top };
  $("orb-container").setPointerCapture(event.pointerId);
});
$("orb-container").addEventListener("pointermove", (event) => {
  if (!drag) return;
  const rect = $("desktop").getBoundingClientRect();
  $("orb-container").style.left = `${Math.max(0, Math.min(rect.width - 242, event.clientX - rect.left - drag.x))}px`;
  $("orb-container").style.top = `${Math.max(32, Math.min(rect.height - 242, event.clientY - rect.top - drag.y))}px`;
});
$("orb-container").addEventListener("pointerup", () => { drag = null; });
$("orb-container").addEventListener("pointercancel", () => { drag = null; });
window.addEventListener("resize", () => {
  if (!state.active) return;
  const orb = $("orb-container");
  orb.style.left = `${Math.max(0, Math.min($("desktop").clientWidth - 240, orb.offsetLeft))}px`;
  orb.style.top = `${Math.max(32, Math.min($("desktop").clientHeight - 240, orb.offsetTop))}px`;
});
function renderClock() { $("clock").textContent = new Intl.DateTimeFormat("zh-CN", { timeZone: "Asia/Shanghai", month: "long", day: "numeric", weekday: "short", hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).format(new Date()); }
renderClock(); setInterval(renderClock, 10000);
renderSettings(); renderHistory(); showScene("settings"); renderSession();
setInterval(renderSettings, 60000);
if (window.matchMedia("(max-width: 720px)").matches) setMenu(false);
