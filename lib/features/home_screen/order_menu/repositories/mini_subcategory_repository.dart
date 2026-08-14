import '../entities/category_entity.dart';

abstract class MiniSubcategoryRepository {
  Future<List<MiniSubcategoryEntity>> getMiniSubcategories(int subcategoryId);
}