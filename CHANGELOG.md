# Changelog

## v0.4.0
- Added bottom tab navigation for Home, Characters, Stellar Jades, and Settings.
- Moved the existing character tracker into the Characters tab.
- Added a Home tab with a persistent Stellar Jade running total.
- Added a Stellar Jades tab with four temporary claim buttons that add to the running total.
- Added a Settings tab action to reset the Stellar Jade count.
- Reorganized active Swift files by responsibility instead of version number.
- Added App, Models, Services, and Views sections for clearer code ownership.
- Split game data models, SwiftData progress storage, JSON loading, and SwiftUI views into separate files.
- Removed retired v0.2.0/v0.3.0 scaffolding files from the active project.
- Added a repeatable importer for `HSR General Character Build Guide 4.5.xlsx`.
- Generated normalized `build_recommendations.json` using existing character, Light Cone, relic, and planar IDs where available.
- Added derived `relic_sets.json` for canonical set metadata built from existing relic data and reviewed aliases.
- Added import alias, override, raw extraction, and validation report files.
- Documented deferred manual-review import items in the README.
- Confirmed the reorganized project builds successfully.

## v0.3.0
- Implemented a proper unit selecter tool, featured with relics and planet sets.
- Image Previews are available as well per character.

## v0.2.1
- Prevented blank character entries from being saved.
- Character, relic, and planet inputs are trimmed before saving.

## v0.2.0
- Characters can be added on a simple basis: type in a name and relic/planet set you would like to use.
- You can toggle a completion check mark to check on your progress.

## v0.1.0
- Inital commit
