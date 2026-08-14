import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class CategoryUseCase {
  final CategoryRepository repository;

  CategoryUseCase({required this.repository});

  Future<List<CategoryEntity>> call() async => await repository.getCategories();
}