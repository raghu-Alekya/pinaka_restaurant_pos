import '../entities/category_entity.dart';
import '../repositories/mini_subcategory_repository.dart';

class FetchMiniSubcategoriesUseCase {
  final MiniSubcategoryRepository repository;

  FetchMiniSubcategoriesUseCase({required this.repository});

  Future<List<MiniSubcategoryEntity>> call(int subcategoryId) async {
    return await repository.getMiniSubcategories(subcategoryId);
  }
}