import 'package:restaurant_captain_app/features/variations/variations_domain/variation_entity.dart';
import 'package:restaurant_captain_app/features/variations/variations_domain/variation_repository.dart';


class FetchVariationsUseCase {
  final VariationRepository repository;

  FetchVariationsUseCase({required this.repository});

  Future<List<VariationEntity>> call(int productId) async {
    return await repository.getVariations(productId);
  }
}