"""Randfälle der Rechenregeln (Wiederholung, Fälligkeit, Mitternacht/Zeitumstellung, KW, Fortschritt).

    python3 prototyp/tests/unit.py
"""
import asyncio
from playwright.async_api import async_playwright
import os,sys
HERE=os.path.dirname(os.path.abspath(__file__))
INIT=open(os.path.join(HERE,'run.py')).read().split('INIT="""')[1].split('"""')[0]
async def main():
  async with async_playwright() as p:
    b=await p.chromium.launch();ctx=await b.new_context(timezone_id='Europe/Berlin',locale='de-DE');await ctx.add_init_script(INIT)
    pg=await ctx.new_page();await pg.goto('file://'+os.path.join(HERE,'..','index.html'));await pg.wait_for_timeout(300)
    r=await pg.evaluate("""()=>{const R=window.__realDate;const out=[];const eq=(n,a,b)=>out.push((JSON.stringify(a)===JSON.stringify(b)?'✓ ':'✗ ')+n+' → '+JSON.stringify(a)+(JSON.stringify(a)===JSON.stringify(b)?'':' (erwartet '+JSON.stringify(b)+')'));
      // Wiederholung monatlich ab 31.01.2028 (Schaltjahr)
      let t={date:'2028-01-31',repeat:'monatlich'};const seq=[];for(let i=0;i<4;i++){t.anchorDay=31;const n=nextRepeatDate(t);seq.push(n);t={date:n,repeat:'monatlich'}}
      eq('monatlich ab 31.01.',seq,['2028-02-29','2028-03-31','2028-04-30','2028-05-31']);
      eq('werktags ab Freitag',nextRepeatDate({date:'2027-01-01',repeat:'werktags'}),'2027-01-04');
      eq('wöchentlich über Zeitumstellung',nextRepeatDate({date:'2027-03-25',repeat:'wöchentlich'}),'2027-04-01');
      window.__NOW=new R(2027,2,28,12).getTime();
      eq('heute fällig',untilText('2027-03-28'),'heute fällig');
      eq('morgen fällig',untilText('2027-03-29'),'morgen fällig');
      eq('gestern',untilText('2027-03-27'),'seit gestern überfällig');
      eq('in 1 Monat (28.04.)',untilText('2027-04-28'),'noch 1 Monat');
      eq('27.04. = noch 30 Tage',untilText('2027-04-27'),'noch 30 Tage');
      eq('2 Jahre 3 Monate',untilText('2029-06-28'),'noch 2 Jahre 3 Mon.');
      // Timer über Mitternacht in der Nacht der Zeitumstellung (31.10.2027)
      const parts=splitByDay(new R(2027,9,30,23).getTime(),new R(2027,9,31,1,30).getTime());
      eq('Nachtschicht 23:00–01:30 aufgeteilt',parts.map(p=>[p.date,p.ms/60e3]),[['2027-10-30',60],['2027-10-31',90]]);
      eq('KW 53/2026',kw(new R(2026,11,31)),53);eq('KW 1/2027 (04.01.)',kw(new R(2027,0,4)),1);eq('KW 52/2027 (01.01.2028)',kw(new R(2028,0,1)),52);
      // Ziel-Fortschritt Randfälle
      const g=m=>goalProgress({status:'aktiv',milestones:[],metric:{type:'number',...m}});
      eq('Schulden -12000→0, jetzt -3000',g({start:-12000,current:-3000,target:0}),0.75);
      eq('Abnehmen 86→75, jetzt 90 (schlechter als Start)',g({start:86,current:90,target:75}),0);
      eq('Ziel übertroffen',g({start:0,current:120000,target:80000}),1);
      eq('Start = Ziel, erreicht',g({start:5,current:5,target:5}),1);
      eq('Ziel ohne Meilensteine',goalProgress({status:'aktiv',milestones:[],metric:{type:'milestones'}}),0);
      return out}""")
    print('\n'.join(r));await b.close()
    bad=[x for x in r if x.startswith('✗')];print('ERGEBNIS:', 'GRÜN' if not bad else f'{len(bad)} falsch');return len(bad)
sys.exit(1 if asyncio.run(main()) else 0)
