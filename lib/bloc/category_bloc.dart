import 'package:flutter_bloc/flutter_bloc.dart';
import '../events/category_event.dart';
import '../models/sidebar/category_model_.dart';
import '../states/category_states.dart';

Future<List<Category>> fetchCategories() async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    Category(
      id: '1',
      name: 'Example Category',
      imagePath: 'assets/images/example.png',
      subCategories: [],
    ),
  ];
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await fetchCategories();
      // On load, no category selected by default (or pick the first)
      emit(CategoryLoaded(categories, selectedCategory: null));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<CategoryState> emit) {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      final selected = currentState.categories.firstWhere(
            (cat) => cat.id == event.categoryId,
        orElse: () => currentState.selectedCategory ?? currentState.categories.first,
      );
      emit(CategoryLoaded(currentState.categories, selectedCategory: selected));
    }
  }
}
