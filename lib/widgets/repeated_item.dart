import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/repeated_item.dart';

// import '../services/repeateditem_apiservices.dart';

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
  List<RepeatedItem> items = [];
  bool isLoading = true;
  String lastUpdated = "";


  @override
  void initState() {
    super.initState();
    loadRepeatedItems();
    _updateLastUpdated();
  }

  @override
  void dispose() {
    // _timer?.cancel();
    super.dispose();
  }

  void _updateLastUpdated() {
    if (!mounted) return;

    setState(() {
      // lastUpdated = DateTime.now() as String;
    });
  }

  Future<void> loadRepeatedItems() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await getKitchenItemsCount(
        token: widget.token,
        restaurantId: widget.restaurantId,
      );

      if (!mounted) return;

      items =
          response.map<RepeatedItem>((e) {
            final bool isVeg = e['is_veg'] ?? true;

            return RepeatedItem(
              name: e['item_name'] ?? '',
              count: e['quantity'] ?? 0,
              veg: isVeg,
              borderColor:
              isVeg ? const Color(0xff2DB347) : const Color(0xffC61D1D),
            );
          }).toList();

      _updateLastUpdated();
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
                  "Items appearing in multiple pending KOTs",
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
                  "Count indicate the number of items pending KOT's that contain the item.",
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
