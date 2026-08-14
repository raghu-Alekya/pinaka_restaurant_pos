import '../../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../All_tables_list_domain/all_tables_list_entity.dart';
import '../All_tables_list_domain/all_tables_list_repository.dart';
import 'all_tables_list_remote_data_source.dart';

class AllTablesRepositoryImpl implements AllTablesRepository {
  final AllTablesRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  AllTablesRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<TableEntity>> getTables() async {
    // Retrieve stored base URL
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found. Please login as merchant first.');
    }

    // Retrieve stored token from captain login
    final captainData = await captainStorage.getCaptainData();
    if (captainData?.data?.token == null) {
      throw Exception('Captain token not found. Please login as captain first.');
    }
    final token = captainData!.data!.token!;

    final response = await remoteDataSource.getAllTables(
      baseUrl: baseUrl,
      token: token,
    );

    return response.toEntityList();
  }
}