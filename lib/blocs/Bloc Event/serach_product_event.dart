abstract class SearchProductEvent {}

class SearchFetchProducts extends SearchProductEvent {
  final String? search;

  SearchFetchProducts({this.search});
}

class SearchClearProducts extends SearchProductEvent {}
