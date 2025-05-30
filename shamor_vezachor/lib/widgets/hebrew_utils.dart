import 'package:intl/intl.dart'; // For Gregorian date formatting
// For Hebrew date, you'd typically use a package like hebcal_dart
// For now, we'll just format Gregorian or return null

class HebrewUtils {
  static const Map<int, String> _gematriaMap = {
    1: 'א', 2: 'ב', 3: 'ג', 4: 'ד', 5: 'ה', 6: 'ו', 7: 'ז', 8: 'ח', 9: 'ט',
    10: 'י', 20: 'כ', 30: 'ל', 40: 'מ', 50: 'נ', 60: 'ס', 70: 'ע', 80: 'פ',
    90: 'צ',
    100: 'ק', 200: 'ר', 300: 'ש', 400: 'ת',
    // For numbers > 400, it gets more complex (e.g., ת"ק, תר"ס).
    // This is a simplified version.
  };

  static String intToGematria(int number) {
    if (number <= 0) return number.toString();
    if (number > 499) {
      return number.toString(); // Simplified, handle larger numbers if needed
    }

    // Special cases for 15 (ט"ו) and 16 (ט"ז)
    if (number == 15) return 'טו';
    if (number == 16) return 'טז';

    String result = '';
    List<int> values = _gematriaMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (int val in values) {
      while (number >= val) {
        result += _gematriaMap[val]!;
        number -= val;
      }
    }
    // Add gershayim if more than one letter, unless it's a single letter >= 100 (like ק, ר, ש, ת)
    if (result.length > 1) {
      // Check if the last two characters are י and ה (15) or י and ו (16)
      if (!((result.endsWith('יה') || result.endsWith('יו')) &&
          result.length == 2)) {
        result =
            '${result.substring(0, result.length - 1)}"${result.substring(result.length - 1)}';
      }
    } else if (result.length == 1 &&
        _gematriaMap.entries.firstWhere((e) => e.value == result).key < 10) {
      result += "'"; // Add geresh for single digit numbers
    }

    return result;
  }

  static String? getCompletionDateString(String? dateStrYYYYMMDD) {
    if (dateStrYYYYMMDD == null || dateStrYYYYMMDD.isEmpty) {
      return null;
    }
    try {
      final dateObj = DateTime.parse(dateStrYYYYMMDD);
      // Placeholder for Hebrew date conversion.
      // Using hebcal_dart package would be:
      // final hebrewDate = JewishDate.fromDateTime(dateObj);
      // return hebrewDate.toStringHeb(); // Or a specific format
      // For now, return Gregorian in a readable format or a placeholder
      return DateFormat('d MMMM yyyy', 'he_IL')
          .format(dateObj); // Example: 24 אוקטובר 2023
      // Or a simple placeholder:
      // return "תאריך עברי ל-${DateFormat('dd/MM/yyyy').format(dateObj)}";
    } catch (e) {
      print("Error parsing date for Hebrew conversion: $e");
      return null;
    }
  }
}
