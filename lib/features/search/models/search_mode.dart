enum SearchMode {
  search,
  research,
  study;

  String get label {
    switch (this) {
      case SearchMode.search:
        return 'Search';
      case SearchMode.research:
        return 'Research';
      case SearchMode.study:
        return 'Study';
    }
  }
}
