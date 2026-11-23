#!/usr/bin/env python3
"""Bildschirmfotos des Klick-Dummys (iPhone-Größe, nur Demo-Daten) für den Roten Faden.

    python3 scripts/bilder.py

Schreibt JPGs (420 px breit) nach docs/produkt/roter-faden/bilder/. Braucht Playwright:
    pip install playwright && playwright install chromium
"""
import asyncio, io, os
from playwright.async_api import async_playwright
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = "file://" + os.path.join(ROOT, "prototyp", "index.html")
OUT = os.path.join(ROOT, "docs", "produkt", "roter-faden", "bilder")


async def shot(pg, name, wait=1400):
    await pg.wait_for_timeout(wait)
    png = await pg.screenshot()
    im = Image.open(io.BytesIO(png)).convert("RGB")
    im = im.resize((420, int(im.height * 420 / im.width)))
    im.save(os.path.join(OUT, name + ".jpg"), quality=82)
    print("  ", name)


async def main():
    os.makedirs(OUT, exist_ok=True)
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(viewport={"width": 390, "height": 844}, device_scale_factor=2, locale="de-DE", timezone_id="Europe/Berlin")
        await pg.goto(APP)
        await shot(pg, "willkommen", 900)
        await pg.click("[data-act=welcome][data-v=demo]")
        await pg.wait_for_timeout(2600)                       # Hinweis-Toast abwarten
        sheet = lambda: pg.click("#sheet .sh [data-act=close]")
        for r in ["heute", "kalender", "habits", "ziele", "rueckblick"]:
            await pg.goto(APP + "#" + r); await shot(pg, r)
        # Heute: Info, Neu, Aufgabe, Fokus, Reflexion
        await pg.goto(APP + "#heute"); await pg.wait_for_timeout(500)
        await pg.click(".phead [data-act=info]"); await shot(pg, "info", 600); await sheet()
        await pg.click(".phead [data-act=new]"); await shot(pg, "neu", 700)
        await pg.click("[data-act=newpick][data-v=task]"); await shot(pg, "neu-aufgabe", 600); await sheet()
        await pg.wait_for_timeout(400)
        await pg.click(".glist .task .bd >> nth=0"); await shot(pg, "aufgabe", 700); await sheet()
        await pg.wait_for_timeout(400)
        await pg.click("[data-act=reflect]"); await shot(pg, "reflexion", 600); await sheet()
        await pg.wait_for_timeout(400)
        await pg.click(".now [data-act=focus]"); await shot(pg, "fokus", 1200)
        await pg.click("[data-act=fstop]"); await pg.wait_for_timeout(400)
        # Habits
        await pg.goto(APP + "#habits"); await pg.wait_for_timeout(500)
        await pg.click(".habits .hb b >> nth=0"); await shot(pg, "habit", 800); await sheet()
        # Ziele: Ziel, Rechnung, Schritt, Vorschläge
        await pg.goto(APP + "#ziele"); await pg.wait_for_timeout(500)
        await pg.click(".goal >> nth=0"); await shot(pg, "ziel", 1300)
        await pg.click("details.calc summary"); await shot(pg, "rechnung", 500)
        await pg.click("details.calc summary"); await pg.wait_for_timeout(300)
        await pg.click(".steprow .sbd >> nth=3"); await shot(pg, "schritt", 900)
        await pg.click("#sheetBody [data-act=opengoal] >> nth=0"); await pg.wait_for_timeout(500)
        await pg.click("[data-act=suggest]"); await shot(pg, "vorschlaege", 700); await sheet()
        # Einstellungen + Termin
        await pg.goto(APP + "#kalender"); await pg.wait_for_timeout(500)
        await pg.click(".phead [data-act=settings]"); await pg.wait_for_timeout(500)
        await pg.click("[data-v=google].switch"); await pg.click("[data-v=apple].switch")
        await shot(pg, "einstellungen", 900); await sheet(); await pg.wait_for_timeout(400)
        await pg.click(".blk.ext >> nth=0"); await shot(pg, "termin", 800); await sheet()
        await b.close()


if __name__ == "__main__":
    asyncio.run(main())
