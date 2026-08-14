import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class ProductUseCase {
  final ProductRepository repository;

  ProductUseCase({required this.repository});

  Future<List<ProductEntity>> call(int categoryId) async =>
      await repository.getProductsByCategory(categoryId);
}