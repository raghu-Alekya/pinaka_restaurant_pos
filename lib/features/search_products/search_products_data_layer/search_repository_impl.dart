
import 'package:restaurant_captain_app/features/search_products/search_products_data_layer/search_remote_data_source.dart';

import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../search_products_domain/search_entity.dart';
import '../search_products_domain/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<SearchResultItem>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found. Please login again.');
    }

    final captainData = await captainStorage.getCaptainData();
    final token = captainData?.data?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Captain token not found. Please login again.');
    }

    final response = await remoteDataSource.searchProducts(
      baseUrl: baseUrl,
      token: token,
      query: query,
    );

    return response.data;
  }
}