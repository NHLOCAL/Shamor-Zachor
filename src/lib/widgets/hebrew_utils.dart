import 'package:gematria/gematria.dart';
import 'package:kosher_dart/kosher_dart.dart';

class HebrewUtils {
  static String intToGematria(int number) {
    if (number <= 0) {
      return number.toString();
    }
    // The gematria package handles all cases. We cast the result to a String.
    return Gematria().gematria(number) as String;
  }

  static String? getCompletionDateString(String? dateStrYYYYMMDD) {
    if (dateStrYYYYMMDD == null || dateStrYYYYMMDD.isEmpty) {
      return null;
    }

    try {
      final DateTime gregorianDate = DateTime.parse(dateStrYYYYMMDD);

      JewishDate hebrewDate = JewishDate.fromDateTime(gregorianDate);

      int dayInt = hebrewDate.getJewishDayOfMonth();
      String dayGematria = HebrewUtils.intToGematria(dayInt);

      HebrewDateFormatter hdf = HebrewDateFormatter();
      hdf.hebrewFormat = true;

      String monthName = hdf.formatMonth(hebrewDate);
      String yearHebrew = hdf.formatHebrewNumber(hebrewDate.getJewishYear());

      return '$dayGematria $monthName $yearHebrew';
    } catch (e) {
      print("Error in getCompletionDateString: $e");
      return null;
    }
  }
}
