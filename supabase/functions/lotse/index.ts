// Einstieg für Supabase Edge Functions (Deno). Der Schlüssel liegt nur hier als Secret – nie in der App.
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   supabase functions deploy lotse
// Dieselbe Logik läuft auf jedem Deno/Node-Host: `behandle(req, abhaengigkeiten)` aus lotse.ts aufrufen.

import Anthropic from "npm:@anthropic-ai/sdk";
import { behandle } from "./lotse.ts";
import { PostgresZaehler, regelnAusUmgebung, SpeicherZaehler } from "./kontingent.ts";
import { modelleAusUmgebung, Modellwahl } from "./modelle.ts";

const env = (k: string) => Deno.env.get(k);

const client = new Anthropic(); // liest ANTHROPIC_API_KEY
const modelle = new Modellwahl(client, modelleAusUmgebung(env("LOTSE_MODELLE")));
const zaehler = env("SUPABASE_URL") && env("SUPABASE_SERVICE_ROLE_KEY")
  ? new PostgresZaehler(env("SUPABASE_URL")!, env("SUPABASE_SERVICE_ROLE_KEY")!)
  : new SpeicherZaehler();
const regeln = regelnAusUmgebung(env);

Deno.serve((req) => behandle(req, { client, modelle, zaehler, regeln, appSchluessel: env("LOTSE_APP_SCHLUESSEL") }));
