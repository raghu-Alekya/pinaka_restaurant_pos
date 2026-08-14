
import 'package:restaurant_captain_app/features/home_screen/order_menu/repositories/product_repository.dart';

import '../../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../datasources/product_remote_data_source.dart';
import '../entities/product_entity.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<ProductEntity>> getProductsByCategory(int categoryId) async {
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found.');
    }

    final captainData = await captainStorage.getCaptainData();
    if (captainData?.data?.token == null) {
      throw Exception('Captain token not found.');
    }
    final token = captainData!.data!.token!;

    final products = await remoteDataSource.getProductsByCategory(
      baseUrl: baseUrl,
      token: token,
      categoryId: categoryId,
    );

    return products.map((e) => e.toEntity()).toList();
  }
}