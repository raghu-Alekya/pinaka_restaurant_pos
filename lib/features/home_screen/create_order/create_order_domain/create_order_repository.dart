
import 'create_order_entity.dart';

abstract class CreateOrderRepository {
  Future<CreateOrderResponseEntity> createOrder(CreateOrderRequestEntity request);
}