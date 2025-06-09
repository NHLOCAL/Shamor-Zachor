class CategorySorter {
  // כאן מגדירים את הסדר הרצוי של הקטגוריות.
  // ניתן לשנות את הרשימה הזו בקלות כדי להתאים את הסדר.
  static const List<String> _desiredOrder = [
    'תנ"ך',
    'משנה',
    'תוספתא',
    'תלמוד בבלי',
    'תלמוד ירושלמי',
    'מדרשי הלכה',
    'מדרשי אגדה',
    'ספרי זוהר',
    'רמב"ם',
    'ראשונים',
    'הלכה',
    'אחרונים',
    'מוסר',
    'חסידות',
    'מחשבה',
    // הוסף לכאן עוד קטגוריות לפי הצורך
  ];

  /// ממיין רשימה של קטגוריות לפי הסדר שהוגדר ב-_desiredOrder.
  /// קטגוריות שאינן ברשימה יופיעו בסוף, ממויינות לפי סדר א-ב.
  static List<String> sort(List<String> categories) {
    categories.sort((a, b) {
      final int indexA = _desiredOrder.indexOf(a);
      final int indexB = _desiredOrder.indexOf(b);

      if (indexA != -1 && indexB != -1) {
        // שתיהן קיימות ברשימה, נמיין לפי הסדר שהוגדר
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        // רק A קיימת, אז היא קודמת
        return -1;
      } else if (indexB != -1) {
        // רק B קיימת, אז היא קודמת
        return 1;
      } else {
        // שתיהן לא קיימות ברשימה, נמיין לפי א-ב
        return a.compareTo(b);
      }
    });
    return categories;
  }
}
