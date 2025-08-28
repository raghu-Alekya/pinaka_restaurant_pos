import '../../models/category/minisubcategory_model.dart';

abstract class MiniSubCategoryState {}

/// Initial state
class MiniSubCategoryInitial extends MiniSubCategoryState {}

/// Loading state
class MiniSubCategoryLoading extends MiniSubCategoryState {}

/// Loaded successfully
class MiniSubCategoryLoaded extends MiniSubCategoryState {
  final List<MiniSubCategory> miniSubCategories;

  /// Track which folders are expanded
  final Set<int> expandedFolderIds;

  MiniSubCategoryLoaded({
    required this.miniSubCategories,
    this.expandedFolderIds = const {},
  });

  MiniSubCategoryLoaded copyWith({
    List<MiniSubCategory>? miniSubCategories,
    Set<int>? expandedFolderIds,
  }) {
    return MiniSubCategoryLoaded(
      miniSubCategories: miniSubCategories ?? this.miniSubCategories,
      expandedFolderIds: expandedFolderIds ?? this.expandedFolderIds,
    );
  }
}

/// Error state
class MiniSubCategoryError extends MiniSubCategoryState {
  final String message;

  MiniSubCategoryError(this.message);
}
