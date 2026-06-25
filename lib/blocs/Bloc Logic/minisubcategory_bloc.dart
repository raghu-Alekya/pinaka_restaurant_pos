import 'package:bloc/bloc.dart';
import '../../models/category/minisubcategory_model.dart';
// import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../Bloc Event/minisubcategory_event.dart';
import '../Bloc State/minisubcategory.dart';
// import '../events/minisubcategory_event.dart';
// import '../repository/minisubcategory_repository.dart';
// import '../states/minisubcategory.dart';
// import 'mini_subcategory_event.dart';
// import 'mini_subcategory_state.dart';

class MiniSubCategoryBloc
    extends Bloc<MiniSubCategoryEvent, MiniSubCategoryState> {
  final MiniSubCategoryRepository repository;
  Set<int> expandedFolderIds = {};
  final Map<int, List<MiniSubCategory>> _cache = {};

  MiniSubCategoryBloc({required this.repository})
      : super(MiniSubCategoryInitial()) {
    on<FetchMiniSubCategories>(_onFetchMiniSubCategories);
    on<ToggleFolder>(_onToggleFolder);
    on<SelectProduct>(_onSelectProduct);
    // ✅ Reset event
    on<ResetMiniSubCategory>((event, emit) {
      expandedFolderIds.clear();
      emit(MiniSubCategoryInitial());
    });

    // Debug: Listen to all state changes
    stream.listen((state) {
      print("BLoC State Changed: $state");
      if (state is MiniSubCategoryLoaded) {
        print("Loaded MiniSubCategories:");
        for (var mini in state.miniSubCategories) {
          print(
              "- ${mini.name} (Folder: ${mini.isFolder}, Products: ${mini.products.length})");
        }
        print("Expanded Folder IDs: ${state.expandedFolderIds}");
      }
    });
  }

  Future<void> _onFetchMiniSubCategories(
      FetchMiniSubCategories event,
      Emitter<MiniSubCategoryState> emit,
      ) async {

    // Return cached data immediately
    if (_cache.containsKey(event.subCategoryId)) {
      print("📦 MiniSubCategories loaded from cache");

      emit(
        MiniSubCategoryLoaded(
          miniSubCategories: _cache[event.subCategoryId]!,
          expandedFolderIds: Set.from(expandedFolderIds),
        ),
      );
      return;
    }

    emit(MiniSubCategoryLoading());

    try {
      final miniSubCategories =
      await repository.fetchMiniSubCategories(event.subCategoryId);

      // Save to cache
      _cache[event.subCategoryId] = miniSubCategories;

      emit(
        MiniSubCategoryLoaded(
          miniSubCategories: miniSubCategories,
          expandedFolderIds: Set.from(expandedFolderIds),
        ),
      );
    } catch (e, stack) {
      print("Error fetching mini-subcategories: $e\n$stack");

      emit(MiniSubCategoryError(e.toString()));
    }
  }
  void _onToggleFolder(ToggleFolder event, Emitter<MiniSubCategoryState> emit) {
    print("Event: ToggleFolder -> ${event.miniSubCategoryId}");
    if (state is MiniSubCategoryLoaded) {
      final currentState = state as MiniSubCategoryLoaded;

      if (expandedFolderIds.contains(event.miniSubCategoryId)) {
        expandedFolderIds.remove(event.miniSubCategoryId);
        print("Folder Collapsed: ${event.miniSubCategoryId}");
      } else {
        expandedFolderIds.add(event.miniSubCategoryId);
        print("Folder Expanded: ${event.miniSubCategoryId}");
      }

      emit(currentState.copyWith(expandedFolderIds: Set.from(expandedFolderIds)));
    }
  }

  void _onSelectProduct(SelectProduct event, Emitter<MiniSubCategoryState> emit) {
    print("Event: SelectProduct -> ${event.product.name} (ID: ${event.product.id})");
    // You can handle product selection logic here
  }
}
