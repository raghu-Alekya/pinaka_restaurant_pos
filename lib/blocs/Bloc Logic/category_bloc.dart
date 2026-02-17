import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/category_repository.dart';
import '../Bloc Event/category_event.dart';
import '../Bloc State/category_states.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc({required this.repository}) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await repository.fetchCategories(
        token: event.token,
        restaurantId: event.restaurantId,
      );

      emit(CategoryLoaded(
        categories: categories,
        selectedCategory: categories.isNotEmpty ? categories[0] : null,
      ));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<CategoryState> emit) {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;

      // Use try/catch to handle not found case
      Category? selected;
      try {
        selected = currentState.categories
            .firstWhere((c) => c.id == event.categoryId);
      } catch (e) {
        selected = null; // fallback if not found
      }

      emit(CategoryLoaded(
        categories: currentState.categories,
        selectedCategory: selected,
      ));
    }
  }

}
