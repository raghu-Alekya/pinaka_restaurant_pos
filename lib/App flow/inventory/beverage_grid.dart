import 'package:flutter/material.dart';
import '../../models/inventory/bev_model.dart';
import 'manage_stock.dart';
// import '../../models/inventory/bevmodel.dart';
// import 'manage_stock_inventory.dart';

class BeverageGrid extends StatelessWidget {
  final List<Products> beverages;

  const BeverageGrid({
    Key? key,
    required this.beverages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (beverages.isEmpty) {
      return const Center(
        child: Text(
          'No beverages found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: beverages.length,
      itemBuilder: (context, index) {
        return BeverageCard(beverage: beverages[index]);
      },
    );
  }
}

class BeverageCard extends StatelessWidget {
  final Products beverage;

  const BeverageCard({
    Key? key,
    required this.beverage,
  }) : super(key: key);


  Color _getStatusColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
  @override
  Widget build(BuildContext context) {
    final status = beverage.statusLabel ?? 'In Stock';
    final statusColor = _getStatusColor(status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ManageStockDialog(beverage: beverage),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            // STATUS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // IMAGE
            (beverage.image?.isNotEmpty ?? false)
                ? Image.network(
              beverage.image!,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 60),
            )
                : const Icon(Icons.broken_image, size: 60),

            const SizedBox(height: 8),

            // NAME
            Text(
              beverage.itemName ?? 'Unnamed',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 6),

            // THRESHOLD
            Text(
              'Threshold: ${beverage.threshold ?? 0}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),

            // REMAINING
            Text(
              'Remaining: ${beverage.remaining ?? 0}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

}