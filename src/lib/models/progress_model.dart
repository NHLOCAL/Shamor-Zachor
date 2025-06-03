class PageProgress {
  bool learn;
  bool review1;
  bool review2;
  bool review3;

  PageProgress({
    this.learn = false,
    this.review1 = false,
    this.review2 = false,
    this.review3 = false,
  });

  Map<String, bool> toJson() => {
        'learn': learn,
        'review1': review1,
        'review2': review2,
        'review3': review3,
      };

  factory PageProgress.fromJson(Map<String, dynamic> json) {
    return PageProgress(
      learn: json['learn'] ?? false,
      review1: json['review1'] ?? false,
      review2: json['review2'] ?? false,
      review3: json['review3'] ?? false,
    );
  }

  bool get isEmpty => !learn && !review1 && !review2 && !review3;

  // Helper methods to set/get properties by string name
  void setProperty(String propertyName, bool value) {
    switch (propertyName) {
      case 'learn':
        learn = value;
        break;
      case 'review1':
        review1 = value;
        break;
      case 'review2':
        review2 = value;
        break;
      case 'review3':
        review3 = value;
        break;
      default:
        // Optionally handle unknown property name, e.g., throw an error or log
        break;
    }
  }

  bool getProperty(String propertyName) {
    switch (propertyName) {
      case 'learn':
        return learn;
      case 'review1':
        return review1;
      case 'review2':
        return review2;
      case 'review3':
        return review3;
      default:
        // Optionally handle unknown property name
        return false;
    }
  }
}

// Structure: categoryName -> bookName -> pageNumberStr (e.g., "2") -> amudKey ("a" or "b") -> PageProgress
typedef FullProgressMap
    = Map<String, Map<String, Map<String, Map<String, PageProgress>>>>;

// Structure for completion dates: categoryName -> bookName -> dateString (YYYY-MM-DD)
typedef CompletionDatesMap = Map<String, Map<String, String>>;
