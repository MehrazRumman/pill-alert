/// Blood groups, in the order they are offered. Stored as the printed string so the value that
/// reaches the doctor report is the one the patient picked, with no mapping in between.
const List<String> kBloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

/// Who the medicines belong to. Everything here is optional — the app is fully usable without a
/// single field filled in, and nothing may ever block a dose confirmation on a missing detail.
///
/// Stored in SharedPreferences alongside [AppSettings] rather than in the database: it is a single
/// row that is read on nearly every screen and written rarely, which is the same shape as the
/// settings, and it avoids a schema migration for data no query ever joins against.
class PatientProfile {
  const PatientProfile({
    this.name = '',
    this.yearOfBirth,
    this.bloodGroup = '',
    this.allergies = '',
    this.conditions = '',
    this.emergencyName = '',
    this.emergencyPhone = '',
  });

  final String name;

  /// Year rather than age, so the number never silently goes stale on a device that sits unused.
  final int? yearOfBirth;
  final String bloodGroup;

  /// Free text, comma-separated. Deliberately not a picker: patients describe allergies in their
  /// own words ("পেনিসিলিন", "সালফা ড্রাগ"), and a fixed list would quietly drop what it can't match.
  final String allergies;
  final String conditions;
  final String emergencyName;
  final String emergencyPhone;

  /// Age in whole years, or null when no year of birth is recorded.
  int? ageOn(DateTime now) {
    final y = yearOfBirth;
    if (y == null) return null;
    final age = now.year - y;
    return age >= 0 && age < 130 ? age : null;
  }

  bool get hasEmergencyContact => emergencyPhone.trim().isNotEmpty;

  /// The allergy list as trimmed, non-empty entries.
  List<String> get allergyList => allergies
      .split(RegExp(r'[,、;]'))
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList();

  /// True when nothing has been filled in — the More hub uses this to decide between a prompt and
  /// a summary.
  bool get isEmpty =>
      name.trim().isEmpty &&
      yearOfBirth == null &&
      bloodGroup.isEmpty &&
      allergies.trim().isEmpty &&
      conditions.trim().isEmpty &&
      emergencyName.trim().isEmpty &&
      emergencyPhone.trim().isEmpty;

  /// Returns the recorded allergies that appear in [medicineName], matched case-insensitively on
  /// whole words so "sulfa" does not fire on "sulfamethoxazole"'s neighbours by accident but does
  /// fire on the drug itself. Used to warn before a medicine is saved.
  List<String> allergyMatches(String medicineName) {
    final haystack = medicineName.toLowerCase();
    return allergyList.where((a) => haystack.contains(a.toLowerCase())).toList();
  }

  PatientProfile copyWith({
    String? name,
    int? yearOfBirth,
    bool clearYearOfBirth = false,
    String? bloodGroup,
    String? allergies,
    String? conditions,
    String? emergencyName,
    String? emergencyPhone,
  }) =>
      PatientProfile(
        name: name ?? this.name,
        yearOfBirth: clearYearOfBirth ? null : (yearOfBirth ?? this.yearOfBirth),
        bloodGroup: bloodGroup ?? this.bloodGroup,
        allergies: allergies ?? this.allergies,
        conditions: conditions ?? this.conditions,
        emergencyName: emergencyName ?? this.emergencyName,
        emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      );
}
