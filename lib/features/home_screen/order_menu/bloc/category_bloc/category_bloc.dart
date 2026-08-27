import 'package:bloc/bloc.dart';
import '../../entities/category_entity.dart';
import '../../entities/product_entity.dart';
import '../../usecases/category_usecase.dart';
import '../../usecases/mini_subcategory_usecase.dart';
import '../../usecases/product_usecase.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryUseCase categoryUseCase;
  final ProductUseCase productUseCase;
  final FetchMiniSubcategoriesUseCase miniSubcategoryUseCase;

  CategoryBloc({
    required this.categoryUseCase,
    required this.productUseCase,
    required this.miniSubcategoryUseCase,
  }) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
    on<UpdateProductsStock>(_onUpdateProductsStock); // ← NEW
  }

  List<CategoryEntity> _allCategories = [];

  /// categoryId -> already-loaded state. Once a category has been
  /// fetched once, switching back to it is instant (no re-hit of the
  /// mini-subcategory / product endpoints).
  final Map<int, CategoryLoaded> _cache = {};

  Future<void> _onLoadCategories(
      LoadCategories event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      final categories = await categoryUseCase();
      _allCategories = categories;
      _cache.clear();
      if (categories.isNotEmpty) {
        await _loadCategoryData(categories.first.id, emit);
      } else {
        emit(CategoryError(message: 'No categories found.'));
      }
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onSelectCategory(
      SelectCategory event,
      Emitter<CategoryState> emit,
      ) async {
    await _loadCategoryData(event.categoryId, emit);
  }

  Future<void> _loadCategoryData(
      int categoryId,
      Emitter<CategoryState> emit,
      ) async {
    // 1) Instant path: already fetched this category before.
    final cached = _cache[categoryId];
    if (cached != null) {
      emit(cached);
      return;
    }

    // 2) Only show a spinner for a category we haven't fetched yet.
    emit(CategoryLoading());

    final category = _allCategories.firstWhere((c) => c.id == categoryId);

    // No subcategories at all -> fetch products directly for the category.
    if (category.subcategories.isEmpty) {
      List<ProductEntity> directProducts = [];
      try {
        directProducts = await productUseCase(categoryId);
      } catch (_) {
        directProducts = [];
      }
      final loaded = CategoryLoaded(
        categories: _allCategories,
        selectedCategoryId: categoryId,
        directProducts: directProducts,
      );
      _cache[categoryId] = loaded;
      emit(loaded);
      return;
    }

    final subsWithMini =
    category.subcategories.where((s) => s.miniSubcategories.isNotEmpty).toList();
    final subsWithoutMini =
    category.subcategories.where((s) => s.miniSubcategories.isEmpty).toList();

    // Fire all mini-subcategory + product requests IN PARALLEL instead of
    // one-by-one in a for-loop — this is what was causing the lag.
    final miniFutures = subsWithMini.map((sub) async {
      try {
        final miniList = await miniSubcategoryUseCase(sub.id);
        return MapEntry(sub.id, miniList);
      } catch (_) {
        return MapEntry(sub.id, sub.miniSubcategories);
      }
    });

    final productFutures = subsWithoutMini.map((sub) async {
      if (sub.directProducts.isNotEmpty) {
        return MapEntry(sub.id, sub.directProducts);
      }
      try {
        final products = await productUseCase(sub.id);
        return MapEntry(sub.id, products);
      } catch (_) {
        return MapEntry(sub.id, <ProductEntity>[]);
      }
    });

    final results = await Future.wait([
      Future.wait(miniFutures),
      Future.wait(productFutures),
    ]);

    final miniResults =
    results[0] as List<MapEntry<int, List<MiniSubcategoryEntity>>>;
    final productResults =
    results[1] as List<MapEntry<int, List<ProductEntity>>>;

    final miniSubcategoriesMap = {for (final e in miniResults) e.key: e.value};
    final subcategoryProducts = {for (final e in productResults) e.key: e.value};

    final loaded = CategoryLoaded(
      categories: _allCategories,
      selectedCategoryId: categoryId,
      subcategories: category.subcategories,
      directProducts: const [],
      subcategoryProducts: subcategoryProducts,
      miniSubcategoriesMap: miniSubcategoriesMap,
    );
    _cache[categoryId] = loaded;
    emit(loaded);
  }

  // ─────────────────────────────────────────────────────────────────
  // NEW: patch in-memory stock status (no network, no CategoryLoading)
  // so Order Menu + Menu Management update instantly after edit.
  // ─────────────────────────────────────────────────────────────────
  Future<void> _onUpdateProductsStock(
      UpdateProductsStock event,
      Emitter<CategoryState> emit,
      ) async {
    if (event.stockById.isEmpty) return;

    ProductEntity patchProduct(ProductEntity p) {
      final newInStock = event.stockById[p.id];
      if (newInStock == null || newInStock == p.inStock) return p;
      return ProductEntity(
        id: p.id,
        name: p.name,
        price: p.price,
        inStock: newInStock,
        isVeg: p.isVeg,
      );
    }

    List<ProductEntity> patchList(List<ProductEntity> list) =>
        list.map(patchProduct).toList();

    // Patch every cached category so tab switches stay correct
    final updatedCache = <int, CategoryLoaded>{};
    for (final entry in _cache.entries) {
      final loaded = entry.value;

      final newDirect = patchList(loaded.directProducts);

      final newSubProducts = <int, List<ProductEntity>>{};
      loaded.subcategoryProducts.forEach((id, list) {
        newSubProducts[id] = patchList(list);
      });

      final newMiniMap = <int, List<MiniSubcategoryEntity>>{};
      loaded.miniSubcategoriesMap.forEach((subId, miniList) {
        newMiniMap[subId] = miniList.map((mini) {
          return MiniSubcategoryEntity(
            id: mini.id,
            name: mini.name,
            products: patchList(mini.products),
            // add any other required fields from your MiniSubcategoryEntity
          );
        }).toList();
      });

      updatedCache[entry.key] = CategoryLoaded(
        categories: loaded.categories,
        selectedCategoryId: loaded.selectedCategoryId,
        subcategories: loaded.subcategories,
        directProducts: newDirect,
        subcategoryProducts: newSubProducts,
        miniSubcategoriesMap: newMiniMap,
      );
    }

    _cache
      ..clear()
      ..addAll(updatedCache);

    // Emit the currently selected category so UI rebuilds immediately
    final current = state;
    if (current is CategoryLoaded) {
      final patched = _cache[current.selectedCategoryId];
      if (patched != null) {
        emit(patched);
      }
    }
  }
}