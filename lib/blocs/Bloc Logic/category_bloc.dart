import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/category_repository.dart';
import '../Bloc Event/category_event.dart';
import '../Bloc State/category_states.dart';
// import '../events/category_event.dart';
// import '../models/sidebar/category_model_.dart';
// import '../repository/category_repository.dart';
// import '../states/category_states.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc({required this.repository}) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryState> emit) async {
    print('Loading categories for ${event.restaurantId}');
    emit(CategoryLoading());
    try {
      final categories = await repository.fetchCategories(
        token: event.token,
        restaurantId: event.restaurantId,
      );
      print('Categories loaded: ${categories.length}');
      // Initially select the first category
      emit(CategoryLoaded(
        categories: categories,
        selectedCategory: categories.isNotEmpty ? categories[0] : null,
      ));
    } catch (e) {
      print('Category loading error: $e');
      emit(CategoryError(e.toString()));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<CategoryState> emit) {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;

      // Use try/catch instead of firstWhere orElse returning null
      Category? selected;
      try {
        selected = currentState.categories
            .firstWhere((c) => c.id == event.categoryId);
      } catch (e) {
        selected = null; // fallback if category not found
      }

      emit(CategoryLoaded(
        categories: currentState.categories,
        selectedCategory: selected,
      ));
    }
  }
}
