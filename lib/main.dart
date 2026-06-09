import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'kitchen_display_screen.dart';
import 'providers/order_provider.dart';
import 'screens/connection_setup_screen.dart';
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
      'Config loaded → host=${config.brokerHost} port=${config.brokerPort} restaurantId=${config.restaurantId}',
    );
    if (config.isValid) {
      _startWithConfig(config);
    } else {
      KdsDebugLog.warn('Config invalid — showing setup screen');
      setState(() => _config = config);
    }
  }

  void _startWithConfig(KdsConfig config) {
    KdsDebugLog.info('Starting with config restaurantId=${config.restaurantId}');
    _orderProvider?.dispose();
    final mqttService = KdsMqttService(
      brokerHost: config.brokerHost,
      brokerPort: config.brokerPort,
      restaurantId: config.restaurantId,
    );
    setState(() {
      _config = config;
      _orderProvider = OrderProvider(mqttService);
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
          config: _config ?? const KdsConfig(
            brokerHost: KdsConfig.defaultBrokerHost,
            brokerPort: KdsConfig.defaultBrokerPort,
            restaurantId: KdsConfig.defaultRestaurantId,
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
