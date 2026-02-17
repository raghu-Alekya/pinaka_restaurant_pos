import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
// import '../models/category/items_model.dart';

abstract class MiniSubCategoryEvent {}

/// Fetch mini-subcategories for a given subcategory ID
class FetchMiniSubCategories extends MiniSubCategoryEvent {
  final int subCategoryId;

  FetchMiniSubCategories( {required this.subCategoryId});
}
class ResetMiniSubCategory extends MiniSubCategoryEvent {}


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
