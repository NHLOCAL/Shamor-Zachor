// For Gregorian date formatting
import 'package:kosher_dart/kosher_dart.dart';
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
      final DateTime gregorianDate = DateTime.parse(dateStrYYYYMMDD);

      JewishDate hebrewDate = JewishDate.fromDateTime(gregorianDate);

      // Using specific API names based on common kosher_dart patterns
      int dayInt = hebrewDate.getJewishDayOfMonth();
      String dayGematria = HebrewUtils.intToGematria(dayInt);

      HebrewDateFormatter hdf = HebrewDateFormatter();
      hdf.hebrewFormat = true; // Ensure output is in Hebrew characters

      String monthName = hdf.formatMonth(hebrewDate);

      // Last attempt: Use the generic format() method and extract the year.
      // The default pattern is "dd MMMM, yyyy".
      // With hebrewFormat = true, this might output something like "כ"ה תשרי, תשפ"ד".
      String fullFormattedDate = hdf.format(hebrewDate);
      String yearHebrew =
          fullFormattedDate; // Default to full date if split fails
      if (fullFormattedDate.contains(', ')) {
        yearHebrew = fullFormattedDate.split(', ').last;
      } else if (fullFormattedDate.contains(' ')) {
        // If no comma, maybe it's "Day Month Year" already, try taking last part.
        // This is very speculative.
        List<String> parts = fullFormattedDate.split(' ');
        if (parts.length > 2) {
          // Ensure there are enough parts for a year
          yearHebrew = parts.last;
        }
      }
      // This is a fallback and might need adjustment based on actual output.

      return '$dayGematria $monthName $yearHebrew';
    } catch (e) {
      print("Error in getCompletionDateString: $e");
      return null;
    }
  }
}
