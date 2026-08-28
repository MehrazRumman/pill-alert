import '../data/repository.dart';
import '../domain/models.dart';
import 'alarm_scheduler.dart';

/// Flips unanswered doses to MISSED once their grace period has passed, and clears the ongoing
/// reminder each one left behind.
///
/// The Kotlin build did this from a BroadcastReceiver at the grace deadline and posted the missed
/// notification from the same place. Here the patient-facing notification is laid down in advance
/// by [AlarmScheduler] (Dart has nothing running at that moment to post it), so this sweep only has
/// to keep the *record* truthful — it runs at launch and on every resume.
class MissedDoseNotifier {
  MissedDoseNotifier._();

  static Future<List<DoseWithMedicine>> sweep(NirbhorRepository repo) async {
    final newlyMissed = await repo.markOverdueDoses();
    if (newlyMissed.isEmpty) return const [];
    // A missed dose is no longer answerable from its reminder, and that reminder is ongoing.
    await AlarmScheduler.clearForDoses(newlyMissed.map((d) => d.dose.id));
    return newlyMissed;
  }
}
