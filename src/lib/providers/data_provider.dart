import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../services/data_loader_service.dart';

class DataProvider with ChangeNotifier {
  final DataLoaderService _dataLoaderService = DataLoaderService();
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allBookData = await _dataLoaderService.loadData();
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
}
