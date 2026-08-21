import 'package:equatable/equatable.dart';
import '../../entities/category_entity.dart';
import '../../entities/product_entity.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  final int selectedCategoryId;
  final List<SubcategoryEntity> subcategories;
  final List<ProductEntity> directProducts;
  final Map<int, List<ProductEntity>> subcategoryProducts;
  final Map<int, List<MiniSubcategoryEntity>> miniSubcategoriesMap;

  const CategoryLoaded({
    required this.categories,
    required this.selectedCategoryId,
    this.subcategories = const [],
    this.directProducts = const [],
    this.subcategoryProducts = const {},
    this.miniSubcategoriesMap = const {},
  });

  /// Distinct mini-subcategory names across the current category
  /// (e.g. "Indian", "Imported") — drives the language/variant toggle
  /// in the UI instead of a hardcoded Indian/English pair.
  List<String> get availableLanguages {
    final seen = <String>{};
    final result = <String>[];
    for (final sub in subcategories) {
      final minis = miniSubcategoriesMap[sub.id] ?? sub.miniSubcategories;
      for (final m in minis) {
        if (m.name.trim().isNotEmpty && seen.add(m.name)) {
          result.add(m.name);
        }
      }
    }
    return result;
  }

  @override
  // IMPORTANT: miniSubcategoriesMap must be included here, otherwise
  // Bloc's built-in equality check can treat two different states as
  // "the same" and skip rebuilding the UI.
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    subcategories,
    directProducts,
    subcategoryProducts,
    miniSubcategoriesMap,
  ];
}

class CategoryError extends CategoryState {
  final String message;

  const CategoryError({required this.message});

  @override
  List<Object?> get props => [message];
}


