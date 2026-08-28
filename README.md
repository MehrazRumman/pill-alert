# নির্ভর · Nirbhor (Flutter)

A Flutter port of the Nirbhor Android app — a bilingual **Bangla-primary / English** pill-reminder
built for low-literacy users. The Kotlin/Compose original lives at `../pill-alert` and stays
buildable; this project is a parallel implementation, not a replacement.

Both can sit on one device: this build's application id is `com.nirbhor.flutter`, the original's is
`com.nirbhor.app`.

## Running it

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"
flutter run                     # debug, on a connected device
flutter build apk --release     # release APK
```

`minSdk` is 26, matching the original: the variable-font weight axes and the alarm APIs both need it.

## How it maps to the Kotlin app

| Kotlin | Flutter |
| --- | --- |
| `ui/theme` design tokens | `lib/theme` — `NirbhorTheme` inherited widget carries type + locale |
| `ui/i18n` (`tr`, `num`, `clock`) | `lib/i18n` + a `BuildContext` extension, same call-site pairing |
| Room + DAOs | `lib/data/database.dart` — sqflite, **identical table and column names** |
| `NirbhorRepository` (Flow) | `lib/data/repository.dart` — a `ChangeNotifier`; `RepoBuilder` re-queries on write |
| DataStore `SettingsStore` | `lib/data/settings_store.dart` — SharedPreferences |
| `AddMedicineDraft` composition-local | `AddDraftScope` over a `ChangeNotifier` |
| `NavActions` + NavHost | `lib/navigation` — named routes, four tabs in one `IndexedStack` |
| `AlarmScheduler` + `AlarmReceiver` | `lib/notifications/alarm_scheduler.dart` — `flutter_local_notifications` |
| `AlarmActivity` | `lib/ui/screens/alarm_screen.dart`, opened by the reminder's full-screen intent |
| CameraX + ML Kit scan | `camera` + `google_mlkit_text_recognition`, parser in `lib/ui/screens/pack_parser.dart` |

The database schema is byte-compatible with the Kotlin build, so a `nirbhor.db` copied across opens
without migration.

## Invariants worth keeping

These were learned the hard way in the original and carry over unchanged:

- **Anek Bangla's Bengali ink spans 1.490em.** `lib/theme/typography.dart` floors every line height
  at `kBanglaMinLine = 1.52`. Designs authored against a Latin face slice matras and descenders off
  in the app's *primary* locale.
- **Archivo has zero Bengali glyphs.** Any Bangla literal shown in the English locale — the brand
  name, the "বাংলা" option, a patient-typed caregiver relationship — must go through
  `context.type.asBangla(...)` or it falls through to a system font, or to tofu.
- **The reminder notification is posted `ongoing`.** Every path that resolves a dose must call
  `AlarmScheduler.clearForDose`, or it sticks on the shade forever.
- **A notification channel's sound is frozen at creation.** Bump
  `NirbhorNotifications._channelVersion` whenever the audio config changes, and add the old id to
  `_supersededReminderChannels`. The tone is a bundled raw resource, never a system-default lookup,
  so a reminder can never resolve to silence.
- **`StockStatus.daysRemaining` is nullable** (paused, or no schedule) — never substitute a sentinel.
- **The alarm preview is write-free.** It is a rehearsal, not a confirmation.
- **The palette is light-only in both system themes**, so the status-bar icons are forced dark.
- **The OCR parser ranks candidate lines by `relativeHeight`, not reading order** — the brand name is
  the largest text on a pack.

## Contrast floors

The design's own tokens fell below WCAG AA in three places, all measured on device. These are
corrected here, and the numbers are recorded so a future palette edit doesn't quietly undo them:

| Where | Was | Now |
| --- | --- | --- |
| `ink3` secondary text (every dose subtitle, meta line, section label) | #8B9A94 — **2.62:1** on paper | #566964 — **5.21:1** on paper, 5.83:1 on card |
| Alarm screen "Skip" button (white fill under a 70%-alpha label) | **1.12:1** — effectively invisible | translucent white fill, full-strength label — **5.60:1** |
| Disabled buttons (enabled colours at 50% opacity) | **1.50:1** | sage fill + `ink3` label — **4.76:1** |
| "DUE NOW" pill, white on `warm` | 3.31:1, under the floor at 11–12sp | white on `warmD` — **6.10:1** |

The palette's character is unchanged: `ink3` is the same desaturated green-grey, just dark enough to
read, and the due-now pill is still amber. This matters more than usual here — the users are elderly,
and the alarm is answered half-asleep.

## Where this port differs

- **Missed doses.** The Kotlin build flipped a dose to MISSED from a `BroadcastReceiver` at the
  grace deadline. Dart has nothing running at that moment, so the patient-facing missed-dose
  notification is *pre-scheduled* by `AlarmScheduler` and the DB sweep (`MissedDoseNotifier.sweep`)
  runs at launch and on every resume. Same notification at the same minute; the record catches up
  when the app is next opened.
- **Repeats.** All of a dose's repeats are laid down at scheduling time and cancelled together,
  rather than re-armed one at a time as each fires.
- **Caregiver delivery is still not implemented** — as in the original, the Family screen says so.

## Not yet done

Native-speaker Bangla copy review; a real caregiver email/SMS backend and the 21:30 digest; app
signing config and store listing.
