import '../../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../datasources/mini_subcategory_remote_data_source.dart';
import '../entities/category_entity.dart';
import 'mini_subcategory_repository.dart';

class MiniSubcategoryRepositoryImpl implements MiniSubcategoryRepository {
  final MiniSubcategoryRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  MiniSubcategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<MiniSubcategoryEntity>> getMiniSubcategories(int subcategoryId) async {
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found.');
    }

    final captainData = await captainStorage.getCaptainData();
    if (captainData?.data?.token == null) {
      throw Exception('Captain token not found.');
    }
    final token = captainData!.data!.token!;

    final response = await remoteDataSource.getMiniSubcategories(
      baseUrl: baseUrl,
      token: token,
      subcategoryId: subcategoryId,
    );

    return response.toEntityList();
  }
}