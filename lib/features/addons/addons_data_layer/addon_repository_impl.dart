import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../addons_domin/addon_entity.dart';
import '../addons_domin/addon_repository.dart';
import 'addon_remote_data_source.dart';

class AddOnRepositoryImpl implements AddOnRepository {
  final AddOnRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  AddOnRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<AddOnEntity>> getAddOnsByProduct(int productId) async {
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found.');
    }

    final captainData = await captainStorage.getCaptainData();
    final token = captainData?.data?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Captain token not found.');
    }

    final response = await remoteDataSource.getAddOnsByProduct(
      baseUrl: baseUrl,
      token: token,
      productId: productId,
    );

    return response.data.map((e) => e.toEntity()).toList();
  }
}