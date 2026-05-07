import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import {
  getAuth,
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  addDoc,
  collection,
  getDocs,
  query,
  where
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { firebaseWebConfig } from "/firebase-config.js";

const appRoot = document.getElementById("app");
const firebaseApp = initializeApp(firebaseWebConfig);
const auth = getAuth(firebaseApp);
const db = getFirestore(firebaseApp);
let checkinInFlight = false;
let activeTab = "home";
let currentTheme = detectInitialTheme();

const I18N = {
  en: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "Email",
    password: "Password",
    signIn: "Sign in",
    createAccount: "Create account",
    welcome: "Welcome",
    onboardingHint: "Create your baseline profile.",
    displayName: "Display name",
    continue: "Continue",
    sourceCloud: "cloud",
    sourceFallback: "fallback",
    hello: "Hello",
    currentStreak: "Current streak",
    days: "days",
    soberSince: "Sober since",
    communityTitle: "Community",
    communitySubtitle: "Stay anonymous, feel together.",
    anonymousCheckin: "Anonymous check-in",
    checkedInToday: "Checked in today",
    todayCheckedIn: "Today: {count} people checked in",
    emergencyReset: "Emergency reset",
    relapsed: "I relapsed",
    signOut: "Sign out",
    language: "Language",
    tabHome: "Home",
    tabStats: "Stats",
    statsTitle: "Statistics",
    statsCurrentStreak: "Current streak",
    statsBestStreak: "Best streak",
    statsRelapses: "Relapses",
    statsCheckins7d: "Check-ins (7 days)",
    theme: "Theme",
    themeLight: "Light",
    themeDark: "Dark"
  },
  ru: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "Почта",
    password: "Пароль",
    signIn: "Войти",
    createAccount: "Создать аккаунт",
    welcome: "Добро пожаловать",
    onboardingHint: "Создайте базовый профиль.",
    displayName: "Имя",
    continue: "Продолжить",
    sourceCloud: "облако",
    sourceFallback: "fallback",
    hello: "Привет",
    currentStreak: "Текущая серия",
    days: "дней",
    soberSince: "Трезв с",
    communityTitle: "Сообщество",
    communitySubtitle: "Оставайся анонимным, но не один.",
    anonymousCheckin: "Анонимный check-in",
    checkedInToday: "Отметка за сегодня есть",
    todayCheckedIn: "Сегодня отметилось: {count}",
    emergencyReset: "Экстренный сброс",
    relapsed: "У меня срыв",
    signOut: "Выйти",
    language: "Язык",
    tabHome: "Главная",
    tabStats: "Статистика",
    statsTitle: "Статистика",
    statsCurrentStreak: "Текущая серия",
    statsBestStreak: "Лучшая серия",
    statsRelapses: "Срывы",
    statsCheckins7d: "Чекины (7 дней)",
    theme: "Тема",
    themeLight: "Светлая",
    themeDark: "Тёмная"
  },
  de: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "E-Mail",
    password: "Passwort",
    signIn: "Anmelden",
    createAccount: "Konto erstellen",
    welcome: "Willkommen",
    onboardingHint: "Erstelle dein Basisprofil.",
    displayName: "Anzeigename",
    continue: "Weiter",
    sourceCloud: "Cloud",
    sourceFallback: "Fallback",
    hello: "Hallo",
    currentStreak: "Aktuelle Serie",
    days: "Tage",
    soberSince: "Nüchtern seit",
    communityTitle: "Community",
    communitySubtitle: "Bleib anonym, aber nicht allein.",
    anonymousCheckin: "Anonymer Check-in",
    checkedInToday: "Heute bereits eingecheckt",
    todayCheckedIn: "Heute eingecheckt: {count}",
    emergencyReset: "Notfall-Reset",
    relapsed: "Ich hatte einen Rückfall",
    signOut: "Abmelden",
    language: "Sprache",
    tabHome: "Start",
    tabStats: "Statistik",
    statsTitle: "Statistik",
    statsCurrentStreak: "Aktuelle Serie",
    statsBestStreak: "Beste Serie",
    statsRelapses: "Rückfälle",
    statsCheckins7d: "Check-ins (7 Tage)",
    theme: "Design",
    themeLight: "Hell",
    themeDark: "Dunkel"
  },
  es: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "Correo",
    password: "Contraseña",
    signIn: "Iniciar sesión",
    createAccount: "Crear cuenta",
    welcome: "Bienvenido",
    onboardingHint: "Crea tu perfil base.",
    displayName: "Nombre",
    continue: "Continuar",
    sourceCloud: "nube",
    sourceFallback: "fallback",
    hello: "Hola",
    currentStreak: "Racha actual",
    days: "días",
    soberSince: "Sobrio desde",
    communityTitle: "Comunidad",
    communitySubtitle: "Permanece anónimo, pero acompañado.",
    anonymousCheckin: "Check-in anónimo",
    checkedInToday: "Check-in de hoy completado",
    todayCheckedIn: "Hoy hicieron check-in: {count}",
    emergencyReset: "Reinicio de emergencia",
    relapsed: "He recaído",
    signOut: "Cerrar sesión",
    language: "Idioma",
    tabHome: "Inicio",
    tabStats: "Estadísticas",
    statsTitle: "Estadísticas",
    statsCurrentStreak: "Racha actual",
    statsBestStreak: "Mejor racha",
    statsRelapses: "Recaídas",
    statsCheckins7d: "Check-ins (7 días)",
    theme: "Tema",
    themeLight: "Claro",
    themeDark: "Oscuro"
  },
  fr: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "E-mail",
    password: "Mot de passe",
    signIn: "Se connecter",
    createAccount: "Créer un compte",
    welcome: "Bienvenue",
    onboardingHint: "Créez votre profil de base.",
    displayName: "Nom affiché",
    continue: "Continuer",
    sourceCloud: "cloud",
    sourceFallback: "secours",
    hello: "Bonjour",
    currentStreak: "Série actuelle",
    days: "jours",
    soberSince: "Sobre depuis",
    communityTitle: "Communauté",
    communitySubtitle: "Restez anonyme, mais pas seul.",
    anonymousCheckin: "Check-in anonyme",
    checkedInToday: "Check-in déjà fait aujourd'hui",
    todayCheckedIn: "Aujourd'hui : {count} check-ins",
    emergencyReset: "Réinitialisation d'urgence",
    relapsed: "J'ai rechuté",
    signOut: "Se déconnecter",
    language: "Langue",
    tabHome: "Accueil",
    tabStats: "Statistiques",
    statsTitle: "Statistiques",
    statsCurrentStreak: "Série actuelle",
    statsBestStreak: "Meilleure série",
    statsRelapses: "Rechutes",
    statsCheckins7d: "Check-ins (7 jours)",
    theme: "Thème",
    themeLight: "Clair",
    themeDark: "Sombre"
  },
  it: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "Email",
    password: "Password",
    signIn: "Accedi",
    createAccount: "Crea account",
    welcome: "Benvenuto",
    onboardingHint: "Crea il tuo profilo base.",
    displayName: "Nome visualizzato",
    continue: "Continua",
    sourceCloud: "cloud",
    sourceFallback: "fallback",
    hello: "Ciao",
    currentStreak: "Serie attuale",
    days: "giorni",
    soberSince: "Sobrio dal",
    communityTitle: "Community",
    communitySubtitle: "Resta anonimo, ma non da solo.",
    anonymousCheckin: "Check-in anonimo",
    checkedInToday: "Check-in di oggi completato",
    todayCheckedIn: "Oggi check-in: {count}",
    emergencyReset: "Reset di emergenza",
    relapsed: "Ho avuto una ricaduta",
    signOut: "Esci",
    language: "Lingua",
    tabHome: "Home",
    tabStats: "Statistiche",
    statsTitle: "Statistiche",
    statsCurrentStreak: "Serie attuale",
    statsBestStreak: "Serie migliore",
    statsRelapses: "Ricadute",
    statsCheckins7d: "Check-in (7 giorni)",
    theme: "Tema",
    themeLight: "Chiaro",
    themeDark: "Scuro"
  },
  ja: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "メール",
    password: "パスワード",
    signIn: "ログイン",
    createAccount: "アカウント作成",
    welcome: "ようこそ",
    onboardingHint: "基本プロフィールを作成してください。",
    displayName: "表示名",
    continue: "続ける",
    sourceCloud: "クラウド",
    sourceFallback: "フォールバック",
    hello: "こんにちは",
    currentStreak: "現在の連続日数",
    days: "日",
    soberSince: "禁酒開始日",
    communityTitle: "コミュニティ",
    communitySubtitle: "匿名のまま、つながりを感じよう。",
    anonymousCheckin: "匿名チェックイン",
    checkedInToday: "本日のチェックイン済み",
    todayCheckedIn: "今日のチェックイン人数: {count}",
    emergencyReset: "緊急リセット",
    relapsed: "再飲酒しました",
    signOut: "ログアウト",
    language: "言語",
    tabHome: "ホーム",
    tabStats: "統計",
    statsTitle: "統計",
    statsCurrentStreak: "現在の連続日数",
    statsBestStreak: "最長記録",
    statsRelapses: "再飲酒回数",
    statsCheckins7d: "チェックイン（7日）",
    theme: "テーマ",
    themeLight: "ライト",
    themeDark: "ダーク"
  },
  pl: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "Email",
    password: "Hasło",
    signIn: "Zaloguj się",
    createAccount: "Utwórz konto",
    welcome: "Witamy",
    onboardingHint: "Utwórz swój profil bazowy.",
    displayName: "Nazwa wyświetlana",
    continue: "Dalej",
    sourceCloud: "chmura",
    sourceFallback: "fallback",
    hello: "Cześć",
    currentStreak: "Aktualna seria",
    days: "dni",
    soberSince: "Trzeźwy od",
    communityTitle: "Społeczność",
    communitySubtitle: "Pozostań anonimowy, ale nie sam.",
    anonymousCheckin: "Anonimowy check-in",
    checkedInToday: "Dzisiejszy check-in wykonany",
    todayCheckedIn: "Dziś check-in: {count}",
    emergencyReset: "Awaryjny reset",
    relapsed: "Miałem nawrót",
    signOut: "Wyloguj",
    language: "Język",
    tabHome: "Start",
    tabStats: "Statystyki",
    statsTitle: "Statystyki",
    statsCurrentStreak: "Aktualna seria",
    statsBestStreak: "Najlepsza seria",
    statsRelapses: "Nawroty",
    statsCheckins7d: "Check-iny (7 dni)",
    theme: "Motyw",
    themeLight: "Jasny",
    themeDark: "Ciemny"
  },
  th: {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "อีเมล",
    password: "รหัสผ่าน",
    signIn: "เข้าสู่ระบบ",
    createAccount: "สร้างบัญชี",
    welcome: "ยินดีต้อนรับ",
    onboardingHint: "สร้างโปรไฟล์พื้นฐานของคุณ",
    displayName: "ชื่อที่แสดง",
    continue: "ดำเนินการต่อ",
    sourceCloud: "คลาวด์",
    sourceFallback: "โหมดสำรอง",
    hello: "สวัสดี",
    currentStreak: "สถิติปัจจุบัน",
    days: "วัน",
    soberSince: "เลิกดื่มตั้งแต่",
    communityTitle: "ชุมชน",
    communitySubtitle: "ไม่เปิดเผยตัวตน แต่ไม่โดดเดี่ยว",
    anonymousCheckin: "เช็กอินแบบไม่ระบุตัวตน",
    checkedInToday: "เช็กอินวันนี้แล้ว",
    todayCheckedIn: "วันนี้เช็กอินแล้ว: {count}",
    emergencyReset: "รีเซ็ตฉุกเฉิน",
    relapsed: "ฉันกลับไปดื่มอีก",
    signOut: "ออกจากระบบ",
    language: "ภาษา",
    tabHome: "หน้าหลัก",
    tabStats: "สถิติ",
    statsTitle: "สถิติ",
    statsCurrentStreak: "สถิติปัจจุบัน",
    statsBestStreak: "สถิติที่ดีที่สุด",
    statsRelapses: "จำนวนครั้งที่กลับไปดื่ม",
    statsCheckins7d: "เช็กอิน (7 วัน)",
    theme: "ธีม",
    themeLight: "สว่าง",
    themeDark: "มืด"
  },
  "zh-Hans": {
    appTitle: "SoberLife",
    appSubtitle: "PWA + Firebase",
    email: "邮箱",
    password: "密码",
    signIn: "登录",
    createAccount: "创建账号",
    welcome: "欢迎",
    onboardingHint: "创建你的基础档案。",
    displayName: "显示名称",
    continue: "继续",
    sourceCloud: "云端",
    sourceFallback: "离线",
    hello: "你好",
    currentStreak: "当前连续天数",
    days: "天",
    soberSince: "戒酒开始于",
    communityTitle: "社区",
    communitySubtitle: "保持匿名，也能感受陪伴。",
    anonymousCheckin: "匿名打卡",
    checkedInToday: "今日已打卡",
    todayCheckedIn: "今日打卡人数：{count}",
    emergencyReset: "紧急重置",
    relapsed: "我复饮了",
    signOut: "退出登录",
    language: "语言",
    tabHome: "主页",
    tabStats: "统计",
    statsTitle: "统计",
    statsCurrentStreak: "当前连续天数",
    statsBestStreak: "最佳连续天数",
    statsRelapses: "复饮次数",
    statsCheckins7d: "打卡（7天）",
    theme: "主题",
    themeLight: "浅色",
    themeDark: "深色"
  }
};

function detectInitialLanguage() {
  const stored = localStorage.getItem("sl_lang");
  if (stored && I18N[stored]) return stored;
  const browser = (navigator.language || "en").toLowerCase();
  if (browser.startsWith("ru")) return "ru";
  if (browser.startsWith("de")) return "de";
  if (browser.startsWith("es")) return "es";
  if (browser.startsWith("fr")) return "fr";
  if (browser.startsWith("it")) return "it";
  if (browser.startsWith("ja")) return "ja";
  if (browser.startsWith("pl")) return "pl";
  if (browser.startsWith("th")) return "th";
  if (browser.startsWith("zh")) return "zh-Hans";
  return "en";
}

let currentLanguage = detectInitialLanguage();

function detectInitialTheme() {
  const stored = localStorage.getItem("sl_theme");
  if (stored === "light" || stored === "dark") return stored;
  return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function applyTheme() {
  document.documentElement.setAttribute("data-theme", currentTheme);
}

applyTheme();

function t(key, params = {}) {
  const dict = I18N[currentLanguage] || I18N.en;
  const template = dict[key] || I18N.en[key] || key;
  return Object.entries(params).reduce((acc, [k, v]) => acc.replace(`{${k}}`, String(v)), template);
}

function renderTopControls() {
  return `
    <section class="card controls-row">
      <div>
        <label class="muted" for="langSelect">${t("language")}</label>
        <select id="langSelect" class="lang-select">
          <option value="en" ${currentLanguage === "en" ? "selected" : ""}>English</option>
          <option value="ru" ${currentLanguage === "ru" ? "selected" : ""}>Русский</option>
          <option value="de" ${currentLanguage === "de" ? "selected" : ""}>Deutsch</option>
          <option value="es" ${currentLanguage === "es" ? "selected" : ""}>Español</option>
          <option value="fr" ${currentLanguage === "fr" ? "selected" : ""}>Français</option>
          <option value="it" ${currentLanguage === "it" ? "selected" : ""}>Italiano</option>
          <option value="ja" ${currentLanguage === "ja" ? "selected" : ""}>日本語</option>
          <option value="pl" ${currentLanguage === "pl" ? "selected" : ""}>Polski</option>
          <option value="th" ${currentLanguage === "th" ? "selected" : ""}>ไทย</option>
          <option value="zh-Hans" ${currentLanguage === "zh-Hans" ? "selected" : ""}>简体中文</option>
        </select>
      </div>
      <div>
        <label class="muted" for="themeSelect">${t("theme")}</label>
        <select id="themeSelect" class="lang-select">
          <option value="light" ${currentTheme === "light" ? "selected" : ""}>${t("themeLight")}</option>
          <option value="dark" ${currentTheme === "dark" ? "selected" : ""}>${t("themeDark")}</option>
        </select>
      </div>
    </section>
  `;
}

function bindTopControls(onChange) {
  const langSelect = document.getElementById("langSelect");
  if (langSelect) {
    langSelect.onchange = () => {
      currentLanguage = langSelect.value;
      localStorage.setItem("sl_lang", currentLanguage);
      onChange();
    };
  }

  const themeSelect = document.getElementById("themeSelect");
  if (themeSelect) {
    themeSelect.onchange = () => {
      currentTheme = themeSelect.value;
      localStorage.setItem("sl_theme", currentTheme);
      applyTheme();
      onChange();
    };
  }
}

function iconHomeSvg() {
  return `<svg class="tab-icon-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M3 10.5 12 4l9 6.5V20a2 2 0 01-2 2H5a2 2 0 01-2-2v-9.5z"/>
    <path d="M9 22v-8h6v8"/>
  </svg>`;
}

function iconStatsSvg() {
  return `<svg class="tab-icon-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M18 21V9"/>
    <path d="M12 21v-9"/>
    <path d="M6 21V5"/>
  </svg>`;
}

function renderBottomTabs() {
  return `
    <section class="card bottom-tabs" role="tablist" aria-label="${t("tabHome")} / ${t("tabStats")}">
      <button type="button" id="tabHomeBtn" role="tab" aria-selected="${activeTab === "home"}" class="tab-icon ${activeTab === "home" ? "active" : ""}" aria-label="${t("tabHome")}">
        ${iconHomeSvg()}
      </button>
      <button type="button" id="tabStatsBtn" role="tab" aria-selected="${activeTab === "stats"}" class="tab-icon ${activeTab === "stats" ? "active" : ""}" aria-label="${t("tabStats")}">
        ${iconStatsSvg()}
      </button>
    </section>
  `;
}

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").catch(() => {});
}

function utcDay() {
  return new Date().toISOString().slice(0, 10);
}

function daysSince(dateIso) {
  const started = new Date(dateIso);
  const now = new Date();
  const ms = now.getTime() - started.getTime();
  return Math.max(0, Math.floor(ms / 86400000));
}

function renderAuth() {
  appRoot.innerHTML = `
    ${renderTopControls()}
    <section class="card">
      <h1>${t("appTitle")}</h1>
      <p class="muted">${t("appSubtitle")}</p>
      <input id="email" type="email" placeholder="${t("email")}" />
      <input id="password" type="password" placeholder="${t("password")}" />
      <div class="row">
        <button id="loginBtn">${t("signIn")}</button>
        <button id="registerBtn" class="secondary">${t("createAccount")}</button>
      </div>
      <p id="authError" class="muted"></p>
    </section>
  `;
  bindTopControls(renderAuth);

  const email = document.getElementById("email");
  const password = document.getElementById("password");
  const authError = document.getElementById("authError");

  document.getElementById("loginBtn").onclick = async () => {
    authError.textContent = "";
    try {
      await signInWithEmailAndPassword(auth, email.value.trim(), password.value);
    } catch (e) {
      authError.textContent = e.message;
    }
  };

  document.getElementById("registerBtn").onclick = async () => {
    authError.textContent = "";
    try {
      await createUserWithEmailAndPassword(auth, email.value.trim(), password.value);
    } catch (e) {
      authError.textContent = e.message;
    }
  };
}

async function loadProfile(uid) {
  const ref = doc(db, "users", uid);
  const snap = await getDoc(ref);
  if (!snap.exists()) return null;
  return snap.data();
}

function renderOnboarding(uid) {
  appRoot.innerHTML = `
    ${renderTopControls()}
    <section class="card">
      <h2>${t("welcome")}</h2>
      <p class="muted">${t("onboardingHint")}</p>
      <input id="name" placeholder="${t("displayName")}" />
      <input id="startDate" type="date" />
      <button id="saveProfile">${t("continue")}</button>
    </section>
  `;
  bindTopControls(() => renderOnboarding(uid));
  document.getElementById("saveProfile").onclick = async () => {
    const name = document.getElementById("name").value.trim();
    const startDate = document.getElementById("startDate").value;
    if (!name || !startDate) return;
    await setDoc(doc(db, "users", uid), {
      name,
      soberSince: startDate,
      lastCommunityCheckinDay: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
  };
}

async function getTodayCheckins() {
  const q = query(collection(db, "communityCheckins"), where("day", "==", utcDay()));
  const snap = await getDocs(q);
  return snap.size;
}

function checkinDocId(uid, day) {
  return `${uid}_${day}`;
}

async function hasCheckedInToday(uid, profile) {
  const day = utcDay();
  if (profile?.lastCommunityCheckinDay === day) return true;
  const ref = doc(db, "communityCheckins", checkinDocId(uid, day));
  const snap = await getDoc(ref);
  return snap.exists();
}

async function checkIn(uid) {
  const day = utcDay();
  const existingByQuery = await getDocs(
    query(collection(db, "communityCheckins"), where("userId", "==", uid), where("day", "==", day))
  );
  if (!existingByQuery.empty) return false;

  const ref = doc(db, "communityCheckins", checkinDocId(uid, day));
  const existing = await getDoc(ref);
  if (existing.exists()) return false;

  await setDoc(ref, {
    userId: uid,
    day,
    createdAt: new Date().toISOString()
  });

  await updateDoc(doc(db, "users", uid), {
    lastCommunityCheckinDay: day,
    updatedAt: new Date().toISOString()
  });

  return true;
}

async function addRelapse(uid) {
  await addDoc(collection(db, "relapseEvents"), {
    userId: uid,
    occurredAt: new Date().toISOString()
  });
}

function last7Days() {
  const out = [];
  for (let i = 0; i < 7; i += 1) {
    const d = new Date();
    d.setUTCDate(d.getUTCDate() - i);
    out.push(d.toISOString().slice(0, 10));
  }
  return out;
}

async function getStats(uid, profile) {
  const relapseSnap = await getDocs(query(collection(db, "relapseEvents"), where("userId", "==", uid)));
  const checkinSnap = await getDocs(query(collection(db, "communityCheckins"), where("userId", "==", uid)));

  const relapseDates = relapseSnap.docs
    .map((docSnap) => docSnap.data()?.occurredAt)
    .filter(Boolean)
    .map((iso) => new Date(iso))
    .sort((a, b) => a.getTime() - b.getTime());

  const now = new Date();
  let cursor = new Date(profile.soberSince);
  let bestStreak = Math.max(0, Math.floor((now.getTime() - cursor.getTime()) / 86400000));
  for (const relapseDate of relapseDates) {
    const streak = Math.max(0, Math.floor((relapseDate.getTime() - cursor.getTime()) / 86400000));
    bestStreak = Math.max(bestStreak, streak);
    cursor = relapseDate;
  }

  const daysSet = new Set(last7Days());
  const checkins7d = checkinSnap.docs.reduce((acc, docSnap) => {
    const day = docSnap.data()?.day;
    return day && daysSet.has(day) ? acc + 1 : acc;
  }, 0);

  return {
    currentStreak: daysSince(profile.soberSince),
    bestStreak,
    relapses: relapseSnap.size,
    checkins7d
  };
}

async function renderHome(uid, profile) {
  const isCloudSource = navigator.onLine;
  const sourceMode = isCloudSource ? t("sourceCloud") : t("sourceFallback");
  const dotClass = isCloudSource ? "dot cloud" : "dot local";
  const todayCheckins = await getTodayCheckins();
  const checkedInToday = await hasCheckedInToday(uid, profile);
  const streak = daysSince(profile.soberSince);

  appRoot.innerHTML = `
    ${renderTopControls()}
    <section class="card">
      <div class="badge"><span class="${dotClass}"></span>${sourceMode}</div>
      <h2>${t("hello")}, ${profile.name}</h2>
      <p>${t("currentStreak")}: <strong>${streak} ${t("days")}</strong></p>
      <p class="muted">${t("soberSince")} ${profile.soberSince}</p>
    </section>
    <section class="card">
      <h3>${t("communityTitle")}</h3>
      <p class="muted">${t("communitySubtitle")}</p>
      <button id="checkinBtn" ${checkedInToday ? "disabled" : ""}>
        ${checkedInToday ? t("checkedInToday") : t("anonymousCheckin")}
      </button>
      <p>${t("todayCheckedIn", { count: todayCheckins })}</p>
    </section>
    <section class="card">
      <h3>${t("emergencyReset")}</h3>
      <button id="relapseBtn" class="sos">${t("relapsed")}</button>
    </section>
    <section class="card">
      <button id="logoutBtn" class="secondary">${t("signOut")}</button>
    </section>
    ${renderBottomTabs()}
  `;
  document.getElementById("tabHomeBtn").onclick = async () => {
    activeTab = "home";
    const refreshed = await loadProfile(uid);
    await renderHome(uid, refreshed);
  };
  document.getElementById("tabStatsBtn").onclick = async () => {
    activeTab = "stats";
    const refreshed = await loadProfile(uid);
    await renderHome(uid, refreshed);
  };
  bindTopControls(async () => {
    const refreshed = await loadProfile(uid);
    await renderHome(uid, refreshed);
  });

  if (activeTab === "stats") {
    const stats = await getStats(uid, profile);
    appRoot.innerHTML = `
      ${renderTopControls()}
      <section class="card">
        <h3>${t("statsTitle")}</h3>
        <p>${t("statsCurrentStreak")}: <strong>${stats.currentStreak} ${t("days")}</strong></p>
        <p>${t("statsBestStreak")}: <strong>${stats.bestStreak} ${t("days")}</strong></p>
        <p>${t("statsRelapses")}: <strong>${stats.relapses}</strong></p>
        <p>${t("statsCheckins7d")}: <strong>${stats.checkins7d}</strong></p>
      </section>
      ${renderBottomTabs()}
    `;
    document.getElementById("tabHomeBtn").onclick = async () => {
      activeTab = "home";
      const refreshed = await loadProfile(uid);
      await renderHome(uid, refreshed);
    };
    document.getElementById("tabStatsBtn").onclick = async () => {
      activeTab = "stats";
      const refreshed = await loadProfile(uid);
      await renderHome(uid, refreshed);
    };
    bindTopControls(async () => {
      const refreshed = await loadProfile(uid);
      await renderHome(uid, refreshed);
    });
    return;
  }

  if (!checkedInToday) {
    document.getElementById("checkinBtn").onclick = async () => {
      if (checkinInFlight) return;
      checkinInFlight = true;

      const button = document.getElementById("checkinBtn");
      button.disabled = true;
      button.textContent = t("checkedInToday");

      try {
        await checkIn(uid);
        const updatedProfile = await loadProfile(uid);
        await renderHome(uid, updatedProfile);
      } finally {
        checkinInFlight = false;
      }
    };
  }

  document.getElementById("relapseBtn").onclick = async () => {
    await addRelapse(uid);
    await updateDoc(doc(db, "users", uid), { soberSince: utcDay(), updatedAt: new Date().toISOString() });
    const updated = await loadProfile(uid);
    await renderHome(uid, updated);
  };

  document.getElementById("logoutBtn").onclick = async () => {
    await signOut(auth);
  };
}

onAuthStateChanged(auth, async (user) => {
  applyTheme();
  if (!user) {
    renderAuth();
    return;
  }
  const profile = await loadProfile(user.uid);
  if (!profile) {
    renderOnboarding(user.uid);
    return;
  }
  await renderHome(user.uid, profile);
});
