import 'dart:developer' as developer;

/// Phone number utilities for formatting, validation, and cleanup
/// Mobile equivalent of web/src/lib/phone-utils.ts
class PhoneUtils {
  // Common country codes with their phone codes
  static const Map<String, Map<String, String>> countryData = {
    'ZA': {'name': 'South Africa', 'code': '+27'},
    'US': {'name': 'United States', 'code': '+1'},
    'GB': {'name': 'United Kingdom', 'code': '+44'},
    'AU': {'name': 'Australia', 'code': '+61'},
    'CA': {'name': 'Canada', 'code': '+1'},
    'DE': {'name': 'Germany', 'code': '+49'},
    'FR': {'name': 'France', 'code': '+33'},
    'IT': {'name': 'Italy', 'code': '+39'},
    'ES': {'name': 'Spain', 'code': '+34'},
    'NL': {'name': 'Netherlands', 'code': '+31'},
    'BE': {'name': 'Belgium', 'code': '+32'},
    'IN': {'name': 'India', 'code': '+91'},
    'CN': {'name': 'China', 'code': '+86'},
    'JP': {'name': 'Japan', 'code': '+81'},
    'KR': {'name': 'South Korea', 'code': '+82'},
    'BR': {'name': 'Brazil', 'code': '+55'},
    'MX': {'name': 'Mexico', 'code': '+52'},
    'AR': {'name': 'Argentina', 'code': '+54'},
    'EG': {'name': 'Egypt', 'code': '+20'},
    'NG': {'name': 'Nigeria', 'code': '+234'},
    'KE': {'name': 'Kenya', 'code': '+254'},
    'GH': {'name': 'Ghana', 'code': '+233'},
  };

  /// Default country code (South Africa as per requirements)
  static const String defaultCountryCode = 'ZA';

  /// Get phone code for a country
  static String getPhoneCode(String countryCode) {
    return countryData[countryCode]?['code'] ?? '+27';
  }

  /// Get country name for a country code
  static String getCountryName(String countryCode) {
    return countryData[countryCode]?['name'] ?? 'South Africa';
  }

  /// Format phone number for WhatsApp (international format with +)
  /// Equivalent to web's formatForWhatsApp function
  static String formatForWhatsApp(String phoneNumber, String countryCode) {
    try {
      developer.log('🔢 Formatting phone for WhatsApp: $phoneNumber with country: $countryCode');
      
      final phoneCode = getPhoneCode(countryCode);
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      if (cleanNumber.isEmpty) {
        developer.log('⚠️ Empty phone number after cleaning');
        return '';
      }

      // If number already starts with country code, return as is
      if (cleanNumber.startsWith(phoneCode.substring(1))) {
        final formatted = '+$cleanNumber';
        developer.log('✅ Phone already has country code: $formatted');
        return formatted;
      }

      // If number starts with +, clean and re-add country code
      if (phoneNumber.startsWith('+')) {
        final withoutPlus = cleanNumber;
        // Remove leading country code if present
        for (final country in countryData.values) {
          final code = country['code']!.substring(1); // Remove +
          if (withoutPlus.startsWith(code)) {
            final nationalNumber = withoutPlus.substring(code.length);
            final formatted = '$phoneCode$nationalNumber';
            developer.log('✅ Replaced country code: $formatted');
            return formatted;
          }
        }
      }

      // Add country code to national number
      final formatted = '$phoneCode$cleanNumber';
      developer.log('✅ Added country code: $formatted');
      return formatted;
    } catch (e) {
      developer.log('❌ Error formatting phone: $e');
      return phoneNumber;
    }
  }

  /// Clean phone number for submission to backend
  /// Equivalent to web's cleanPhoneForSubmission function
  static String cleanPhoneForSubmission(String phoneNumber, String countryCode) {
    try {
      developer.log('🧹 Cleaning phone for submission: $phoneNumber');
      
      if (phoneNumber.trim().isEmpty) {
        developer.log('⚠️ Empty phone number provided');
        return '';
      }

      // First format for WhatsApp to get consistent international format
      final whatsappFormatted = formatForWhatsApp(phoneNumber, countryCode);
      
      if (whatsappFormatted.isEmpty) {
        developer.log('⚠️ WhatsApp formatting failed');
        return '';
      }

      // Additional cleanup for backend submission
      final cleaned = whatsappFormatted.trim();
      
      // Validate the final result
      if (isValidPhoneNumber(cleaned)) {
        developer.log('✅ Phone cleaned successfully: $cleaned');
        return cleaned;
      } else {
        developer.log('❌ Cleaned phone failed validation: $cleaned');
        return '';
      }
    } catch (e) {
      developer.log('❌ Error cleaning phone: $e');
      return '';
    }
  }

  /// Validate phone number format
  /// Must match backend validation: /^\+?[1-9]\d{1,14}$/
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;
    
    // Backend regex pattern: /^\+?[1-9]\d{1,14}$/
    final backendPattern = RegExp(r'^\+?[1-9]\d{1,14}$');
    final isValid = backendPattern.hasMatch(phoneNumber);
    
    developer.log('🔍 Validating phone: $phoneNumber -> $isValid');
    return isValid;
  }

  /// Clean phone number (remove all non-digit characters except +)
  static String _cleanPhoneNumber(String phoneNumber) {
    // Remove all characters except digits and +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remove + if not at the beginning
    if (cleaned.contains('+') && !cleaned.startsWith('+')) {
      return cleaned.replaceAll('+', '');
    }
    
    // Remove leading + for processing
    if (cleaned.startsWith('+')) {
      return cleaned.substring(1);
    }
    
    return cleaned;
  }

  /// Get list of countries for dropdown/picker
  static List<Map<String, String>> getCountriesList() {
    return countryData.entries
        .map((entry) => {
              'code': entry.key,
              'name': entry.value['name']!,
              'phoneCode': entry.value['code']!,
            })
        .toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  /// Search countries by name or code
  static List<Map<String, String>> searchCountries(String query) {
    if (query.isEmpty) return getCountriesList();
    
    final lowercaseQuery = query.toLowerCase();
    return getCountriesList()
        .where((country) =>
            country['name']!.toLowerCase().contains(lowercaseQuery) ||
            country['code']!.toLowerCase().contains(lowercaseQuery) ||
            country['phoneCode']!.contains(query))
        .toList();
  }

  /// Format phone number for display (with country code)
  static String formatForDisplay(String phoneNumber, String countryCode) {
    final formatted = formatForWhatsApp(phoneNumber, countryCode);
    if (formatted.isEmpty) return phoneNumber;
    
    // Add some formatting for better readability
    if (formatted.length > 4) {
      final code = getPhoneCode(countryCode);
      if (formatted.startsWith(code)) {
        final national = formatted.substring(code.length);
        return '$code $national';
      }
    }
    
    return formatted;
  }
}
