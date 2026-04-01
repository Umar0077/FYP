import 'package:flutter/material.dart';

/// Controller for job suggestions logic.
class JobSuggestionsController with ChangeNotifier {
  String selectedFilter = 'All';

  void setFilter(String f) {
    selectedFilter = f;
    notifyListeners();
  }
}
