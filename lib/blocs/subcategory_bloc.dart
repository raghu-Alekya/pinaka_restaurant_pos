import 'package:flutter_bloc/flutter_bloc.dart';
import '../events/subcategory_event.dart';
import '../repository/subcategory_repository.dart';
// import '../states/subcategory_state.dart';
import '../models/category/subcategory_model.dart';
// import '../repositories/subcategory_repository.dart';
import '../states/subcategory_states.dart';

class SubCategoryBloc extends Bloc<SubCategoryEvent, SubCategoryState> {
  final SubCategoryRepository subCategoryRepository;

  SubCategoryBloc({required this.subCategoryRepository}) : super(SubCategoryInitial()) {
    on<LoadSubCategories>(_onLoadSubCategories);
    on<SelectSubCategory>(_onSelectSubCategory);
  }

  Future<void> _onLoadSubCategories(
      LoadSubCategories event,
      Emitter<SubCategoryState> emit,
      ) async {
    emit(SubCategoryLoading());
    try {
      final subCategories = await subCategoryRepository.fetchSubCategories(event.categoryId);
      emit(SubCategoryLoaded(subCategories, selectedSubCategory: null));
    } catch (e) {
      emit(SubCategoryError(e.toString()));
    }
  }

  void _onSelectSubCategory(
      SelectSubCategory event,
      Emitter<SubCategoryState> emit,
      ) {
    final currentState = state;
    if (currentState is SubCategoryLoaded) {
      final selected = currentState.subCategories.firstWhere(
            (sc) => sc.id == event.subCategoryId,
        orElse: () => currentState.selectedSubCategory ?? currentState.subCategories.first,
      );
      emit(SubCategoryLoaded(currentState.subCategories, selectedSubCategory: selected));
    }
  }
}
