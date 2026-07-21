import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Event/inventory%20_event.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/product_bloc.dart';
// import 'package:pinaka_restaurant_pos/blocs/Bloc%20Event/inventory%20_event.dart';
import '../../models/category/subcategory_model.dart';
import '../../repositories/subcategory_repository.dart';
import '../Bloc Event/product_event.dart';
import '../Bloc Event/subcategory_event.dart';
import '../Bloc State/subcategory_states.dart';
import '../Bloc Event/minisubcategory_event.dart';
import '../Bloc Logic/minisubcategory_bloc.dart';
import 'inventory_bloc.dart';


class SubCategoryBloc extends Bloc<SubCategoryEvent, SubCategoryState> {
  final SubCategoryRepository subCategoryRepository;
  final MiniSubCategoryBloc miniSubCategoryBloc;
  final ProductBloc productBloc;

  // ✅ NEW: Caches subcategories per categoryId so re-selecting the same
  // category (e.g. tapping it again in the sidebar) doesn't re-fetch from
  // the network every time. Same pattern as MiniSubCategoryBloc's _cache.
  final Map<String, List<SubCategory>> _subCategoryCache = {};

  SubCategoryBloc({
    required this.subCategoryRepository,
    required this.miniSubCategoryBloc,
    required this.productBloc,
  }) : super(const SubCategoryInitial()) {
    on<LoadSubCategories>(_onLoadSubCategories);
    on<SelectSubCategory>(_onSelectSubCategory);
    on<ResetSubCategory>((event, emit) {
      _subCategoryCache.clear(); // ✅ purge stale session data, same as MiniSubCategoryBloc
      emit(const SubCategoryInitial());
    });
  }

  Future<void> _onLoadSubCategories(
      LoadSubCategories event, Emitter<SubCategoryState> emit) async {

    // ✅ Serve from cache instantly if this category was already loaded
    final cached = _subCategoryCache[event.categoryId];
    if (cached != null) {
      print("📦 SubCategories loaded from cache for category ${event.categoryId}");

      if (cached.isEmpty) {
        emit(SubCategoryLoaded(subcategories: [], selectedSubCategory: null));
        productBloc.add(
          FetchProductsBySubCategory(
            subCategoryId: int.parse(event.categoryId),
          ),
        );
        return;
      }

      final firstSub = cached.first;

      emit(SubCategoryLoaded(
        subcategories: cached,
        selectedSubCategory: firstSub.id,
      ));

      // Mini-subcategories/products for the first sub are already cached
      // inside MiniSubCategoryBloc/ProductBloc too, so these calls will
      // themselves resolve from cache instead of hitting the network.
      miniSubCategoryBloc.add(FetchMiniSubCategories(subCategoryId: firstSub.id));
      productBloc.add(
        FetchProductsBySubCategory(
          subCategoryId: firstSub.id,
        ),
      );
      return;
    }

    emit(const SubCategoryLoading());
    try {
      final subcategories = await subCategoryRepository.fetchSubCategories(
        token: event.token,
        categoryId: event.categoryId,
      );

      // ✅ Save to cache
      _subCategoryCache[event.categoryId] = subcategories;

      if (subcategories.isEmpty) {
        emit(SubCategoryLoaded(subcategories: [], selectedSubCategory: null));
        productBloc.add(
          FetchProductsBySubCategory(
            subCategoryId: int.parse(event.categoryId),
          ),
        );
        return;
      }

      final firstSub = subcategories.first;

      emit(SubCategoryLoaded(
        subcategories: subcategories,
        selectedSubCategory: firstSub.id,
      ));

      // Load mini-subcategories automatically
      // miniSubCategoryBloc.add(ResetMiniSubCategory());
      miniSubCategoryBloc.add(FetchMiniSubCategories(subCategoryId: firstSub.id));
      productBloc.add(
        FetchProductsBySubCategory(
          subCategoryId: firstSub.id,
        ) ,
      );
    } catch (e) {
      emit(SubCategoryError(e.toString()));
    }
  }

  void _onSelectSubCategory(
      SelectSubCategory event,
      Emitter<SubCategoryState> emit,
      ) {
    if (state is! SubCategoryLoaded) return;

    final current = state as SubCategoryLoaded;

    // Already selected? Do nothing.
    if (current.selectedSubCategory == event.subCategory.id) {
      return;
    }

    emit(
      SubCategoryLoaded(
        subcategories: current.subcategories,
        selectedSubCategory: event.subCategory.id,
      ),
    );

    // ❌ REMOVED: miniSubCategoryBloc.add(ResetMiniSubCategory());
    // This was the actual bug — ResetMiniSubCategory calls _cache.clear()
    // inside MiniSubCategoryBloc, so it wiped every previously-fetched
    // folder's products on EVERY tab tap, forcing a re-fetch every time.
    // ResetMiniSubCategory should only fire when leaving the category
    // entirely (DashboardScreen._onBreadcrumbTap already does this at
    // index == 0), not on every subcategory selection.

    miniSubCategoryBloc.add(
      FetchMiniSubCategories(
        subCategoryId: event.subCategory.id,
      ),
    );
  }
}