// Der Assistent-Server (Fassung 2, Werkzeugschleife): Claude bekommt Frage, App-Wissen, Kurzstand und die Werkzeuge der App.
// Braucht Claude Daten, antwortet der Server mit Werkzeugaufrufen; die App führt sie aus (sie rechnet) und schickt die
// Ergebnisse zurück („schritte“). Das wiederholt sich, bis Claude mit Text antwortet. Allgemeine Fragen beantwortet Claude selbst.
// Der Server speichert keine Fragen. Gespeichert wird nur der Zähler je Nutzer und Tag (eine Frage zählt einmal, egal wie viele Schritte).
//
// Schnittstelle (JSON, POST):
//   Anfrage  { frage, wissen, kurzstand, werkzeuge:[{name,beschreibung,parameter:{name:beschreibung}}],
//              verlauf:[{rolle:"nutzer"|"lotse", text}], schritte:[{inhalt:[…Claude-Inhalt…], ergebnisse:[{id,text}]}],
//              nutzer (UUID), kanal, pro (bool), zeitzone }
//   Antwort  { art:"werkzeuge", aufrufe:[{id,name,parameter}], inhalt:[…] } | { art:"text", text }  + kontingent:{ frei, limit, pro }
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
  /** Werkzeugschritte dieser Frage: was Claude angefordert hat (unverändert zurück) und was die App geliefert hat */
  schritte: Schritt[];
  nutzer: string;
  kanal: Kanal;
  pro: boolean;
  zeitzone?: string;
}

export interface Schritt {
  inhalt: Anthropic.ContentBlockParam[];
  ergebnisse: { id: string; text: string }[];
}

export type Antwort =
  | { art: "werkzeuge"; aufrufe: { id: string; name: string; parameter: Record<string, string> }[]; inhalt: unknown[] }
  | { art: "text"; text: string };

export const MAX_SCHRITTE = 6;

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
    schritte: schrittePruefen(a.schritte),
    nutzer: a.nutzer,
    kanal: a.kanal as Kanal,
    pro: a.pro === true,
    zeitzone: typeof a.zeitzone === "string" ? a.zeitzone : undefined,
  };
}

/** Schritte: höchstens MAX_SCHRITTE, je Schritt Claude-Inhalt (Array) und Ergebnisse mit id und Text. Ungültig → leer. */
export function schrittePruefen(roh: unknown): Schritt[] {
  if (!Array.isArray(roh)) return [];
  const out: Schritt[] = [];
  for (const s of roh.slice(0, MAX_SCHRITTE)) {
    if (!s || typeof s !== "object") return [];
    const { inhalt, ergebnisse } = s as Record<string, unknown>;
    if (!Array.isArray(inhalt) || !Array.isArray(ergebnisse) || JSON.stringify(inhalt).length > 20_000) return [];
    const e = (ergebnisse as { id?: unknown; text?: unknown }[])
      .filter((x) => typeof x?.id === "string" && typeof x?.text === "string")
      .map((x) => ({ id: x.id as string, text: (x.text as string).slice(0, 8_000) }));
    out.push({ inhalt: inhalt as Anthropic.ContentBlockParam[], ergebnisse: e });
  }
  return out;
}

/** Werkzeuge der App → Tools der API. Alle Parameter sind Texte. */
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
  return tools;
}

// Wie der Assistent denkt und schreibt. Wissen über die App kommt aus der App (AppWissen) – hier nur Haltung und Stil.
export const ROLLE = `Du bist „Assistent“, die KI in der iPhone-App Kompass (Aufgaben, Termine, Habits, Ziele, Kalender, Rückblick). Du bist ein kluger, warmherziger Assistent – mit Zugriff auf die Daten des Nutzers über Werkzeuge.

So arbeitest du:
- Fragen zu den eigenen Daten (Tag, Termine, freie Zeit, Aufgaben, Habits, Ziele, Fortschritt, Rückblick): rufe die passenden Werkzeuge auf – gern mehrere, auch nacheinander – und antworte dann mit den Ergebnissen. Zahlen, Prozente, Uhrzeiten und Stände übernimmst du aus Werkzeug-Ergebnissen oder dem Stand; du rechnest sie nie selbst nach oder um.
- Fragen zur App (wo finde ich, wie geht, warum zählt): antworte aus dem App-Wissen unten. Erfinde keine Funktionen; gibt es etwas nicht, sag es ehrlich und nenne den nächsten passenden Weg.
- Allgemeine Fragen (Wissen, Reisen, Rechnen, Schreiben, Ideen, Rat): beantworte sie hilfsbereit und sachlich richtig aus deinem Wissen. Wenn es passt, schlag eine Brücke zur App (z. B. Fahrzeit → „Soll ich die Fahrt als Termin eintragen?“). Für Live-Daten (Verkehr, Fahrpläne, Wetter, Preise, Nachrichten) hast du keinen Zugriff: sag das in einem Halbsatz und gib eine gute Schätzung.
- Ändern (Aufgabe oder Termin anlegen) nur, wenn der Nutzer es möchte – dann das Werkzeug aufrufen und kurz bestätigen. Fehlt etwas Wesentliches (z. B. die Uhrzeit), frag nach.
- Mehrdeutig: beantworte die wahrscheinlichste Deutung und frag dann kurz nach.
- Gesundheit, Recht, Geld: allgemein helfen, bei Ernstem auf Fachleute verweisen.

Stil:
- Deutsch, per du, natürlich und freundlich – wie ein kluger Freund, nicht wie ein Protokoll.
- Beginne direkt mit der Antwort; das Wichtigste **fett**. Danach, wenn es hilft, kurze Absätze oder eine Liste mit „- “. Leerzeile zwischen Absätzen.
- Markdown sparsam: **fett**, Listen mit „- “ oder „1. “. Keine Überschriften mit #, keine Tabellen, keine Emojis.
- Länge passend zur Frage: einfache Fragen 1–3 Sätze, Pläne und Erklärungen gern länger, aber selten über 150 Wörter.
- Uhrzeiten als „14:30“, Daten als „Mi, 25. Nov.“. Wiederhole keine Werkzeug-Rohtexte, sondern formuliere sie lesbar.
- Wenn sinnvoll, zum Schluss ein konkretes Angebot als kurze Frage.`;

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
  // Rolle + App-Wissen sind bei allen Nutzern gleich → Prompt-Cache (Tools stehen davor und werden mit gecacht).
  const system: Anthropic.TextBlockParam[] = [{ type: "text", text: ROLLE }];
  if (a.wissen.trim()) system.push({ type: "text", text: "App-Wissen:\n" + a.wissen });
  system[system.length - 1].cache_control = { type: "ephemeral" };

  const nachrichten: Anthropic.MessageParam[] = [
    ...verlaufAlsNachrichten(a.verlauf),
    { role: "user", content: a.kurzstand.trim() ? `Stand (von der App berechnet):\n${a.kurzstand}\n\nFrage: ${a.frage}` : a.frage },
  ];
  for (const s of a.schritte) {
    nachrichten.push({ role: "assistant", content: s.inhalt });
    nachrichten.push({ role: "user", content: s.ergebnisse.map((e) => ({ type: "tool_result" as const, tool_use_id: e.id, content: e.text || "(leer)" })) });
  }
  // Letzter Schritt erreicht: keine Werkzeuge mehr, Claude muss antworten
  const mitWerkzeugen = a.schritte.length < MAX_SCHRITTE;

  const r = await mitRueckfall(d, "gespraech", (model) =>
    d.client.messages.create({
      model,
      max_tokens: 2000,
      output_config: { effort: "medium" },
      system,
      ...(mitWerkzeugen ? { tools: alsTools(a.werkzeuge) } : {}),
      messages: nachrichten,
    }));

  const aufrufe = r.content.filter((b): b is Anthropic.ToolUseBlock => b.type === "tool_use");
  if (aufrufe.length && r.stop_reason === "tool_use") {
    return {
      art: "werkzeuge",
      aufrufe: aufrufe.map((t) => ({
        id: t.id,
        name: t.name,
        parameter: Object.fromEntries(Object.entries(t.input as Record<string, unknown>).filter(([, v]) => typeof v === "string" && v).map(([k, v]) => [k, v as string])),
      })),
      inhalt: r.content,
    };
  }
  const text = r.content.filter((b): b is Anthropic.TextBlock => b.type === "text").map((b) => b.text).join("\n").trim();
  if (r.stop_reason === "refusal" || !text) return { art: "text", text: "Dazu kann ich leider nichts sagen. Frag mich gern etwas anderes – zu deinem Tag, deinen Zielen oder ganz allgemein." };
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
  const ersterSchritt = a.schritte.length === 0;
  if (ersterSchritt && bisher >= limit) return json(429, { fehler: "kontingent", limit, pro, frei: 0 });

  try {
    const antwort = await beantworten(a, d);
    let stand = bisher;
    if (ersterSchritt) {
      stand = bisher + 1;
      try {
        stand = await d.zaehler.zaehlen(a.nutzer, tag);
      } catch { /* Antwort steht schon – Zähler nachtragen ist nicht möglich, nicht schlimm */ }
    }
    return json(200, { ...antwort, kontingent: { frei: Math.max(0, limit - stand), limit, pro } });
  } catch (e) {
    if (e instanceof ModellFehler) return json(503, { fehler: "modell" });
    if (e instanceof Anthropic.RateLimitError) return json(503, { fehler: "ausgelastet" });
    if (e instanceof Anthropic.APIConnectionError) return json(503, { fehler: "verbindung" });
    if (e instanceof Anthropic.APIError) return json(502, { fehler: "api", status: e.status });
    return json(500, { fehler: "unbekannt" });
  }
}
