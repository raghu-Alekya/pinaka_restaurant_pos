import 'create_order_entity.dart';
import 'create_order_repository.dart';

class CreateOrderUseCase {
  final CreateOrderRepository repository;

  CreateOrderUseCase({required this.repository});

  Future<CreateOrderResponseEntity> call(CreateOrderRequestEntity request) async {
    return await repository.createOrder(request);
  }
}