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
    <section class="card">
      <h1>SoberLife</h1>
      <p class="muted">PWA + Firebase</p>
      <input id="email" type="email" placeholder="Email" />
      <input id="password" type="password" placeholder="Password" />
      <div class="row">
        <button id="loginBtn">Sign in</button>
        <button id="registerBtn" class="secondary">Create account</button>
      </div>
      <p id="authError" class="muted"></p>
    </section>
  `;

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
    <section class="card">
      <h2>Welcome</h2>
      <p class="muted">Create your baseline profile.</p>
      <input id="name" placeholder="Display name" />
      <input id="startDate" type="date" />
      <button id="saveProfile">Continue</button>
    </section>
  `;
  document.getElementById("saveProfile").onclick = async () => {
    const name = document.getElementById("name").value.trim();
    const startDate = document.getElementById("startDate").value;
    if (!name || !startDate) return;
    await setDoc(doc(db, "users", uid), {
      name,
      soberSince: startDate,
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

async function hasCheckedInToday(uid) {
  const day = utcDay();
  const ref = doc(db, "communityCheckins", checkinDocId(uid, day));
  const snap = await getDoc(ref);
  return snap.exists();
}

async function checkIn(uid) {
  const day = utcDay();
  const ref = doc(db, "communityCheckins", checkinDocId(uid, day));
  const existing = await getDoc(ref);
  if (existing.exists()) return false;

  await setDoc(ref, {
    userId: uid,
    day,
    createdAt: new Date().toISOString()
  });
  return true;
}

async function addRelapse(uid) {
  await addDoc(collection(db, "relapseEvents"), {
    userId: uid,
    occurredAt: new Date().toISOString()
  });
}

async function renderHome(uid, profile) {
  const sourceMode = navigator.onLine ? "cloud" : "fallback";
  const dotClass = sourceMode === "cloud" ? "dot cloud" : "dot local";
  const todayCheckins = await getTodayCheckins();
  const checkedInToday = await hasCheckedInToday(uid);
  const streak = daysSince(profile.soberSince);

  appRoot.innerHTML = `
    <section class="card">
      <div class="badge"><span class="${dotClass}"></span>${sourceMode}</div>
      <h2>Hello, ${profile.name}</h2>
      <p>Current streak: <strong>${streak} days</strong></p>
      <p class="muted">Sober since ${profile.soberSince}</p>
    </section>
    <section class="card">
      <h3>Community</h3>
      <p class="muted">Stay anonymous, feel together.</p>
      <button id="checkinBtn" ${checkedInToday ? "disabled" : ""}>
        ${checkedInToday ? "Checked in today" : "Anonymous check-in"}
      </button>
      <p>Today: ${todayCheckins} people checked in</p>
    </section>
    <section class="card">
      <h3>Emergency reset</h3>
      <button id="relapseBtn" class="sos">I relapsed</button>
    </section>
    <section class="card">
      <button id="logoutBtn" class="secondary">Sign out</button>
    </section>
  `;

  if (!checkedInToday) {
    document.getElementById("checkinBtn").onclick = async () => {
      await checkIn(uid);
      const updatedProfile = await loadProfile(uid);
      await renderHome(uid, updatedProfile);
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
