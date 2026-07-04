import 'package:flutter/material.dart';
import 'package:kds_app/widgets/mercahant%20validation%20screen.dart';
import 'package:kds_app/widgets/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'kitchen_display_screen.dart';
import 'providers/order_provider.dart';
import 'screens/connection_setup_screen.dart';
import 'services/api_services.dart';
import 'services/kds_mqtt_service.dart';
import 'utils/kds_logger.dart';
import 'utils/AppConstant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  KdsConfig? _config;
  OrderProvider? _orderProvider;
  String? _storeBaseUrl;
  String? _storeName;
  String? _storeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMerchantStatus();
  }

  Future<void> _checkMerchantStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('store_base_url');
      final name = prefs.getString('store_name');
      final id = prefs.getString('store_id');

      if (baseUrl != null && baseUrl.isNotEmpty) {
        AppConstants.updateBaseUrl(baseUrl);
      }

      final config = await KdsConfig.load();

      if (mounted) {
        setState(() {
          _storeBaseUrl = baseUrl;
          _storeName = name;
          _storeId = id;
          _isLoading = false;
        });
      }

      if (config.isValid && config.apiToken.isNotEmpty) {
        _startWithConfig(config);
      }
    } catch (e) {
      KdsDebugLog.error("Error checking merchant status: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startWithConfig(KdsConfig config) {
    final mqttService = KdsMqttService(
      brokerHost: config.brokerHost,
      brokerPort: config.brokerPort,
      restaurantId: config.restaurantId,
    );

    final apiService = OrderApiService(
      getToken: () async => config.apiToken,
      restaurantId: int.tryParse(config.restaurantId) ?? 1,
    );

    final provider = OrderProvider(
      mqttService,
      apiService,
    );

    setState(() {
      _config = config;
      _orderProvider = provider;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _orderProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xff2F4376),
            ),
          ),
        ),
      );
    }

    if (_orderProvider == null) {
      if (_storeBaseUrl != null && _storeBaseUrl!.isNotEmpty) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kitchen Dashboard',
          home: EmployeeLoginScreen(
            onLoginSuccess: (config) {
              _startWithConfig(config);
            },
            storeBaseUrl: _storeBaseUrl!,
            storeName: _storeName ?? '',
            storeId: _storeId ?? '',
          ),
        );
      }

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kitchen Dashboard',
        home: MerchantOnboardingScreen(
          onLoginSuccess: (config) {
            _checkMerchantStatus();
            _startWithConfig(config);
          },
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _orderProvider!,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kitchen Dashboard',
        home: KitchenDashboardScreen(
          token: _config!.apiToken,
          restaurantId: int.tryParse(_config!.restaurantId) ?? 1,
          onOpenSettings: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            await prefs.remove('api_token');
            await prefs.remove('restaurant_id');

            _orderProvider?.dispose();

            setState(() {
              _orderProvider = null;
              _config = null;
            });

            _checkMerchantStatus();
          },
        ),
      ),
    );
  }
}
