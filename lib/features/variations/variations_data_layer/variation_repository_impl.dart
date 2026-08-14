
import 'package:restaurant_captain_app/features/variations/variations_data_layer/variation_remote_data_source.dart';

import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../variations_domain/variation_entity.dart';
import '../variations_domain/variation_repository.dart';

class VariationRepositoryImpl implements VariationRepository {
  final VariationRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  VariationRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<VariationEntity>> getVariations(int productId) async {
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found.');
    }

    final captainData = await captainStorage.getCaptainData();
    final token = captainData?.data?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Captain token not found.');
    }

    final response = await remoteDataSource.getVariations(
      baseUrl: baseUrl,
      token: token,
      productId: productId,
    );

    return response.variations.map((e) => e.toEntity()).toList();
  }
}