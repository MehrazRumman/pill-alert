# Nirbhor — Screen Implementation Brief (read this fully before coding)

You are implementing one or more **screens** of Nirbhor, a bilingual (Bangla-primary / English)
Android medication-reminder app, in **Jetpack Compose / Kotlin**. The foundation (theme, components,
data layer, navigation) is already built. Your job is to replace **stub screen files** with faithful
implementations of the design.

## The design is the spec
- **Spec (authoritative):** `/private/tmp/claude-501/-Users-rumman-pill-alert/6d13a4c7-1b50-44a0-a697-197d75d46650/scratchpad/design/uploads/Pill Reminder App Design/README.md`
- **Exact copy / values (HTML canvas):** `…/Nirbhor Pill Reminder.dc.html` (same folder). `grep` it for a
  screen's Bangla/English strings when you need exact wording. Do **not** port HTML/CSS — rebuild with
  the components below.
- Read the README section for **your** screen id(s) closely. Follow copy in **both** languages.

## Hard rules (from the design principles — these must survive)
1. **Never introduce red.** Missed / low-stock / errors / delete all use `warm` / `warmD`.
2. **Meaning three ways at once** for dose status: shape mark + fill + word. Never colour alone.
3. **Bangla text: never** apply `letterSpacing`, `uppercase`, or split/highlight substrings. Use the
   provided components which already handle this.
4. **Numerals are locale-level.** Never hard-code digits in a user-facing string. Use `num()`,
   `numStr()`, `percent()`, `clock()` (see i18n below) so Bangla shows Bengali numerals (০১২৩৪৫৬৭৮৯).
5. **Touch targets:** honour the sizes in the README (48 min, 56 dose-confirm, 60–68 flow, 72 stepper,
   80 alarm confirm).
6. A medicine's **mark is fixed and stored** — always render it via its stored `MarkShape` + `markColor`.

## Do NOT
- Do **not** edit any shared file (anything under `ui/theme`, `ui/components`, `ui/marks`, `ui/i18n`,
  `data`, `domain`, `navigation`, `notifications`). If you need a new reusable helper, add it as a
  **private** composable inside your own screen file.
- Do **not** run `./gradlew` or start the Gradle daemon (other agents are building concurrently; the
  parent will compile everything centrally). Just write correct Kotlin.
- Do **not** change function signatures of the stub you're implementing, or the navigation graph.

## Files you own
You are told exactly which screen file(s) to implement. Replace the stub body; keep the package
(`com.nirbhor.app.ui.screens`) and the existing function signature.

---

## The API you build with

### Theme tokens — `com.nirbhor.app.ui.theme.NirbhorTheme`
`NirbhorTheme.colors.<token>` and `NirbhorTheme.type.<role>` inside any @Composable.
Colours: `ink, ink2, ink3, paper, card, sage, line, calm, calmD, calmSoft, warm, warmSoft, warmD`,
mark accents `markSlate, markOchre, markMauve`, dark-alarm `markCalmOnDark, markSlateOnDark, alarmText`.
Type roles: `titleHero, header, alarmTime, alarmName, bigStat, cardTitlePrimary, cardTitleSecondary,
body, meta, sectionLabel, buttonLabel, statusPill`.
Spacing/radius/targets: `com.nirbhor.app.ui.theme.Dimens.*` and shapes `NirbhorShapes.*`.

### i18n — `com.nirbhor.app.ui.i18n.*`
- `tr("বাংলা", "English")` → picks copy for the active locale (`@Composable`).
- `num(int)`, `numStr("৫৪টি"/"54 left")`, `percent(int)`, `clock(hour, minute)` → localised numerals/time.
- `LocalIsBangla.current` : Boolean if you need to branch.

### Marks — `com.nirbhor.app.ui.marks.*`
`MedicineMark(shape = medicine.mark, color = Color(medicine.markColor), size = 34.dp)`.
On the dark alarm surface, lighten to `markCalmOnDark` / `markSlateOnDark`.

### Components — `com.nirbhor.app.ui.components.*`
- `PrimaryButton(text, onClick, height=, leftAligned=, leading=, container=, content=)`,
  `SecondaryButton(...)` (outlined).
- `NbCard{}`, `UrgentCard{}` (2px warm border + amber shadow — due-now), `TintPanel(background){}`
  (flat sage / calmSoft / warmSoft panels), plus `Modifier.nbCardShadow(shape, elevated)`.
- `SectionLabel(text)` (handles EN-uppercase / BN-sentence-case automatically),
  `StatusPill(text, background, contentColor)`.
- `ProgressRing(fraction, diameter=, strokeWidth=, center={})` (home ring + record donut).
- `NbSwitch(checked, onCheckedChange, onColor=)`, `SegmentedControl(options, selectedIndex, onSelect)`,
  `QuantityStepper(value, onChange, valueLabel, unitLabel, size=, step=)`,
  `QuickChip(label, selected, onClick)`, `SelectableRow(title, selected, onClick, subtitle=, leading=)`,
  `CheckCircle(selected)`.
- `NirbhorTopBar(title, onBack=, trailing=)` (pushed-screen header),
  `BottomNavBar(...)` (provided by the app root — do not add it to pushed screens),
  `Scrim(onDismiss)`, `SheetSurface{}` (bottom-sheet container: 24px top, grab handle),
  `UndoToast(message, actionLabel, onAction)`.
- Icons: use `androidx.compose.material.icons.Icons.*` (material-icons-extended) as Lucide stand-ins
  (ArrowBack, Check, Add, Remove, Notifications, CameraAlt, Search, Mic, Mail, Smartphone, People,
  Download, WarningAmber (use for alert-triangle, still amber/warm — never red), Info, Lock, BarChart,
  Share, Upload, WbSunny, Brightness3/DarkMode for moon, Schedule for clock).

### Data — `com.nirbhor.app.navigation.LocalAppContainer.current`
`.repository` is a `NirbhorRepository`; `.settings` is a `SettingsStore`; `.appScope` a CoroutineScope.
Read models with `collectAsStateWithLifecycle`. Key repository API:
- `repository.medicines: Flow<List<Medicine>>`, `repository.medicine(id): Flow<Medicine?>`
- `repository.timelineFor(LocalDate.now()): Flow<List<TimelineBlock>>` (home) — each block has
  `block, hour, minute, doses: List<DoseWithMedicine>`, plus `allTaken`, `anyDueNow`.
- `repository.stockStatuses(): Flow<List<StockStatus>>`
- `repository.primaryCaregiver: Flow<Caregiver?>`, `repository.alertLog(): Flow<List<AlertLogItem>>`
- suspend: `markTaken(doseId, source, late)`, `undoTaken(doseId)`, `skipDose(doseId)`,
  `snoozeDose(doseId)`, `addStock(id, delta)`, `setStock(id, count)`, `upsertMedicine(m)`,
  `deleteMedicine(id)`, `upsertCaregiver(c)`, `adherenceOver(days): AdherenceWindow`.
Call suspend functions from `rememberCoroutineScope().launch { }` or the container's `appScope`.
Domain models + enums are in `com.nirbhor.app.domain.*` (Medicine, DoseOccurrence, DoseWithMedicine,
TimelineBlock, DoseStatus, TimeBlock, FoodRelation, Frequency, Caregiver, StockStatus, AppSettings…).

### Add-medicine flow shared state — `com.nirbhor.app.domain.LocalAddDraft.current`
A mutable `AddMedicineDraft` (displayName, packName, strength, form, condition, mark, markColor,
dosePerIntake, foodRelation, timeTokens, resolvedTimes, frequency, weekdaysMask, stockCount, highRisk).
Read/write across steps; `.toMedicine()` builds the record; `.reset()` after finishing.

### Navigation — `actions: NavActions` (passed into every screen)
`back()`, `finishOnboarding()`, `openMedicine(id)`, `openInbox()`, `openRefill()`, `openFamily()`,
`openCaregiverNotify()`, `openCaregiverCode()`, `openDoctorReport()`, `openSettings()`,
`openAlarmPreview()`, `openPermissionPriming()`, and the add-flow: `startAddMedicine()`, `addScan()`,
`addSearch()`, `addPrescription()`, `addTiming()`, `addQuantity()`, `addReview()`, `finishAddMedicine()`.

## Layout defaults
- Designed at 412×892. Single column, vertically scrollable (`Column` + `verticalScroll` or
  `LazyColumn`); header + bottom nav are fixed. Screen horizontal padding **20.dp** (`Dimens.screenPadding`).
- Must tolerate 360px width and 130% font scale without clipping — Bangla screens are the tight ones.
- Respect the OS reduce-motion setting for any animation (keep animation minimal per the README).
- Pushed screens: start with `NirbhorTopBar(...)`, then a scrollable body on `colors.paper`.
- Main-tab screens (Home/Cabinet/Record/More): no top bar chrome from you beyond the in-content header
  the design shows; the bottom nav is added by the app root.

## Quality bar
High fidelity. Match colours, type roles, spacing, radii, and copy to the README. When a value is a
range, pick the middle. Prefer the provided components over re-rolling primitives. Keep new helpers
private and local. Comment only where a design rule isn't obvious from the code.
