import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/subcategory_repository.dart';
import '../../repositories/product_repository.dart';
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

      // 🚀 Background pre-fetch: quietly load all subcategories and products in parallel
      for (final cat in categories) {
        SubCategoryRepository().fetchSubCategories(
          token: event.token,
          categoryId: cat.id,
        ).then((subCategories) {
          for (final subCat in subCategories) {
            ProductRepository().fetchProductsBySubCategory(subCat.id).catchError((_) {});
          }
        }).catchError((_) {});
      }
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst("Exception: ", "");

      print("Category Error: $message");
      print(stackTrace);

      emit(CategoryError(message));
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



// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../models/sidebar/category_model_.dart';
// import '../../repositories/category_repository.dart';
// import '../Bloc Event/category_event.dart';
// import '../Bloc State/category_states.dart';
//
// class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
//   final CategoryRepository repository;
//
//   // ✅ NEW: Caches categories per restaurantId so re-entering this bloc's
//   // screen (e.g. DashboardScreen gets recreated after navigating away and
//   // back) doesn't re-fetch from the network every time. Same pattern as
//   // MiniSubCategoryBloc/_subCategoryCache in SubCategoryBloc.
//   final Map<String, List<Category>> _categoryCache = {};
//
//   CategoryBloc({required this.repository}) : super(CategoryInitial()) {
//     on<LoadCategories>(_onLoadCategories);
//     on<SelectCategory>(_onSelectCategory);
//   }
//
//   Future<void> _onLoadCategories(
//       LoadCategories event, Emitter<CategoryState> emit) async {
//
//     // ✅ Serve from cache instantly if we've already fetched it
//     final cached = _categoryCache[event.restaurantId];
//     if (cached != null) {
//       print("📦 Categories loaded from cache for restaurant ${event.restaurantId}");
//
//       emit(CategoryLoaded(
//         categories: cached,
//         selectedCategory: cached.isNotEmpty ? cached[0] : null,
//       ));
//       return;
//     }
//
//     emit(CategoryLoading());
//     try {
//       final categories = await repository.fetchCategories(
//         token: event.token,
//         restaurantId: event.restaurantId,
//       );
//
//       // ✅ Save to cache
//       _categoryCache[event.restaurantId] = categories;
//
//       emit(CategoryLoaded(
//         categories: categories,
//         selectedCategory: categories.isNotEmpty ? categories[0] : null,
//       ));
//     } catch (e, stackTrace) {
//       final message = e.toString().replaceFirst("Exception: ", "");
//
//       print("Category Error: $message");
//       print(stackTrace);
//
//       emit(CategoryError(message));
//     }
//   }
//
//   void _onSelectCategory(SelectCategory event, Emitter<CategoryState> emit) {
//     if (state is CategoryLoaded) {
//       final currentState = state as CategoryLoaded;
//
//       // Use try/catch to handle not found case
//       Category? selected;
//       try {
//         selected = currentState.categories
//             .firstWhere((c) => c.id == event.categoryId);
//       } catch (e) {
//         selected = null; // fallback if not found
//       }
//
//       emit(CategoryLoaded(
//         categories: currentState.categories,
//         selectedCategory: selected,
//       ));
//     }
//   }
//
// }