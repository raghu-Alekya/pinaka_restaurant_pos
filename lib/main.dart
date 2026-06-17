import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'kitchen_display_screen.dart';
import 'providers/order_provider.dart';
import 'screens/connection_setup_screen.dart';
import 'services/api_services.dart';
import 'services/kds_mqtt_service.dart';
import 'utils/kds_logger.dart';
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

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await KdsConfig.load();

    KdsDebugLog.info(
      'Config loaded → '
          'host=${config.brokerHost}, '
          'port=${config.brokerPort}, '
          'restaurantId=${config.restaurantId}, '
          'tokenEmpty=${config.apiToken.isEmpty}',
    );

    if (config.isValid) {
      _startWithConfig(config);
    } else {
      KdsDebugLog.warn('Config invalid — showing setup screen');
      setState(() => _config = config);
    }
  }

  void _startWithConfig(KdsConfig config) {
    KdsDebugLog.info(
      'Starting with config restaurantId=${config.restaurantId}',
    );

    _orderProvider?.dispose();

    final mqttService = KdsMqttService(
      brokerHost: config.brokerHost,
      brokerPort: config.brokerPort,
      restaurantId: config.restaurantId,
    );

    final apiService = OrderApiService(
      getToken: () async =>
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3ODEwODY0NjUsIm5iZiI6MTc4MTA4NjQ2NSwiZXhwIjoxNzgzNjc4NDY1LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.uXAQqbZ1WZ_HvHNP_tA3BQ28ILdqVssmIWTOfrMr-1U',
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
    if (_orderProvider == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kitchen Dashboard',
        home: ConnectionSetupScreen(
          config: _config ??
              const KdsConfig(
                brokerHost: KdsConfig.defaultBrokerHost,
                brokerPort: KdsConfig.defaultBrokerPort,
                restaurantId: KdsConfig.defaultRestaurantId,
                apiToken: '',
              ),
          onConnected: _startWithConfig,
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _orderProvider!,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kitchen Dashboard',
        home: KitchenDashboardScreen(
          onOpenSettings: () async {
            await KdsConfig.clear();
            _orderProvider?.dispose();
            setState(() {
              _orderProvider = null;
              _config = null;
            });
            _loadConfig();
          },
        ),
      ),
    );
  }
}
