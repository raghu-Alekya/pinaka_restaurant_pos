// blocs/search/search_product_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/search_repository.dart';
import '../Bloc Event/serach_product_event.dart';
import '../Bloc State/search_product_state.dart';
// import 'search_product_event.dart';
// import 'search_product_state.dart';
// import '../../repositories/search_product_repository.dart';

class SearchProductBloc
    extends Bloc<SearchProductEvent, SearchProductState> {
  final Search_ProductRepository repository;

  SearchProductBloc(this.repository) : super(SearchProductInitial()) {
    on<SearchFetchProducts>(_onSearchFetchProducts);
    on<SearchClearProducts>(_onSearchClearProducts);
  }

  Future<void> _onSearchFetchProducts(
      SearchFetchProducts event,
      Emitter<SearchProductState> emit,
      ) async {
    try {
      // ✅ Normalize + null-safety
      final query = (event.search ?? '').trim().toLowerCase();

      // 🚫 Do nothing if less than 2 characters
      if (query.length < 2) {
        emit(SearchProductInitial());
        return;
      }

      emit(SearchProductLoading());

      final products =
      await repository.SearchfetchProducts(search: query);

      if (products.isEmpty) {
        emit(SearchProductEmpty());
      } else {
        emit(SearchProductLoaded(products));
      }
    } catch (e) {
      emit(SearchProductError(e.toString()));
    }
  }


  void _onSearchClearProducts(
      SearchClearProducts event,
      Emitter<SearchProductState> emit,
      ) {
    emit(SearchProductInitial());
  }
}
