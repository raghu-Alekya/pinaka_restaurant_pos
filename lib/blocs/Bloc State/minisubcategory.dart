import '../../models/category/minisubcategory_model.dart';

abstract class MiniSubCategoryState {}

/// Initial state
class MiniSubCategoryInitial extends MiniSubCategoryState {}

/// Loading state — only ever used for the very first fetch of a session,
/// when there is truly nothing previously loaded to keep showing.
class MiniSubCategoryLoading extends MiniSubCategoryState {}

/// Loaded successfully
class MiniSubCategoryLoaded extends MiniSubCategoryState {
  final List<MiniSubCategory> miniSubCategories;

  /// Track which folders are expanded
  final Set<int> expandedFolderIds;

  /// True while a newer subcategory (or a background refresh of this one)
  /// is being fetched. The data above is still the last-known-good data —
  /// UI can optionally show a subtle, non-blocking indicator for this,
  /// but should keep rendering [miniSubCategories] as-is.
  final bool isRefreshing;

  /// True when the most recent fetch attempt failed (e.g. offline) and
  /// we're falling back to showing the last-known-good [miniSubCategories]
  /// instead of wiping the screen with an error.
  final bool isOffline;

  MiniSubCategoryLoaded({
    required this.miniSubCategories,
    this.expandedFolderIds = const {},
    this.isRefreshing = false,
    this.isOffline = false,
  });

  MiniSubCategoryLoaded copyWith({
    List<MiniSubCategory>? miniSubCategories,
    Set<int>? expandedFolderIds,
    bool? isRefreshing,
    bool? isOffline,
  }) {
    return MiniSubCategoryLoaded(
      miniSubCategories: miniSubCategories ?? this.miniSubCategories,
      expandedFolderIds: expandedFolderIds ?? this.expandedFolderIds,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

/// Error state — only ever emitted when there is NO previous data at all
/// to fall back on (true first load of the session, with no connectivity).
class MiniSubCategoryError extends MiniSubCategoryState {
  final String message;

  MiniSubCategoryError(this.message);
}