# Roadmap

## Done
- [x] Visual keyboard (keys, knobs, 3 layers), four board orientations
- [x] Key editor: chords, sequences, text typing, mouse, media, raw HID, capture
- [x] One-click upload, live validation, English / Português UI
- [x] Export a layer to a file and import it back (⤓ / ⤒ next to the layer tabs)
- [x] Reopens on the last edited / uploaded config (including unsaved changes and the selected layer)
- [x] macOS app builder (`scripts/make_app.sh`)

## To do
**Editing**
- [ ] Undo / redo
- [ ] Copy / paste a key, swap two keys (drag & drop), copy a key to another layer
- [ ] Per-key labels ("Desktop 1", "Clear") shown on the virtual keycaps and saved with the config
- [ ] Export / import a whole config (or just a knob) from the clipboard
- [ ] Accents and `ç` in "Type text" + a layout selector (US / ABNT2 / ISO)
- [ ] Command palette / search for key names

**Safety & history**
- [ ] Automatic backup of every uploaded config, with an "upload history" you can restore
- [ ] Visual diff against the last uploaded config
- [ ] Conflict hints: duplicate chords, shortcuts macOS already uses

**Presets**
- [ ] Layer library (macOS shortcuts, Zoom, Premiere, Photoshop, VS Code, media control…)
- [ ] Model presets (3×1, 3×2, 3×3, 4×3…) with accurate drawings and knob numbering
- [ ] "Launch an app from a key" helper: suggests an unused chord and shows how to bind it in macOS Shortcuts

**Output**
- [ ] Printable cheat-sheet / keycap-legend sticker sheet (PDF / PNG)

**Distribution**
- [ ] GitHub Actions: lint + tests, build a signed/notarized `.app` / `.dmg` on release
- [ ] Linux and Windows support (device detection, privilege handling)
- [ ] Unit tests for YAML round-trip, orientation conversion and text→keys
