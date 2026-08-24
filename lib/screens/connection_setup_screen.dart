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

  // Existing restaurant ID
  final String restaurantId;

  // Store ID obtained from merchant login
  final String storeId;

  final String apiToken;

  const KdsConfig({
    required this.brokerHost,
    required this.brokerPort,
    required this.restaurantId,
    required this.storeId,
    this.apiToken = '',
  });

  // ==========================================================
  // NORMALIZE BROKER HOST
  // ==========================================================

  static String _normalizeHost(String host) {
    final trimmed = host.trim();

    if (_legacyHosts.contains(trimmed)) {
      KdsDebugLog.warn(
        'Migrating broker host $trimmed → $defaultBrokerHost '
            '(broker runs on this PC)',
      );

      return defaultBrokerHost;
    }

    return trimmed;
  }

  // ==========================================================
  // LOAD CONFIG
  // ==========================================================

  static Future<KdsConfig> load() async {
    final prefs = await SharedPreferences.getInstance();

    // ----------------------------------------------------------
    // RESTAURANT ID
    // ----------------------------------------------------------

    String restaurantId = defaultRestaurantId;

    final rawRestaurantId = prefs.get('restaurant_id');

    if (rawRestaurantId != null) {
      restaurantId = rawRestaurantId.toString().trim();
    }

    // ----------------------------------------------------------
    // STORE ID
    // ----------------------------------------------------------
    // This must be saved during merchant login.
    // ----------------------------------------------------------

    final storeId =
        prefs.getString('store_id')?.trim() ?? '';

    // ----------------------------------------------------------
    // MQTT HOST
    // ----------------------------------------------------------

    final host = _normalizeHost(
      prefs.getString('mqtt_broker_host') ??
          defaultBrokerHost,
    );

    // ----------------------------------------------------------
    // CREATE CONFIG
    // ----------------------------------------------------------

    final config = KdsConfig(
      brokerHost: host,

      brokerPort:
      prefs.getInt('mqtt_broker_port') ??
          defaultBrokerPort,

      restaurantId: restaurantId,

      storeId: storeId,

      apiToken:
      prefs.getString('api_token') ??
          prefs.getString('token') ??
          '',
    );

    return config;
  }

  // ==========================================================
  // SAVE CONFIG
  // ==========================================================

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    print("Saving API Token: '$apiToken'");
    print("Saving Restaurant ID: '$restaurantId'");
    print("Saving Store ID: '$storeId'");

    // MQTT host
    await prefs.setString(
      'mqtt_broker_host',
      brokerHost,
    );

    // MQTT port
    await prefs.setInt(
      'mqtt_broker_port',
      brokerPort,
    );

    // Existing restaurant ID
    await prefs.setString(
      'restaurant_id',
      restaurantId,
    );

    // Store ID from merchant login
    await prefs.setString(
      'store_id',
      storeId,
    );

    // API token
    await prefs.setString(
      'api_token',
      apiToken,
    );
  }

  // ==========================================================
  // CLEAR CONFIG
  // ==========================================================

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('mqtt_broker_host');
    await prefs.remove('mqtt_broker_port');

    await prefs.remove('restaurant_id');

    await prefs.remove('store_id');

    await prefs.remove('api_token');

    KdsDebugLog.info('Config cleared');
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  bool get isValid {
    final validRestaurant =
        restaurantId.isNotEmpty &&
            restaurantId != '0';

    final validStore =
        storeId.isNotEmpty &&
            storeId != '0';

    return validRestaurant && validStore;
  }
}

// ============================================================
// CONNECTION SETUP SCREEN
// ============================================================

class ConnectionSetupScreen extends StatefulWidget {
  final KdsConfig config;

  final void Function(KdsConfig config) onConnected;

  const ConnectionSetupScreen({
    super.key,
    required this.config,
    required this.onConnected,
  });

  @override
  State<ConnectionSetupScreen> createState() =>
      _ConnectionSetupScreenState();
}

class _ConnectionSetupScreenState
    extends State<ConnectionSetupScreen> {

  late final TextEditingController _hostController;

  late final TextEditingController _portController;

  late final TextEditingController _restaurantController;

  late final TextEditingController _storeController;

  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();

    // --------------------------------------------------------
    // HOST
    // --------------------------------------------------------

    _hostController = TextEditingController(
      text: widget.config.brokerHost,
    );

    // --------------------------------------------------------
    // PORT
    // --------------------------------------------------------

    _portController = TextEditingController(
      text: widget.config.brokerPort.toString(),
    );

    // --------------------------------------------------------
    // RESTAURANT ID
    // --------------------------------------------------------

    _restaurantController =
        TextEditingController(
          text: widget.config.restaurantId,
        );

    // --------------------------------------------------------
    // STORE ID
    // --------------------------------------------------------
    // Automatically populated from merchant login.
    // --------------------------------------------------------

    _storeController =
        TextEditingController(
          text: widget.config.storeId,
        );

    // --------------------------------------------------------
    // TOKEN
    // --------------------------------------------------------

    _tokenController = TextEditingController(
      text: widget.config.apiToken,
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _restaurantController.dispose();
    _storeController.dispose();
    _tokenController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SAVE AND CONNECT
  // ==========================================================

  Future<void> _saveAndConnect() async {
    final restaurantId =
    _restaurantController.text.trim();

    final storeId =
    _storeController.text.trim();

    final brokerHost =
    _hostController.text.trim();
    final brokerPort =
        int.tryParse(
          _portController.text.trim(),
        ) ??
            KdsConfig.defaultBrokerPort;
    final apiToken =
    _tokenController.text.trim();

    // --------------------------------------------------------
    // RESTAURANT ID VALIDATION
    // --------------------------------------------------------

    if (restaurantId.isEmpty ||
        restaurantId == '0') {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Restaurant ID is required',
          ),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // STORE ID VALIDATION
    // --------------------------------------------------------

    if (storeId.isEmpty ||
        storeId == '0') {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Store ID not found. Please login again.',
          ),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // CREATE CONFIG
    // --------------------------------------------------------

    final config = KdsConfig(
      brokerHost: brokerHost,

      brokerPort: brokerPort,

      restaurantId: restaurantId,

      storeId: storeId,

      apiToken: apiToken,
    );

    // --------------------------------------------------------
    // SAVE
    // --------------------------------------------------------

    await config.save();

    // --------------------------------------------------------
    // DEBUG
    // --------------------------------------------------------

    KdsDebugLog.info(
      'Config saved → '
          'host=${config.brokerHost} '
          'port=${config.brokerPort} '
          'restaurantId=${config.restaurantId} '
          'storeId=${config.storeId}',
    );

    // --------------------------------------------------------
    // CONNECT
    // --------------------------------------------------------

    widget.onConnected(config);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF4F4F4),

      body: Center(
        child: Container(
          width: 420,

          padding:
          const EdgeInsets.all(28),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
            BorderRadius.circular(16),

            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
              ),
            ],
          ),

          child: Column(
            mainAxisSize:
            MainAxisSize.min,

            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'KDS Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Store ID is automatically taken '
                    'from merchant login.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // MQTT HOST
              // ==================================================

              TextField(
                controller:
                _hostController,

                decoration:
                const InputDecoration(
                  labelText:
                  'MQTT Broker IP',

                  border:
                  OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // PORT
              // ==================================================

              TextField(
                controller:
                _portController,

                keyboardType:
                TextInputType.number,

                decoration:
                const InputDecoration(
                  labelText: 'Port',

                  border:
                  OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RESTAURANT ID
              // ==================================================

              TextField(
                controller:
                _restaurantController,

                decoration:
                const InputDecoration(
                  labelText:
                  'Restaurant ID',

                  border:
                  OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // STORE ID
              // ==================================================
              // Read-only because it comes from merchant login.
              // ==================================================

              TextField(
                controller:
                _storeController,

                readOnly: true,

                decoration:
                const InputDecoration(
                  labelText:
                  'Store ID',

                  border:
                  OutlineInputBorder(),

                  suffixIcon:
                  Icon(
                    Icons.lock_outline,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // API TOKEN
              // ==================================================

              TextField(
                controller:
                _tokenController,

                obscureText: true,

                decoration:
                const InputDecoration(
                  labelText:
                  'API Token',

                  border:
                  OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // CONNECT BUTTON
              // ==================================================

              ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(
                    0xff6C74B8,
                  ),

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),

                onPressed:
                _saveAndConnect,

                child:
                const Text(
                  'Connect to POS',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}