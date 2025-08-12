import 'package:flutter_bloc/flutter_bloc.dart';
import '../events/minisubcategory_event.dart';
import '../models/category/minisubcategory_model.dart';
import '../states/minisubcategory.dart';

typedef MiniSubCategoryFetcher = Future<List<MiniSubCategory>> Function(String parentId);

class MiniSubCategoryBloc extends Bloc<MiniSubCategoryEvent, MiniSubCategoryState> {
  final MiniSubCategoryFetcher fetcher;

  MiniSubCategoryBloc({required this.fetcher}) : super(MiniSubCategoryInitial()) {
    on<LoadMiniSubCategories>(_onLoadMiniSubCategories);
    on<SelectMiniSubCategory>(_onSelectMiniSubCategory);
  }

  Future<void> _onLoadMiniSubCategories(
      LoadMiniSubCategories event,
      Emitter<MiniSubCategoryState> emit,
      ) async {
    emit(MiniSubCategoryLoading());
    try {
      final miniSubs = await fetcher(event.parentId);
      emit(MiniSubCategoryLoaded(miniSubs));
    } catch (e) {
      emit(MiniSubCategoryError(e.toString()));
    }
  }

  void _onSelectMiniSubCategory(
      SelectMiniSubCategory event,
      Emitter<MiniSubCategoryState> emit,
      ) {
    final currentState = state;
    if (currentState is MiniSubCategoryLoaded) {
      final selected = currentState.miniSubCategories.firstWhere(
            (m) => m.id == event.miniSubCategoryId,
        orElse: () => currentState.selectedMiniSubCategory ?? currentState.miniSubCategories.first,
      );
      emit(MiniSubCategoryLoaded(currentState.miniSubCategories, selectedMiniSubCategory: selected));
    }
  }
}
