import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/search_repository.dart';
import '../Bloc Event/serach_product_event.dart';
import '../Bloc State/search_product_state.dart';
// import 'product_event.dart';
// import 'product_state.dart';
// import '../repositories/product_repository.dart';

class ProductBloc extends Bloc<SearchProductEvent, SearchProductState> {
  final Search_ProductRepository  repository;

  ProductBloc(this.repository) : super(SearchProductInitial()) {
    on<SearchFetchProducts>(_onFetchProducts);
    on<SearchClearProducts>((event, emit) => emit(SearchProductInitial()));
  }

  Future<void> _onFetchProducts(
      SearchFetchProducts event,
      Emitter<SearchProductState> emit,
      ) async {
    emit(SearchProductLoading());

    try {
      final products =
      await repository.SearchfetchProducts(search: event.search);

      if (products.isEmpty) {
        emit(SearchProductEmpty());
      } else {
        emit(SearchProductLoaded(products));
      }
    } catch (e) {
      emit(SearchProductError(e.toString()));
    }
  }
}
