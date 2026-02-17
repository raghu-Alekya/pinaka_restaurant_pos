import 'package:flutter/material.dart';

class ViewOrderScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const ViewOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          width: 900,
          height: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "View Order",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Review the details of an order",
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT PANEL
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order ID and Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order["id"]?.toString() ?? "-",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(order["timestamp"] ?? "-",
                                        style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusColor(order["status"]?.toString()).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order["status"]?.toString() ?? "Unknown",
                                    style: TextStyle(
                                        color: _statusColor(order["status"]?.toString()),
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                            const Divider(height: 30),
                            // Order Details
                            const Text("Order Details",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 10),
                            buildDetailRow("Order ID", order["id"]?.toString() ?? "-"),
                            buildDetailRow("Timestamp", order["timestamp"] ?? "-"),
                            buildDetailRow("Price", "Rs. ${order["price"] ?? 0}/-"),
                            buildDetailRow("Payment Type", order["paymentType"] ?? "-"),
                            buildDetailRow("Order Type", order["orderType"] ?? "-"),
                            buildDetailRow("Additional Info", order["additionalInfo"] ?? "-"),
                            const SizedBox(height: 20),
                            // Customer Details
                            const Text("Customer Details",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 10),
                            buildDetailRow("Customer Name", order["customerName"] ?? "-"),
                            buildDetailRow("Contact Number", order["customerContact"] ?? "-"),
                          ],
                        ),
                      ),
                    ),
                    // RIGHT PANEL (KOT list dynamically)
                    Expanded(
                      flex: 6,
                      child: Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: ((order["kots"] as List<dynamic>?) ?? [])
                                .map((kot) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: buildKOTCard(
                                kot["kotNo"]?.toString() ?? "-",
                                kot["date"] ?? "-",
                                kot["time"] ?? "-",
                                (kot["items"] as List<dynamic>?) ?? [],
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Status color helper
  Color _statusColor(String? status) {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "processing":
        return Colors.orange;
      case "yet-to-prepare":
        return Colors.red;
      case "Declined":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper for left panel detail rows
  static Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // Helper for KOT Card
  static Widget buildKOTCard(
      String kotNo, String date, String time, List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("KOT No: $kotNo",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text("Date : .$date   $time",
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          // Table header
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Table rows
          Column(
            children: items.asMap().entries.map((entry) {
              int index = entry.key + 1;
              var item = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text("$index")),
                    Expanded(flex: 3, child: Text(item['name']?.toString() ?? "-")),
                    Expanded(flex: 2, child: Text("${item['qty'] ?? 0}x")),
                    Expanded(
                        flex: 2,
                        child: Text(
                          item['amount']?.toString() ?? "-",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}