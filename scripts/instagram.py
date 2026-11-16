#!/usr/bin/env python3
"""Insert an "Af Instagram" gallery into topic pages.

Media live in img/instagram/<topic>/ (compressed copies of the
@hideftextiles archive made with tungufoss/instagram-archiver).
Each page gets its gallery just before its `::: {.hofundur}` box,
between the markers below, so the script can be re-run safely.

Videos are hosted on YouTube (https://www.youtube.com/@tungufoss,
playlist "HiDEF textiles") and embedded with an iframe, never committed.
Put each video's YouTube ID in YOUTUBE below, keyed by "<post>_<nn>"
as in the archive file name. A video without an ID falls back to the
local .mp4, which only exists until it has been uploaded.
"""
import pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
IG = "https://www.instagram.com/p/{}/"
YT = "https://www.youtube-nocookie.com/embed/{}"
PLAYLIST = "PLcHERjMhsyhA"  # YouTube playlist ID (PL...) for "HiDEF textiles", once created

# "<post>_<nn>" -> YouTube video ID
YOUTUBE = {
  "C7JRfAQAhQk_01": "q3RybTmCukQ",
  "C7JShzsgfhF_01": "E-YEauBHt4o",
  "C7kVoW4AIAt_01": "ea3GYfEOE38",
  "C7kbxeFIKz1_01": "LJIMnjNcIB0",
  "C7oKGV2AjQK_01": "25q8OGhGbdM",
  "C766unfoZAJ_01": "oHeMyZ-bNfU",
  "C8pGS9KIQrP_01": "TiNsSSR-E3A",
  "C8w0kCxoyt4_01": "X0GN0K7PwQE",
  "C84sH57IV-Y_01": "eGkWztHbTXQ",
  "C-5CF7KAgNj_04": "Ozf-9MO2r8M",
}

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
    """Media of one post, in order: ("youtube", id), ("video", path) or ("image", path).

    Videos listed in YOUTUBE need no local file; their .mp4 and poster .jpg
    can be deleted once uploaded. Photos are WebP (make images).
    """
    topic = page.split("/")[0]
    d = ROOT / "img" / "instagram" / topic
    items = {}
    for f in sorted(d.glob(f"*_{post}_*")):
        nn = f.stem.rsplit("_", 1)[1]
        if f.suffix == ".mp4" or nn not in items:
            items[nn] = ("video" if f.suffix == ".mp4" else "image", f"../img/instagram/{topic}/{f.name}")
    for k, vid in YOUTUBE.items():
        if k.rsplit("_", 1)[0] == post:
            items[k.rsplit("_", 1)[1]] = ("youtube", vid)
    return [items[nn] for nn in sorted(items)]

def block(page, items):
    out = [START, "", "## Af Instagram", "",
           "Myndir og myndbönd sem teymið birti á [Instagram](https://www.instagram.com/hideftextiles/) meðan á verkefninu stóð."
           + (f" Öll myndböndin eru líka í [spilunarlistanum HiDEF textiles á YouTube](https://www.youtube.com/playlist?list={PLAYLIST})." if PLAYLIST else ""), "",
           '```{=html}', '<div class="instagram">']
    for post, date, cap in items:
        for n, (kind, ref) in enumerate(media(page, post)):
            if kind == "youtube":
                el = (f'<iframe src="{YT.format(ref)}" title="{cap}" loading="lazy" '
                      'allow="accelerometer; encrypted-media; gyroscope; picture-in-picture; web-share" '
                      'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>')
            elif kind == "video":
                el = f'<video controls preload="none" playsinline poster="{ref[:-4]}.webp"><source src="{ref}" type="video/mp4"></video>'
            else:
                el = f'<a href="{ref}" class="lightbox" data-gallery="instagram"><img src="{ref}" alt="{cap}" loading="lazy"></a>'
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
