import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../services/kds_mqtt_service.dart';
import '../utils/kds_logger.dart';

class DebugLogPanel extends StatefulWidget {
  const DebugLogPanel({super.key});

  @override
  State<DebugLogPanel> createState() => _DebugLogPanelState();
}

class _DebugLogPanelState extends State<DebugLogPanel> {
  @override
  void initState() {
    super.initState();
    KdsDebugLog.listen(_onLogUpdate);
  }

  @override
  void dispose() {
    KdsDebugLog.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final logs = KdsDebugLog.logs;

    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff1e1e1e),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              const Text(
                'KDS Debug Log',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                'State: ${provider.connectionState.name}',
                style: TextStyle(
                  color: provider.connectionState == KdsConnectionState.connected
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  KdsDebugLog.clear();
                  setState(() {});
                },
                child: const Text('Clear', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Text(
            'Broker: ${provider.brokerHost}:${provider.brokerPort} | '
            'Topic: ${provider.subscribedTopic} | '
            'MQTT msgs: ${provider.mqttMessagesReceived} | '
            'Orders: ${provider.orders.length} | '
            'Pending: ${provider.pendingOrders.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          if (provider.connectionError != null)
            Text(
              'Error: ${provider.connectionError}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: logs.isEmpty
                ? const Text(
                    'No logs yet...',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (_, i) => Text(
                      logs[i],
                      style: TextStyle(
                        color: logs[i].contains('[ERROR]')
                            ? Colors.redAccent
                            : logs[i].contains('[WARN]')
                                ? Colors.orangeAccent
                                : Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
