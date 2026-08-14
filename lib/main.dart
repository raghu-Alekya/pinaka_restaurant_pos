import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_captain_app/utils/cart_provider.dart';
import 'features/ captain_pin_login/captain_login_bloc/captain_login_bloc.dart';
import 'features/ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import 'features/ captain_pin_login/captain_login_data_layer/captain_local_storage_impl.dart';
import 'features/ captain_pin_login/captain_login_data_layer/captain_login_remote_data_source.dart';
import 'features/ captain_pin_login/captain_login_data_layer/captain_login_repository_impl.dart';
import 'features/ captain_pin_login/captain_login_domain/captain_login_repository.dart';
import 'features/ captain_pin_login/captain_login_domain/captain_login_usecase.dart';
import 'features/ captain_pin_login/captain_login_screen.dart';
import 'features/ merchant_login/merchant_login_bloc/merchant_login_bloc.dart';
import 'features/ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import 'features/ merchant_login/merchant_login_data_layer/merchant_local_storage_impl.dart';
import 'features/ merchant_login/merchant_login_data_layer/merchant_login_remote_data_source.dart';
import 'features/ merchant_login/merchant_login_data_layer/merchant_login_repository_impl.dart';
import 'features/ merchant_login/merchant_login_domain/merchant_login_repository.dart';
import 'features/ merchant_login/merchant_login_domain/merchant_login_usecase.dart';
import 'features/ merchant_login/merchant_login_screen.dart';
import 'features/addons/addons_data_layer/addon_remote_data_source.dart';
import 'features/addons/addons_data_layer/addon_repository_impl.dart';
import 'features/addons/addons_domin/addon_repository.dart';
import 'features/addons/addons_domin/fetch_addons_usecase.dart';
import 'features/bill_summary/bill_summary_bloc/bill_summary_bloc.dart';
import 'features/bill_summary/bill_summary_data_layer/bill_summary_remote_data_source.dart';
import 'features/bill_summary/bill_summary_data_layer/bill_summary_repository_impl.dart';
import 'features/bill_summary/bill_summary_domain/bill_summary_repository.dart';
import 'features/bill_summary/bill_summary_domain/bill_summary_usecase.dart';
import 'features/home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
import 'features/home_screen/All_tables_list/All_tables_list_data_layer/all_tables_list_remote_data_source.dart';
import 'features/home_screen/All_tables_list/All_tables_list_data_layer/all_tables_list_repository_impl.dart';
import 'features/home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_remote_data_source.dart';
import 'features/home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_repository_impl.dart';
import 'features/home_screen/All_tables_list/All_tables_list_domain/all_tables_list_repository.dart';
import 'features/home_screen/All_tables_list/All_tables_list_domain/all_tables_list_usecase.dart';
import 'features/home_screen/All_tables_list/All_tables_list_domain/get_order_by_table_usecase.dart';
import 'features/home_screen/All_tables_list/All_tables_list_domain/order_by_table_entity.dart';
import 'features/home_screen/Zones/Zones_bloc/zones_bloc.dart';
import 'features/home_screen/Zones/zones_data_layer/zone_remote_data_source.dart';
import 'features/home_screen/Zones/zones_data_layer/zone_repository_impl.dart';
import 'features/home_screen/Zones/zones_domain/zone_repository.dart';
import 'features/home_screen/Zones/zones_domain/zone_usecase.dart';
import 'features/home_screen/Zones/Zones_bloc/zones_bloc.dart';
import 'features/home_screen/Zones/zones_data_layer/zone_remote_data_source.dart';
import 'features/home_screen/Zones/zones_data_layer/zone_repository_impl.dart';
import 'features/home_screen/Zones/zones_domain/zone_repository.dart';
import 'features/home_screen/Zones/zones_domain/zone_usecase.dart';
import 'features/home_screen/create_order/create_order_bloc/create_order_bloc.dart';
import 'features/home_screen/create_order/create_order_data_layer/create_order_remote_data_source.dart';
import 'features/home_screen/create_order/create_order_data_layer/create_order_repository_impl.dart';
import 'features/home_screen/create_order/create_order_domain/create_order_repository.dart';
import 'features/home_screen/create_order/create_order_domain/create_order_usecase.dart';
import 'features/home_screen/TableManagement_Screen.dart';
import 'features/home_screen/order_menu/bloc/category_bloc/category_bloc.dart';
import 'features/home_screen/order_menu/datasources/category_remote_data_source.dart';
import 'features/home_screen/order_menu/datasources/mini_subcategory_remote_data_source.dart';
import 'features/home_screen/order_menu/datasources/product_remote_data_source.dart';
import 'features/home_screen/order_menu/repositories/category_repository.dart';
import 'features/home_screen/order_menu/repositories/category_repository_impl.dart';
import 'features/home_screen/order_menu/repositories/mini_subcategory_repository.dart';
import 'features/home_screen/order_menu/repositories/mini_subcategory_repository_impl.dart';
import 'features/home_screen/order_menu/repositories/product_repository.dart';
import 'features/home_screen/order_menu/repositories/product_repository_impl.dart';
import 'features/home_screen/order_menu/usecases/category_usecase.dart';
import 'features/home_screen/order_menu/usecases/mini_subcategory_usecase.dart';
import 'features/home_screen/order_menu/usecases/product_usecase.dart';
import 'features/kots_list/kots_list_bloc/kots_list_bloc.dart';
import 'features/kots_list/kots_list_data_layer/kots_list_remote_data_source.dart';
import 'features/kots_list/kots_list_data_layer/kots_list_repository_impl.dart';
import 'features/kots_list/kots_list_domin/kots_list_repository.dart';
import 'features/kots_list/kots_list_domin/kots_list_usecase.dart';
import 'features/search_products/search_products_bloc/search_bloc.dart';
import 'features/search_products/search_products_data_layer/search_remote_data_source.dart';
import 'features/search_products/search_products_data_layer/search_repository_impl.dart';
import 'features/search_products/search_products_domain/search_repository.dart';
import 'features/search_products/search_products_domain/search_usecase.dart';
import 'features/variations/variations_data_layer/variation_remote_data_source.dart';
import 'features/variations/variations_data_layer/variation_repository_impl.dart';
import 'features/variations/variations_domain/fetch_variations_usecase.dart';
import 'features/variations/variations_domain/variation_repository.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Local Storage
        Provider<MerchantLocalStorage>(
          create: (_) => MerchantLocalStorageImpl(),
        ),
        Provider<CaptainLocalStorage>(
          create: (_) => CaptainLocalStorageImpl(),
        ),
        // Remote Data Sources
        Provider<MerchantLoginRemoteDataSource>(
          create: (_) => MerchantLoginRemoteDataSourceImpl(),
        ),
        Provider<CaptainLoginRemoteDataSource>(
          create: (_) => CaptainLoginRemoteDataSourceImpl(),
        ),
        Provider<ZoneRemoteDataSource>(
          create: (_) => ZoneRemoteDataSourceImpl(),
        ),
        // Repositories
        Provider<MerchantLoginRepository>(
          create: (context) => MerchantLoginRepositoryImpl(
            remoteDataSource: context.read<MerchantLoginRemoteDataSource>(),
            localStorage: context.read<MerchantLocalStorage>(),
          ),
        ),
        Provider<CaptainLoginRepository>(
          create: (context) => CaptainLoginRepositoryImpl(
            remoteDataSource: context.read<CaptainLoginRemoteDataSource>(),
            merchantLocalStorage: context.read<MerchantLocalStorage>(),
            captainLocalStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<ZoneRepository>(
          create: (context) => ZoneRepositoryImpl(
            remoteDataSource: context.read<ZoneRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        // UseCases
        Provider<MerchantLoginUseCase>(
          create: (context) => MerchantLoginUseCase(
            repository: context.read<MerchantLoginRepository>(),
          ),
        ),
        Provider<CaptainLoginUseCase>(
          create: (context) => CaptainLoginUseCase(
            repository: context.read<CaptainLoginRepository>(),
          ),
        ),
        Provider<ZoneUseCase>(
          create: (context) => ZoneUseCase(
            repository: context.read<ZoneRepository>(),
          ),
        ),
        // BLoCs
        BlocProvider<MerchantLoginBloc>(
          create: (context) => MerchantLoginBloc(
            loginUseCase: context.read<MerchantLoginUseCase>(),
          ),
        ),
        BlocProvider<CaptainLoginBloc>(
          create: (context) => CaptainLoginBloc(
            loginUseCase: context.read<CaptainLoginUseCase>(),
          ),
        ),
        BlocProvider<ZoneBloc>(
          create: (context) => ZoneBloc(
            useCase: context.read<ZoneUseCase>(),
          ),
        ),


        // All Tables Remote Data Source
        Provider<AllTablesRemoteDataSource>(
          create: (_) => AllTablesRemoteDataSourceImpl(),
        ),
// All Tables Repository
        Provider<AllTablesRepository>(
          create: (context) => AllTablesRepositoryImpl(
            remoteDataSource: context.read<AllTablesRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
// All Tables UseCase
        Provider<AllTablesUseCase>(
          create: (context) => AllTablesUseCase(
            repository: context.read<AllTablesRepository>(),
          ),
        ),
// All Tables BLoC
        BlocProvider<AllTablesBloc>(
          create: (context) => AllTablesBloc(
            useCase: context.read<AllTablesUseCase>(),
          ),
        ),

        Provider<CreateOrderRemoteDataSource>(
          create: (_) => CreateOrderRemoteDataSourceImpl(),
        ),
// Create Order Repository
        Provider<CreateOrderRepository>(
          create: (context) => CreateOrderRepositoryImpl(
            remoteDataSource: context.read<CreateOrderRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
// Create Order UseCase
        Provider<CreateOrderUseCase>(
          create: (context) => CreateOrderUseCase(
            repository: context.read<CreateOrderRepository>(),
          ),
        ),
// Create Order BLoC
        BlocProvider<CreateOrderBloc>(
          create: (context) => CreateOrderBloc(
            useCase: context.read<CreateOrderUseCase>(),
          ),
        ),

        ////====

        // Category & Product Remote Data Sources
        Provider<CategoryRemoteDataSource>(
          create: (_) => CategoryRemoteDataSourceImpl(),
        ),
        Provider<ProductRemoteDataSource>(
          create: (_) => ProductRemoteDataSourceImpl(),
        ),
// Repositories
        Provider<CategoryRepository>(
          create: (context) => CategoryRepositoryImpl(
            remoteDataSource: context.read<CategoryRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<ProductRepository>(
          create: (context) => ProductRepositoryImpl(
            remoteDataSource: context.read<ProductRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
// UseCases
        Provider<CategoryUseCase>(
          create: (context) => CategoryUseCase(
            repository: context.read<CategoryRepository>(),
          ),
        ),
        Provider<ProductUseCase>(
          create: (context) => ProductUseCase(
            repository: context.read<ProductRepository>(),
          ),
        ),
        Provider<MiniSubcategoryRemoteDataSource>(
          create: (_) => MiniSubcategoryRemoteDataSourceImpl(),
        ),
        Provider<MiniSubcategoryRepository>(
          create: (context) => MiniSubcategoryRepositoryImpl(
            remoteDataSource: context.read<MiniSubcategoryRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<FetchMiniSubcategoriesUseCase>(
          create: (context) => FetchMiniSubcategoriesUseCase(
            repository: context.read<MiniSubcategoryRepository>(),
          ),
        ),
// BLoC
        BlocProvider<CategoryBloc>(
          create: (context) => CategoryBloc(
            categoryUseCase: context.read<CategoryUseCase>(),
            productUseCase: context.read<ProductUseCase>(),
            miniSubcategoryUseCase: context.read<FetchMiniSubcategoriesUseCase>(), // <-- Add
          ),
        ),

        Provider<OrderByTableRemoteDataSource>(
          create: (_) => OrderByTableRemoteDataSourceImpl(),
        ),
        Provider<OrderByTableRepository>(
          create: (context) => OrderByTableRepositoryImpl(
            remoteDataSource: context.read<OrderByTableRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<GetOrderByTableUseCase>(
          create: (context) => GetOrderByTableUseCase(
            repository: context.read<OrderByTableRepository>(),
          ),
        ),

        Provider<KotsListRemoteDataSource>(
          create: (_) => KotsListRemoteDataSourceImpl(),
        ),
        Provider<KotsListRepository>(
          create: (context) => KotsListRepositoryImpl(
            remoteDataSource: context.read<KotsListRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<KotsListUseCase>(
          create: (context) => KotsListUseCase(
            repository: context.read<KotsListRepository>(),
          ),
        ),
        BlocProvider<KotsListBloc>(
          create: (context) => KotsListBloc(
            useCase: context.read<KotsListUseCase>(),
          ),
        ),

        // Inside providers list:
        Provider<BillSummaryRemoteDataSource>(
          create: (_) => BillSummaryRemoteDataSourceImpl(),
        ),
        Provider<BillSummaryRepository>(
          create: (context) => BillSummaryRepositoryImpl(
            remoteDataSource: context.read<BillSummaryRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<BillSummaryUseCase>(
          create: (context) => BillSummaryUseCase(
            repository: context.read<BillSummaryRepository>(),
          ),
        ),
        BlocProvider<BillSummaryBloc>(
          create: (context) => BillSummaryBloc(
            useCase: context.read<BillSummaryUseCase>(),
          ),
        ),

        Provider<SearchRemoteDataSource>(
          create: (_) => SearchRemoteDataSourceImpl(),
        ),
        Provider<SearchRepository>(
          create: (context) => SearchRepositoryImpl(
            remoteDataSource: context.read<SearchRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<SearchUseCase>(
          create: (context) => SearchUseCase(
            repository: context.read<SearchRepository>(),
          ),
        ),
        BlocProvider<SearchBloc>(
          create: (context) => SearchBloc(
            useCase: context.read<SearchUseCase>(),
          ),
        ),

        Provider<AddOnRemoteDataSource>(
          create: (_) => AddOnRemoteDataSourceImpl(),
        ),
        Provider<AddOnRepository>(
          create: (context) => AddOnRepositoryImpl(
            remoteDataSource: context.read<AddOnRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<FetchAddOnsUseCase>(
          create: (context) => FetchAddOnsUseCase(
            repository: context.read<AddOnRepository>(),
          ),
        ),

        Provider<VariationRemoteDataSource>(
          create: (_) => VariationRemoteDataSourceImpl(),
        ),
        Provider<VariationRepository>(
          create: (context) => VariationRepositoryImpl(
            remoteDataSource: context.read<VariationRemoteDataSource>(),
            merchantStorage: context.read<MerchantLocalStorage>(),
            captainStorage: context.read<CaptainLocalStorage>(),
          ),
        ),
        Provider<FetchVariationsUseCase>(
          create: (context) => FetchVariationsUseCase(
            repository: context.read<VariationRepository>(),
          ),
        ),

        ChangeNotifierProvider(create: (_) => CartProvider()), // <-- global cart

      ],
      child: MaterialApp(
        title: 'Merchant App',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthCheck(),
      ),
    );
  }
}

/// Checks stored login status and routes accordingly.
class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final merchantStorage = context.read<MerchantLocalStorage>();
    final captainStorage = context.read<CaptainLocalStorage>();

    final merchantData = await merchantStorage.getMerchantData();
    final isMerchantLoggedIn = merchantData != null && merchantData.success;

    final captainData = await captainStorage.getCaptainData();
    final isCaptainLoggedIn =
        isMerchantLoggedIn && captainData != null && captainData.success;

    Widget nextScreen;
    if (isCaptainLoggedIn) {
      nextScreen = const TableManagementScreen();
    } else if (isMerchantLoggedIn) {
      nextScreen = const CaptainLoginScreen();
    } else {
      nextScreen = const MerchantLoginScreen();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while checking
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}