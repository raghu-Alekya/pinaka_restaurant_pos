import 'package:restaurant_captain_app/features/variations/variations_domain/variation_entity.dart';

abstract class VariationRepository {
  Future<List<VariationEntity>> getVariations(int productId);
}