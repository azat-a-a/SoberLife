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
import { getFunctions, httpsCallable } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-functions.js";
import { firebaseWebConfig, firebaseFunctionsRegion } from "/firebase-config.js";

const appRoot = document.getElementById("app");
const firebaseApp = initializeApp(firebaseWebConfig);
const auth = getAuth(firebaseApp);
const db = getFirestore(firebaseApp);
const functionsClient = getFunctions(firebaseApp, firebaseFunctionsRegion || "europe-west1");
let checkinInFlight = false;
let activeTab = "home";
let currentTheme = detectInitialTheme();
let sosScreenOpen = false;
let sosMessages = [];
let sosSending = false;

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
    themeDark: "Dark",
    sosButton: "SOS — I might relapse",
    sosTitle: "SOS support",
    sosBack: "Back",
    sosDisclaimer:
      "This chat is not emergency care. If you may harm yourself or someone else, contact local emergency services or a crisis hotline right away.",
    sosPlaceholder: "What is happening right now? A few words are enough.",
    sosSend: "Send",
    sosThinking: "Thinking…",
    sosIntro:
      "I am here with you — opening this screen took courage. Before we talk, take one slow exhale, longer than your inhale. When you are ready, tell me what you notice: the urge, thoughts, tension, or situation. I will stay with you.",
    sosErrorGeneric: "The assistant is temporarily unavailable. Wait a moment and try again.",
    sosErrorOffline: "You appear to be offline. Connect to the internet to use the assistant.",
    sosAriaThread: "Chat messages",
    sosErrorRegionHint:
      "SOS cloud function was not found. Check that firebaseFunctionsRegion in firebase-config.js matches \"region\" in functions/index.js, then run: firebase deploy --only functions && firebase deploy --only hosting.",
    sosErrorSecretHint:
      "Server is missing the DeepSeek key. Run: firebase functions:secrets:set DEEPSEEK_API_KEY then firebase deploy --only functions."
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
    themeDark: "Тёмная",
    sosButton: "SOS — могу сорваться",
    sosTitle: "Поддержка SOS",
    sosBack: "Назад",
    sosDisclaimer:
      "Это не скорая помощь. Если есть риск для жизни или здоровья — срочно звоните в экстренные службы или на линию кризисной помощи.",
    sosPlaceholder: "Что происходит прямо сейчас? Достаточно пары слов.",
    sosSend: "Отправить",
    sosThinking: "Думаю…",
    sosIntro:
      "Я рядом — то, что вы открыли этот экран, уже шаг заботы о себе. Сначала сделайте одно медленное выдыхание, чуть длиннее вдоха. Когда будете готовы, напишите, что замечаете: тягу, мысли, напряжение или ситуацию.",
    sosErrorGeneric: "Помощник сейчас недоступен. Попробуйте ещё раз через минуту.",
    sosErrorOffline: "Нет подключения к интернету — нужна сеть, чтобы связаться с ассистентом.",
    sosAriaThread: "Сообщения чата",
    sosErrorRegionHint:
      "Не найдена облачная функция SOS. Проверьте: firebaseFunctionsRegion в firebase-config.js должен совпадать с region в functions/index.js, затем: firebase deploy --only functions и firebase deploy --only hosting.",
    sosErrorSecretHint:
      "На сервере нет ключа DeepSeek: firebase functions:secrets:set DEEPSEEK_API_KEY и снова firebase deploy --only functions."
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
    themeDark: "Dunkel",
    sosButton: "SOS — drohender Rückfall",
    sosTitle: "SOS-Unterstützung",
    sosBack: "Zurück",
    sosDisclaimer:
      "Dieser Chat ersetzt keine Notfallversorgung. Bei akuter Gefahr wählen Sie bitte einen Notruf oder eine Krisenhotline.",
    sosPlaceholder: "Was passiert gerade? Ein paar Worte genügen.",
    sosSend: "Senden",
    sosThinking: "Denke nach …",
    sosIntro:
      "Ich bin bei dir — diesen Bildschirm zu öffnen, war bereits ein Schritt der Selbstfürsorge. Mach zuerst ein langsames Ausatmen, etwas länger als das Einatmen. Wenn du soweit bist: Was bemerkst du zuerst—Drang, Gedanken, Anspannung oder die Situation?",
    sosErrorGeneric: "Assistent vorübergehend nicht erreichbar. Bitte kurz warten und erneut versuchen.",
    sosErrorOffline: "Du scheinst offline zu sein. Für den Assistenten ist Internetverbindung nötig.",
    sosAriaThread: "Chatnachrichten"
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
    themeDark: "Oscuro",
    sosButton: "SOS — puedo recaer",
    sosTitle: "Apoyo SOS",
    sosBack: "Volver",
    sosDisclaimer:
      "Este chat no es emergencia. Si hay peligro inmediato, llama a servicios de urgencia o una línea de crisis.",
    sosPlaceholder: "¿Qué está pasando ahora? Con unas palabras basta.",
    sosSend: "Enviar",
    sosThinking: "Pensando…",
    sosIntro:
      "Estoy contigo — abrir esta pantalla ya es un gesto de cuidado. Primero exhala más lento y un poco más largo que al inhalar. Cuando puedas, escribe qué notas primero: el antojo, pensamientos, tensión o la situación.",
    sosErrorGeneric: "El asistente no está disponible por ahora. Espera un momento e inténtalo otra vez.",
    sosErrorOffline: "Parece que estás sin conexión. Hace falta internet para usar el asistente.",
    sosAriaThread: "Mensajes del chat"
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
    themeDark: "Sombre",
    sosButton: "SOS — risque de rechute",
    sosTitle: "Soutien SOS",
    sosBack: "Retour",
    sosDisclaimer:
      "Ce chat n’est pas un service d’urgence. En danger immédiat, contactez les secours ou une ligne de crise.",
    sosPlaceholder: "Qu’est-ce qui se passe maintenant ? Quelques mots suffisent.",
    sosSend: "Envoyer",
    sosThinking: "Réflexion…",
    sosIntro:
      "Je suis là avec vous — ouvrir cet écran est déjà un acte de soin. Respirez lentement : l’expiration un peu plus longue que l’inspiration. Quand vous êtes prêt·e : qu’est-ce que vous remarquez en premier — l’envie, les pensées, la tension ou la situation ?",
    sosErrorGeneric: "L’assistant est momentanément indisponible. Réessayez dans un instant.",
    sosErrorOffline: "Vous semblez hors ligne ; Internet est nécessaire pour joindre l’assistant.",
    sosAriaThread: "Messages du chat"
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
    themeDark: "Scuro",
    sosButton: "SOS — rischio di ricaduta",
    sosTitle: "Supporto SOS",
    sosBack: "Indietro",
    sosDisclaimer:
      "Questa chat non è emergenza. Se c’è pericolo immediato, contatta i servizi di emergenza o una linea di crisi.",
    sosPlaceholder: "Cosa sta succedendo ora? Bastano poche parole.",
    sosSend: "Invia",
    sosThinking: "Sto pensando…",
    sosIntro:
      "Sono qui con te — aprire questa schermata è già cura di te. Fai prima un lungo espira, più lungo dell’inspira. Quando sei pronto: cosa noti per prima cosa — voglia, pensieri, tensione o la situazione?",
    sosErrorGeneric: "L’assistente non è disponibile al momento. Riprova tra poco.",
    sosErrorOffline: "Sembri offline: serve internet per usare l’assistente.",
    sosAriaThread: "Messaggi della chat"
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
    themeDark: "ダーク",
    sosButton: "SOS — 再飲酒しそう",
    sosTitle: "SOSサポート",
    sosBack: "戻る",
    sosDisclaimer:
      "このチャットは緊急対応ではありません。生命や安全の危険がある場合は、すぐに救急・警察・いのちの電話などに連絡してください。",
    sosPlaceholder: "今、何が起きていますか？短くて大丈夫です。",
    sosSend: "送信",
    sosThinking: "考えています…",
    sosIntro:
      "ここにいます。この画面を開けただけでも、自分を守ろうとする力です。まずは、吸う息より長く、ゆっくり吐き出しましょう。よくなったら、いま強いものは何ですか――衝動、考え、体の張り、状況、どれでしょう。",
    sosErrorGeneric: "アシスタントに接続できませんでした。少ししてから再度お試しください。",
    sosErrorOffline: "オフラインのようです。アシスタントにはインターネットが必要です。",
    sosAriaThread: "チャット"
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
    themeDark: "Ciemny",
    sosButton: "SOS — zbliżam się do nawrotu",
    sosTitle: "Wsparcie SOS",
    sosBack: "Wstecz",
    sosDisclaimer:
      "To nie jest pogotowie. Jeśli jest realne ryzyko dla życia lub zdrowia — zadzwoń na numer alarmowy lub linię wsparcia.",
    sosPlaceholder: "Co dzieje się teraz? Wystarczą kilka słów.",
    sosSend: "Wyślij",
    sosThinking: "Myślę…",
    sosIntro:
      "Jestem przy Tobie — sam fakt otwarcia tego ekranu to już dbanie o siebie. Najpierw zrób wolny wydech trochę dłuższy niż wdech. Jak będziesz gotowa/gotowy: co najpierw zauważasz — pokusę, myśli, napięcie czy sytuację?",
    sosErrorGeneric: "Asystent jest chwilowo niedostępny. Spróbuj ponownie za chwilę.",
    sosErrorOffline: "Wygląda na to, że jesteś offline — potrzebny jest internet.",
    sosAriaThread: "Wiadomości czatu"
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
    themeDark: "มืด",
    sosButton: "SOS — ใกล้จะถอยหลัง",
    sosTitle: "ช่วยเหลือฉุกเฉิน",
    sosBack: "กลับ",
    sosDisclaimer:
      "แชทนี้ไม่ใช่บริการฉุกเฉิน หากอยู่ในภาวะไม่ปลอดภัย โปรดติดต่อหน่วยกู้ภัยหรือสายด่วนวิกฤต",
    sosPlaceholder: "ตอนนี้เกิดอะไรขึ้น? พิมพ์สั้นๆ ได้",
    sosSend: "ส่ง",
    sosThinking: "กำลังคิด…",
    sosIntro:
      "เราอยู่ตรงนี้ — การเปิดหน้าจอนี้เป็นการดูแลตัวเองแล้ว หายใจออกช้าๆ ให้ยาวกว่าการหายใจเข้า เมื่อพร้อม บอกสิ่งที่สังเกตก่อนคิดถึง — ความอยาก ความคิด ความตึง หรือสถานการณ์",
    sosErrorGeneric: "ผู้ช่วยใช้งานไม่ได้ชั่วคราว โปรดลองอีกครั้งในเมื่อครู่",
    sosErrorOffline: "ขณะนี้ออฟไลน์ ต้องใช้อินเทอร์เน็ตเพื่อพูดกับผู้ช่วย",
    sosAriaThread: "ข้อความการสนทนา"
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
    themeDark: "深色",
    sosButton: "SOS — 我可能坚持不住",
    sosTitle: "紧急支持",
    sosBack: "返回",
    sosDisclaimer:
      "此对话不能替代急救。如有立即危险，请拨打当地急救或心理危机热线。",
    sosPlaceholder: "此刻发生了什么？简短描述即可。",
    sosSend: "发送",
    sosThinking: "思考中…",
    sosIntro:
      "我在这里。你能打开这个页面，已经是自我照顾的一步。先慢慢呼气，让呼气比吸气更长一些。准备好后，请告诉我你最先注意到的是：冲动、想法、身体紧张，还是情境？",
    sosErrorGeneric: "助手暂时不可用，请稍后再试。",
    sosErrorOffline: "当前似乎离线，使用助手需要网络连接。",
    sosAriaThread: "聊天消息"
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

function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

function sosThreadMarkup() {
  return sosMessages
    .map(
      (m) =>
        `<div class="msg msg--${m.role === "user" ? "user" : "assistant"}" aria-live="polite">${escapeHtml(
          m.content
        )}</div>`
    )
    .join("");
}

function scrollSosThreadBottom() {
  const el = document.getElementById("sosThread");
  if (el) requestAnimationFrame(() => (el.scrollTop = el.scrollHeight));
}

async function openSOSAssistant(uid, profile) {
  sosScreenOpen = true;
  sosMessages = [{ role: "assistant", content: t("sosIntro") }];
  const fresh = await loadProfile(uid);
  await renderHome(uid, fresh || profile);
}

function formatSOSCallableError(err) {
  const code = err?.code || "";
  const msg = String(err?.message || "").trim();

  console.error("[SOS sosDeepseekChat]", code, msg, err);

  if (code === "functions/not-found" || code === "not-found" || /NOT_FOUND/i.test(msg)) {
    return `${t("sosErrorRegionHint")}`;
  }

  if (code === "failed-precondition") {
    if (/missing api key/i.test(msg) || /not configured/i.test(msg)) {
      return t("sosErrorSecretHint");
    }
    return msg || t("sosErrorGeneric");
  }

  if (code === "unauthenticated") {
    return msg || t("sosErrorGeneric");
  }

  if (msg.length > 15 && msg.length < 720 && code !== "functions/internal") {
    return msg;
  }

  return t("sosErrorGeneric");
}

function renderSOSScreen(uid, profile) {
  appRoot.innerHTML = `
    ${renderTopControls()}
    <section class="card sos-hero">
      <button type="button" id="sosBack" class="secondary sos-back">${t("sosBack")}</button>
      <h2>${t("sosTitle")}</h2>
      <p class="muted sos-disclaimer">${t("sosDisclaimer")}</p>
    </section>
    <div id="sosThread" class="sos-thread card" tabindex="0" role="log" aria-label="${escapeHtml(t("sosAriaThread"))}">
      ${sosThreadMarkup()}
      ${
        sosSending
          ? `<div class="msg msg--assistant sos-typing"><span>${escapeHtml(t("sosThinking"))}</span></div>`
          : ""
      }
    </div>
    <section class="card sos-composer">
      <textarea id="sosInput" rows="3" ${sosSending ? "disabled" : ""}></textarea>
      <button type="button" id="sosSendBtn" class="${sosSending ? "secondary" : ""}" ${sosSending ? "disabled" : ""}>
        ${t("sosSend")}
      </button>
    </section>
  `;

  const input = document.getElementById("sosInput");
  if (input) input.placeholder = t("sosPlaceholder");

  document.getElementById("sosBack").onclick = async () => {
    sosSending = false;
    sosScreenOpen = false;
    const fresh = await loadProfile(uid);
    await renderHome(uid, fresh || profile);
  };

  bindTopControls(() => renderSOSScreen(uid, profile));

  const sendChat = async () => {
    if (sosSending) return;
    const text = document.getElementById("sosInput")?.value?.trim().slice(0, 4000);
    if (!text) return;
    if (!navigator.onLine) {
      sosMessages.push({ role: "assistant", content: t("sosErrorOffline") });
      renderSOSScreen(uid, profile);
      return;
    }
    sosMessages.push({ role: "user", content: text });
    sosSending = true;
    renderSOSScreen(uid, profile);

    try {
      const sosFn = httpsCallable(functionsClient, "sosDeepseekChat", { timeout: 150000 });
      const result = await sosFn({ messages: sosMessages, locale: currentLanguage });
      const reply = result.data?.reply;
      if (reply) sosMessages.push({ role: "assistant", content: reply });
      else sosMessages.push({ role: "assistant", content: t("sosErrorGeneric") });
    } catch (err) {
      sosMessages.push({ role: "assistant", content: formatSOSCallableError(err) });
    } finally {
      sosSending = false;
      renderSOSScreen(uid, profile);
      scrollSosThreadBottom();
    }
  };

  document.getElementById("sosSendBtn").onclick = () => sendChat();
  const ta = document.getElementById("sosInput");
  if (ta) {
    ta.onkeydown = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "Enter") sendChat();
    };
    if (!sosSending) ta.focus();
  }

  scrollSosThreadBottom();
}

async function renderHome(uid, profile) {
  const isCloudSource = navigator.onLine;
  const sourceMode = isCloudSource ? t("sourceCloud") : t("sourceFallback");
  const dotClass = isCloudSource ? "dot cloud" : "dot local";
  const todayCheckins = await getTodayCheckins();
  const checkedInToday = await hasCheckedInToday(uid, profile);
  const streak = daysSince(profile.soberSince);

  if (sosScreenOpen) {
    renderSOSScreen(uid, profile);
    return;
  }

  appRoot.innerHTML = `
    ${renderTopControls()}
    <section class="card">
      <div class="badge"><span class="${dotClass}"></span>${sourceMode}</div>
      <h2>${t("hello")}, ${profile.name}</h2>
      <p>${t("currentStreak")}: <strong>${streak} ${t("days")}</strong></p>
      <p class="muted">${t("soberSince")} ${profile.soberSince}</p>
    </section>
    <section class="card sos-gate-card">
      <button type="button" id="openSOSBtn" class="sos sos-open">${t("sosButton")}</button>
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
      <section class="card">
        <button type="button" id="openSOSFromStatsBtn" class="sos sos-open">${t("sosButton")}</button>
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
    document.getElementById("openSOSFromStatsBtn").onclick = async () => openSOSAssistant(uid, profile);
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

  document.getElementById("openSOSBtn").onclick = async () => openSOSAssistant(uid, profile);
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
