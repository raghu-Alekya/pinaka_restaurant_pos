import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
// import '../models/category/items_model.dart';

abstract class MiniSubCategoryEvent {}

/// Fetch mini-subcategories for a given subcategory ID
class FetchMiniSubCategories extends MiniSubCategoryEvent {
  final int subCategoryId;

  FetchMiniSubCategories( {required this.subCategoryId});
}

/// ⚠️ IMPORTANT: This no longer clears the in-memory cache — it only
/// resets transient UI state (which folders are expanded). Cache used to
/// be wiped here, which meant every sidebar category tap threw away
/// perfectly good, previously-loaded data (including data you'd want
/// while offline). Use [ClearMiniSubCategoryCache] for a true full reset
/// (e.g. on logout).
class ResetMiniSubCategory extends MiniSubCategoryEvent {}

/// Fully clears the mini-subcategory cache. Only dispatch this on logout /
/// switching accounts / starting a brand-new session — NOT on every
/// category tap.
class ClearMiniSubCategoryCache extends MiniSubCategoryEvent {}

/// Toggle expand/collapse of a folder
class ToggleFolder extends MiniSubCategoryEvent {
  final int miniSubCategoryId;

  ToggleFolder(this.miniSubCategoryId);
}

/// (Optional) Select a product
class SelectProduct extends MiniSubCategoryEvent {
  final Product product;

  SelectProduct(this.product);
}

/// Internal: fired when a silent background refresh succeeds. Not meant
/// to be dispatched from UI code.
class MiniSubCategoryBackgroundFetchSucceeded extends MiniSubCategoryEvent {
  final int subCategoryId;
  final List<MiniSubCategory> miniSubCategories;

  MiniSubCategoryBackgroundFetchSucceeded(
      this.subCategoryId, this.miniSubCategories);
}

/// Internal: fired when a silent background refresh fails (e.g. offline).
/// Not meant to be dispatched from UI code.
class MiniSubCategoryBackgroundFetchFailed extends MiniSubCategoryEvent {
  final int subCategoryId;

  MiniSubCategoryBackgroundFetchFailed(this.subCategoryId);
}