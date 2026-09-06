#!/usr/bin/env python3
import argparse
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

NS = {
    "m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}

ELEMENT_SHEETS = ["Physical", "Fire", "Ice", "Wind", "Lightning", "Quantum", "Imaginary"]
SOURCE = {"name": "HSR General Character Build Guide", "version": "4.5"}
SUPERSCRIPTS = "¹²³⁴⁵⁶⁷⁸⁹⁰"
SUPERSCRIPT_MAP = str.maketrans("¹²³⁴⁵⁶⁷⁸⁹⁰", "1234567890")


def normalize_name(value):
    value = value or ""
    value = value.replace("’", "'").replace("“", '"').replace("”", '"')
    value = re.sub(r"\s+", " ", value)
    return value.strip(" .")


def match_key(value):
    value = normalize_name(value).lower()
    return re.sub(r"[^a-z0-9]+", "", value)


def split_lines(value):
    if not value:
        return []
    normalized = value.replace("\r\n", "\n").replace("\r", "\n")
    return [part.strip() for part in re.split(r"\n|\s+\|\s+", normalized) if part.strip()]


def column_number(cell_reference):
    match = re.match(r"([A-Z]+)", cell_reference)
    number = 0
    for character in match.group(1):
        number = number * 26 + ord(character) - 64
    return number


def read_cell_text(cell, shared_strings):
    if cell.attrib.get("t") == "inlineStr":
        return "".join(text.text or "" for text in cell.iter(f"{{{NS['m']}}}t"))

    value = cell.find("m:v", NS)
    if value is None:
        return ""

    text = value.text or ""
    if cell.attrib.get("t") == "s":
        return shared_strings[int(text)]

    return text


def load_workbook(path):
    with zipfile.ZipFile(path) as archive:
        shared_strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            for item in root.findall("m:si", NS):
                shared_strings.append("".join(text.text or "" for text in item.iter(f"{{{NS['m']}}}t")))

        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        relationship_paths = {rel.attrib["Id"]: rel.attrib["Target"] for rel in relationships}
        sheets = {}

        for sheet in workbook.find("m:sheets", NS):
            name = sheet.attrib["name"].strip()
            relationship_id = sheet.attrib[f"{{{NS['r']}}}id"]
            sheet_path = "xl/" + relationship_paths[relationship_id]
            rows = defaultdict(dict)
            root = ET.fromstring(archive.read(sheet_path))

            for row in root.findall("m:sheetData/m:row", NS):
                row_index = int(row.attrib["r"])
                for cell in row.findall("m:c", NS):
                    col_index = column_number(cell.attrib["r"])
                    rows[row_index][col_index] = read_cell_text(cell, shared_strings).strip()

            sheets[name] = rows

        return sheets


def load_source_data(resource_dir):
    return {
        "characters": json.loads((resource_dir / "characters.json").read_text()),
        "light_cones": json.loads((resource_dir / "light_cones.json").read_text()),
        "relics": json.loads((resource_dir / "relics.json").read_text()),
    }


def extract_annotations(value):
    return [marker.translate(SUPERSCRIPT_MAP) for marker in re.findall(f"[{SUPERSCRIPTS}]+", value or "")]


def strip_annotations(value):
    return re.sub(f"[{SUPERSCRIPTS}]+", "", value or "").strip()


def extract_conditions(value):
    conditions = []
    for condition in re.findall(r"\(([^)]+)\)", value or ""):
        conditions.append(normalize_name(condition))
    prefix = re.match(r"^\s*For\s+([^:]+):\s*(.+)$", value or "", re.IGNORECASE)
    if prefix:
        conditions.append("For " + normalize_name(prefix.group(1)))
    return conditions


def extract_availability(value):
    values = []
    for availability in re.findall(r"\[([^]]+)\]", value or ""):
        values.append(normalize_name(availability))
    return values or None


def clean_ranked_name(value):
    value = normalize_name(strip_annotations(value))
    value = re.sub(r"^\s*For\s+[^:]+:\s*", "", value, flags=re.IGNORECASE)
    value = re.sub(r"^(~~|\*)\s*", "", value).strip()
    value = re.sub(r"^\d+\s*(?:-\s*|\.\)\s*|\.\s*|\)\s*)", "", value).strip()
    value = re.sub(r"\[[^]]+\]", "", value).strip()
    value = re.sub(r"\([^)]*\)", "", value).strip()
    value = re.sub(r"[345]★", "", value).strip()
    value = re.sub(r"^(?:4|2)\s*[- ]?\s*PC\s*:\s*", "", value, flags=re.IGNORECASE).strip()
    value = re.sub(r"^\d+\s*[- ]?\s*PC\s*:\s*", "", value, flags=re.IGNORECASE).strip()
    value = re.sub(r"^PC\s*:\s*", "", value, flags=re.IGNORECASE).strip()
    return normalize_name(value)


def split_recommendation_cell(value):
    return split_lines(value)


def parse_ranked_items(value, item_type, aliases, validation, build_context):
    items = []
    last_rank = None

    for raw_item in split_recommendation_cell(value):
        if raw_item in {"-", "Equipment", "Light Cone", "4 Piece Set (Relic Set)", "2 Piece Set (Planar Ornament)"}:
            continue

        tied = raw_item.strip().startswith("~~")
        special = raw_item.strip().startswith("*")
        rank_match = re.match(r"^\s*(?:~~\s*)?(\d+)\s*(?:-\s*|\.\)|\.|\))", raw_item)
        if rank_match:
            last_rank = int(rank_match.group(1))
        rank = last_rank

        pieces = None
        piece_match = re.search(r"\b([24])\s*[- ]?\s*PC\b", raw_item, re.IGNORECASE)
        if piece_match:
            pieces = int(piece_match.group(1))

        source_name = clean_ranked_name(raw_item)
        if not source_name or source_name in {"Set", "Sets", "Choose 1", "Choose 2", "Support Build", "Sub DPS Build", "Battery Build", "Please read the \"Other Notes\" section"}:
            if source_name:
                validation["uninterpreted_lines"].append({"context": build_context, "text": raw_item})
            continue

        item = {
            "source_name": source_name,
            "rank": rank,
            "tied": tied,
            "special": special,
            "availability": extract_availability(raw_item),
            "conditions": extract_conditions(raw_item),
            "footnote_refs": extract_annotations(raw_item),
        }

        if item_type == "light_cone":
            canonical = aliases["light_cones"].get(source_name, source_name)
            light_cone_id = aliases["_light_cone_name_to_id"].get(match_key(canonical))
            item["light_cone_id"] = light_cone_id
            if light_cone_id is None:
                validation["unmatched_light_cones"][source_name].add(build_context)
        else:
            item["pieces"] = pieces
            set_aliases = aliases["relic_sets"] if item_type == "relic_set" else aliases["planar_sets"]
            set_id = set_aliases.get(source_name)
            item["set_id"] = set_id
            if set_id is None:
                validation[f"unmatched_{item_type}s"][source_name].add(build_context)

        items.append(item)

    return items


def parse_stats(value, aliases, validation, context):
    stats = []
    raw_parts = []
    for item in split_lines(value):
        raw_parts.extend(part.strip() for part in re.split(r"/|,|\bor\b", item) if part.strip())

    for part in raw_parts:
        clean = normalize_name(strip_annotations(part))
        clean = re.sub(r"\([^)]*\)", "", clean).strip()
        clean = re.sub(r"\s+", " ", clean)
        stat_id = aliases["stats"].get(clean)
        if stat_id:
            stats.append(stat_id)
        elif clean:
            stats.append({"source": clean})
            validation["unknown_stats"][clean].add(context)

    return stats


def parse_substats(value, aliases, validation, context):
    priorities = []
    last_rank = None

    for raw_item in split_recommendation_cell(value):
        tied = raw_item.strip().startswith("~~")
        rank_match = re.match(r"^\s*(?:~~\s*)?(\d+)\s*(?:-\s*|\.\)|\.|\))", raw_item)
        if rank_match:
            last_rank = int(rank_match.group(1))
        clean = re.sub(r"^\s*(?:~~\s*)?\d+\s*(?:-\s*|\.\)\s*|\.\s*|\)\s*)", "", raw_item)
        clean = re.sub(r"^\s*~~\s*", "", clean)
        stats = parse_stats(clean, aliases, validation, context)
        if stats:
            priorities.append({"rank": last_rank, "stats": stats, "tied": tied, "footnote_refs": extract_annotations(raw_item)})

    return priorities


def parse_stat_targets(value, aliases, validation, context):
    targets = []
    for raw_item in split_lines(value):
        footnote_refs = extract_annotations(raw_item)
        clean = normalize_name(strip_annotations(raw_item))
        match = re.match(r"^([^:]+):\s*(.+)$", clean)
        if match:
            source_stat = normalize_name(match.group(1))
            stat_id = aliases["stats"].get(source_stat)
            if not stat_id:
                validation["unknown_stats"][source_stat].add(context + " stat target")
                stat_id = {"source": source_stat}
            targets.append({
                "stat": stat_id,
                "target": normalize_name(match.group(2)),
                "footnote_refs": footnote_refs,
            })
        elif clean:
            targets.append({"source_text": clean, "footnote_refs": footnote_refs})
    return targets


def parse_ability_priority(rows, start, end):
    abilities = []
    for row_index in range(start, end):
        for col in (8, 9):
            value = rows.get(row_index, {}).get(col, "")
            for item in split_lines(value):
                clean = normalize_name(strip_annotations(item))
                if clean == "Ability Priority":
                    continue
                match = re.match(r"^(~~\s*)?(\d+)\s*(?:-\s*|\.\)\s*|\.\s*|\)\s*)(.+)$", clean)
                if match:
                    abilities.append({
                        "rank": int(match.group(2)),
                        "ability": normalize_name(match.group(3)),
                        "tied": bool(match.group(1)),
                        "footnote_refs": extract_annotations(item),
                    })
                elif clean and clean != "-":
                    abilities.append({"rank": None, "ability": clean, "tied": clean.startswith("~~"), "footnote_refs": extract_annotations(item)})
    return abilities


def parse_notes(rows, start, end):
    notes = {"relics": [], "abilities": [], "general": [], "references": []}
    variant_notes = defaultdict(list)
    current_label = None

    for row_index in range(start, end):
        label = normalize_name(rows.get(row_index, {}).get(3, ""))
        text = normalize_name(rows.get(row_index, {}).get(4, ""))
        ability_note = normalize_name(rows.get(row_index, {}).get(11, ""))

        if ability_note and ability_note != "Ability Notes":
            notes["abilities"].extend(split_lines(ability_note))

        if not label and not text:
            continue

        if label.startswith("Relic Notes"):
            current_label = "relics"
        elif label.startswith("Other Notes"):
            current_label = "general"
        elif label.startswith("References"):
            current_label = "references"
        elif label.startswith("Notes"):
            current_label = "variant"
            variant_notes[label].extend(split_lines(text))
            continue
        elif label in {"Role:", "Archetype:"}:
            continue

        if current_label == "variant" and text:
            variant_notes[label].extend(split_lines(text))
        elif current_label in notes and text:
            notes[current_label].extend(split_lines(text))
        elif label and text and label not in {"Role:", "Archetype:"}:
            notes["general"].append(" ".join([label, text]).strip())
        elif label and not text and label not in {"Role:", "Archetype:"}:
            notes["general"].append(label)

    return notes, dict(variant_notes)


def parse_role_or_archetype(value, aliases=None):
    parts = []
    for item in split_lines(value):
        clean = normalize_name(item)
        clean = re.sub(r"^(Role|Archetype):\s*", "", clean)
        if not clean or clean in {"Role:", "Archetype:"}:
            continue
        if aliases:
            parts.append(aliases.get(clean, re.sub(r"[^a-z0-9]+", "_", clean.lower()).strip("_")))
        else:
            parts.append(re.sub(r"[^a-z0-9]+", "_", clean.lower()).strip("_"))
    return [part for part in parts if part]


def find_block_starts(rows):
    starts = []
    for row_index, cells in sorted(rows.items()):
        if cells.get(2) and cells.get(3) and cells.get(4) == "Equipment":
            starts.append(row_index)
    return starts


def find_variant_starts(rows, start, end):
    starts = [start]
    for row_index in range(start + 1, end):
        cells = rows.get(row_index, {})
        label = normalize_name(cells.get(3, ""))
        has_recommendations = bool(cells.get(4))
        if label.startswith("Role:") and has_recommendations:
            starts.append(row_index)
    return starts


def build_variant_label(rows, variant_start, block_start, overrides):
    if variant_start == block_start:
        return "General"
    previous_notes = None
    for row_index in range(variant_start - 1, block_start - 1, -1):
        label = normalize_name(rows.get(row_index, {}).get(3, ""))
        if label.startswith("Notes"):
            previous_notes = overrides["build_variant_labels"].get(label, label.replace("Notes |", "").strip())
            break
    roles = parse_role_or_archetype(rows.get(variant_start, {}).get(2, ""))
    return previous_notes or (roles[0].replace("_", " ").title() if roles else f"Variant {variant_start - block_start + 1}")


def parse_variant(rows, block_start, variant_start, variant_end, aliases, overrides, validation, context):
    row = rows.get(variant_start, {})
    next_row = rows.get(variant_start + 1, {})
    build_id = re.sub(r"[^a-z0-9]+", "_", build_variant_label(rows, variant_start, block_start, overrides).lower()).strip("_") or "default"
    label = build_variant_label(rows, variant_start, block_start, overrides)

    light_cone_text = rows.get(block_start + 2, {}).get(4, "") if variant_start == block_start else row.get(4, "")
    relic_text = rows.get(block_start + 2, {}).get(5, "") if variant_start == block_start else next_row.get(5, "")
    planar_row = variant_start + 9 if variant_start == block_start else variant_start + 7
    main_stat_start = variant_start + 4 if variant_start == block_start else variant_start + 2

    notes, variant_notes = parse_notes(rows, variant_start, variant_end)
    for note_label, note_values in variant_notes.items():
        normalized_label = overrides["build_variant_labels"].get(note_label, note_label)
        if match_key(normalized_label) == match_key(label):
            notes["general"].extend(note_values)

    roles = parse_role_or_archetype(rows.get(variant_start + 8, {}).get(3, "") if variant_start == block_start else row.get(3, ""), aliases["roles"])
    archetypes = parse_role_or_archetype(rows.get(variant_start + 11, {}).get(3, "") if variant_start == block_start else rows.get(variant_start + 5, {}).get(3, ""))
    baseline = rows.get(planar_row, {}).get(7, "")

    build = {
        "id": "default" if variant_start == block_start else build_id,
        "label": label,
        "roles": roles,
        "archetypes": archetypes,
        "light_cones": parse_ranked_items(light_cone_text, "light_cone", aliases, validation, context),
        "relic_sets": parse_ranked_items(relic_text, "relic_set", aliases, validation, context),
        "planar_sets": parse_ranked_items(rows.get(planar_row, {}).get(5, ""), "planar_set", aliases, validation, context),
        "main_stats": {
            "body": parse_stats(rows.get(main_stat_start, {}).get(6, ""), aliases, validation, context + " body"),
            "feet": parse_stats(rows.get(main_stat_start + 3, {}).get(6, ""), aliases, validation, context + " feet"),
            "sphere": parse_stats(rows.get(main_stat_start + 6, {}).get(6, ""), aliases, validation, context + " sphere"),
            "rope": parse_stats(rows.get(main_stat_start + 9, {}).get(6, ""), aliases, validation, context + " rope"),
        },
        "substats": parse_substats(rows.get(block_start + 2, {}).get(7, "") if variant_start == block_start else row.get(7, ""), aliases, validation, context + " substats"),
        "stat_targets": parse_stat_targets(baseline, aliases, validation, context),
        "ability_priority": parse_ability_priority(rows, variant_start, variant_end),
        "notable_eidolons": split_lines(rows.get(block_start + 2, {}).get(10, "") if variant_start == block_start else row.get(10, "")),
        "notes": notes,
    }

    if not build["light_cones"] or not build["relic_sets"] or not build["planar_sets"]:
        validation["missing_required_fields"].append({
            "context": context,
            "build_id": build["id"],
            "missing": [key for key in ["light_cones", "relic_sets", "planar_sets"] if not build[key]],
        })

    return build


def match_characters(name, element, path, aliases, overrides, characters, validation, context):
    canonical_name = overrides["character_name_aliases"].get(name, name)
    canonical_element = aliases["elements"].get(element, element)
    source_path = normalize_name(re.sub(r"\[[^]]+\]", "", path))
    canonical_path = aliases["paths"].get(source_path, source_path)
    matches = []

    for character_id, character in characters.items():
        name_matches = match_key(character["name"]) == match_key(canonical_name)
        trailblazer_matches = canonical_name == "Trailblazer" and character["name"] == "{NICKNAME}"
        if (name_matches or trailblazer_matches) and character["element"] == canonical_element and character["path"] == canonical_path:
            matches.append(character_id)

    if not matches:
        validation["unmatched_characters"].append({
            "context": context,
            "name": name,
            "element": element,
            "path": path,
            "expected_element": canonical_element,
            "expected_path": canonical_path,
        })

    return matches


def build_relic_sets_resource(relics, aliases):
    grouped = defaultdict(list)
    for relic in relics.values():
        grouped[relic["set_id"]].append(relic)

    names_by_id = {}
    for category in ("relic_sets", "planar_sets"):
        for name, set_id in aliases[category].items():
            names_by_id.setdefault(set_id, name)

    resource = {}
    for set_id, name in sorted(names_by_id.items(), key=lambda item: int(item[0])):
        if set_id not in grouped:
            continue
        expected_category = "planar" if set_id.startswith("3") else "relic"
        representative = sorted(grouped[set_id], key=lambda item: item["id"])[0]
        resource[set_id] = {
            "id": set_id,
            "name": name,
            "category": expected_category,
            "icon": representative["icon"],
            "source": "derived_from_existing_relics_json_and_import_aliases",
        }
    return resource


def convert_sets_to_lists(value):
    if isinstance(value, defaultdict):
        return {key: sorted(list(items)) for key, items in sorted(value.items())}
    if isinstance(value, dict):
        return {key: convert_sets_to_lists(item) for key, item in value.items()}
    if isinstance(value, set):
        return sorted(list(value))
    if isinstance(value, list):
        return [convert_sets_to_lists(item) for item in value]
    return value


def validate_references(output, source_data, relic_sets_resource, validation):
    character_ids = set(source_data["characters"])
    light_cone_ids = set(source_data["light_cones"])
    relic_set_ids = {set_id for set_id, value in relic_sets_resource.items() if value["category"] == "relic"}
    planar_set_ids = {set_id for set_id, value in relic_sets_resource.items() if value["category"] == "planar"}
    duplicate_ids = [item for item, count in Counter(output.keys()).items() if count > 1]
    validation["duplicate_character_keys"] = duplicate_ids

    for character_id, record in output.items():
        if character_id not in character_ids:
            validation["invented_or_missing_character_ids"].append(character_id)
        for build in record["builds"]:
            for item in build["light_cones"]:
                light_cone_id = item.get("light_cone_id")
                if light_cone_id and light_cone_id not in light_cone_ids:
                    validation["invalid_light_cone_ids"].append({"character_id": character_id, "light_cone_id": light_cone_id})
            for item in build["relic_sets"]:
                set_id = item.get("set_id")
                if set_id and set_id not in relic_set_ids:
                    validation["invalid_relic_set_ids"].append({"character_id": character_id, "set_id": set_id, "source_name": item["source_name"]})
            for item in build["planar_sets"]:
                set_id = item.get("set_id")
                if set_id and set_id not in planar_set_ids:
                    validation["invalid_planar_set_ids"].append({"character_id": character_id, "set_id": set_id, "source_name": item["source_name"]})


def write_markdown_report(path, report):
    def count(value):
        return len(value) if hasattr(value, "__len__") else 0

    lines = [
        "# Build Recommendations Import Validation",
        "",
        "| Check | Result |",
        "| --- | --- |",
        f"| Workbook character builds found | {report['workbook_character_builds_found']} |",
        f"| Matched existing character IDs | {report['matched_character_ids']} |",
        f"| Unmatched workbook characters | {count(report['unmatched_characters'])} |",
        f"| Light Cone recommendations | {report['light_cone_recommendations']} |",
        f"| Matched Light Cone recommendations | {report['matched_light_cone_recommendations']} |",
        f"| Unmatched Light Cone names | {count(report['unmatched_light_cones'])} |",
        f"| Matched relic-set recommendations | {report['matched_relic_set_recommendations']} |",
        f"| Unmatched relic-set names | {count(report['unmatched_relic_sets'])} |",
        f"| Matched planar-set recommendations | {report['matched_planar_set_recommendations']} |",
        f"| Unmatched planar-set names | {count(report['unmatched_planar_sets'])} |",
        f"| Unknown stat values | {count(report['unknown_stats'])} |",
        f"| Duplicate character keys | {count(report['duplicate_character_keys'])} |",
        f"| Missing required fields | {count(report['missing_required_fields'])} |",
        f"| Records with multiple build variants | {count(report['multiple_build_variant_records'])} |",
        f"| Validation failed | {report['validation_failed']} |",
        "",
        "## Unresolved Items",
        "",
    ]

    sections = [
        ("Unmatched Characters", report["unmatched_characters"]),
        ("Unmatched Light Cones", report["unmatched_light_cones"]),
        ("Unmatched Relic Sets", report["unmatched_relic_sets"]),
        ("Unmatched Planar Sets", report["unmatched_planar_sets"]),
        ("Unknown Stats", report["unknown_stats"]),
        ("Uninterpreted Lines", report["uninterpreted_lines"]),
        ("Expanded Trailblazer Matches", report["expanded_character_matches"]),
        ("Multiple Build Variants", report["multiple_build_variant_records"]),
    ]

    for title, values in sections:
        lines.append(f"### {title}")
        if not values:
            lines.extend(["None.", ""])
            continue
        if isinstance(values, dict):
            for key, contexts in values.items():
                lines.append(f"- `{key}`: {', '.join(contexts[:6])}")
        else:
            for value in values[:40]:
                lines.append(f"- `{json.dumps(value, ensure_ascii=False)}`")
            if len(values) > 40:
                lines.append(f"- ... {len(values) - 40} more")
        lines.append("")

    path.write_text("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workbook", default="HSR Tracker/HSR General Character Build Guide 4.5.xlsx")
    parser.add_argument("--resource-dir", default="HSR Tracker/HSR Tracker")
    parser.add_argument("--aliases", default="ImportData/build_recommendation_aliases.json")
    parser.add_argument("--overrides", default="ImportData/build_recommendation_overrides.json")
    parser.add_argument("--audit-dir", default="ImportAudit")
    args = parser.parse_args()

    workbook_path = Path(args.workbook)
    resource_dir = Path(args.resource_dir)
    audit_dir = Path(args.audit_dir)
    audit_dir.mkdir(parents=True, exist_ok=True)

    aliases = json.loads(Path(args.aliases).read_text())
    overrides = json.loads(Path(args.overrides).read_text())
    source_data = load_source_data(resource_dir)
    aliases["_light_cone_name_to_id"] = {match_key(value["name"]): key for key, value in source_data["light_cones"].items()}

    sheets = load_workbook(workbook_path)
    validation = {
        "workbook_character_builds_found": 0,
        "matched_character_ids": 0,
        "unmatched_characters": [],
        "ambiguous_character_matches": [],
        "expanded_character_matches": [],
        "unmatched_light_cones": defaultdict(set),
        "unmatched_relic_sets": defaultdict(set),
        "unmatched_planar_sets": defaultdict(set),
        "unknown_stats": defaultdict(set),
        "missing_required_fields": [],
        "duplicate_character_keys": [],
        "invented_or_missing_character_ids": [],
        "invalid_light_cone_ids": [],
        "invalid_relic_set_ids": [],
        "invalid_planar_set_ids": [],
        "multiple_build_variant_records": [],
        "uninterpreted_lines": [],
    }
    output = {}
    audit_records = []

    for sheet_name in ELEMENT_SHEETS:
        rows = sheets[sheet_name]
        starts = find_block_starts(rows)
        bounds = starts + [max(rows.keys()) + 1]

        for index, start in enumerate(starts):
            end = bounds[index + 1]
            character_name = normalize_name(rows[start].get(2, ""))
            path_value = normalize_name(rows[start].get(3, "")).split("\n")[0]
            context = f"{sheet_name} row {start} {character_name}"
            validation["workbook_character_builds_found"] += 1

            character_ids = match_characters(character_name, sheet_name, path_value, aliases, overrides, source_data["characters"], validation, context)
            if len(character_ids) > 1:
                validation["expanded_character_matches"].append({"context": context, "character_ids": character_ids})

            variant_starts = find_variant_starts(rows, start, end)
            variant_bounds = variant_starts + [end]
            builds = []

            for variant_index, variant_start in enumerate(variant_starts):
                variant_end = variant_bounds[variant_index + 1]
                builds.append(parse_variant(rows, start, variant_start, variant_end, aliases, overrides, validation, context))

            if len(builds) > 1:
                validation["multiple_build_variant_records"].append({"context": context, "build_count": len(builds)})

            audit_records.append({
                "sheet": sheet_name,
                "start_row": start,
                "end_row": end - 1,
                "source_character_name": character_name,
                "source_element": sheet_name,
                "source_path": path_value,
                "matched_character_ids": character_ids,
                "builds": builds,
            })

            for character_id in character_ids:
                output[character_id] = {
                    "character_id": character_id,
                    "source_character_name": character_name,
                    "source": SOURCE,
                    "builds": builds,
                }
                validation["matched_character_ids"] += 1

    relic_sets_resource = build_relic_sets_resource(source_data["relics"], aliases)
    validate_references(output, source_data, relic_sets_resource, validation)

    (resource_dir / "build_recommendations.json").write_text(json.dumps(output, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    (resource_dir / "relic_sets.json").write_text(json.dumps(relic_sets_resource, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    (audit_dir / "build_recommendations_raw.json").write_text(json.dumps(audit_records, indent=2, ensure_ascii=False) + "\n")

    validation_report = convert_sets_to_lists(validation)
    validation_report["light_cone_recommendations"] = sum(
        len(build["light_cones"]) for record in output.values() for build in record["builds"]
    )
    validation_report["matched_light_cone_recommendations"] = sum(
        1 for record in output.values() for build in record["builds"] for item in build["light_cones"] if item.get("light_cone_id")
    )
    validation_report["matched_relic_set_recommendations"] = sum(
        1 for record in output.values() for build in record["builds"] for item in build["relic_sets"] if item.get("set_id")
    )
    validation_report["matched_planar_set_recommendations"] = sum(
        1 for record in output.values() for build in record["builds"] for item in build["planar_sets"] if item.get("set_id")
    )

    failed = bool(
        validation_report["duplicate_character_keys"]
        or validation_report["invented_or_missing_character_ids"]
        or validation_report["invalid_light_cone_ids"]
        or validation_report["invalid_relic_set_ids"]
        or validation_report["invalid_planar_set_ids"]
        or validation_report["missing_required_fields"]
    )
    validation_report["validation_failed"] = failed

    (audit_dir / "build_recommendations_validation.json").write_text(json.dumps(validation_report, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    write_markdown_report(audit_dir / "build_recommendations_validation.md", validation_report)
    print(json.dumps({
        "records": len(output),
        "workbook_character_builds_found": validation_report["workbook_character_builds_found"],
        "matched_character_ids": validation_report["matched_character_ids"],
        "unmatched_characters": len(validation_report["unmatched_characters"]),
        "unmatched_light_cones": len(validation_report["unmatched_light_cones"]),
        "unmatched_relic_sets": len(validation_report["unmatched_relic_sets"]),
        "unmatched_planar_sets": len(validation_report["unmatched_planar_sets"]),
        "unknown_stats": len(validation_report["unknown_stats"]),
        "validation_failed": failed,
    }, indent=2))
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
