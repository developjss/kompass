"""Kleiner Word-Baukasten ohne fremde Pakete (nur Python-Standard).
Baut eine .docx mit Überschriften (mit Sprungmarken), Absätzen, internen Links, Bildern, Tabellen,
Hinweis-Kästen und Aufzählungen. Benutzt von roter_faden.py.
"""
import struct
import zipfile
from xml.sax.saxutils import escape

INK = "18233F"; ACCENT = "3B4CCA"; SOFT = "E6E9FB"; GREY = "4D5262"; LINE = "D5D8E3"
FONT = "Helvetica Neue"


def _img_size(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        w, h = struct.unpack(">II", data[16:24])
        return w, h, "png"
    i = 2
    while i < len(data):
        if data[i] != 0xFF:
            i += 1; continue
        marker = data[i + 1]
        if marker in (0xC0, 0xC1, 0xC2):
            h, w = struct.unpack(">HH", data[i + 5:i + 9])
            return w, h, "jpeg"
        seg = struct.unpack(">H", data[i + 2:i + 4])[0]
        i += 2 + seg
    raise ValueError("unknown image " + path)


class Doc:
    def __init__(self):
        self.body = []
        self.media = []          # (name, path)
        self.rels = []           # (rid, type, target)
        self.bm = 0
        self.pic = 0
        self.anchors = []        # alle Sprungmarken
        self.links = []          # alle Link-Ziele
        self.images = []         # alle Bildpfade
        self.headings = []       # (Ebene, Text, Anker, neue Seite)

    # ---------- runs ----------
    @staticmethod
    def run(text, bold=False, italic=False, color=None, size=None, mono=False):
        rpr = ""
        if bold: rpr += "<w:b/>"
        if italic: rpr += "<w:i/>"
        if color: rpr += f'<w:color w:val="{color}"/>'
        if size: rpr += f'<w:sz w:val="{size}"/><w:szCs w:val="{size}"/>'
        if mono: rpr += '<w:rFonts w:ascii="Menlo" w:hAnsi="Menlo"/>'
        return f'<w:r><w:rPr>{rpr}</w:rPr><w:t xml:space="preserve">{escape(text)}</w:t></w:r>'

    def link(self, text, anchor):
        if anchor.startswith("http"):
            # 20.11.2026: Links in den Arbeitsordner (GitHub) und auf Fahrplan/Landkarte – extern, ohne Sprungmarke.
            rid = f"rIdL{len(self.rels) + 1}"
            self.rels.append((rid, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink", anchor + '" TargetMode="External'))
            self.external = getattr(self, "external", []) + [anchor]
            return (f'<w:hyperlink r:id="{rid}" w:history="1"><w:r><w:rPr><w:color w:val="{ACCENT}"/><w:u w:val="single"/></w:rPr>'
                    f'<w:t xml:space="preserve">{escape(text)}</w:t></w:r></w:hyperlink>')
        self.links.append(anchor)
        return (f'<w:hyperlink w:anchor="{anchor}" w:history="1"><w:r><w:rPr><w:color w:val="{ACCENT}"/><w:u w:val="single"/></w:rPr>'
                f'<w:t xml:space="preserve">{escape(text)}</w:t></w:r></w:hyperlink>')

    def rich(self, s):
        """Text mit **fett** und [[Linktext|anker]]."""
        out = []
        import re
        for part in re.split(r"(\*\*[^*]+\*\*|\[\[[^\]]+\]\])", s):
            if not part: continue
            if part.startswith("**"): out.append(self.run(part[2:-2], bold=True))
            elif part.startswith("[["):
                t, a = part[2:-2].split("|"); out.append(self.link(t, a))
            else: out.append(self.run(part))
        return "".join(out)

    # ---------- blocks ----------
    def p(self, s, style=None, align=None, space_after=None, keep=False, raw=False):
        ppr = ""
        if style: ppr += f'<w:pStyle w:val="{style}"/>'
        if keep: ppr += "<w:keepNext/>"
        if space_after is not None: ppr += f'<w:spacing w:after="{space_after}"/>'
        if align: ppr += f'<w:jc w:val="{align}"/>'
        self.body.append(f"<w:p><w:pPr>{ppr}</w:pPr>{s if raw else self.rich(s)}</w:p>")

    def h(self, text, level, anchor=None, new_page=False):
        b = ""
        if anchor:
            self.bm += 1
            b = f'<w:bookmarkStart w:id="{self.bm}" w:name="{anchor}"/><w:bookmarkEnd w:id="{self.bm}"/>'
            self.anchors.append(anchor)
        pb = "<w:pageBreakBefore/>" if new_page else ""
        self.headings.append((level, text, anchor, new_page))
        self.body.append(f'<w:p><w:pPr><w:pStyle w:val="Heading{level}"/>{pb}</w:pPr>{b}{self.run(text)}</w:p>')

    def crumb(self, parts):
        """Brotkrumen-Zeile über einer Seite: [(text, anker|None), ...] – mit Links zurück."""
        out = []
        for i, (t, a) in enumerate(parts):
            if i: out.append(self.run("  ›  ", color=GREY, size=17))
            out.append(self.link(t, a) if a else self.run(t, color=GREY, size=17))
        self.body.append(f'<w:p><w:pPr><w:pStyle w:val="Small"/><w:pageBreakBefore/><w:spacing w:after="40"/></w:pPr>{"".join(out)}</w:p>')

    def bullets(self, items, arrow=False):
        for it in items:
            num = 2 if arrow else 1
            self.body.append(f'<w:p><w:pPr><w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="{num}"/></w:numPr>'
                             f'<w:spacing w:after="60"/></w:pPr>{self.rich(it)}</w:p>')

    def page_break(self):
        self.body.append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

    def _image_xml(self, path, width_cm):
        self.images.append(path)
        w, h, kind = _img_size(path)
        self.pic += 1
        name = f"image{self.pic}.{'png' if kind == 'png' else 'jpeg'}"
        rid = f"rIdImg{self.pic}"
        self.media.append((name, path))
        self.rels.append((rid, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image", f"media/{name}"))
        cx = int(width_cm * 360000); cy = int(cx * h / w)
        return (f'<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="{cx}" cy="{cy}"/>'
                f'<wp:docPr id="{self.pic}" name="Bild {self.pic}"/><wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
                f'<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic>'
                f'<pic:nvPicPr><pic:cNvPr id="{self.pic}" name="{name}"/><pic:cNvPicPr/></pic:nvPicPr>'
                f'<pic:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
                f'<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
                f'<a:ln w="6350"><a:solidFill><a:srgbClr val="{LINE}"/></a:solidFill></a:ln></pic:spPr>'
                f'</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>')

    def image(self, path, width_cm, caption=None):
        self.body.append(f'<w:p><w:pPr><w:jc w:val="center"/><w:keepNext/><w:spacing w:after="60"/></w:pPr>{self._image_xml(path, width_cm)}</w:p>')
        if caption: self.p(caption, style="Caption", align="center")

    def shots(self, items, width_cm=4.6):
        """Screenshots nebeneinander: [(pfad, beschriftung), ...] – höchstens 3 pro Reihe."""
        n = len(items); total = 9638; cw = total // n
        cells = ""
        for path, cap in items:
            cells += (f'<w:tc><w:tcPr><w:tcW w:w="{cw}" w:type="dxa"/><w:vAlign w:val="top"/></w:tcPr>'
                      f'<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="40"/></w:pPr>{self._image_xml(path, width_cm)}</w:p>'
                      f'<w:p><w:pPr><w:pStyle w:val="Caption"/><w:jc w:val="center"/></w:pPr>{self.rich(cap)}</w:p></w:tc>')
        grid = "".join(f'<w:gridCol w:w="{cw}"/>' for _ in items)
        self.body.append(f'<w:tbl><w:tblPr><w:tblW w:w="{total}" w:type="dxa"/><w:jc w:val="center"/>'
                         f'<w:tblBorders><w:top w:val="nil"/><w:left w:val="nil"/><w:bottom w:val="nil"/><w:right w:val="nil"/><w:insideH w:val="nil"/><w:insideV w:val="nil"/></w:tblBorders>'
                         f'<w:tblLayout w:type="fixed"/></w:tblPr><w:tblGrid>{grid}</w:tblGrid><w:tr><w:trPr><w:cantSplit/></w:trPr>{cells}</w:tr></w:tbl>')
        self.p("", space_after=60)

    def table(self, rows, widths, header=True):
        total = sum(widths)
        grid = "".join(f'<w:gridCol w:w="{w}"/>' for w in widths)
        trs = ""
        for i, row in enumerate(rows):
            tcs = ""
            for j, cell in enumerate(row):
                shade = f'<w:shd w:val="clear" w:color="auto" w:fill="{SOFT}"/>' if (header and i == 0) else ""
                text = f"**{cell}**" if (header and i == 0) else cell
                tcs += (f'<w:tc><w:tcPr><w:tcW w:w="{widths[j]}" w:type="dxa"/>{shade}</w:tcPr>'
                        f'<w:p><w:pPr><w:spacing w:before="40" w:after="40"/></w:pPr>{self.rich(text)}</w:p></w:tc>')
            trs += f'<w:tr><w:trPr><w:cantSplit/>{"<w:tblHeader/>" if header and i == 0 else ""}</w:trPr>{tcs}</w:tr>'
        b = f'w:val="single" w:sz="4" w:space="0" w:color="{LINE}"'
        self.body.append(f'<w:tbl><w:tblPr><w:tblW w:w="{total}" w:type="dxa"/>'
                         f'<w:tblBorders><w:top {b}/><w:left {b}/><w:bottom {b}/><w:right {b}/><w:insideH {b}/><w:insideV {b}/></w:tblBorders>'
                         f'<w:tblLayout w:type="fixed"/><w:tblCellMar><w:left w:w="100" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr>'
                         f'<w:tblGrid>{grid}</w:tblGrid>{trs}</w:tbl>')
        self.p("", space_after=60)

    def box(self, title, lines, fill="EEF0FD", edge=ACCENT):
        """Hinweis-Kasten mit farbigem Rand links."""
        inner = f'<w:p><w:pPr><w:spacing w:after="60"/></w:pPr>{self.run(title, bold=True, color=INK)}</w:p>'
        for l in lines:
            inner += f'<w:p><w:pPr><w:spacing w:after="40"/></w:pPr>{self.rich(l)}</w:p>'
        self.body.append(f'<w:tbl><w:tblPr><w:tblW w:w="9638" w:type="dxa"/>'
                         f'<w:tblBorders><w:top w:val="nil"/><w:bottom w:val="nil"/><w:right w:val="nil"/><w:left w:val="single" w:sz="24" w:space="0" w:color="{edge}"/></w:tblBorders>'
                         f'<w:tblCellMar><w:top w:w="100" w:type="dxa"/><w:left w:w="200" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/><w:right w:w="160" w:type="dxa"/></w:tblCellMar></w:tblPr>'
                         f'<w:tblGrid><w:gridCol w:w="9638"/></w:tblGrid><w:tr><w:trPr><w:cantSplit/></w:trPr><w:tc><w:tcPr><w:tcW w:w="9638" w:type="dxa"/>'
                         f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/></w:tcPr>{inner}</w:tc></w:tr></w:tbl>')
        self.p("", space_after=60)

    # ---------- save ----------
    def save(self, path, title, page_word="Seite"):
        W = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
        doc = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document {W} '
               'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
               'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
               'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>'
               + "".join(self.body) +
               '<w:sectPr><w:footerReference w:type="default" r:id="rIdFooter"/><w:pgSz w:w="11906" w:h="16838"/>'
               '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="567" w:footer="567" w:gutter="0"/></w:sectPr>'
               '</w:body></w:document>')

        def hstyle(i, size, before, after, color=INK):
            return (f'<w:style w:type="paragraph" w:styleId="Heading{i}"><w:name w:val="heading {i}"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/>'
                    f'<w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="{before}" w:after="{after}"/><w:outlineLvl w:val="{i-1}"/></w:pPr>'
                    f'<w:rPr><w:rFonts w:ascii="{FONT}" w:hAnsi="{FONT}"/><w:b/><w:color w:val="{color}"/><w:sz w:val="{size}"/><w:szCs w:val="{size}"/></w:rPr></w:style>')
        styles = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles {W}>'
                  f'<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="{FONT}" w:hAnsi="{FONT}" w:eastAsia="{FONT}" w:cs="{FONT}"/>'
                  f'<w:color w:val="{INK}"/><w:sz w:val="21"/><w:szCs w:val="21"/><w:lang w:val="de-DE"/></w:rPr></w:rPrDefault>'
                  '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>'
                  f'<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/><w:rPr><w:rFonts w:ascii="{FONT}" w:hAnsi="{FONT}" w:eastAsia="{FONT}" w:cs="{FONT}"/></w:rPr></w:style>'
                  f'<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:before="0" w:after="120"/></w:pPr>'
                  f'<w:rPr><w:rFonts w:ascii="{FONT}" w:hAnsi="{FONT}"/><w:b/><w:color w:val="{INK}"/><w:sz w:val="64"/><w:szCs w:val="64"/></w:rPr></w:style>'
                  f'<w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="240"/></w:pPr>'
                  f'<w:rPr><w:color w:val="{GREY}"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>'
                  + hstyle(1, 36, 360, 160) + hstyle(2, 27, 280, 100, ACCENT) + hstyle(3, 23, 200, 80) +
                  f'<w:style w:type="paragraph" w:styleId="Caption"><w:name w:val="caption"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="80"/></w:pPr>'
                  f'<w:rPr><w:i/><w:color w:val="{GREY}"/><w:sz w:val="17"/><w:szCs w:val="17"/></w:rPr></w:style>'
                  '<w:style w:type="paragraph" w:styleId="ListParagraph"><w:name w:val="List Paragraph"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:ind w:left="567"/></w:pPr></w:style>'
                  f'<w:style w:type="paragraph" w:styleId="Small"><w:name w:val="Small"/><w:basedOn w:val="Normal"/><w:rPr><w:color w:val="{GREY}"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr></w:style>'
                  '<w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/><w:rPr><w:color w:val="3B4CCA"/><w:u w:val="single"/></w:rPr></w:style>'
                  '</w:styles>')
        numbering = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:numbering {W}>'
                     '<w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="singleLevel"/><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/>'
                     f'<w:lvlText w:val="•"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="567" w:hanging="283"/></w:pPr><w:rPr><w:color w:val="{ACCENT}"/></w:rPr></w:lvl></w:abstractNum>'
                     '<w:abstractNum w:abstractNumId="1"><w:multiLevelType w:val="singleLevel"/><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/>'
                     f'<w:lvlText w:val="→"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="567" w:hanging="340"/></w:pPr><w:rPr><w:b/><w:color w:val="{ACCENT}"/></w:rPr></w:lvl></w:abstractNum>'
                     '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num><w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num></w:numbering>')
        footer = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr {W}><w:p><w:pPr><w:pStyle w:val="Small"/><w:jc w:val="center"/></w:pPr>'
                  f'{self.run(title + " · " + page_word + " ")}<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>'
                  '<w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p></w:ftr>')
        rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                '<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
                '<Relationship Id="rIdNum" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>'
                '<Relationship Id="rIdFooter" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>'
                + "".join(f'<Relationship Id="{i}" Type="{t}" Target="{g}"/>' for i, t, g in self.rels) + '</Relationships>')
        ct = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
              '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>'
              '<Default Extension="png" ContentType="image/png"/><Default Extension="jpeg" ContentType="image/jpeg"/>'
              '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
              '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
              '<Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>'
              '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>'
              '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>')
        root = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
                '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>')
        core = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
                'xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>' + escape(title) + '</dc:title><dc:creator>Kompass</dc:creator></cp:coreProperties>')
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("[Content_Types].xml", ct)
            z.writestr("_rels/.rels", root)
            z.writestr("docProps/core.xml", core)
            z.writestr("word/document.xml", doc)
            z.writestr("word/styles.xml", styles)
            z.writestr("word/numbering.xml", numbering)
            z.writestr("word/footer1.xml", footer)
            z.writestr("word/_rels/document.xml.rels", rels)
            for name, src in self.media:
                z.write(src, "word/media/" + name)
