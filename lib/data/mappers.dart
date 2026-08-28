import '../domain/models.dart';

/// Row ⇄ domain conversion. Column names and stored enum spellings match the Room entities exactly.

List<String> csvToList(String? csv) =>
    (csv == null || csv.isEmpty) ? const [] : csv.split(',').where((s) => s.isNotEmpty).toList();

String listToCsv(List<String> items) => items.join(',');

Medicine medicineFromRow(Map<String, Object?> r) => Medicine(
      id: r['id'] as String,
      displayName: r['displayName'] as String? ?? '',
      packName: r['packName'] as String? ?? '',
      strength: r['strength'] as String? ?? '',
      form: r['form'] as String? ?? '',
      condition: r['condition'] as String? ?? '',
      mark: MarkShape.fromName(r['mark'] as String?),
      markColor: (r['markColor'] as num?)?.toInt() ?? 0xFF2F6B5B,
      dosePerIntake: (r['dosePerIntake'] as num?)?.toDouble() ?? 1,
      foodRelation: FoodRelation.fromStored(r['foodRelation'] as String?),
      frequency: Frequency.fromStored(r['frequency'] as String?),
      weekdaysMask: (r['weekdaysMask'] as num?)?.toInt() ?? 0,
      timeTokens: csvToList(r['timeTokens'] as String?),
      resolvedTimes: csvToList(r['resolvedTimes'] as String?),
      stockCount: (r['stockCount'] as num?)?.toInt() ?? 0,
      stockUpdatedAt: (r['stockUpdatedAt'] as num?)?.toInt() ?? 0,
      highRisk: ((r['highRisk'] as num?)?.toInt() ?? 0) != 0,
      paused: ((r['paused'] as num?)?.toInt() ?? 0) != 0,
    );

Map<String, Object?> medicineToRow(Medicine m, {required int createdAt}) => {
      'id': m.id,
      'displayName': m.displayName,
      'packName': m.packName,
      'strength': m.strength,
      'form': m.form,
      'condition': m.condition,
      'mark': m.mark.storedName,
      'markColor': m.markColor,
      'dosePerIntake': m.dosePerIntake,
      'foodRelation': m.foodRelation.stored,
      'frequency': m.frequency.stored,
      'weekdaysMask': m.weekdaysMask,
      'timeTokens': listToCsv(m.timeTokens),
      'resolvedTimes': listToCsv(m.resolvedTimes),
      'stockCount': m.stockCount,
      'stockUpdatedAt': m.stockUpdatedAt,
      'highRisk': m.highRisk ? 1 : 0,
      'paused': m.paused ? 1 : 0,
      'createdAt': createdAt,
    };

DoseOccurrence doseFromRow(Map<String, Object?> r) => DoseOccurrence(
      id: (r['id'] as num).toInt(),
      medicineId: r['medicineId'] as String,
      scheduledEpochMillis: (r['scheduledEpochMillis'] as num).toInt(),
      hour: (r['hour'] as num).toInt(),
      minute: (r['minute'] as num).toInt(),
      block: TimeBlock.fromStored(r['block'] as String?),
      status: DoseStatus.fromStored(r['status'] as String?),
      confirmedAt: (r['confirmedAt'] as num?)?.toInt(),
      source: DoseSource.fromStored(r['source'] as String?),
    );

Caregiver caregiverFromRow(Map<String, Object?> r) => Caregiver(
      id: r['id'] as String,
      name: r['name'] as String? ?? '',
      relationship: r['relationship'] as String? ?? '',
      email: r['email'] as String? ?? '',
      emailVerified: ((r['emailVerified'] as num?)?.toInt() ?? 0) != 0,
      phone: r['phone'] as String? ?? '',
      channels: csvToList(r['channels'] as String?)
          .map(CaregiverChannel.fromStored)
          .whereType<CaregiverChannel>()
          .toSet(),
      digestFrequency: DigestFrequency.fromStored(r['digestFrequency'] as String?),
      escalateOnSecondMiss: ((r['escalateOnSecondMiss'] as num?)?.toInt() ?? 0) != 0,
      notifyOnMissedTwice: ((r['notifyOnMissedTwice'] as num?)?.toInt() ?? 0) != 0,
      notifyOnOutOfStock: ((r['notifyOnOutOfStock'] as num?)?.toInt() ?? 0) != 0,
      weeklySummary: ((r['weeklySummary'] as num?)?.toInt() ?? 0) != 0,
    );

Map<String, Object?> caregiverToRow(Caregiver c) => {
      'id': c.id,
      'name': c.name,
      'relationship': c.relationship,
      'email': c.email,
      'emailVerified': c.emailVerified ? 1 : 0,
      'phone': c.phone,
      'channels': listToCsv(c.channels.map((e) => e.stored).toList()),
      'digestFrequency': c.digestFrequency.stored,
      'escalateOnSecondMiss': c.escalateOnSecondMiss ? 1 : 0,
      'notifyOnMissedTwice': c.notifyOnMissedTwice ? 1 : 0,
      'notifyOnOutOfStock': c.notifyOnOutOfStock ? 1 : 0,
      'weeklySummary': c.weeklySummary ? 1 : 0,
    };
