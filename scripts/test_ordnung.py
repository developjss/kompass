"""Tests für scripts/ordnung.py: python3 scripts/test_ordnung.py"""
import datetime as dt, importlib.util, os, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("ordnung", os.path.join(HERE, "ordnung.py"))
O = importlib.util.module_from_spec(spec); spec.loader.exec_module(O)


class Ordnung(unittest.TestCase):
    def test_stand_lesen(self):
        self.assertEqual(O.stand_date("Stand: 17. November 2026 · x"), dt.date(2026, 11, 17))
        self.assertEqual(O.stand_date("Stand: 3.2.2027"), dt.date(2027, 2, 3))
        self.assertIsNone(O.stand_date("kein Datum"))

    def test_alte_dokumente_werden_gemeldet(self):
        hints = O.old_docs(["docs/leitung/fahrplan.md"], dt.date(2027, 3, 1))
        self.assertTrue(hints and "Stand erneuern oder archivieren" in hints[0])

    def test_kaputter_verweis_wird_gefunden(self):
        import tempfile
        d = tempfile.mkdtemp(); old = O.ROOT; O.ROOT = d
        try:
            os.makedirs(os.path.join(d, "docs"))
            open(os.path.join(d, "docs", "a.md"), "w").write("Siehe `docs/gibt-es-nicht.md` und `docs/a.md`.")
            errs, _ = O.broken_refs(["docs/a.md"])
            self.assertEqual(len(errs), 1)
            self.assertIn("docs/gibt-es-nicht.md", errs[0])
        finally:
            O.ROOT = old

    def test_der_arbeitsordner_ist_in_ordnung(self):
        errs, _ = O.report(dt.date.today())
        self.assertEqual(errs, [], "\n".join(errs))


if __name__ == "__main__":
    unittest.main()
