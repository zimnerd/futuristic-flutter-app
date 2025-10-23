/// Verification method enum - matches backend VerificationMethod enum
enum VerificationMethod {
  email('email'),
  sms('sms'),
  whatsapp('whatsapp');

  final String value;
  const VerificationMethod(this.value);

  @override
  String toString() => value;

  /// Convert string to VerificationMethod enum
  static VerificationMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'email':
        return VerificationMethod.email;
      case 'sms':
        return VerificationMethod.sms;
      case 'whatsapp':
        return VerificationMethod.whatsapp;
      default:
        throw ArgumentError('Invalid verification method: $value');
    }
  }

  /// Display label for UI
  String get displayLabel {
    switch (this) {
      case VerificationMethod.email:
        return 'Email';
      case VerificationMethod.sms:
        return 'SMS';
      case VerificationMethod.whatsapp:
        return 'WhatsApp';
    }
  }

  /// Icon name for UI display
  String get iconName {
    switch (this) {
      case VerificationMethod.email:
        return 'email';
      case VerificationMethod.sms:
        return 'sms';
      case VerificationMethod.whatsapp:
        return 'whatsapp';
    }
  }
}
