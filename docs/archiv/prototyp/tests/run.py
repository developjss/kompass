"""Personen-Test: 4 Personen × N Tage im Klick-Dummy, jede Zahl gegen eine unabhängige zweite Rechnung (sim.js).

    python3 prototyp/tests/run.py [prototyp/index.html] [Tage, Standard 730] [Name-Filter]
"""
import asyncio,json,os,sys
from playwright.async_api import async_playwright
from personas import PERSONAS
HERE=os.path.dirname(os.path.abspath(__file__))
APP=os.path.abspath(sys.argv[1]) if len(sys.argv)>1 else os.path.join(HERE,'..','index.html')
DAYS=int(sys.argv[2]) if len(sys.argv)>2 else 730
INIT="""(()=>{const R=Date;window.__realDate=R;window.__NOW=null;
function F(...a){if(!(this instanceof F))return new R(window.__NOW??R.now()).toString();return a.length?new R(...a):new R(window.__NOW??R.now())}
F.prototype=R.prototype;F.now=()=>window.__NOW??R.now();F.UTC=R.UTC;F.parse=R.parse;window.Date=F;try{localStorage.clear()}catch(e){}})();"""
async def main():
  async with async_playwright() as p:
    b=await p.chromium.launch()
    out=[]
    for name,src in [x for x in PERSONAS.items() if len(sys.argv)<4 or sys.argv[3] in x[0]]:
      ctx=await b.new_context(viewport={'width':1400,'height':900},timezone_id='Europe/Berlin',locale='de-DE')
      await ctx.add_init_script(INIT)
      pg=await ctx.new_page();errs=[]
      pg.on('pageerror',lambda e:errs.append(str(e)))
      pg.on('console',lambda m:None)
      await pg.goto('file://'+APP);await pg.wait_for_timeout(300)
      await pg.add_script_tag(path=os.path.join(HERE,'sim.js'))
      r=await pg.evaluate("([n,src,d])=>__runSim(n,'2026-12-01',d,{persona:src})",[name,src,DAYS])
      r['pageErrors']=errs[:5]
      out.append(r);await ctx.close()
    json.dump(out,open(os.path.join(HERE,'ergebnis.json'),'w'),ensure_ascii=False,indent=1)
    fails=sum(len(r['checks']) for r in out)+sum(len(r['pageErrors']) for r in out)
    for r in out:
      print('\n=== ',r['persona'],'| Vergleiche',r.get('cmp'),'| Eingriffe',r.get('edits'),'| Größe',round(r['size']/1024),'KB | Render max ms',{k:round(v) for k,v in r['renderMs'].items()},'| max Timer h',r['maxRunningH'],'| Fehler',r['pageErrors'])
      for g in r['goals']:print('   Ziel:',g)
      for h in r['habits']:print('   Habit:',h)
      for k,v in r['checks'].items():print(f"   ✗ {k} ({v['count']}×) z.B. {v['first']['date']}: {v['first']['detail']}")
    await b.close()
    print('\nERGEBNIS:', 'GRÜN' if not fails else f'{fails} Prüfungen mit Abweichung'); return fails
sys.exit(1 if asyncio.run(main()) else 0)
