"""Metro dil araçlarının ortak parçaları: QML/JS ve C++ dize değişmezi çözümleyicisi, dil listesi.

dizeler(metin, tur) -> [(baslangic, bitis, tirnak, icerik)]  (baslangic/bitis tırnaklar dahil)
tur: "js" (QML/JS/JSON: '…', "…", `…` şablon, // ve /* */ yorumlar) | "cpp" (C++: "…", ham R"x(…)x", '…' karakter)
"""
import json
import re

# Türkçe kaynak + 10 dil (sistem dili; desteklenmeyen dil -> en)
DILLER = ["tr", "en", "de", "fr", "es", "it", "pt_BR", "ru", "pl", "nl", "az"]
YEREL = {"tr": "tr_TR", "en": "en_US", "de": "de_DE", "fr": "fr_FR", "es": "es_ES", "it": "it_IT",
         "pt_BR": "pt_BR", "ru": "ru_RU", "pl": "pl_PL", "nl": "nl_NL", "az": "az_AZ"}


def dil_sec(diller):
    """LANGUAGE/LC_ALL/LC_MESSAGES/LANG listesinden desteklenen ilk dil."""
    for d in diller:
        d = d.split(".")[0].split("@")[0]
        if not d or d in ("C", "POSIX"):
            continue
        if d in DILLER:
            return d
        if d.startswith("pt_BR") or d == "pt":
            return "pt_BR"
        k = d.split("_")[0]
        if k in DILLER:
            return k
    return "en"


def sistem_dili():
    """Açılış ve oturum açma ekranının dili: /etc/locale.conf (LANGUAGE, LANG), yoksa ortam."""
    import os
    diller = []
    try:
        for satir in open("/etc/locale.conf", encoding="utf-8"):
            a, _, d = satir.strip().partition("=")
            if a in ("LANGUAGE", "LC_MESSAGES", "LANG") and d:
                diller += d.strip('"').split(":")
    except OSError:
        pass
    diller += [os.environ.get(k, "") for k in ("LANGUAGE", "LANG")]
    return dil_sec([d for d in diller if d])


def dizeler(t, tur="js"):
    sonuc = []
    i, n = 0, len(t)
    while i < n:
        c = t[i]
        if c == "/" and i + 1 < n and t[i + 1] == "/":
            j = t.find("\n", i)
            i = n if j < 0 else j
            continue
        if c == "/" and i + 1 < n and t[i + 1] == "*":
            j = t.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if tur == "cpp" and c == "R" and t.startswith('R"', i) and (i == 0 or not (t[i - 1].isalnum() or t[i - 1] == "_")):
            j = t.find("(", i)
            ayrac = t[i + 2:j]
            k = t.find(")" + ayrac + '"', j)
            i = n if k < 0 else k + len(ayrac) + 2
            continue
        if c in "\"'" or (tur == "js" and c == "`"):
            j = i + 1
            while j < n and t[j] != c:
                if t[j] == "\\":
                    j += 1
                elif t[j] == "\n" and c != "`":
                    break
                j += 1
            if j < n and t[j] == c:
                if not (tur == "cpp" and c == "'"):
                    sonuc.append((i, j + 1, c, t[i + 1:j]))
                i = j + 1
                continue
            i = j
            continue
        i += 1
    return sonuc


def kacir(v, tirnak):
    """Çeviriyi aynı tırnak türüne uygun kaçışlarla yaz."""
    v = v.replace("\\", "\\\\").replace("\n", "\\n")
    return v.replace(tirnak, "\\" + tirnak)


def coz(icerik):
    """Kaynaktaki kaçışları sözlük anahtarına çevir (\\" -> ", \\n -> yeni satır, \\uXXXX korunur)."""
    return re.sub(r'\\(["\'`\\])', r"\1", icerik).replace("\\n", "\n")


def sozluk(yol):
    try:
        return json.loads(open(yol, encoding="utf-8").read())
    except FileNotFoundError:
        return {}
