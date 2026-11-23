"""Tests für scripts/fahrplan.py – nur Standardbibliothek: python3 -m unittest scripts/test_fahrplan.py"""
import datetime as dt, importlib.util, json, os, tempfile, unittest, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("fahrplan", os.path.join(HERE, "fahrplan.py"))
F = importlib.util.module_from_spec(spec); spec.loader.exec_module(F)
D = dt.date


def data(*tasks, phase=2):
    return {"meta": {"phase": phase}, "team": [{"id": "ceo", "name": "Gründer", "rolle": "CEO"}, {"id": "claude", "name": "Claude", "rolle": "KI"}],
            "aufgaben": [dict({"status": "offen", "wer": "ceo", "bereich": "Leitung"}, **t) for t in tasks]}


def topf(d, today, tid):
    return next(i for i in F.classify(d, today) if i["a"]["id"] == tid)


class Wiederholung(unittest.TestCase):
    def test_woechentlich_montags(self):
        self.assertEqual(F.occurrences({"art": "woechentlich", "tag": 1}, D(2026, 11, 17), D(2026, 11, 30)), [D(2026, 11, 23), D(2026, 11, 30)])

    def test_monatlich_am_31_im_februar_der_28(self):
        self.assertEqual(F.occurrences({"art": "monatlich", "tag": 31}, D(2027, 2, 1), D(2027, 3, 31)), [D(2027, 2, 28), D(2027, 3, 31)])

    def test_quartal_und_jahr(self):
        self.assertEqual(F.occurrences({"art": "quartal", "monate": [1, 4, 7, 10], "tag": 2}, D(2026, 11, 17), D(2027, 5, 1)), [D(2027, 1, 2), D(2027, 4, 2)])
        self.assertEqual(F.occurrences({"art": "jaehrlich", "monat": 6, "tag": 1}, D(2026, 11, 17), D(2028, 1, 1)), [D(2027, 6, 1)])


class Toepfe(unittest.TestCase):
    today = D(2026, 11, 17)

    def test_einmalig_nach_datum(self):
        d = data({"id": "a", "titel": "A", "faellig": "2026-11-10"}, {"id": "b", "titel": "B", "faellig": "2026-11-17"},
                 {"id": "c", "titel": "C", "faellig": "2026-11-30"}, {"id": "e", "titel": "E", "faellig": "2027-01-15"}, {"id": "n", "titel": "N"})
        self.assertEqual([topf(d, self.today, x)["topf"] for x in "abcen"], ["ueberfaellig", "heute", "bald", "spaeter", "naechstes"])

    def test_blockiert_bis_vorgaenger_erledigt(self):
        d = data({"id": "a", "titel": "A"}, {"id": "b", "titel": "B", "nach": ["a"]})
        self.assertEqual(topf(d, self.today, "b")["topf"], "blockiert")
        d["aufgaben"][0]["status"] = "erledigt"
        self.assertEqual(topf(d, self.today, "b")["topf"], "naechstes")

    def test_phase_und_ereignis(self):
        d = data({"id": "p", "titel": "P", "phase": 3}, {"id": "e", "titel": "E", "status": "wartet", "ausloeser": "Leck"})
        self.assertEqual(topf(d, self.today, "p")["topf"], "spaeter")
        self.assertEqual(topf(d, self.today, "e")["topf"], "ereignis")

    def test_wiederkehrend_ueberfaellig_bis_erledigt(self):
        d = data({"id": "m", "titel": "M", "wiederholung": {"art": "monatlich", "tag": 1}})
        self.assertEqual(topf(d, self.today, "m")["topf"], "ueberfaellig")
        d["aufgaben"][0]["erledigtAm"] = "2026-11-02"
        i = topf(d, self.today, "m")
        self.assertEqual((i["topf"], i["datum"]), ("bald", D(2026, 12, 1)))

    def test_neue_pflicht_zaehlt_ab_seit(self):
        d = data({"id": "m", "titel": "M", "wiederholung": {"art": "monatlich", "tag": 1}, "seit": "2026-11-17"})
        self.assertEqual(topf(d, self.today, "m")["datum"], D(2026, 12, 1))

    def test_erledigte_einmalige_fallen_weg(self):
        d = data({"id": "x", "titel": "X", "status": "erledigt"})
        self.assertEqual(F.classify(d, self.today), [])


class Pruefung(unittest.TestCase):
    def test_findet_fehler(self):
        d = data({"id": "a", "titel": "A", "wer": "niemand"}, {"id": "a", "titel": "A2"}, {"id": "b", "titel": "B", "nach": ["fehlt"]},
                 {"id": "c", "titel": "C", "faellig": "17.11."}, {"id": "w", "titel": "W", "status": "wartet"})
        errs = "\n".join(F.check(d))
        for part in ("doppelte ids", "Person niemand", "nach fehlt", "c: faellig", "w: wartet, aber worauf"):
            self.assertIn(part, errs)

    def test_echte_daten_sind_sauber(self):
        self.assertEqual(F.check(F.load()), [])

    def test_bereich_kommt_aus_der_landkarte(self):
        self.assertEqual(F.bereich({"landkarte": "sync"}), "Technik")
        self.assertEqual(F.bereich({"landkarte": "co"}), "Leitung")
        self.assertEqual(F.bereich({"landkarte": "p-claude"}), "Team")


class Befehle(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.path = os.path.join(self.tmp, "aufgaben.json")
        with open(self.path, "w", encoding="utf-8") as f:
            json.dump(data({"id": "a", "titel": "A"}, {"id": "m", "titel": "M", "wiederholung": {"art": "monatlich", "tag": 1}}), f)
        self.old, F.DATA = F.DATA, self.path

    def tearDown(self):
        F.DATA = self.old

    def test_zuweisen_und_erledigt(self):
        self.assertEqual(F.main(["zuweisen", "a", "claude"]), 0)
        self.assertEqual(F.main(["zuweisen", "a", "unbekannt"]), 1)
        self.assertEqual(F.main(["erledigt", "a", "--datum", "2026-11-17"]), 0)
        self.assertEqual(F.main(["erledigt", "m", "--datum", "2026-11-17"]), 0)
        d = F.load(self.path)
        a, m = d["aufgaben"]
        self.assertEqual((a["wer"], a["status"], m["status"], m["erledigtAm"]), ("claude", "erledigt", "offen", "2026-11-17"))

    def test_export_xlsx_und_csv(self):
        x, c = os.path.join(self.tmp, "f.xlsx"), os.path.join(self.tmp, "f.csv")
        self.assertEqual(F.main(["export", "--format", "xlsx", "--out", x, "--datum", "2026-11-17"]), 0)
        self.assertEqual(F.main(["export", "--format", "csv", "--out", c, "--datum", "2026-11-17"]), 0)
        with zipfile.ZipFile(x) as z:
            self.assertIn("xl/worksheets/sheet1.xml", z.namelist())
            self.assertIn("A", z.read("xl/worksheets/sheet1.xml").decode())
        with open(c, encoding="utf-8-sig") as f:
            self.assertTrue(f.readline().startswith("id;Titel;Bereich"))

    def test_view_fuer_die_seite(self):
        out = os.path.join(self.tmp, "view.json")
        self.assertEqual(F.main(["view", "--out", out, "--datum", "2026-11-17"]), 0)
        v = json.load(open(out, encoding="utf-8"))
        self.assertEqual(v["stand"], "2026-11-17")
        self.assertEqual({a["id"] for a in v["aufgaben"]}, {"a", "m"})
        self.assertTrue(all("topf" in a and "bereich" in a for a in v["aufgaben"]))


if __name__ == "__main__":
    unittest.main()
