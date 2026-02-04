/// App settings from Firestore `app_settings/settings`.
class AppSettings {
  final bool abstractSubmissionOpen;
  final bool fullPaperSubmissionOpen;

  AppSettings({
    this.abstractSubmissionOpen = true,
    this.fullPaperSubmissionOpen = false,
  });

  factory AppSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return AppSettings();
    return AppSettings(
      abstractSubmissionOpen: data['abstractSubmissionOpen'] as bool? ?? true,
      fullPaperSubmissionOpen: data['fullPaperSubmissionOpen'] as bool? ?? false,
    );
  }
}
