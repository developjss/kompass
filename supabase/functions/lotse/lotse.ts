// Der Lotse-Server: nimmt eine Frage samt App-Wissen und Werkzeugen entgegen und antwortet mit
// einem Werkzeugaufruf (die App rechnet) oder mit Text (Beratung). Zwei Stufen:
//   1. Werkzeugwahl – kleines Modell, effort low, mit den Werkzeugen der App als Tools
//   2. Gespräch – größeres Modell, nur wenn Stufe 1 das Werkzeug „beraten“ wählt
// Der Server speichert keine Fragen. Gespeichert wird nur der Zähler je Nutzer und Tag.
//
// Schnittstelle (JSON, POST):
//   Anfrage  { frage, wissen, kurzstand, werkzeuge:[{name,beschreibung,parameter:{name:beschreibung}}],
//              verlauf:[{rolle:"nutzer"|"lotse", text}], nutzer (UUID), kanal, pro (bool), zeitzone }
//   Antwort  { art:"werkzeug", name, parameter } | { art:"text", text }  + kontingent:{ frei, limit, pro }
//   Fehler   429 { fehler:"kontingent", limit, pro }  · 400 { fehler:"anfrage" }  · 503 { fehler:"modell" }

import Anthropic from "npm:@anthropic-ai/sdk";
import { type Kanal, heute, istPro, limitFuer, type Regeln, type Zaehler } from "./kontingent.ts";
import { Modellwahl } from "./modelle.ts";

export interface WerkzeugBeschreibung {
  name: string;
  beschreibung: string;
  parameter: Record<string, string>;
}

export interface Anfrage {
  frage: string;
  wissen: string;
  kurzstand: string;
  werkzeuge: WerkzeugBeschreibung[];
  verlauf: { rolle: "nutzer" | "lotse"; text: string }[];
  nutzer: string;
  kanal: Kanal;
  pro: boolean;
  zeitzone?: string;
}

export type Antwort =
  | { art: "werkzeug"; name: string; parameter: Record<string, string>; einleitung?: string }
  | { art: "text"; text: string };

export interface Abhaengigkeiten {
  client: Anthropic;
  modelle: Modellwahl;
  zaehler: Zaehler;
  regeln: Regeln;
  appSchluessel?: string;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const KANAELE: Kanal[] = ["debug", "beta", "testflight", "store"];

export function anfragePruefen(roh: unknown): Anfrage | null {
  if (!roh || typeof roh !== "object") return null;
  const a = roh as Record<string, unknown>;
  if (typeof a.frage !== "string" || !a.frage.trim() || a.frage.length > 2000) return null;
  if (typeof a.nutzer !== "string" || !UUID.test(a.nutzer)) return null;
  if (!KANAELE.includes(a.kanal as Kanal)) return null;
  if (!Array.isArray(a.werkzeuge) || a.werkzeuge.length === 0 || a.werkzeuge.length > 50) return null;
  return {
    frage: a.frage.trim(),
    wissen: typeof a.wissen === "string" ? a.wissen.slice(0, 40_000) : "",
    kurzstand: typeof a.kurzstand === "string" ? a.kurzstand.slice(0, 4_000) : "",
    werkzeuge: (a.werkzeuge as WerkzeugBeschreibung[]).filter((w) => typeof w.name === "string" && /^[a-zA-Z]+$/.test(w.name)),
    verlauf: Array.isArray(a.verlauf)
      ? (a.verlauf as Anfrage["verlauf"]).filter((v) => (v.rolle === "nutzer" || v.rolle === "lotse") && typeof v.text === "string").slice(-12)
      : [],
    nutzer: a.nutzer,
    kanal: a.kanal as Kanal,
    pro: a.pro === true,
    zeitzone: typeof a.zeitzone === "string" ? a.zeitzone : undefined,
  };
}

/** Werkzeuge der App → Tools der API. Alle Parameter sind Texte; `beraten` kommt für Stufe 2 dazu. */
export function alsTools(werkzeuge: WerkzeugBeschreibung[]): Anthropic.Tool[] {
  const tools: Anthropic.Tool[] = werkzeuge.map((w) => ({
    name: w.name,
    description: w.beschreibung,
    input_schema: {
      type: "object" as const,
      properties: Object.fromEntries(Object.entries(w.parameter).map(([k, v]) => [k, { type: "string", description: v }])),
      additionalProperties: false,
    },
  }));
  tools.push({
    name: "beraten",
    description:
      "Nur wenn kein anderes Werkzeug passt und die Frage ein Abwägen braucht: Konflikte zwischen Zielen, Priorisierung, Motivation, Einordnung. Nicht für Fakten oder Zahlen – die liefern die anderen Werkzeuge.",
    input_schema: { type: "object" as const, properties: { grund: { type: "string", description: "Worum es geht, ein Satz" } }, additionalProperties: false },
  });
  return tools;
}

// Gemeinsamer Stil – der Lotse soll sich lesen wie ein erfahrener, freundlicher Assistent, nicht wie ein Protokoll.
const STIL = `Stil:
- Antworte auf Deutsch, per „du“, ruhig und klar. Keine Floskeln, kein Lob ohne Anlass, keine Ausrufezeichen-Häufung.
- Erst die Antwort in einem Satz. Dann höchstens drei kurze Punkte mit „•“, nur wenn sie etwas hinzufügen. Zum Schluss ein konkreter nächster Schritt oder ein Angebot als Frage.
- Keine Markdown-Auszeichnung (keine Sternchen, keine Überschriften), keine Abkürzungen wie „Std.“, keine Telegramm-Sätze.
- Kurz: meist unter 70 Wörtern, bei Beratung höchstens 120.`;

const ROLLE_WERKZEUGWAHL = `Du bist der Lotse in der App Kompass (Aufgaben, Habits, Ziele, Kalender).
Regeln:
- Zahlen, Prozente, Termine und Stände nennst du nie selbst. Dafür rufst du immer ein Werkzeug auf – die App rechnet.
- Erkennst du, was der Nutzer will, rufe genau ein Werkzeug auf und fülle die Parameter aus dem Text (Datum als JJJJ-MM-TT, heute/morgen/übermorgen/Wochentag umrechnen; wichtig = "ja"/"nein"; Ziel = Name wie in der App). Vor dem Aufruf darfst du einen kurzen einleitenden Satz schreiben („Schauen wir auf deine Woche.“) – oder nichts.
- Braucht die Frage ein Abwägen (Ziel-Konflikte, Priorisierung, Motivation, „was soll ich zuerst“), rufe „beraten“ auf.
- Fragen außerhalb von Kompass (Allgemeinwissen, Nachrichten, Rechnen, andere Apps): beantworte sie nicht inhaltlich. Sag in einem freundlichen Satz, dass du für Ziele, Habits, Aufgaben und Termine da bist, und biete etwas Passendes an, z. B. „Soll ich dir zeigen, was heute ansteht?“.
- Begrüßung, Dank, Rückfrage: ein kurzer, warmer Satz.
${STIL}`;

const ROLLE_GESPRAECH = `Du bist der Lotse in der App Kompass: ein ruhiger, ehrlicher Begleiter für Ziele, Habits und Alltag.
Regeln:
- Nutze nur die Zahlen aus dem mitgelieferten Stand. Erfinde keine Werte. Fehlt dir etwas für ein Urteil, sag das in einem Nebensatz, nicht als eigener Absatz.
- Eine klare Empfehlung, ein bis zwei Gründe, ein nächster Schritt, den man heute tun kann.
- Sprich den Nutzer so an, wie ein guter Coach es täte: direkt, wohlwollend, ohne Belehrung.
${STIL}`;

function verlaufAlsNachrichten(verlauf: Anfrage["verlauf"]): Anthropic.MessageParam[] {
  // Die API verlangt wechselnde Rollen; gleiche Rollen hintereinander werden zusammengelegt.
  const out: Anthropic.MessageParam[] = [];
  for (const v of verlauf) {
    const role = v.rolle === "nutzer" ? "user" : "assistant";
    const letzte = out[out.length - 1];
    if (letzte && letzte.role === role) letzte.content = `${letzte.content}\n${v.text}`;
    else out.push({ role, content: v.text });
  }
  if (out.length && out[0].role === "assistant") out.shift();
  if (out.length && out[out.length - 1].role === "user") out.pop(); // die aktuelle Frage kommt separat
  return out;
}

export async function beantworten(a: Anfrage, d: Abhaengigkeiten): Promise<Antwort> {
  // App-Wissen ist bei allen Nutzern gleich → Prompt-Cache (ab einer Mindestlänge je Modell). Leere Blöcke lehnt die API ab.
  const wissen: Anthropic.TextBlockParam[] = a.wissen.trim() ? [{ type: "text", text: a.wissen, cache_control: { type: "ephemeral" } }] : [];
  const system: Anthropic.TextBlockParam[] = [{ type: "text", text: ROLLE_WERKZEUGWAHL }, ...wissen];
  const nachrichten: Anthropic.MessageParam[] = [
    ...verlaufAlsNachrichten(a.verlauf),
    { role: "user", content: a.kurzstand.trim() ? `Stand:\n${a.kurzstand}\n\nFrage: ${a.frage}` : a.frage },
  ];

  const erste = await mitRueckfall(d, "werkzeugwahl", (model) =>
    d.client.messages.create({
      model,
      max_tokens: 1024,
      output_config: { effort: "low" },
      system,
      tools: alsTools(a.werkzeuge),
      messages: nachrichten,
    }));

  const tool = erste.content.find((b): b is Anthropic.ToolUseBlock => b.type === "tool_use");
  if (tool && tool.name !== "beraten") {
    const parameter: Record<string, string> = {};
    for (const [k, v] of Object.entries(tool.input as Record<string, unknown>)) if (typeof v === "string" && v) parameter[k] = v;
    const einleitung = erste.content.filter((b): b is Anthropic.TextBlock => b.type === "text").map((b) => b.text.trim()).filter(Boolean).join(" ");
    return einleitung ? { art: "werkzeug", name: tool.name, parameter, einleitung } : { art: "werkzeug", name: tool.name, parameter };
  }
  if (!tool) {
    const text = erste.content.filter((b): b is Anthropic.TextBlock => b.type === "text").map((b) => b.text).join("\n").trim();
    if (erste.stop_reason === "refusal" || !text) return { art: "text", text: "Dazu kann ich nichts sagen. Frag mich zu deinen Zielen, Habits, Aufgaben oder Terminen." };
    return { art: "text", text };
  }

  // Stufe 2: Gespräch
  const zweite = await mitRueckfall(d, "gespraech", (model) =>
    d.client.beta.messages.create({
      model,
      max_tokens: 1500,
      output_config: { effort: "low" },
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: [{ type: "text", text: ROLLE_GESPRAECH }, ...wissen],
      messages: nachrichten,
    }));
  const text = zweite.content.filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text").map((b) => b.text).join("\n").trim();
  if (zweite.stop_reason === "refusal" || !text) return { art: "text", text: "Dazu kann ich nichts sagen. Frag mich zu deinen Zielen, Habits, Aufgaben oder Terminen." };
  return { art: "text", text };
}

/** Ruft das erste verfügbare Modell der Rolle; ist es inzwischen weg (404), das nächste. */
async function mitRueckfall<T>(d: Abhaengigkeiten, rolle: "werkzeugwahl" | "gespraech", aufruf: (model: string) => Promise<T>): Promise<T> {
  const versucht: string[] = [];
  for (;;) {
    const model = await d.modelle.fuer(rolle, versucht);
    if (!model) throw new ModellFehler("Kein Modell für Rolle " + rolle);
    try {
      return await aufruf(model);
    } catch (e) {
      if (e instanceof Anthropic.NotFoundError) {
        d.modelle.alsWeg(model);
        versucht.push(model);
        continue;
      }
      throw e;
    }
  }
}

export class ModellFehler extends Error {}

/** HTTP-Einstieg, unabhängig vom Host (Deno.serve, Node, Supabase). */
export async function behandle(req: Request, d: Abhaengigkeiten): Promise<Response> {
  const json = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
  if (req.method !== "POST") return json(405, { fehler: "methode" });
  if (d.appSchluessel && req.headers.get("X-Kompass-App") !== d.appSchluessel) return json(401, { fehler: "app" });

  let a: Anfrage | null = null;
  try {
    a = anfragePruefen(await req.json());
  } catch { /* ungültiges JSON */ }
  if (!a) return json(400, { fehler: "anfrage" });

  const pro = istPro(a.kanal, a.pro, d.regeln);
  const limit = limitFuer(pro, d.regeln);
  const tag = heute(a.zeitzone);
  let bisher = 0;
  try {
    bisher = await d.zaehler.stand(a.nutzer, tag);
  } catch {
    return json(503, { fehler: "zaehler" }); // Zähler nicht erreichbar → lieber nicht antworten als unbegrenzt
  }
  if (bisher >= limit) return json(429, { fehler: "kontingent", limit, pro, frei: 0 });

  try {
    const antwort = await beantworten(a, d);
    let stand = bisher + 1;
    try {
      stand = await d.zaehler.zaehlen(a.nutzer, tag);
    } catch { /* Antwort steht schon – Zähler nachtragen ist nicht möglich, nicht schlimm */ }
    return json(200, { ...antwort, kontingent: { frei: Math.max(0, limit - stand), limit, pro } });
  } catch (e) {
    if (e instanceof ModellFehler) return json(503, { fehler: "modell" });
    if (e instanceof Anthropic.RateLimitError) return json(503, { fehler: "ausgelastet" });
    if (e instanceof Anthropic.APIConnectionError) return json(503, { fehler: "verbindung" });
    if (e instanceof Anthropic.APIError) return json(502, { fehler: "api", status: e.status });
    return json(500, { fehler: "unbekannt" });
  }
}
