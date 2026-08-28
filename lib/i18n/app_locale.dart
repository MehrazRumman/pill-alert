/// The writing systems the app sets type in. Script, not language: Spanish and English are both
/// Latin and share every metric, while Bengali and Devanagari each need their own face and their
/// own line-height floor.
enum NbScript { bengali, devanagari, latin }

/// A language the app can actually be read in — as opposed to [LocalePref], which is what the
/// patient chose and may be "follow the device".
enum AppLocale {
  bn('BN', 'bn', NbScript.bengali, 'বাংলা'),
  en('EN', 'en', NbScript.latin, 'English'),
  hi('HI', 'hi', NbScript.devanagari, 'हिन्दी'),
  es('ES', 'es', NbScript.latin, 'Español');

  const AppLocale(this.stored, this.code, this.script, this.endonym);

  /// Persisted form, and the value [LocalePref] stores.
  final String stored;

  /// BCP-47 language subtag, for MaterialApp and the platform.
  final String code;

  final NbScript script;

  /// The language's name in itself. Always shown in its own script — a language list that names
  /// every option in English is useless to the person who cannot read English.
  final String endonym;

  bool get isBangla => this == AppLocale.bn;

  /// Bengali and Devanagari both stack marks above the headline and hang conjuncts below the
  /// baseline; Latin does neither. Almost every typographic difference in the app follows this
  /// split rather than the language.
  bool get isIndic => script != NbScript.latin;

  static AppLocale fromDeviceCode(String? languageCode) =>
      AppLocale.values.firstWhere((l) => l.code == languageCode, orElse: () => AppLocale.en);
}
