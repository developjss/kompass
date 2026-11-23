// Modell-Rollen des Lotsen. Die App kennt keine Modellnamen – nur der Server.
// Je Rolle eine Reihe von Kandidaten: der erste verfügbare wird genommen. Fällt ein Modell weg
// (Anthropic stellt Modelle nach Ankündigung ein), rückt automatisch der nächste nach – ohne App-Update.
// Überschreiben ohne Code-Änderung: Umgebungsvariable LOTSE_MODELLE als JSON, z. B.
//   {"werkzeugwahl":["claude-haiku-5-5"],"gespraech":["claude-sonnet-5-5","claude-opus-5-5"]}

import Anthropic from "npm:@anthropic-ai/sdk";

export type Rolle = "werkzeugwahl" | "gespraech";

export const STANDARD_MODELLE: Record<Rolle, string[]> = {
  // günstig und schnell: wählt das Werkzeug (Preise Stand 03.11.2026: 0,10 $ / 0,50 $ je Mio. Token)
  werkzeugwahl: ["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"],
  // abwägen und formulieren: Ziel-Konflikte, Beratung (2 $ / 10 $ je Mio. Token)
  gespraech: ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"],
};

export function modelleAusUmgebung(json: string | undefined): Record<Rolle, string[]> {
  if (!json) return STANDARD_MODELLE;
  try {
    const parsed = JSON.parse(json) as Partial<Record<Rolle, string[]>>;
    return {
      werkzeugwahl: parsed.werkzeugwahl?.length ? parsed.werkzeugwahl : STANDARD_MODELLE.werkzeugwahl,
      gespraech: parsed.gespraech?.length ? parsed.gespraech : STANDARD_MODELLE.gespraech,
    };
  } catch {
    return STANDARD_MODELLE;
  }
}

/** Merkt sich je Modell, ob es erreichbar ist (eine Stunde), damit nicht jede Frage die Modellliste abfragt. */
export class Modellwahl {
  private bekannt = new Map<string, { ok: boolean; bis: number }>();
  constructor(private client: Anthropic, private kandidaten: Record<Rolle, string[]>, private ttlMs = 60 * 60 * 1000) {}

  async verfuegbar(modell: string): Promise<boolean> {
    const m = this.bekannt.get(modell);
    if (m && m.bis > Date.now()) return m.ok;
    let ok = true;
    try {
      await this.client.models.retrieve(modell);
    } catch (e) {
      // 404 = unbekannt oder für dieses Konto nicht freigeschaltet; alles andere (Netz, 5xx) gilt nicht als „weg“
      ok = !(e instanceof Anthropic.NotFoundError);
    }
    this.bekannt.set(modell, { ok, bis: Date.now() + this.ttlMs });
    return ok;
  }

  /** Erstes verfügbares Modell der Rolle; nach einem Fehlschlag mit `ausschliessen` das nächste. */
  async fuer(rolle: Rolle, ausschliessen: string[] = []): Promise<string | null> {
    for (const m of this.kandidaten[rolle]) {
      if (ausschliessen.includes(m)) continue;
      if (await this.verfuegbar(m)) return m;
    }
    return null;
  }

  alsWeg(modell: string) {
    this.bekannt.set(modell, { ok: false, bis: Date.now() + this.ttlMs });
  }
}
