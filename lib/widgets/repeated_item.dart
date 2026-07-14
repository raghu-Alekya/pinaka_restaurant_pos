import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';

class RepeatedItem {
  final String name;
  final int count;
  final bool veg;
  final Color borderColor;

  const RepeatedItem({
    required this.name,
    required this.count,
    required this.veg,
    required this.borderColor,
  });
}

class RepeatedItemsScreen extends StatefulWidget {
  final String token;
  final int restaurantId;
  final bool isEmbedded;

  const RepeatedItemsScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    this.isEmbedded = false,
  });

  @override
  State<RepeatedItemsScreen> createState() => _RepeatedItemsScreenState();
}

class _RepeatedItemsScreenState extends State<RepeatedItemsScreen> {
  bool isLoading = true;
  String lastUpdated = "";

  @override
  void initState() {
    super.initState();
    lastUpdated = DateFormat('hh:mm a').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadRepeatedItems();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadRepeatedItems() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      await context.read<OrderProvider>().loadExistingOrders();
      if (!mounted) return;
      setState(() {
        lastUpdated = DateFormat('hh:mm a').format(DateTime.now());
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final summaryOrders = orderProvider.orders.where((o) {
      return o.status == 'Preparing';
    });

    final Map<String, int> nameToCount = {};
    final Map<String, bool> nameToVeg = {};

    for (final order in summaryOrders) {
      for (final item in order.items) {
        final itemStatus = item.status.toLowerCase();
        if (itemStatus == 'cancelled' || itemStatus == 'cancel') {
          continue;
        }

        final name = item.name;
        nameToCount[name] = (nameToCount[name] ?? 0) + item.qty;
        nameToVeg[name] = item.isVeg;
      }
    }

    final computedItems = nameToCount.entries.map((entry) {
      final name = entry.key;
      final count = entry.value;
      final isVeg = nameToVeg[name] ?? true;
      return RepeatedItem(
        name: name,
        count: count,
        veg: isVeg,
        borderColor: isVeg ? const Color(0xff2DB347) : const Color(0xffC61D1D),
      );
    }).toList();

    computedItems.sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) return countCompare;
      return a.name.compareTo(b.name);
    });

    final items = computedItems;

    final content = Column(
      children: [
        Row(
          children: [
            if (!widget.isEmbedded) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SUMMARY",
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                  ),
                ),
                const Text(
                  "Cumulative summary of preparing KOT items",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.history, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              "Last Updated: $lastUpdated",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2F365F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: loadRepeatedItems,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Refresh"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 2.15,
                        ),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: item.borderColor,
                                  width: 3,
                                ),
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                Text(
                                  "${item.count}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    color: Color(0xffB31313),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    item.veg
                                        ? const Color(0xff2DB347)
                                        : const Color(0xffC61D1D),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                item.veg ? "Veg" : "Non-Veg",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xffF4F8FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff5D8EFF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Color(0xff2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Counts indicate the total quantity of items across all preparing KOTs.",
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE5EBF5)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: content,
        ),
      ),
    );
  }
}
