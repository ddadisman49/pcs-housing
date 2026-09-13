

import os
import requests
import csv
from pathlib import Path

import openpyxl

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

def load_existing_installations_from_supabase():
    env_file = Path(".env.tools")
    load_env_file(env_file)

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
        },
        timeout=30,
    )

    response.raise_for_status()

    return {
        row["name"].strip()
        for row in response.json()
        if row.get("name")
    }

INPUT_FILE = Path(
    r"tools\data\installations_source.csv"
)

OUTPUT_FILE = Path(
    r"tools\data\installations_supabase.csv"
)

NEW_ONLY_OUTPUT_FILE = Path(
    r"tools\data\installations_new_only.csv"
)

BAH_FILE = Path(
    r"tools\data\BAH-PDF-Excel-2026"
    r"\2026 BAH Rates - Updated with TX270 Temporary Increase.xlsx"
)

REQUIRED_COLUMNS = [
    "name",
    "branch",
    "city",
    "state",
    "zip_code",
    "military_housing_area",
    "latitude",
    "longitude",
]

def load_valid_mhas():
    workbook = openpyxl.load_workbook(
        BAH_FILE,
        read_only=True,
        data_only=True,
    )

    sheet = workbook["With"]

    valid_mhas = set()

    for row in sheet.iter_rows(values_only=True):
        if not row:
            continue

        first_value = row[0]

        if first_value is None:
            continue

        mha = str(first_value).strip().upper()

        if (
            len(mha) == 5
            and mha[:2].isalpha()
            and mha[2:].isdigit()
        ):
            valid_mhas.add(mha)

    return valid_mhas


def validate_rows(valid_mhas):
    with INPUT_FILE.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as input_file:
        reader = csv.DictReader(input_file)

        if reader.fieldnames != REQUIRED_COLUMNS:
            raise ValueError(
                "CSV columns do not match expected columns."
            )

        rows = list(reader)

    seen_names = set()
    clean_rows = []

    for row in rows:
        name = row["name"].strip()

        if not name:
            raise ValueError(
                "Installation name is missing."
            )

        if name in seen_names:
            raise ValueError(
                f"Duplicate installation found: {name}"
            )

        seen_names.add(name)

        mha = (
            row["military_housing_area"]
            .strip()
            .upper()
        )

        if not mha:
            raise ValueError(
                f"MHA is missing for {name}"
            )

        if mha not in valid_mhas:
            raise ValueError(
                f"Invalid 2026 MHA for {name}: {mha}"
            )

        branch = row["branch"].strip()

        city = row["city"].strip()

        state = (
            row["state"]
            .strip()
            .upper()
        )

        zip_code = row["zip_code"].strip()

        latitude = float(
            row["latitude"]
        )

        longitude = float(
            row["longitude"]
        )

        if latitude < -90 or latitude > 90:
            raise ValueError(
                f"Invalid latitude for {name}: "
                f"{latitude}"
            )

        if longitude < -180 or longitude > 180:
            raise ValueError(
                f"Invalid longitude for {name}: "
                f"{longitude}"
            )

        clean_rows.append(
            {
                "name": name,
                "branch": branch,
                "city": city,
                "state": state,
                "zip_code": zip_code,
                "military_housing_area": mha,
                "latitude": latitude,
                "longitude": longitude,
            }
        )

    return clean_rows


def write_csv(path, rows):
    with path.open(
        "w",
        encoding="utf-8",
        newline="",
    ) as output_file:
        writer = csv.DictWriter(
            output_file,
            fieldnames=REQUIRED_COLUMNS,
        )

        writer.writeheader()
        writer.writerows(rows)


def main():
    valid_mhas = load_valid_mhas()

    clean_rows = validate_rows(
        valid_mhas
    )

    write_csv(
        OUTPUT_FILE,
        clean_rows,
    )

    existing_installations = load_existing_installations_from_supabase()

    new_rows = [
        row
        for row in clean_rows
        if row["name"]
        not in existing_installations
    ]

    write_csv(
        NEW_ONLY_OUTPUT_FILE,
        new_rows,
    )

    print(
        f"Official 2026 BAH areas loaded: "
        f"{len(valid_mhas)}"
    )

    print(
        f"Installation validation complete: "
        f"{len(clean_rows)} rows"
    )

    print(
        f"Existing installations skipped: "
        f"{len(clean_rows) - len(new_rows)}"
    )

    print(
        f"New installations ready to import: "
        f"{len(new_rows)}"
    )

    print(
        f"Created {NEW_ONLY_OUTPUT_FILE}"
    )


if __name__ == "__main__":
    main()