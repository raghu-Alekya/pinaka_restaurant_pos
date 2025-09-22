import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_model.dart';
import '../../repositories/order_repository.dart';
import 'dashboard screen.dart';

class GuestDetailsPopup extends StatefulWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final List<Map<String, dynamic>> placedTables;
  final void Function(Guestcount) onGuestSaved;
  final String token;
  final String restaurantId;

  const GuestDetailsPopup({
    Key? key,
    required this.index,
    required this.tableData,
    required this.placedTables,
    required this.onGuestSaved,
    required this.token,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<GuestDetailsPopup> createState() => _GuestDetailsPopupState();
}

class _GuestDetailsPopupState extends State<GuestDetailsPopup> {
  List<int> selectedGuests = [];

  @override
  Widget build(BuildContext context) {
    final tableCapacity = widget.tableData['capacity'] ?? 6;

    final int tableId =
        widget.tableData['table_id'] ??
            widget.tableData['id'] ??
            0;

    final int zoneId =
        widget.tableData['zone_id'] ??
            widget.tableData['zoneId'] ??
            0;

    final String tableName =
        widget.tableData['table_name'] ??
            widget.tableData['name'] ??
            'Unknown Table';

    final String zoneName =
        widget.tableData['zone_name'] ??
            widget.tableData['zoneName'] ??
            widget.tableData['areaName'] ??
            'Unknown Zone';
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: const BoxConstraints(maxWidth: 600, minWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Guest Numbers",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),

                /// Guest selection buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(tableCapacity, (index) {
                    int guest = index + 1;
                    bool isSelected = selectedGuests.contains(guest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGuests = List.generate(guest, (i) => i + 1);
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE4E4E7)
                              : const Color(0xFFF6F6F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$guest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.black
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),

                /// Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedGuests.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                              Text('Please select number of guests'),
                            ),
                          );
                          return;
                        }

                        final guestDetails =
                        Guestcount(guestCount: selectedGuests.length);

                        if (tableId == 0 || zoneId == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cannot create order: Table/Zone ID missing'),
                            ),
                          );
                          return;
                        }
                        context.read<OrderBloc>().add(
                          SelectTable(
                            tableId: tableId,
                            zoneId: zoneId,
                            tableName: tableName,
                            zoneName: zoneName,
                          ),
                        );

                        final orderRepository = OrderRepository(
                          baseUrl:
                          'https://merchantrestaurant.alektasolutions.com',
                        );

                        try {
                          final OrderModel orderData =
                          await orderRepository.createOrder(
                            tableId: tableId,
                            zoneId: zoneId,
                            tableName: tableName,
                            zoneName: zoneName,
                            restaurantId: widget.restaurantId,
                            restaurantName: 'My Restaurant',
                            guests: [guestDetails],
                            token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NTgyNjk5NDcsIm5iZiI6MTc1ODI2OTk0NywiZXhwIjoxNzYwODYxOTQ3LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.WxZtMoMWv6NRDmaLd4Gt1N4_gIW9x25WyGTWIuWVre4",
                            guestCount: selectedGuests.length,
                          );

                          // Dispatch CreateOrder event to Bloc
                          context.read<OrderBloc>().add(
                            CreateOrder(
                              orderId: orderData.orderId,
                              tableId: tableId,
                              zoneId: zoneId,
                              tableName: tableName,
                              zoneName: zoneName,
                              restaurantId: widget.restaurantId,
                              guests: [guestDetails],
                            ),
                          );


                          // Navigate to DashboardScreen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DashboardScreen(
                                guestDetails: guestDetails,
                                token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NTgyNjk5NDcsIm5iZiI6MTc1ODI2OTk0NywiZXhwIjoxNzYwODYxOTQ3LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.WxZtMoMWv6NRDmaLd4Gt1N4_gIW9x25WyGTWIuWVre4",
                                restaurantId: widget.restaurantId,
                                orderId: orderData.orderId,
                                tableId: tableId,
                                tableName: tableName,
                                zoneId: zoneId,
                                zoneName: zoneName,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to create order: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "SELECT AND CONTINUE",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
