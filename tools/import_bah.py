import csv
import re
from pathlib import Path

import openpyxl


INPUT_FILE = Path(
    r"tools\data\BAH-PDF-Excel-2026"
    r"\2026 BAH Rates - Updated with TX270 Temporary Increase.xlsx"
)

OUTPUT_FILE = Path(
    r"tools\data\2026_BAH_Rates_Supabase.csv"
)

YEAR = 2026


def normalize_pay_grade(value: str) -> str:
    value = value.strip().upper()

    match = re.fullmatch(r"([EOW])0?(\d)(E?)", value)

    if not match:
        return value

    prefix, number, suffix = match.groups()

    return f"{prefix}{number}{suffix}"


def load_sheet(workbook, sheet_name: str) -> dict:
    sheet = workbook[sheet_name]

    rows = list(sheet.iter_rows(values_only=True))

    header_row_index = None

    for index, row in enumerate(rows):
        if row and row[0] == "MHA":
            header_row_index = index
            break

    if header_row_index is None:
        raise ValueError(
            f"Could not find header row in sheet: {sheet_name}"
        )

    headers = rows[header_row_index]

    data = {}

    for row in rows[header_row_index + 1:]:
        mha = row[0]

        if not mha:
            continue

        mha_name = row[1]

        for column_index in range(2, len(headers)):
            pay_grade = headers[column_index]

            if not pay_grade:
                continue

            rate = row[column_index]

            if rate is None:
                continue

            normalized_grade = normalize_pay_grade(
                str(pay_grade)
            )

            key = (
                str(mha).strip(),
                str(mha_name).strip(),
                normalized_grade,
            )

            data[key] = rate

    return data


def main():
    workbook = openpyxl.load_workbook(
        INPUT_FILE,
        read_only=True,
        data_only=True,
    )

    with_rates = load_sheet(workbook, "With")
    without_rates = load_sheet(workbook, "Without")

    all_keys = sorted(
        set(with_rates.keys()) | set(without_rates.keys())
    )

    with OUTPUT_FILE.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as csv_file:
        writer = csv.writer(csv_file)

        writer.writerow(
            [
                "year",
                "military_housing_area",
                "mha_name",
                "pay_grade",
                "with_dependents",
                "without_dependents",
            ]
        )

        for key in all_keys:
            mha, mha_name, pay_grade = key

            writer.writerow(
                [
                    YEAR,
                    mha,
                    mha_name,
                    pay_grade,
                    with_rates.get(key),
                    without_rates.get(key),
                ]
            )

    print(
        f"Created {OUTPUT_FILE}"
    )

    print(
        f"Total BAH rows: {len(all_keys)}"
    )


if __name__ == "__main__":
    main()