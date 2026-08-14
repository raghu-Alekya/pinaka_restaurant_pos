import 'addon_entity.dart';
import 'addon_repository.dart';

class FetchAddOnsUseCase {
  final AddOnRepository repository;

  FetchAddOnsUseCase({required this.repository});

  Future<List<AddOnEntity>> call(int productId) async {
    return await repository.getAddOnsByProduct(productId);
  }
}