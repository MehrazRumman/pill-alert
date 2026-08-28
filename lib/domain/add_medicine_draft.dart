import 'package:flutter/foundation.dart';

import 'dose_scheduler.dart';
import 'models.dart';

/// Shared draft across the add-medicine flow (3a → 3c → 3d → 3e). Held above the flow so every step
/// is back-navigable without losing entered data (README > Add-medicine flow). The mark + colour are
/// assigned once at creation and stored on the record.
class AddMedicineDraft extends ChangeNotifier {
  String displayName = '';
  String packName = '';
  String strength = '';
  String form = '';
  String condition = '';
  MarkShape mark = MarkShape.filledCircle;
  int markColor = 0xFF2F6B5B;
  double dosePerIntake = 1;
  FoodRelation foodRelation = FoodRelation.none;
  List<String> timeTokens = const []; // morning/noon/night
  List<String> resolvedTimes = const [];
  Frequency frequency = Frequency.daily;
  int weekdaysMask = 0;
  int stockCount = 0;
  bool highRisk = false;

  /// Set when the flow was entered to edit an existing medicine rather than to create one — the
  /// review step then keeps the original id (and its dose history) instead of minting a new record.
  String? editingId;

  void update(void Function() mutate) {
    mutate();
    notifyListeners();
  }

  void reset() {
    displayName = '';
    packName = '';
    strength = '';
    form = '';
    condition = '';
    mark = MarkShape.filledCircle;
    markColor = 0xFF2F6B5B;
    dosePerIntake = 1;
    foodRelation = FoodRelation.none;
    timeTokens = const [];
    resolvedTimes = const [];
    frequency = Frequency.daily;
    weekdaysMask = 0;
    stockCount = 0;
    highRisk = false;
    editingId = null;
    notifyListeners();
  }

  /// Loads an existing medicine in for editing.
  void loadFrom(Medicine m) {
    displayName = m.displayName;
    packName = m.packName;
    strength = m.strength;
    form = m.form;
    condition = m.condition;
    mark = m.mark;
    markColor = m.markColor;
    dosePerIntake = m.dosePerIntake;
    foodRelation = m.foodRelation;
    timeTokens = List.of(m.timeTokens);
    resolvedTimes = List.of(m.resolvedTimes);
    frequency = m.frequency;
    weekdaysMask = m.weekdaysMask;
    stockCount = m.stockCount;
    highRisk = m.highRisk;
    editingId = m.id;
    notifyListeners();
  }

  Medicine toMedicine() => Medicine(
        id: editingId ?? 'm-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}',
        displayName: displayName.trim().isEmpty ? packName : displayName,
        packName: packName,
        strength: strength,
        form: form,
        condition: condition,
        mark: mark,
        markColor: markColor,
        dosePerIntake: dosePerIntake,
        foodRelation: foodRelation,
        frequency: frequency,
        weekdaysMask: weekdaysMask,
        timeTokens: timeTokens,
        resolvedTimes: resolvedTimes.isNotEmpty
            ? resolvedTimes
            : timeTokens
                .map((t) => DoseScheduler.blockDefaultTime(TimeBlock.fromToken(t)))
                .toList(),
        stockCount: stockCount,
        stockUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        highRisk: highRisk,
        paused: false,
      );

  /// Everything a recorded allergy could plausibly match on. The pack name is included because the
  /// generic a patient reacts to is often printed there and not in the display name.
  String get allergyHaystack => '$displayName $packName $condition';
}
