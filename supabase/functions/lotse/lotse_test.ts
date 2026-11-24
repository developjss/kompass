// Tests der reinen Teile: Anfrageprüfung, Tool-Umwandlung, Kontingent-Regeln, Datum.
//   deno test supabase/functions/lotse/
import { assertEquals } from "jsr:@std/assert";
import { alsTools, anfragePruefen, antwortText, MAX_SCHRITTE, schrittePruefen } from "./lotse.ts";
import { heute, istPro, limitFuer, regelnAusUmgebung, SpeicherZaehler } from "./kontingent.ts";
import { modelleAusUmgebung, STANDARD_MODELLE } from "./modelle.ts";

const gueltig = {
  frage: "Was steht heute an?",
  wissen: "Kompass …",
  kurzstand: "Heute: 2026-11-23",
  werkzeuge: [{ name: "heute", beschreibung: "Was heute ansteht", parameter: {} }],
  verlauf: [],
  nutzer: "6F9619FF-8B86-D011-B42D-00C04FC964FF",
  kanal: "store",
  pro: false,
};

Deno.test("Anfrage: gültig und ungültig", () => {
  assertEquals(anfragePruefen(gueltig)?.frage, "Was steht heute an?");
  assertEquals(anfragePruefen({ ...gueltig, nutzer: "x" }), null);
  assertEquals(anfragePruefen({ ...gueltig, kanal: "egal" }), null);
  assertEquals(anfragePruefen({ ...gueltig, frage: "" }), null);
  assertEquals(anfragePruefen({ ...gueltig, werkzeuge: [] }), null);
});

Deno.test("Werkzeuge werden zu Tools", () => {
  const tools = alsTools([{ name: "aufgabeAnlegen", beschreibung: "legt an", parameter: { titel: "Text", datum: "JJJJ-MM-TT" } }]);
  assertEquals(tools.length, 1);
  assertEquals(tools[0].name, "aufgabeAnlegen");
  assertEquals(Object.keys((tools[0].input_schema as { properties: Record<string, unknown> }).properties), ["titel", "datum"]);
});

Deno.test("Schritte: gültig, begrenzt, ungültig → leer", () => {
  const s = { inhalt: [{ type: "tool_use", id: "t1", name: "heute", input: {} }], ergebnisse: [{ id: "t1", text: "3 Termine" }] };
  assertEquals(schrittePruefen([s]).length, 1);
  assertEquals(schrittePruefen(Array(10).fill(s)).length, MAX_SCHRITTE);
  assertEquals(schrittePruefen([{ inhalt: "x", ergebnisse: [] }]), []);
  assertEquals(schrittePruefen(undefined), []);
  assertEquals(anfragePruefen({ ...gueltig, schritte: [s] })?.schritte.length, 1);
});

Deno.test("Kontingent: Tester sind Pro, Store-Nutzer nur wenn gemeldet", () => {
  const r = regelnAusUmgebung(() => undefined);
  assertEquals(r.freiProTag, 5);
  assertEquals(istPro("testflight", false, r), true);
  assertEquals(istPro("store", false, r), false);
  assertEquals(istPro("store", true, r), true);
  const streng = regelnAusUmgebung((k) => (k === "LOTSE_TESTER_FREI" ? "false" : undefined));
  assertEquals(istPro("beta", false, streng), false);
  assertEquals(limitFuer(false, r), 5);
  assertEquals(limitFuer(true, r), 300);
});

Deno.test("Zähler zählt je Nutzer und Tag", async () => {
  const z = new SpeicherZaehler();
  assertEquals(await z.zaehlen("a", "2026-11-23"), 1);
  assertEquals(await z.zaehlen("a", "2026-11-23"), 2);
  assertEquals(await z.stand("a", "2026-11-24"), 0);
});

Deno.test("Heute in Zeitzone des Nutzers", () => {
  const jetzt = new Date("2026-11-23T23:30:00Z");
  assertEquals(heute("Europe/Berlin", jetzt), "2026-11-24");
  assertEquals(heute("America/Los_Angeles", jetzt), "2026-11-23");
  assertEquals(heute("Quatsch/Zone", jetzt), "2026-11-24");
});

Deno.test("Modelle aus Umgebung, sonst Standard", () => {
  assertEquals(modelleAusUmgebung(undefined), STANDARD_MODELLE);
  assertEquals(modelleAusUmgebung("kaputt"), STANDARD_MODELLE);
  assertEquals(modelleAusUmgebung('{"gespraech":["claude-opus-5-5"]}').gespraech, ["claude-opus-5-5"]);
  assertEquals(modelleAusUmgebung('{"gespraech":["claude-opus-5-5"]}').werkzeugwahl, STANDARD_MODELLE.werkzeugwahl);
});

Deno.test("Antworttext: nach der Websuche, Zitatblöcke verbunden, Quellen", () => {
  const t = antwortText([
    { type: "text", text: "Ich schaue nach." },
    { type: "server_tool_use", id: "s1", name: "web_search", input: {} },
    { type: "web_search_tool_result", tool_use_id: "s1", content: [] },
    { type: "text", text: "Morgen wird es " },
    { type: "text", text: "**8 °C** und bewölkt.", citations: [{ url: "https://wetter.example/ulm", title: "Wetter Ulm" }] },
  ]);
  assertEquals(t, "Morgen wird es **8 °C** und bewölkt.\n\nQuellen: [Wetter Ulm](https://wetter.example/ulm)");
  assertEquals(antwortText([{ type: "text", text: "Hallo" }]), "Hallo");
});
