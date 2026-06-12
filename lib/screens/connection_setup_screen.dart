import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/kds_logger.dart';
class KdsConfig {
  static const defaultBrokerHost = '178.16.140.169';
  static const defaultBrokerPort = 1883;
  static const defaultRestaurantId = '1';

  /// Old POS default — no broker here; migrate to localhost.
  static const _legacyHosts = {'178.16.140.169'};

  final String brokerHost;
  final int brokerPort;
  final String restaurantId;
  final String apiToken;

  const KdsConfig({
    required this.brokerHost,
    required this.brokerPort,
    required this.restaurantId,
    this.apiToken = '',
  });

  static String _normalizeHost(String host) {
    final trimmed = host.trim();
    if (_legacyHosts.contains(trimmed)) {
      KdsDebugLog.warn(
        'Migrating broker host $trimmed → $defaultBrokerHost (broker runs on this PC)',
      );
      return defaultBrokerHost;
    }
    return trimmed;
  }

  static Future<KdsConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final rawHost = prefs.getString('mqtt_broker_host') ?? defaultBrokerHost;
    final host = _normalizeHost(rawHost);

    final config = KdsConfig(
      brokerHost: host,
      brokerPort: prefs.getInt('mqtt_broker_port') ?? defaultBrokerPort,
      restaurantId:
          prefs.getString('restaurant_id') ?? defaultRestaurantId,
      apiToken: prefs.getString('api_token') ?? '',
    );

    // Persist migration if host was corrected
    if (rawHost != host) {
      await config.save();
    }

    return config;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_broker_host', brokerHost);
    await prefs.setInt('mqtt_broker_port', brokerPort);
    await prefs.setString('restaurant_id', restaurantId);
    await prefs.setString('api_token', apiToken);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mqtt_broker_host');
    await prefs.remove('mqtt_broker_port');
    await prefs.remove('restaurant_id');
    await prefs.remove('api_token');
    KdsDebugLog.info('Config cleared');
  }

  bool get isValid => restaurantId.isNotEmpty;
}

class ConnectionSetupScreen extends StatefulWidget {
  final KdsConfig config;
  final void Function(KdsConfig config) onConnected;

  const ConnectionSetupScreen({
    super.key,
    required this.config,
    required this.onConnected,
  });

  @override
  State<ConnectionSetupScreen> createState() => _ConnectionSetupScreenState();
}

class _ConnectionSetupScreenState extends State<ConnectionSetupScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _restaurantController;
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.config.brokerHost);
    _portController =
        TextEditingController(text: widget.config.brokerPort.toString());
    _restaurantController =
        TextEditingController(text: widget.config.restaurantId);
    _tokenController = TextEditingController(text: widget.config.apiToken);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _restaurantController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _saveAndConnect() async {
    final restaurantId = _restaurantController.text.trim();
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant ID is required')),
      );
      return;
    }

    final config = KdsConfig(
      brokerHost: _hostController.text.trim(),
      brokerPort: int.tryParse(_portController.text.trim()) ?? 1883,
      restaurantId: restaurantId,
      apiToken: _tokenController.text.trim(),
    );

    await config.save();
    KdsDebugLog.info(
      'Config saved → host=${config.brokerHost} port=${config.brokerPort} restaurantId=${config.restaurantId}',
    );
    widget.onConnected(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'KDS Connection',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use 127.0.0.1 if broker runs on this PC. Restaurant ID must match POS (e.g. 1).',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'MQTT Broker IP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _restaurantController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Token (for status updates)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  _hostController.text = KdsConfig.defaultBrokerHost;
                  _portController.text = KdsConfig.defaultBrokerPort.toString();
                  _restaurantController.text = KdsConfig.defaultRestaurantId;
                },
                child: const Text('Use localhost (127.0.0.1)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6C74B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveAndConnect,
                child: const Text(
                  'Connect to POS',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
