import 'package:flutter/material.dart';
import 'package:kds_app/services/kds_mqtt_service.dart';
import '../providers/order_provider.dart';

class TopBarWidget extends StatelessWidget {
  final OrderProvider orderProvider;

  const TopBarWidget({
    super.key,
    required this.orderProvider,
  });

  Widget _connectionBadge(OrderProvider provider) {
    Color color;

    switch (provider.connectionState) {
      case KdsConnectionState.connected:
        color = Colors.green;
        break;
      case KdsConnectionState.connecting:
        color = Colors.orange;
        break;
      case KdsConnectionState.disconnected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: color,
          ),
          const SizedBox(width: 6),
          Text(
            provider.connectionState.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            "PINAKA",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),

          _connectionBadge(orderProvider),

          if (orderProvider.connectionState !=
              KdsConnectionState.connected)
            TextButton(
              onPressed: () => orderProvider.reconnect(),
              child: const Text('Reconnect'),
            ),

          const Spacer(),

          const CircleAvatar(
            radius: 20,
            child: Icon(Icons.person),
          ),

          const SizedBox(width: 10),

          const Text(
            "Madhuri Thota",
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}