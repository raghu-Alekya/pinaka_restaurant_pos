import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';

import '../bill_summary_domain/bill_summary_entity.dart';
import '../bill_summary_domain/bill_summary_repository.dart';
import 'bill_summary_remote_data_source.dart';

class BillSummaryRepositoryImpl implements BillSummaryRepository {
  final BillSummaryRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  BillSummaryRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<BillSummaryEntity> getBillSummary({
    required int orderId,
    required int restaurantId,
    required String orderType,
    required int zoneId,
  }) async {
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found.');
    }

    final captainData = await captainStorage.getCaptainData();
    final token = captainData?.data?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Captain token not found.');
    }

    final response = await remoteDataSource.getBillSummary(
      baseUrl: baseUrl,
      token: token,
      orderId: orderId,
      restaurantId: restaurantId,
      orderType: orderType,
      zoneId: zoneId,
    );

    return response.toEntity();
  }
}