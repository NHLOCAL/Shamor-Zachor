import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../services/data_loader_service.dart';
import '../services/custom_book_service.dart'; // Added import

class DataProvider with ChangeNotifier {
  final DataLoaderService _dataLoaderService = DataLoaderService();
  final CustomBookService _customBookService = CustomBookService(); // Added service instance
  Map<String, BookCategory> _allBookData = {};
  bool _isLoading = false;
  String? _error;

  Map<String, BookCategory> get allBookData => _allBookData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DataProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _dataLoaderService.clearCache(); // Added cache clearing
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allBookData = await _dataLoaderService.loadData();
      print("[DataProvider] LoadAllData Complete. _allBookData keys: ${_allBookData.keys.toList()}");
      _allBookData.forEach((key, category) {
        print("[DataProvider] Category: ${category.name}");
        print("  Has subcategories: ${category.subcategories != null && category.subcategories!.isNotEmpty}");
        if (category.subcategories != null && category.subcategories!.isNotEmpty) {
          category.subcategories!.forEach((subCat) {
            print("    SubCategory: ${subCat.name}, Books count: ${subCat.books.length}, Sub-subcategories: ${subCat.subcategories != null && subCat.subcategories!.isNotEmpty}");
            if (subCat.subcategories != null && subCat.subcategories!.isNotEmpty) {
              for (var deepSubCat in subCat.subcategories!) {
                print("      DeepSubCategory: ${deepSubCat.name}, Books count: ${deepSubCat.books.length}");
              }
            }
          });
        }
        print("  Direct books count: ${category.books.length}");
      });
    } catch (e) {
      _error = e.toString();
      print("Error in DataProvider: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  BookCategory? getCategory(String categoryName) {
    return _allBookData[categoryName];
  }

  BookDetails? getBookDetails(String categoryName, String bookName) {
    return _allBookData[categoryName]?.books[bookName];
  }

  // Custom book management methods
  Future<void> addCustomBook({
      required String categoryName,
      required String bookName,
      required String contentType,
      required int pages,
      required List<String> columns,
  }) async {
      _isLoading = true;
      _error = null;
      notifyListeners();
      try {
          await _customBookService.addCustomBook(
              categoryName: categoryName,
              bookName: bookName,
              contentType: contentType,
              pages: pages,
              columns: columns,
          );
          await loadAllData(); // Reload all data after adding
      } catch (e) {
          _error = "Error adding custom book: ${e.toString()}";
      }
      _isLoading = false;
      notifyListeners();
  }

  Future<void> editCustomBook({
      required String id,
      required String categoryName,
      required String bookName,
      required String contentType,
      required int pages,
      required List<String> columns,
  }) async {
      _isLoading = true;
      _error = null;
      notifyListeners();
      try {
          final success = await _customBookService.editCustomBook(
              id: id,
              categoryName: categoryName,
              bookName: bookName,
              contentType: contentType,
              pages: pages,
              columns: columns,
          );
          if (success) {
              await loadAllData(); // Reload all data after editing
          } else {
              _error = "Failed to find custom book to edit (ID: $id).";
          }
      } catch (e) {
          _error = "Error editing custom book: ${e.toString()}";
      }
      _isLoading = false;
      notifyListeners();
  }

  Future<void> deleteCustomBook(String id) async {
      _isLoading = true;
      _error = null;
      notifyListeners();
      try {
          final success = await _customBookService.deleteCustomBook(id);
          if (success) {
              await loadAllData(); // Reload all data after deleting
          } else {
              _error = "Failed to find custom book to delete (ID: $id).";
          }
      } catch (e) {
          _error = "Error deleting custom book: ${e.toString()}";
      }
      _isLoading = false;
      notifyListeners();
  }
}
