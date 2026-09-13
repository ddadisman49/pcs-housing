import csv
import os
import re
from difflib import SequenceMatcher
from pathlib import Path
from collections import Counter
import requests
from bs4 import BeautifulSoup


PROJECT_ROOT = Path(__file__).resolve().parent.parent
HTML_FILE = PROJECT_ROOT / "tools" / "data" / "military_installations_view_all.html"
OUTPUT_FILE = PROJECT_ROOT / "tools" / "data" / "installations_gap_report.csv"
ENV_FILE = PROJECT_ROOT / ".env.tools"


def load_env_file(path):
    if not path.exists():
        raise FileNotFoundError(f"Environment file not found: {path}")

    with path.open("r", encoding="utf-8") as file:
        for line in file:
            line = line.strip()

            if not line or line.startswith("#") or "=" not in line:
                continue

            key, value = line.split("=", 1)
            os.environ[key.strip()] = value.strip()


def normalize_name(name):
    name = name.lower()

    replacements = {
        "&": " and ",
        "air force base": "afb",
        "space force base": "sfb",
        "naval air station": "nas",
        "marine corps air station": "mcas",
        "joint base": "jb",
        "united states": "us",
        "u.s.": "us",
    }

    for old, new in replacements.items():
        name = name.replace(old, new)

    name = re.sub(r"[^a-z0-9]+", " ", name)
    name = re.sub(r"\s+", " ", name)

    return name.strip()


def load_existing_installations():
    load_env_file(ENV_FILE)

    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_PUBLISHABLE_KEY")

    if not supabase_url or not supabase_key:
        raise RuntimeError(
            "SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY "
            "must be set in .env.tools"
        )

    url = f"{supabase_url.rstrip('/')}/rest/v1/installations"

    response = requests.get(
        url,
        headers={
            "apikey": supabase_key,
        },
        params={
            "select": "name",
            "order": "name.asc",
        },
        timeout=30,
    )

    response.raise_for_status()

    return sorted(
        {
            row["name"].strip()
            for row in response.json()
            if row.get("name")
        }
    )

def is_guard_or_reserve_unit(name):
    normalized = name.upper().strip()

    unit_patterns = [
        r"^\d+\s*ARW$",
        r"^\d+\s*AW$",
        r"^\d+\s*FW$",
        r"^\d+\s*WG$",
        r"^\d+\s*IW$",
        r"^\d+\s*RQW$",
        r"^\d+\s*ACW$",
        r"^\d+\s*ATKW$",
        r"^\d+\s*BW$",
        r"^\d+\s*OW$",
        r"^\d+\s*SW$",
        r"^\d+\s*MSG$",
        r"^\d+\s*MXG$",
        r"^\d+\s*OG$",
    ]

    return any(
        re.fullmatch(pattern, normalized)
        for pattern in unit_patterns
    )

def load_official_installations():
    if not HTML_FILE.exists():
        raise FileNotFoundError(
            f"MilitaryINSTALLATIONS HTML file not found: {HTML_FILE}"
        )

    html = HTML_FILE.read_text(
        encoding="utf-8",
        errors="ignore",
    )

    soup = BeautifulSoup(html, "html.parser")

    installations = set()

    for link in soup.find_all("a", href=True):
        href = link.get("href", "")
        name = link.get_text(" ", strip=True)

        if not name:
            continue

        if is_guard_or_reserve_unit(name):
            continue

        href_lower = href.lower()

        if (
            "/military-installation/" in href_lower
            or "/installation/" in href_lower
        ):
            installations.add(name.strip())

    # Fallback for saved pages whose links use another structure.
    if not installations:
        for link in soup.find_all("a"):
            name = link.get_text(" ", strip=True)

            if not name:
                continue

            if is_guard_or_reserve_unit(name):
                continue

            if len(name) < 3 or len(name) > 120:
                continue

            installations.add(name.strip())

    return sorted(installations)


def similarity(a, b):
    return SequenceMatcher(
        None,
        normalize_name(a),
        normalize_name(b),
    ).ratio()


def find_best_match(official_name, existing_names):
    best_name = ""
    best_score = 0.0

    normalized_official = normalize_name(official_name)

    for existing_name in existing_names:
        normalized_existing = normalize_name(existing_name)

        if normalized_official == normalized_existing:
            return existing_name, 1.0

        score = similarity(
            official_name,
            existing_name,
        )

        if score > best_score:
            best_score = score
            best_name = existing_name

    return best_name, best_score

def classify_candidate(name, closest_name, score):
    upper = name.upper().strip()

    if upper == "MCCS HAMPTON ROADS":
     return "EXCLUDE - SUPPORT ORGANIZATION"

    if upper == "USAG HAWAII":
     return "EXISTING UMBRELLA ORGANIZATION"

    overseas_terms = [
        "AIR BASE",
        "AB",
        "USAG ANSBACH",
        "USAG BAVARIA",
        "USAG BENELUX",
        "USAG DAEGU",
        "USAG HUMPHREYS",
        "USAG ITALY",
        "USAG JAPAN",
        "USAG OKINAWA",
        "USAG POLAND",
        "USAG RHEINLAND",
        "USAG STUTTGART",
        "USAG WIESBADEN",
        "USAG YONGSAN",
        "GUAM",
        "DIEGO GARCIA",
        "SIGONELLA",
        "SASEBO",
        "YOKOSUKA",
        "ATSUGI",
        "IWAKUNI",
        "OKINAWA",
        "CHINHAE",
        "GUANTANAMO",
        "NAPLES",
        "GAETA",
        "ANKARA",
        "AVIANO",
        "BUECHEL",
        "CANBERRA",
        "GEILENKIRCHEN",
        "GHEDI",
        "INCIRLIK",
        "IZMIR",
        "KADENA",
        "KALKAR",
        "KLEINE BROGEL",
        "KUNSAN",
        "LAJES",
        "MISAWA",
        "MORÓN",
        "OSAN",
        "PAPA AIR BASE",
        "RAF ",
        "RAMSTEIN",
        "SPANGDAHLEM",
        "STAVANGER",
        "VOLKEL",
        "YOKOTA",
        "FORT BUCHANAN",
        "JOINT REGION MARIANAS - ANDERSEN AFB",
    ]

    recruiting_terms = [
        "USARD,",
        "RECRUITING BATTALION",
        "MEDICAL RECRUITING BATTALION",
        "CADET COMMAND",
    ]

    guard_reserve_terms = [
        " ARW",
        " AW",
        " FW",
        " WG",
        " IW",
        " RQW",
        " ACW",
        " ATKW",
        " SOW",
        " BW",
        " ARB",
        " CES",
        " WING",
    ]

    alias_pairs = [
        ("FORT RUCKER", "Fort Novosel"),
(
    "NAVAL BASE VENTURA COUNTY - POINT MUGU/PORT HUENEME",
    "Naval Base Ventura County",
),
(
    "NAVAL SUPPORT ACTIVITY ANNAPOLIS - U.S. NAVAL ACADEMY",
    "Naval Support Activity Annapolis",
),
        ("FORT GEORGE G. MEADE - NAVY", "Fort Meade"),
        (
            "JOINT BASE ANDREWS-NAVAL AIR FACILITY WASHINGTON",
            "Joint Base Andrews",
        ),
        (
            "JOINT BASE SAN ANTONIO (LACKLAND, RANDOLPH, SAM HOUSTON)",
            "Joint Base San Antonio",
        ),
        (
            "NAVAL BASE VENTURA COUNTY - POINT MUGU/PORT HUENEME",
            "Naval Base Ventura County",
        ),
        (
            "NAVAL SUPPORT ACTIVITY ANNAPOLIS - U.S. NAVAL ACADEMY",
            "Naval Support Activity Annapolis",
        ),
        (
            "NAVAL SUPPORT ACTIVITY BETHESDA HOME OF WALTER REED "
            "NATIONAL MILITARY MEDICAL CENTER",
            "Naval Support Activity Bethesda",
        ),
        (
            "MAXWELL AFB AND GUNTER ANNEX",
            "Maxwell AFB",
        ),
        (
            "USAG ALASKA, WAINWRIGHT",
            "Fort Wainwright",
        ),
        (
            "USAG ALASKA, GREELY",
            "Fort Greely",
        ),
        (
            "USCG BASE PORTSMOUTH",
            "Coast Guard Base Portsmouth",
        ),
    ]

    if any(term in upper for term in overseas_terms):
        return "EXCLUDE - OVERSEAS"

    if any(term in upper for term in recruiting_terms):
        return "EXCLUDE - RECRUITING/CADET"

    if any(term in upper for term in guard_reserve_terms):
        return "EXCLUDE - GUARD/RESERVE"

    for official_alias, existing_alias in alias_pairs:
     if normalize_name(name) == normalize_name(official_alias):
        return "EXISTING ALIAS"

    if score >= 0.82:
        return "REVIEW - LIKELY SAME INSTALLATION"

    return "GENUINE CONUS GAP - REVIEW"

def main():
    official_names = load_official_installations()
    existing_names = load_existing_installations()

    report_rows = []

    matched = 0
    likely_match = 0
    missing = 0

    for official_name in official_names:
        closest_name, score = find_best_match(
            official_name,
            existing_names,
        )

        if score == 1.0:
         status = "MATCHED"
         matched += 1

        else:
         status = classify_candidate(
        official_name,
        closest_name,
        score,
    )

        if status == "REVIEW - LIKELY SAME INSTALLATION":
         likely_match += 1

        elif status == "GENUINE CONUS GAP - REVIEW":
         missing += 1

        report_rows.append(
            {
                "official_installation": official_name,
                "status": status,
                "closest_supabase_installation": closest_name,
                "similarity": f"{score:.3f}",
            }
        )

        status_counts = Counter(
          row["status"]
          for row in report_rows
)

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with OUTPUT_FILE.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as file:
        writer = csv.DictWriter(
            file,
            fieldnames=[
                "official_installation",
                "status",
                "closest_supabase_installation",
                "similarity",
            ],
        )

        writer.writeheader()
        writer.writerows(report_rows)

    print()
    print("Installation gap audit complete")
    print("--------------------------------")
    print(f"Official installation entries found: {len(official_names)}")
    print(f"Current Supabase installations:      {len(existing_names)}")
    print()

    for status, count in sorted(status_counts.items()):
     print(f"{status:<35} {count}")

print()
print(f"Created: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()