import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/category/subcategory_model.dart';
import '../../repositories/subcategory_repository.dart';
import '../Bloc Event/subcategory_event.dart';
import '../Bloc State/subcategory_states.dart';

class SubCategoryBloc extends Bloc<SubCategoryEvent, SubCategoryState> {
  final SubCategoryRepository subCategoryRepository;

  SubCategoryBloc({required this.subCategoryRepository})
      : super(SubCategoryInitial()) {
    on<LoadSubCategories>(_onLoadSubCategories);
    on<SelectSubCategory>(_onSelectSubCategory);

    // ✅ Add ResetSubCategory handler inside constructor
    on<ResetSubCategory>((event, emit) {
      emit(SubCategoryInitial()); // or SubCategoryLoading() if you prefer
    });
  }

  // Load all subcategories for a category
  // Inside _onLoadSubCategories
  Future<void> _onLoadSubCategories(
      LoadSubCategories event, Emitter<SubCategoryState> emit) async {
    emit(SubCategoryLoading());
    try {
      final subcategories = await subCategoryRepository.fetchSubCategories(
        token: event.token,
        categoryId: event.categoryId,
      );

      if (subcategories.isEmpty) {
        emit(SubCategoryLoaded(subcategories: [], selectedSubCategory: null));
        return;
      }

      // ❌ Make sure selectedSubCategory is null, not first subcategory
      emit(SubCategoryLoaded(
        subcategories: subcategories,
        selectedSubCategory: null, // <--- no auto-selection
      ));
    } catch (e) {
      emit(SubCategoryError(e.toString()));
    }
  }


  // Select a specific subcategory
  void _onSelectSubCategory(
      SelectSubCategory event, Emitter<SubCategoryState> emit) {
    if (state is SubCategoryLoaded) {
      final currentState = state as SubCategoryLoaded;

      final exists = currentState.subcategories
          .any((s) => s.id == event.subCategoryId);
      if (!exists) return;

      emit(SubCategoryLoaded(
        subcategories: currentState.subcategories,
        selectedSubCategory: event.subCategoryId,
      ));

      // ⚠️ Do NOT trigger mini-subcategory or product loading here.
      // Let the UI BlocListener handle it.
    }
  }
}
