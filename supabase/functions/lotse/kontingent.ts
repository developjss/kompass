// Kontingent: wie viele Fragen ein Nutzer pro Tag an das Sprachmodell stellen darf.
// Regeln auf dem Gerät kosten nichts und zählen nicht. Gezählt wird nur, was den Server erreicht.
//
// Umgebungsvariablen (alle optional):
//   LOTSE_FREI_PRO_TAG   Fragen pro Tag ohne Pro (Standard 5)
//   LOTSE_PRO_PRO_TAG    Fragen pro Tag mit Pro – Schutz vor Missbrauch (Standard 300)
//   LOTSE_TESTER_FREI    "true" (Standard): Debug-, Beta- und TestFlight-Builds zählen wie Pro.
//                        Zur App-Store-Veröffentlichung auf "false" setzen.
//   LOTSE_PRO_PRUEFUNG   "aus" (Standard): die App meldet Pro selbst. [RISIKO] Vor dem Store: App-Store-Server-API prüfen (Aufgabe l-pro-pruefung).

export type Kanal = "debug" | "beta" | "testflight" | "store";

export interface Regeln {
  freiProTag: number;
  proProTag: number;
  testerFrei: boolean;
}

export function regelnAusUmgebung(env: (k: string) => string | undefined): Regeln {
  const zahl = (k: string, standard: number) => {
    const n = Number(env(k));
    return Number.isFinite(n) && n >= 0 ? n : standard;
  };
  return {
    freiProTag: zahl("LOTSE_FREI_PRO_TAG", 5),
    proProTag: zahl("LOTSE_PRO_PRO_TAG", 300),
    testerFrei: (env("LOTSE_TESTER_FREI") ?? "true") !== "false",
  };
}

/** Gilt dieser Nutzer als Pro? Tester (Debug/Beta/TestFlight) sind es, solange LOTSE_TESTER_FREI gilt. */
export function istPro(kanal: Kanal, proGemeldet: boolean, regeln: Regeln): boolean {
  if (regeln.testerFrei && kanal !== "store") return true;
  return proGemeldet;
}

export function limitFuer(pro: boolean, regeln: Regeln): number {
  return pro ? regeln.proProTag : regeln.freiProTag;
}

/** Zählt Anfragen je Nutzer und Tag. `zaehlen` erhöht und gibt den neuen Stand zurück. */
export interface Zaehler {
  zaehlen(nutzer: string, tag: string): Promise<number>;
  stand(nutzer: string, tag: string): Promise<number>;
}

/** Für lokale Entwicklung und Tests – vergisst alles beim Neustart. */
export class SpeicherZaehler implements Zaehler {
  private werte = new Map<string, number>();
  async zaehlen(nutzer: string, tag: string) {
    const k = `${nutzer}|${tag}`;
    const n = (this.werte.get(k) ?? 0) + 1;
    this.werte.set(k, n);
    return n;
  }
  async stand(nutzer: string, tag: string) {
    return this.werte.get(`${nutzer}|${tag}`) ?? 0;
  }
}

/** Postgres über PostgREST (Supabase), atomar per SQL-Funktion `lotse_zaehlen` – siehe supabase/migrations. */
export class PostgresZaehler implements Zaehler {
  constructor(private url: string, private schluessel: string) {}

  private async rpc(name: string, args: Record<string, unknown>): Promise<number> {
    const r = await fetch(`${this.url}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: this.schluessel, Authorization: `Bearer ${this.schluessel}` },
      body: JSON.stringify(args),
    });
    if (!r.ok) throw new Error(`Kontingent-Datenbank: ${r.status}`);
    return Number(await r.json());
  }

  zaehlen(nutzer: string, tag: string) {
    return this.rpc("lotse_zaehlen", { p_nutzer: nutzer, p_tag: tag });
  }
  stand(nutzer: string, tag: string) {
    return this.rpc("lotse_stand", { p_nutzer: nutzer, p_tag: tag });
  }
}

/** Heutiges Datum in der Zeitzone des Nutzers (die App schickt sie mit), als JJJJ-MM-TT. */
export function heute(zeitzone: string | undefined, jetzt = new Date()): string {
  try {
    return new Intl.DateTimeFormat("sv-SE", { timeZone: zeitzone || "Europe/Berlin" }).format(jetzt);
  } catch {
    return new Intl.DateTimeFormat("sv-SE", { timeZone: "Europe/Berlin" }).format(jetzt);
  }
}
