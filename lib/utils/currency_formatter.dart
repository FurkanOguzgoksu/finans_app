import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Displays a double amount in 100.000,00 format.
  static String format(double amount) {
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);
    return format.format(amount).trim();
  }

  /// Parses a formatted string like "100.000,50" back to double 100000.50
  static double? parse(String text) {
    if (text.isEmpty) return null;
    // Remove dots (thousands separators) and replace comma with dot for parsing
    String cleanText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanText);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Keep only digits and commas
    String text = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    
    // Prevent multiple commas
    int commaCount = text.split(',').length - 1;
    if (commaCount > 1) {
      text = oldValue.text;
    }

    if (text.isEmpty) {
       return newValue.copyWith(text: '');
    }

    // Split integer and decimal parts
    List<String> parts = text.split(',');
    String intPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Limit decimal to 2 digits
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Format integer part with thousands separator
    if (intPart.isNotEmpty) {
      final int value = int.parse(intPart);
      final format = NumberFormat.decimalPattern('tr_TR');
      intPart = format.format(value);
    }

    // Reconstruct the formatted string
    String newText = intPart;
    if (text.contains(',')) {
      newText += ',$decimalPart';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
