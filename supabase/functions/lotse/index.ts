// Einstieg für Supabase Edge Functions (Deno). Der Schlüssel liegt nur hier als Secret – nie in der App.
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   supabase functions deploy lotse
// Dieselbe Logik läuft auf jedem Deno/Node-Host: `behandle(req, abhaengigkeiten)` aus lotse.ts aufrufen.

import Anthropic from "npm:@anthropic-ai/sdk";
import { behandle } from "./lotse.ts";
import { PostgresZaehler, regelnAusUmgebung, SpeicherZaehler } from "./kontingent.ts";
import { modelleAusUmgebung, Modellwahl } from "./modelle.ts";

const env = (k: string) => Deno.env.get(k);

const zaehler = env("SUPABASE_URL") && env("SUPABASE_SERVICE_ROLE_KEY")
  ? new PostgresZaehler(env("SUPABASE_URL")!, env("SUPABASE_SERVICE_ROLE_KEY")!)
  : new SpeicherZaehler();
const regeln = regelnAusUmgebung(env);

// Client erst bei der ersten Anfrage – ohne Schlüssel startet die Funktion trotzdem und antwortet 503 statt abzustürzen.
let client: Anthropic | null = null;
let modelle: Modellwahl | null = null;

Deno.serve((req) => {
  if (!env("ANTHROPIC_API_KEY")) {
    return new Response(JSON.stringify({ fehler: "schluessel", hinweis: "ANTHROPIC_API_KEY fehlt – Dashboard → Edge Functions → Secrets" }),
      { status: 503, headers: { "Content-Type": "application/json" } });
  }
  client ??= new Anthropic();
  modelle ??= new Modellwahl(client, modelleAusUmgebung(env("LOTSE_MODELLE")));
  return behandle(req, { client, modelle, zaehler, regeln, appSchluessel: env("LOTSE_APP_SCHLUESSEL") });
});
