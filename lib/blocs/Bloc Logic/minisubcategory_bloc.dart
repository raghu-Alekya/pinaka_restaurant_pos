import 'package:bloc/bloc.dart';
import '../../models/category/items_model.dart';
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
  final Map<int, List<MiniSubCategory>> _cache = {}; // MiniSubCategoryBloc

  // The last successfully loaded data, kept around so the bloc never has
  // to fall back to a blank Loading/Error state once we have SOMETHING
  // to show. This is intentionally NOT cleared by ResetMiniSubCategory.
  MiniSubCategoryLoaded? _lastLoaded;

  // Which subcategory is currently "active" (most recently requested).
  // Used to ignore stale async results if the user has already moved on
  // to a different subcategory tab before an older fetch resolves.
  int? _activeSubCategoryId;

  // Guards against firing duplicate background refreshes for the same id.
  final Set<int> _inFlightRefresh = {};

  MiniSubCategoryBloc({required this.repository})
    : super(MiniSubCategoryInitial()) {
    on<FetchMiniSubCategories>(_onFetchMiniSubCategories);
    on<ToggleFolder>(_onToggleFolder);
    on<SelectProduct>(_onSelectProduct);
    on<MiniSubCategoryBackgroundFetchSucceeded>(_onBackgroundFetchSucceeded);
    on<MiniSubCategoryBackgroundFetchFailed>(_onBackgroundFetchFailed);

    // ✅ Reset event — clears only transient UI state now, NOT the cache.
    // Clearing `_cache` here used to mean every sidebar category tap threw
    // away previously-loaded (and offline-usable) data, forcing a fresh
    // network fetch — and a raw error dump if that fetch failed offline.
    on<ResetMiniSubCategory>((event, emit) {
      expandedFolderIds.clear();
      // Intentionally NOT touching `_cache` or `_lastLoaded` — whatever
      // was already loaded stays available (and on screen) so switching
      // categories/subcategories never blanks the UI or forces a refetch
      // of data we already have.
    });

    // ✅ True full reset — only for logout / new session.
    on<ClearMiniSubCategoryCache>((event, emit) {
      expandedFolderIds.clear();
      _cache.clear();
      _lastLoaded = null;
      _activeSubCategoryId = null;
      _inFlightRefresh.clear();
      emit(MiniSubCategoryInitial());
    });

    // Debug: Listen to all state changes
    stream.listen((state) {
      print("BLoC State Changed: $state");
      if (state is MiniSubCategoryLoaded) {
        print(
          "Loaded MiniSubCategories (isRefreshing=${state.isRefreshing}, "
          "isOffline=${state.isOffline}):",
        );
        for (var mini in state.miniSubCategories) {
          print(
            "- ${mini.name} (Folder: ${mini.isFolder}, Products: ${mini.products.length})",
          );
        }
        print("Expanded Folder IDs: ${state.expandedFolderIds}");
      }
    });
  }

  bool hasCacheFor(int subCategoryId) => _cache.containsKey(subCategoryId);
  List<MiniSubCategory>? getCacheFor(int subCategoryId) =>
      _cache[subCategoryId];
  void saveToCache(int subCategoryId, List<MiniSubCategory> data) =>
      _cache[subCategoryId] = data;

  Future<void> _onFetchMiniSubCategories(
    FetchMiniSubCategories event,
    Emitter<MiniSubCategoryState> emit,
  ) async {
    final id = event.subCategoryId;
    _activeSubCategoryId = id;

    // 1) Cache hit -> instant, no Loading state at all, zero flicker.
    if (_cache.containsKey(id)) {
      print("📦 MiniSubCategories loaded from cache");

      final loaded = MiniSubCategoryLoaded(
        miniSubCategories: _cache[id]!,
        expandedFolderIds: Set.from(expandedFolderIds),
      );
      _lastLoaded = loaded;
      emit(loaded);

      // Keep it fresh silently — never blocks or replaces what's on screen
      // unless the data actually changed.
      _refreshInBackground(id);
      return;
    }

    // No cache for this subcategory
    emit(MiniSubCategoryLoading());

    try {
      final miniSubCategories = await repository.fetchMiniSubCategories(id);

      if (isClosed || _activeSubCategoryId != id) {
        // User already moved to a different subcategory — still cache the
        // result for later, just don't touch the UI with it now.
        _cache[id] = miniSubCategories;
        return;
      }

      // Save to cache
      _cache[id] = miniSubCategories;

      final loaded = MiniSubCategoryLoaded(
        miniSubCategories: miniSubCategories,
        expandedFolderIds: Set.from(expandedFolderIds),
      );
      _lastLoaded = loaded;
      emit(loaded);
    } catch (e, stack) {
      print("Error fetching mini-subcategories: $e\n$stack");

      if (isClosed || _activeSubCategoryId != id) return; // stale, ignore

      if (_lastLoaded != null) {
        // Don't blank the screen with a raw error — keep the last good
        // content visible and simply flag that we're offline/stale.
        emit(_lastLoaded!.copyWith(isRefreshing: false, isOffline: true));
      } else {
        // Truly nothing cached anywhere and the very first fetch failed.
        emit(MiniSubCategoryError(_friendlyError(e)));
      }
    }
  }

  /// Fire-and-forget silent refresh for an already-cached subcategory.
  /// Never shows a spinner and never blanks the screen — only updates the
  /// UI if the refreshed data actually differs from what's cached, and
  /// only if that subcategory is still the one being viewed.
  void _refreshInBackground(int id) {
    if (_inFlightRefresh.contains(id)) return;
    _inFlightRefresh.add(id);

    repository
        .fetchMiniSubCategories(id)
        .then((data) {
          _inFlightRefresh.remove(id);
          if (isClosed) return;
          add(MiniSubCategoryBackgroundFetchSucceeded(id, data));
        })
        .catchError((_) {
          _inFlightRefresh.remove(id);
          if (isClosed) return;
          add(MiniSubCategoryBackgroundFetchFailed(id));
        });
  }

  void _onBackgroundFetchSucceeded(
    MiniSubCategoryBackgroundFetchSucceeded event,
    Emitter<MiniSubCategoryState> emit,
  ) {
    final previouslyCached = _cache[event.subCategoryId];
    final changed =
        !_sameMiniSubCategoryIds(previouslyCached, event.miniSubCategories);

    _cache[event.subCategoryId] = event.miniSubCategories;

    if (changed && _activeSubCategoryId == event.subCategoryId) {
      final loaded = MiniSubCategoryLoaded(
        miniSubCategories: event.miniSubCategories,
        expandedFolderIds: Set.from(expandedFolderIds),
      );
      _lastLoaded = loaded;
      emit(loaded);
    }
  }

  void _onBackgroundFetchFailed(
    MiniSubCategoryBackgroundFetchFailed event,
    Emitter<MiniSubCategoryState> emit,
  ) {
    // Cached data is already on screen and stays exactly as it is —
    // nothing to do here besides logging (e.g. transient offline blip
    // while silently refreshing an already-visited subcategory).
    print(
      "Background refresh failed for subcategory ${event.subCategoryId} "
      "(offline?) — keeping cached data as-is.",
    );
  }

  bool _sameMiniSubCategoryIds(
    List<MiniSubCategory>? a,
    List<MiniSubCategory> b,
  ) {
    if (a == null) return false;
    if (a.length != b.length) return false;
    final idsA = a.map((e) => e.id).toSet();
    final idsB = b.map((e) => e.id).toSet();
    return idsA.length == idsB.length && idsA.containsAll(idsB);
  }

  /// Keeps the raw ClientException/SocketException text out of the UI for
  /// the one case where we truly have nothing else to show.
  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection failed')) {
      return "You're offline. Please check your internet connection.";
    }
    return "Something went wrong loading items. Please try again.";
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

      final updated = currentState.copyWith(
        expandedFolderIds: Set.from(expandedFolderIds),
      );
      _lastLoaded = updated;
      emit(updated);
    }
  }

  void _onSelectProduct(
    SelectProduct event,
    Emitter<MiniSubCategoryState> emit,
  ) {
    print(
      "Event: SelectProduct -> ${event.product.name} (ID: ${event.product.id})",
    );
    // You can handle product selection logic here
  }
}
