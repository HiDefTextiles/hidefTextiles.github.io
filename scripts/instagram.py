#!/usr/bin/env python3
"""Insert an "Af Instagram" gallery into topic pages.

Media live in img/instagram/<topic>/ (compressed copies of the
@hideftextiles archive made with tungufoss/instagram-archiver).
Each page gets its gallery just before its `::: {.hofundur}` box,
between the markers below, so the script can be re-run safely.
"""
import pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
IG = "https://www.instagram.com/p/{}/"
START, END = "<!-- instagram:start -->", "<!-- instagram:end -->"

# page -> list of (post id, date, caption). Captions summarise the post text.
PAGES = {
  "prjonavel/velin.qmd": [
    ("C7JQwBag-Et", "19. maí 2024", "Passap Duomatic 80 fékk meira að segja handbók á íslensku."),
    ("C7LznxOo96o", "20. maí 2024", "Djúphreinsun: allar nálar (180 á hverju nálarbeði) teknar úr og hreinsaðar með ísóprópanóli. Það tók 2–4 manns tvo vinnudaga."),
    ("C7JShzsgfhF", "19. maí 2024", "Fyrstu kynni: fyrirstaða á aftari lásnum reyndist vera of stutt lykkjustærð miðað við garnið."),
    ("C7kIplBgBXF", "29. maí 2024", "Þýsk áhrif: Passap var svissneskt og helsti opni hugbúnaðurinn er eftir Þjóðverja."),
  ],
  "prjonavel/prjon.qmd": [
    ("C7JRfAQAhQk", "19. maí 2024", "Fyrsta æfingarverkefnið úr Duo80 handbókinni: pottaleppur."),
    ("C7oEX5Zg5L2", "30. maí 2024", "Fyrstu prufurnar eftir æfingamynstrum í leiðarvísinum fyrir Duo80."),
    ("C7oPPEUAERo", "30. maí 2024", "Mannleg mistök: hér prjónaðist ekki af nálunum eins og búist var við."),
  ],
  "prjonavel/motor.qmd": [
    ("C7kVoW4AIAt", "29. maí 2024", "Ástandsskoðun á Electra 4600 mótornum. Lásinn var ekki festur í færibandið og segulskynjari skaust af."),
    ("C-5BftiAt-R", "20. ágúst 2024", "Prufa með mótor."),
  ],
  "prjonavel/nalastyring.qmd": [
    ("C7kbxeFIKz1", "29. maí 2024", "Arduino örstýring lóðuð við DIN-tengi E6000 vélarinnar kveikir og slekkur á seglunum í fremra lásaborðinu."),
    ("C7oKGV2AjQK", "31. maí 2024", "Björninn: harðkóðaður vigur segir seglunum hvort næstu nálar fari í vinnu- eða hvíldarstöðu."),
  ],
  "prjonavel/senda-mynstur.qmd": [
    ("C766unfoZAJ", "7. júní 2024", "Sett af skipunum sent á vélina: JSON strengur með upphafsstaðsetningu og mynstri úr 0 og 1."),
  ],
  "prjonavel/honnun.qmd": [
    ("C9xaz9Agxi7", "23. júlí 2024", "Prjónað eftir ljósmynd og eftir mynd af málverki."),
  ],
  "sjonabok/prjonad.qmd": [
    ("C9Cf8FFgDZZ", "5. júlí 2024", "Fyrsta myndin sem heppnaðist vel, tekin úr Íslensku Sjónabókinni."),
    ("C9KbfzDI1Wo", "8. júlí 2024", "Forritið speglaði myndirnar, en því var kippt í lag í hvelli."),
    ("C-5CF7KAgNj", "20. ágúst 2024", "Ýmislegt prjónað."),
  ],
  "verkefnid/sumarid.qmd": [
    ("C7646broU6a", "7. júní 2024", "Heimsókn frá Flík (Marta og Þórey) í VR-III."),
    ("C8pGS9KIQrP", "25. júní 2024", "Heimsókn til Heimilisiðnaðarfélags Íslands."),
    ("C8w0kCxoyt4", "28. júní 2024", "Heimsókn í Kidka, framleiðslufyrirtæki fyrir prjónavörur."),
    ("C84sH57IV-Y", "1. júlí 2024", "Textílmiðstöð Íslands á Blönduósi tók vel á móti teyminu."),
    ("C89j9F-orvl", "3. júlí 2024", "Myndir úr heimsókninni í Textílmiðstöð Íslands."),
  ],
  "verkefnid/teymi.qmd": [
    ("C7wu6c3I6yu", "3. júní 2024", "Elías Lúðvíksson, sem sá um vélauppfærslurnar. Ljósmynd: mbl.is/Kristinn Magnússon."),
  ],
  "verkefnid/index.qmd": [
    ("DFhlZR0ACh5", "1. febrúar 2025", "HiDef textíll á UTmessunni 8. febrúar 2025 í Hörpu."),
    ("DF0hT23AiW2", "8. febrúar 2025", "Takk öll sem kíktu á okkur á UTmessunni."),
    ("DGDom8DsFbC", "14. febrúar 2025", "Prjón og gervigreind mætast: frá bás Háskóla Íslands á UTmessunni."),
  ],
}

def media(page, post):
    topic = page.split("/")[0]
    d = ROOT / "img" / "instagram" / topic
    files = sorted(d.glob(f"*_{post}_*"))
    vids = {f.stem for f in files if f.suffix == ".mp4"}
    return [f for f in files if f.suffix == ".mp4" or f.stem not in vids], topic

def block(page, items):
    out = [START, "", "## Af Instagram", "",
           "Myndir og myndbönd sem teymið birti á [Instagram](https://www.instagram.com/hideftextiles/) meðan á verkefninu stóð.", "",
           '```{=html}', '<div class="instagram">']
    for post, date, cap in items:
        files, topic = media(page, post)
        for n, f in enumerate(files):
            src = f"../img/instagram/{topic}/{f.name}"
            if f.suffix == ".mp4":
                el = f'<video controls preload="none" playsinline poster="../img/instagram/{topic}/{f.stem}.jpg"><source src="{src}" type="video/mp4"></video>'
            else:
                el = f'<a href="{src}" class="lightbox" data-gallery="instagram"><img src="{src}" alt="{cap}" loading="lazy"></a>'
            text = f'{cap} ' if n == 0 else ''
            out.append(f'<figure>{el}<figcaption>{text}<a href="{IG.format(post)}">Færslan á Instagram</a>, {date}.</figcaption></figure>')
    out += ["</div>", "```", "", END, ""]
    return "\n".join(out)

for page, items in PAGES.items():
    p = ROOT / page
    s = p.read_text()
    s = re.sub(re.escape(START) + ".*?" + re.escape(END) + "\n*", "", s, flags=re.S)
    i = s.rfind("::: {.hofundur}")
    s = s[:i] + block(page, items) + "\n" + s[i:]
    p.write_text(s)
    print("updated", page)
