"""
export_schemes.py
Run once: python export_schemes.py
Reads all 11 CSVs from sgp/files and writes sakshmseva/assets/data/schemes.json
"""
import csv
import json
import os
import re

FILES_DIR  = os.path.join(os.path.dirname(__file__), "sgp", "files")
OUTPUT     = os.path.join(os.path.dirname(__file__), "sakshmseva", "assets", "data", "schemes.json")

# Same mapping as SchemeModel.fromJson in Dart
CATEGORY_MAP = {
    "agriculture": "agriculture",
    "farmer":      "agriculture",
    "education":   "education",
    "health":      "healthcare",
    "wellness":    "healthcare",
    "women":       "women",
    "child":       "women",
    "empowerment": "women",
    "industry":    "industry",
    "msme":        "industry",
    "social":      "social",
    "justice":     "social",
    "welfare":     "social",
    "skill":       "skill",
    "employment":  "skill",
    "environment": "environment",
    "renewable":   "environment",
    "energy":      "environment",
    "tourism":     "tourism",
    "culture":     "tourism",
    "transport":   "transport",
    "infrastructure": "transport",
    "digital":     "digital",
    "e-governance": "digital",
    "governance":  "digital",
}

def map_category(filename):
    low = filename.lower()
    for kw, cat in CATEGORY_MAP.items():
        if kw in low:
            return cat
    return "social"

def safe(v):
    return (v or "").strip()

schemes = []

for fname in sorted(os.listdir(FILES_DIR)):
    if not fname.endswith(".csv"):
        continue
    path = os.path.join(FILES_DIR, fname)
    category = map_category(fname)

    with open(path, encoding="utf-8", errors="replace") as f:
        reader = csv.reader(f)
        rows = list(reader)

    # Skip header rows until we find the real header (contains "Scheme Name")
    header_idx = None
    for i, row in enumerate(rows):
        joined = " ".join(row).lower()
        if "scheme name" in joined or "scheme" in joined:
            header_idx = i
            break
    if header_idx is None:
        continue

    header_row = [h.strip().lower() for h in rows[header_idx]]

    def col(row, *names):
        for name in names:
            for i, h in enumerate(header_row):
                if name in h and i < len(row):
                    return safe(row[i])
        return ""

    for row in rows[header_idx + 1:]:
        if not any(c.strip() for c in row):
            continue
        name = col(row, "scheme name", "scheme")
        if not name or name.lower() in ("scheme name", "name"):
            continue
        desc        = col(row, "description", "desc", "about")
        status      = col(row, "status", "mode", "type")
        services    = col(row, "service", "benefit", "provided")
        docs        = col(row, "document", "doc")

        scheme_id = re.sub(r"[^a-z0-9]", "_", name.lower())

        schemes.append({
            "id":               scheme_id,
            "scheme_name":      name,
            "description":      desc,
            "category":         category,
            "status":           status,
            "services":         services,
            "documents_needed": docs,
        })

os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(schemes, f, ensure_ascii=False, indent=2)

print(f"✅  Wrote {len(schemes)} schemes → {OUTPUT}")
