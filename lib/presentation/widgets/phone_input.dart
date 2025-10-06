import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/phone_utils.dart';

/// A custom phone input widget with country code selector
/// Mobile equivalent of web's PhoneInput component
class PhoneInput extends StatefulWidget {
  const PhoneInput({
    super.key,
    this.initialValue = '',
    this.initialCountryCode = PhoneUtils.defaultCountryCode,
    this.onChanged,
    this.onCountryChanged,
    this.validator,
    this.enabled = true,
    this.decoration,
    this.showCountryFlag = true,
    this.autovalidateMode,
  });

  final String initialValue;
  final String initialCountryCode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCountryChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final InputDecoration? decoration;
  final bool showCountryFlag;
  final AutovalidateMode? autovalidateMode;

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  late TextEditingController _controller;
  late String _selectedCountryCode;
  late String _phoneCode;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode;
    _phoneCode = PhoneUtils.getPhoneCode(_selectedCountryCode);
    _controller = TextEditingController(text: widget.initialValue);
    
    // Try to detect user's country from location if using default
    if (widget.initialCountryCode == PhoneUtils.defaultCountryCode) {
      _detectUserCountry();
    }
  }

  /// Detect user's country from location and update country code
  Future<void> _detectUserCountry() async {
    try {
      final detectedCountry = await PhoneUtils.getDefaultCountryCode();
      if (mounted && detectedCountry != _selectedCountryCode) {
        setState(() {
          _selectedCountryCode = detectedCountry;
          _phoneCode = PhoneUtils.getPhoneCode(detectedCountry);
        });

        // Notify parent about the country change
        if (widget.onCountryChanged != null) {
          widget.onCountryChanged!(detectedCountry);
        }
      }
    } catch (e) {
      // Silently fail and keep the default country
      // Error is already logged in PhoneUtils.getDefaultCountryCode()
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPhoneNumberChanged(String value) {
    if (widget.onChanged != null) {
      // Format the complete phone number and notify parent
      final formattedPhone = PhoneUtils.formatForWhatsApp(value, _selectedCountryCode);
      widget.onChanged!(formattedPhone);
    }
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
      _phoneCode = PhoneUtils.getPhoneCode(countryCode);
    });
    
    if (widget.onCountryChanged != null) {
      widget.onCountryChanged!(countryCode);
    }
    
    // Re-format current phone number with new country code
    if (_controller.text.isNotEmpty) {
      _onPhoneNumberChanged(_controller.text);
    }
  }

  Future<void> _showCountryPicker() async {
    final countries = PhoneUtils.getCountriesList();
    
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryPickerBottomSheet(
        countries: countries,
        selectedCountryCode: _selectedCountryCode,
      ),
    );

    if (selected != null) {
      _onCountryChanged(selected['code']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      autovalidateMode: widget.autovalidateMode,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15), // Max international phone length
      ],
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        labelText: widget.decoration?.labelText ?? 'Phone Number',
        hintText: widget.decoration?.hintText ?? 'Enter your phone number',
        prefixIcon: InkWell(
          onTap: widget.enabled ? _showCountryPicker : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showCountryFlag) ...[
                  _buildCountryFlag(_selectedCountryCode),
                  const SizedBox(width: 8),
                ],
                Text(
                  _phoneCode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
      ),
      validator: widget.validator != null
          ? (value) {
              final formattedPhone = PhoneUtils.formatForWhatsApp(
                value ?? '',
                _selectedCountryCode,
              );
              return widget.validator!(formattedPhone);
            }
          : null,
      onChanged: _onPhoneNumberChanged,
    );
  }

  Widget _buildCountryFlag(String countryCode) {
    // Simple emoji flags for common countries
    const flagMap = {
      'ZA': '🇿🇦', // South Africa
      'US': '🇺🇸', // United States
      'GB': '🇬🇧', // United Kingdom
      'AU': '🇦🇺', // Australia
      'CA': '🇨🇦', // Canada
      'DE': '🇩🇪', // Germany
      'FR': '🇫🇷', // France
      'IT': '🇮🇹', // Italy
      'ES': '🇪🇸', // Spain
      'NL': '🇳🇱', // Netherlands
      'BE': '🇧🇪', // Belgium
      'IN': '🇮🇳', // India
      'CN': '🇨🇳', // China
      'JP': '🇯🇵', // Japan
      'KR': '🇰🇷', // South Korea
      'BR': '🇧🇷', // Brazil
      'MX': '🇲🇽', // Mexico
      'AR': '🇦🇷', // Argentina
      'EG': '🇪🇬', // Egypt
      'NG': '🇳🇬', // Nigeria
      'KE': '🇰🇪', // Kenya
      'GH': '🇬🇭', // Ghana
    };

    return Text(
      flagMap[countryCode] ?? '🌐',
      style: const TextStyle(fontSize: 20),
    );
  }
}

class _CountryPickerBottomSheet extends StatefulWidget {
  const _CountryPickerBottomSheet({
    required this.countries,
    required this.selectedCountryCode,
  });

  final List<Map<String, String>> countries;
  final String selectedCountryCode;

  @override
  State<_CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<_CountryPickerBottomSheet> {
  late List<Map<String, String>> _filteredCountries;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = PhoneUtils.searchCountries(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      height: mediaQuery.size.height * 0.7,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Select Country',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search countries...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            style: TextStyle(color: colorScheme.onSurface),
            onChanged: _filterCountries,
          ),
          
          const SizedBox(height: 16),
          
          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country['code'] == widget.selectedCountryCode;
                
                return ListTile(
                  leading: Text(
                    _getCountryFlag(country['code']!),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country['name']!,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  trailing: Text(
                    country['phoneCode']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => Navigator.of(context).pop(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getCountryFlag(String countryCode) {
    const flagMap = {
      'ZA': '🇿🇦', 'US': '🇺🇸', 'GB': '🇬🇧', 'AU': '🇦🇺', 'CA': '🇨🇦',
      'DE': '🇩🇪', 'FR': '🇫🇷', 'IT': '🇮🇹', 'ES': '🇪🇸', 'NL': '🇳🇱',
      'BE': '🇧🇪', 'IN': '🇮🇳', 'CN': '🇨🇳', 'JP': '🇯🇵', 'KR': '🇰🇷',
      'BR': '🇧🇷', 'MX': '🇲🇽', 'AR': '🇦🇷', 'EG': '🇪🇬', 'NG': '🇳🇬',
      'KE': '🇰🇪', 'GH': '🇬🇭',
    };
    return flagMap[countryCode] ?? '🌐';
  }
}
