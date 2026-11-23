// Personen-Simulation für Kompass. Läuft im Browser-Kontext der App (page.evaluate).
// Nutzt die echten App-Funktionen und rechnet alle angezeigten Zahlen unabhängig nach.
window.__runSim = function (personaName, startISO, days, opts = {}) {
  sug = null;
  const views0 = ['heute', 'kalender', 'habits', 'ziele', 'rueckblick'];
  const findings = [];
  const flag = (check, date, detail) => findings.push({ persona: personaName, check, date, detail });
  // --- deterministischer Zufall
  let seed = [...personaName].reduce((a, c) => a * 31 + c.charCodeAt(0), 7) >>> 0;
  const rnd = () => { seed |= 0; seed = (seed + 0x6D2B79F5) | 0; let t = Math.imul(seed ^ (seed >>> 15), 1 | seed); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  const pick = a => a[Math.floor(rnd() * a.length)];
  const [Y, M, D] = startISO.split('-').map(Number);
  const R = window.__realDate;
  const at = (dayIdx, h, m = 0) => new R(Y, M - 1, D + dayIdx, h, m).getTime();
  const setNow = (dayIdx, h, m = 0) => { window.__NOW = at(dayIdx, h, m); };
  // --- unabhängige Referenz-Rechnungen (bewusst anders implementiert als die App)
  const keyOf = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const dayList = (fromKey, toKey) => { const out = []; let d = pd(fromKey); while (keyOf(d) <= toKey) { out.push(new Date(d)); d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1); } return out; };
  const isDue = (h, d) => h.days.includes(d.getDay() === 0 ? 7 : d.getDay());
  function refStreak(h) { const T = today(); const ds = dayList(h.created, T).reverse(); let s = 0; for (const d of ds) { const k = keyOf(d); if (!isDue(h, d)) continue; if (h.log[k]) s++; else if (k === T) continue; else break; } return s; }
  function refBest(h) { let b = 0, c = 0; const T = today(); for (const d of dayList(h.created, T)) { if (!isDue(h, d)) continue; const k = keyOf(d); if (h.log[k]) { c++; b = Math.max(b, c); } else if (k !== T) c = 0; } return b; }
  function refRate(h, n = 30) { const T = today(); let due = 0, done = 0; for (let i = 0; i < n; i++) { const d = new Date(pd(T).getFullYear(), pd(T).getMonth(), pd(T).getDate() - i); const k = keyOf(d); if (k < h.created || !isDue(h, d)) continue; if (k === T && !h.log[k]) continue; due++; if (h.log[k]) done++; } return due ? done / due : 0; }
  function refIsoWeek(d) { // Donnerstag-Regel, andere Implementierung
    const day = (d.getDay() + 6) % 7; const thu = new Date(d.getFullYear(), d.getMonth(), d.getDate() - day + 3);
    const firstThu = new Date(thu.getFullYear(), 0, 4); const fday = (firstThu.getDay() + 6) % 7; const w1 = new Date(firstThu.getFullYear(), 0, 4 - fday + 3);
    return 1 + Math.round((thu - w1) / (7 * 864e5));
  }
  // Referenz-Rechnung, bewusst eigenständig geschrieben (nicht aus der App kopiert)
  function refStep(st) { if (st.done) return 1; const k = ['auto', 'time', 'habit', 'number'].includes(st.kind) ? st.kind : 'auto'; let p;
    if (k === 'auto') { const ts = S.tasks.filter(t => t.stepId === st.id && (!t.repeat || t.repeat === 'nie')); p = ts.length ? 0.9 * ts.filter(t => t.done).length / ts.length : 0; }
    else if (k === 'time') { let ms = 0; for (const x of S.sessions) if (x.stepId === st.id) ms += x.ms; p = (+st.target > 0) ? ms / 3600000 / (+st.target) : 0; }
    else if (k === 'habit') { const h = S.habits.find(x => x.id === st.habitId); const T = today(); p = (h && +st.target > 0) ? Object.keys(h.log).filter(d => h.log[d] && d >= (st.since || '') && d <= T).length / (+st.target) : 0; }
    else { const a = +st.start || 0, c = +st.current || 0, t = +st.target || 0; p = t === a ? (c === t ? 1 : 0) : (c - a) / (t - a); }
    return Math.min(1, Math.max(0, Number.isFinite(p) ? p : 0)); }
  function refProgress(g) { if (g.status === 'erreicht') return 1; const m = g.metric || {}; if (m.type === 'number') { const a = +m.start || 0, c = +m.current || 0, t = +m.target; if (t === a) return c === t ? 1 : 0; return Math.min(1, Math.max(0, (c - a) / (t - a))); }
    let W = 0, P = 0; for (const st of g.milestones || []) { const w = [1, 2, 3].includes(+st.weight) ? +st.weight : 1; W += w; P += w * refStep(st); } return W ? P / W : 0; }
  const realSessions = []; // was wirklich gearbeitet wurde, sauber nach Kalendertag aufgeteilt
  function logReal(goalId, fromMs, toMs, stepId) { let a = fromMs; while (a < toMs) { const d = new R(a); const next = new R(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime(); const b = Math.min(toMs, next); realSessions.push({ goalId, stepId: stepId || null, date: keyOf(new Date(a)), ms: b - a }); a = b; } }

  // --- leerer Start, wie ein neuer Nutzer
  setNow(0, 7);
  S = migrate({ v: 1, goals: [], habits: [], tasks: [], sessions: [], reflections: {}, eventLinks: {}, cals: { google: true, apple: true }, settings: {}, timer: null, updated: Date.now() });
  const T0 = today();
  for (const v of views0) { route = v; try { render(); const tx = document.getElementById('view').innerText; if (/NaN|undefined|Infinity/.test(tx)) flag('Leerer Start: kaputter Text', T0, v); } catch (e) { flag('Leerer Start: Absturz', T0, v + ': ' + e.message); } }
  const P = opts.persona;
  const mkGoal = (g) => { const o = { id: uid(), color: COLORS[S.goals.length], icon: 'star', status: 'aktiv', created: today(), milestones: [], why: '', cat: '', ...g }; S.goals.push(o); return o; };
  const mkHabit = (h) => { const o = { id: uid(), color: COLORS[(S.habits.length + 3) % COLORS.length], icon: 'star', goalId: null, log: {}, created: today(), ...h }; S.habits.push(o); return o; };
  const ctx = { mkGoal, mkHabit, rnd, pick, S: () => S };
  const persona = eval('(' + P + ')')(ctx);

  const views = views0;
  let renderMs = {};
  let maxRunning = 0;
  for (let i = 0; i < days; i++) {
    setNow(i, 6, 30);
    const T = today();
    if (i % 10 === 0 || false) console.log('simday', i, T, JSON.stringify(S).length, S.tasks.length, Math.round(performance.memory.usedJSHeapSize/1e6)+'MB', document.getElementsByTagName('*').length, document.querySelectorAll('.toast,.dragghost').length);
    const dt = pd(T);
    // Ereignisse aus dem Kalender einem Ziel zuordnen (wie ein Nutzer: jeden Termin einzeln antippen)
    if (persona.linkEvents && i < 7) for (const e of eventsForDate(T)) { const g = persona.linkEvents(e); if (g && !e.allDay && !S.eventLinks[seriesOf(e)]) { S.eventLinks[seriesOf(e)] = { goalId: g.id, since: T }; persona._links = (persona._links || []).concat([{ k: seriesOf(e), g, since: T }]); } }
    // Tagesablauf
    const plan = persona.day(i, dt, rnd);
    for (const t of plan.tasks) { const task = addTask(t.title, t.inbox ? null : T, t.goal ? 'hoch' : 'normal', t.goal ? t.goal.id : null, 'bottom'); if (t.time) task.time = t.time; if (t.repeat) task.repeat = t.repeat; t.ref = task; }
    for (const w of plan.work) {
      const task = w.task.ref; if (!task || task.done) continue;
      setNow(i, w.h, w.m || 0); startTimer(task.id);
      if (w.pauseAfter) { setNow(i, w.h, (w.m || 0) + w.pauseAfter); pauseTimer(); setNow(i, w.h, (w.m || 0) + w.pauseAfter + 20); startTimer(task.id); }
      const endMs = at(i, w.h, (w.m || 0) + w.dur + (w.pauseAfter ? 20 : 0));
      if (w.forget) { logReal(task.goalId, window.__NOW, window.__NOW + 4 * 3600e3, task.stepId); persona._forgot = { task, endDay: i + w.forget }; continue; }
      window.__NOW = endMs; const before = S.sessions.length; stopTimer(); const s = S.sessions[S.sessions.length - 1];
      if (S.sessions.length > before) logReal(task.goalId, at(i, w.h, w.m || 0), endMs - (w.pauseAfter ? 20 * 60e3 : 0), task.stepId);
      if (w.done !== false) { completeTask(task); }
      if (S.sessions.length - before > 0) { const added = S.sessions.slice(before).reduce((a, x) => a + x.ms, 0); if (added > 4 * 3600e3) flag('Einzelne Fokus-Sitzung über 4 h gebucht', T, Math.round(added / 36e5) + ' h'); }
    }
    if (persona._forgot && persona._forgot.endDay === i) { setNow(i, 20); const f = persona._forgot; const before = S.sessions.length; stopTimer(); const s = S.sessions[S.sessions.length - 1]; if (S.sessions.length > before && s.ms > 12 * 3600e3) flag('Vergessener Timer zählt unbegrenzt', T, `Timer ${Math.round(s.ms / 3600e3)} h am Stück gebucht`); persona._forgot = null; }
    // Habits abends
    setNow(i, 21, 30);
    for (const h of S.habits) { if (isDue(h, dt) && rnd() < persona.habitP(h, i)) h.log[T] = 1; }
    if (persona.evening) persona.evening(i, dt, T);
    // Wochenreflexion sonntags
    if (dt.getDay() === 0 && rnd() < 0.7) S.reflections['woche:' + ymd(monday(dt))] = { fortschritt: 'ok', saved: Date.now() };
    // Laufender Timer über Mitternacht (Nachtmensch)
    if (plan.night) { const task = addTask(plan.night.title, T, 'hoch', plan.night.goal.id); setNow(i, 23, 0); startTimer(task.id); window.__NOW = at(i + 1, 1, 30); stopTimer(); completeTask(task); logReal(task.goalId, at(i, 23), at(i + 1, 1, 30), task.stepId); }

    // ---------- Prüfungen ----------
    setNow(i, 22, 0);
    checkForgottenTimer(); // so tickt die App im Hintergrund jede Sekunde
    if (S.timer) { const run = curTimerMs(); maxRunning = Math.max(maxRunning, run); }
    // ISO-Kalenderwoche
    if (kw(dt) !== refIsoWeek(dt)) flag('Kalenderwoche falsch', T, `App KW ${kw(dt)} statt ${refIsoWeek(dt)}`);
    // Habits
    for (const h of S.habits) {
      const a = habitStreak(h), b = refStreak(h); if (a !== b) flag('Habit-Serie falsch', T, `${h.title}: App ${a}, richtig ${b}`);
      const c = habitBest(h), d = refBest(h); if (c !== d) flag('Beste Serie falsch', T, `${h.title}: App ${c}, richtig ${d}`);
      const e = Math.round(habitRate(h) * 100), f = Math.round(refRate(h) * 100); if (Math.abs(e - f) > 0) flag('Habit-Quote 30 Tage falsch', T, `${h.title}: App ${e} %, richtig ${f} %`);
    }
    // Ziele
    for (const g of S.goals) { const a = goalProgress(g), b = refProgress(g); if (!isFinite(a) || Math.abs(a - b) > 1e-9) flag('Ziel-Fortschritt falsch', T, `${g.title}: App ${a}, richtig ${b}`); if (g.due === T && /überfällig/.test(untilText(g.due))) flag('Fälligkeitstag als „überfällig“', T, g.title); }
    // Liegen gebliebene Aufgaben
    const overdue = S.tasks.filter(t => t.date && t.date < T && !t.done);
    if (overdue.length && dt.getDate() === 1) { route = 'heute'; render(); if (!/Liegen geblieben/i.test(document.getElementById('view').innerText)) flag('Offene Aufgaben von früheren Tagen verschwinden von „Heute“', T, `${overdue.length} offen`); }
    // Wiederholung
    const reps = S.tasks.filter(t => t.repeat && t.repeat !== 'nie');
    if (reps.length) { const series = {}; reps.forEach(t => { const k = t.series || t.id; (series[k] = series[k] || []).push(t); });
      for (const [k, list] of Object.entries(series)) { const open = list.filter(t => !t.done); const doneL = list.filter(t => t.done);
        if (open.length > 1 + (persona.repeatExtra || 0)) flag('Wiederholung legt doppelte Aufgaben an', T, `${list[0].title}: ${open.length} offen`);
        if (doneL.length && !open.length) flag('„Wiederholen“ hat keine Wirkung', T, `${list[0].title}: kein Folgetermin`);
        const last = doneL.sort((a, b) => a.date.localeCompare(b.date)).pop(); const nx = open[0];
        if (last && nx && last.repeat === 'monatlich') { const a = pd(last.date), b = pd(nx.date); if (!((b.getMonth() - a.getMonth() + 12) % 12 === 1)) flag('Monatliche Wiederholung springt falsch', T, `${last.date} → ${nx.date}`); }
        if (last && nx && last.repeat === 'wöchentlich' && daysBetween(pd(last.date), pd(nx.date)) % 7 !== 0) flag('Wöchentliche Wiederholung falsch', T, `${last.date} → ${nx.date}`); } }
    // Wöchentlich bzw. Stichtage alle Ansichten rendern
    const isCheckDay = dt.getDay() === 0 || dt.getDate() === 1 || i === days - 1 || (dt.getMonth() === 11 && dt.getDate() >= 28) || (dt.getMonth() === 1 && dt.getDate() === 29) || (dt.getMonth() === 2 && dt.getDate() >= 25) || (dt.getMonth() === 9 && dt.getDate() >= 25);
    if (isCheckDay) {
      for (const v of views) {
        route = v; const t0 = R.now(); try { render(); } catch (e) { flag('Absturz beim Anzeigen', T, `${v}: ${e.message}`); continue; }
        renderMs[v] = Math.max(renderMs[v] || 0, R.now() - t0);
        const html = document.getElementById('view').innerHTML;
        const txt = document.getElementById('view').innerText;
        const bad = txt.match(/NaN|undefined|Infinity|\bnull\b|in -\d+ Jahren|-\d+ Tage/);
        if (bad) flag('Kaputter Text in Ansicht', T, `${v}: „${bad[0]}“ – …${txt.slice(Math.max(0, bad.index - 40), bad.index + 30).replace(/\s+/g, ' ')}…`);
        if (v === 'ziele') document.querySelectorAll('.horizon .gd').forEach(el => { const l = parseFloat(el.style.left); if (l < 0 || l > 100) flag('Ziel liegt außerhalb der Zeitachse', T, `${el.innerText.trim() || 'Ziel'} bei ${l.toFixed(0)} %`); });
        if (v === 'rueckblick') {
          // Fokuszeit der Woche nachrechnen (nach Kalendertagen sauber aufgeteilt)
          const from = ymd(monday(dt)), to = ymd(addD(monday(dt), 6));
          const ref = realSessions.filter(s => s.date >= from && s.date <= to).reduce((a, s) => a + s.ms, 0);
          const shown = document.querySelector('[data-metric=fokus]').innerText.trim();
          if (shown !== fmtDur(ref)) flag('Wochen-Fokuszeit weicht ab', T, `App ${shown}, richtig ${fmtDur(ref)}`);
          // Habit-Quote der Woche
          let due = 0, done = 0; for (const d of dayList(from, T < to ? T : to)) for (const h of S.habits) { const k = keyOf(d); if (k < h.created || !isDue(h, d)) continue; if (k === T && !h.log[k]) continue; due++; if (h.log[k]) done++; }
          const q = document.querySelector('[data-metric=habitq]').innerText.replace(/\s/g, '');
          const refQ = (due ? Math.round(done / due * 100) : 0) + '%';
          if (q !== refQ) flag('Habit-Quote der Woche weicht ab', T, `App ${q}, richtig ${refQ}`);
        }
      }
    }
    if (persona._links && dt.getDay() === 0) for (const L of persona._links) { if (L.g.status !== 'aktiv') continue;
      let ref = 0; for (const d of dayList(L.since, T)) for (const e of eventsForDate(keyOf(d))) if (seriesOf(e) === L.k && !e.allDay) ref += (e.end - e.start) * 60e3;
      const ses = S.sessions.filter(x => x.goalId === L.g.id).reduce((a, x) => a + x.ms, 0); const app = goalMs(L.g.id) - ses;
      const otherLinks = persona._links.filter(o => o !== L && o.g === L.g); if (!otherLinks.length && Math.abs(app - ref) > 1000) flag('Zeit aus Kalenderterminen falsch', T, `${L.g.title}: App ${fmtDur(app)}, richtig ${fmtDur(ref)}`); }
    // ----- zufällige Eingriffe in Schritte (wie ein Nutzer, der viel anpasst) -----
    if (i % 9 === 4) { const gs = S.goals.filter(g => g.status === 'aktiv'); const g = gs[Math.floor(rnd() * gs.length)];
      if (g) { const op = Math.floor(rnd() * 11); const st = g.milestones[Math.floor(rnd() * g.milestones.length)]; const fake = d => ({ dataset: d });
        try {
          if (op === 0 || !st) addStepToGoal(g, { title: 'Schritt ' + i, kind: pick(['auto', 'time', 'habit', 'number']), target: pick([5, 20, 100, 0.5]), start: pick([0, -500]), current: pick([0, 3, 40]), unit: 'x', weight: pick([1, 2, 3]), habitId: (S.habits[Math.floor(rnd() * S.habits.length)] || {}).id });
          else if (op === 1) A.stepweight(fake({ id: g.id, v: st.id, w: String(pick([1, 2, 3])) }));
          else if (op === 2) st.weight = pick([5, '2', null, 0, -1, 'x']);
          else if (op === 3) A.stepkind(fake({ id: g.id, v: st.id, k: pick(['auto', 'time', 'habit', 'number']) }));
          else if (op === 4) A.steptoggle(fake({ id: g.id, v: st.id }));
          else if (op === 5) deleteStep(g, st.id);
          else if (op === 6) { const ts = S.tasks.filter(t => t.goalId === g.id); const t = ts[Math.floor(rnd() * ts.length)]; if (t) removeTask(t, { endSeries: false }); }
          else if (op === 7) { const ts = S.tasks.filter(t => t.goalId === g.id); const t = ts[Math.floor(rnd() * ts.length)]; if (t) t.stepId = pick([null, st.id, 'gibt-es-nicht']); }
          else if (op === 8) { st.current = pick([-50, 0, 7, 1e6]); st.target = pick([0, -3, 10, st.start || 0]); }
          else if (op === 9) { sug = null; sheetSuggest(g.id); sug.list.forEach(x => x.sel = rnd() < .6); A.sugapply(); closeSheetQuiet(); }
          else if (op === 10) { const was = g.metric && g.metric.type; A.goalmetric(fake({ id: g.id, v: was === 'number' ? 'milestones' : 'number' })); if (rnd() < .5) A.goalmetric(fake({ id: g.id, v: was === 'number' ? 'number' : 'milestones' })); }
        } catch (e) { flag('Absturz bei Änderung', T, `op ${op}: ${e.message}`); }
        closeSheetQuiet(); } }
    // ----- Rechnung prüfen: jeder Schritt und jedes Ziel gegen die Referenz -----
    for (const g of S.goals) {
      for (const st of g.milestones || []) { window.__cmp = (window.__cmp || 0) + 1; const a = stepInfo(st).p, b = refStep(st); if (Math.abs(a - b) > 1e-9) flag('Schritt-Stand falsch', T, `${g.title} / ${st.title} (${st.kind}): App ${a}, richtig ${b}`);
        if ((st.kind === 'time') && !st.done) { const ref = realSessions.filter(x => x.stepId === st.id).reduce((q, x) => q + x.ms, 0) / 36e5; if (Math.abs(ref - stepHours(st)) > 1e-6) flag('Schritt-Stunden falsch', T, `${st.title}: App ${stepHours(st)}, richtig ${ref}`); } }
      const pc = goalPace(g); if (!(pc.exp >= 0 && pc.exp <= 1) || !Number.isFinite(pc.p)) flag('„Auf Kurs“ ungültig', T, `${g.title}: ${JSON.stringify(pc)}`);
      const fc = goalForecast(g); if (fc && fc.eta && !/^\d{4}-\d\d-\d\d$/.test(fc.eta)) flag('Prognose ungültig', T, `${g.title}: ${JSON.stringify(fc)}`);
    }
    if (dt.getDay() === 3) { recordProgress(); for (const g of S.goals) { sheetGoal(g.id); const tx = document.getElementById('sheetBody').innerText; const bad = tx.match(/NaN|undefined|Infinity/); if (bad) flag('Ziel-Ansicht: kaputter Text', T, `${g.title}: …${tx.slice(Math.max(0, bad.index - 50), bad.index + 20).replace(/\s+/g, ' ')}`);
      for (const st of (g.milestones || []).slice(0, 3)) { sheetStep(g.id, st.id); const t2 = document.getElementById('sheetBody').innerText; if (/NaN|undefined|Infinity/.test(t2)) flag('Schritt-Ansicht: kaputter Text', T, `${g.title} / ${st.title}`); } } closeSheetQuiet(); }
    if (persona.after) persona.after(i, dt, T, flag);
  }
  const size = JSON.stringify(S).length;
  // Zusammenfassen
  const byCheck = {};
  for (const f of findings) { (byCheck[f.check] = byCheck[f.check] || { count: 0, first: f, persona: f.persona }).count++; }
  return { cmp: window.__cmp, edits: Math.floor(days / 9), persona: personaName, days, size, renderMs, maxRunningH: Math.round(maxRunning / 3600e3), tasks: S.tasks.length, sessions: S.sessions.length, goals: S.goals.map(g => `${g.title}: ${Math.round(goalProgress(g) * 100)} %`), habits: S.habits.map(h => `${h.title}: Serie ${habitStreak(h)}, Best ${habitBest(h)}, 30T ${Math.round(habitRate(h) * 100)} %`), checks: byCheck };
};
