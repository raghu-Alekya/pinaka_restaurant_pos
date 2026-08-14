

import '../../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../create_order_domain/create_order_entity.dart';
import '../create_order_domain/create_order_repository.dart';
import 'create_order_model.dart';
import 'create_order_remote_data_source.dart';

class CreateOrderRepositoryImpl implements CreateOrderRepository {
  final CreateOrderRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  CreateOrderRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<CreateOrderResponseEntity> createOrder(CreateOrderRequestEntity request) async {
    // Retrieve base URL
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found. Please login as merchant first.');
    }

    // Retrieve token
    final captainData = await captainStorage.getCaptainData();
    if (captainData?.data?.token == null) {
      throw Exception('Captain token not found. Please login as captain first.');
    }
    final token = captainData!.data!.token!;

    // Convert entity to request model
    final requestModel = CreateOrderRequest(
      flagType: request.flagType,
      tableId: request.tableId,
      tableName: request.tableName,
      zoneId: request.zoneId,
      zoneName: request.zoneName,
      restaurantId: request.restaurantId,
      restaurantName: request.restaurantName,
      guestCount: request.guestCount,
      guestDetails: request.guestDetails.map((e) => GuestDetail(guestCount: e.guestCount)).toList(),
      reservationId: request.reservationId,
      orderDatetime: request.orderDatetime,
    );

    final response = await remoteDataSource.createOrder(
      baseUrl: baseUrl,
      token: token,
      request: requestModel,
    );

    return response.toEntity();
  }
}