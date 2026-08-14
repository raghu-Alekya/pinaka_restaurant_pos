
import 'addon_entity.dart';

abstract class AddOnRepository {
  Future<List<AddOnEntity>> getAddOnsByProduct(int productId);
}