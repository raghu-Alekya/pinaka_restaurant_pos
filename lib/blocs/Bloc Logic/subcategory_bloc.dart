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

  SubCategoryBloc({
    required this.subCategoryRepository,
    required this.miniSubCategoryBloc,
    required this.productBloc,
  }) : super(const SubCategoryInitial()) {
    on<LoadSubCategories>(_onLoadSubCategories);
    on<SelectSubCategory>(_onSelectSubCategory);
    on<ResetSubCategory>((event, emit) => emit(const SubCategoryInitial()));
  }

  Future<void> _onLoadSubCategories(
      LoadSubCategories event, Emitter<SubCategoryState> emit) async {
    emit(const SubCategoryLoading());
    try {
      final subcategories = await subCategoryRepository.fetchSubCategories(
        token: event.token,
        categoryId: event.categoryId,
      );

      if (subcategories.isEmpty) {
        emit(SubCategoryLoaded(subcategories: [], selectedSubCategory: null));
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

    miniSubCategoryBloc.add(ResetMiniSubCategory());

    miniSubCategoryBloc.add(
      FetchMiniSubCategories(
        subCategoryId: event.subCategory.id,
      ),
    );
  }
}
