import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/subcategory_repository.dart';
import '../Bloc Event/subcategory_event.dart';
import '../Bloc State/subcategory_states.dart';
// import '../events/subcategory_event.dart';
// import '../states/subcategory_state.dart';
// import '../repository/subcategory_repository.dart';
// import '../models/sidebar/subcategory_model.dart';
// import '../states/subcategory_states.dart';

class SubCategoryBloc extends Bloc<SubCategoryEvent, SubCategoryState> {
  final SubCategoryRepository subCategoryRepository;

  SubCategoryBloc({required this.subCategoryRepository}) : super(SubCategoryInitial()) {
    on<LoadSubCategories>(_onLoadSubCategories);
    on<SelectSubCategory>(_onSelectSubCategory);
  }

  Future<void> _onLoadSubCategories(
      LoadSubCategories event, Emitter<SubCategoryState> emit) async {
    emit(SubCategoryLoading());
    try {
      final subcategories = await subCategoryRepository.fetchSubCategories(
        token: event.token,
        categoryId: event.categoryId,
      );

      emit(SubCategoryLoaded(
        subcategories: subcategories,
        selectedSubCategory: subcategories.isNotEmpty ? subcategories[0] : null,
      ));
    } catch (e) {
      emit(SubCategoryError(e.toString()));
    }
  }

  void _onSelectSubCategory(
      SelectSubCategory event, Emitter<SubCategoryState> emit) {
    if (state is SubCategoryLoaded) {
      final currentState = state as SubCategoryLoaded;

      final selected = currentState.subcategories
          .where((s) => s.id == event.subCategoryId)
          .toList();

      emit(SubCategoryLoaded(
        subcategories: currentState.subcategories,
        selectedSubCategory: selected.isNotEmpty ? selected.first : null,
      ));
    }
  }
}
