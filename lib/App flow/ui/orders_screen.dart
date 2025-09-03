import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';

import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../local database/table_dao.dart';
import '../../models/order/order_items.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../utils/logger.dart';
import '../widgets/orderlist_widget.dart';
import '../widgets/view_all_kots.dart';
import 'guest_details_popup.dart';

class OrderPanel extends StatelessWidget {
  final Function(int) onGuestSaved;
  final Map<String, double> addonPrices;
  final String token;
  final String restaurantId;
  final Guestcount guestcount;
  final int orderId;
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final List<Map<String, dynamic>> placedTables;
  final String pin;
  final String restaurantName;

  const OrderPanel({
    super.key,
    required this.onGuestSaved,
    required this.addonPrices,
    required this.token,
    required this.restaurantId,
    required this.guestcount,
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName, required this.placedTables, required this.pin, required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        return Container(
          width: 800,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header row with badges & actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  headerBadgeRow(state),
                  Row(
                    children: [
                      actionButton(
                        'Cancel',
                        'assets/icon/delete.png',
                        Colors.red,
                        onPressed: () async {
                          AppLogger.info("Cancel order clicked");

                          // 1. Cancel order in Bloc
                          context.read<OrderBloc>().add(CancelOrder());

                          // 2. Show message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Order cancelled")),
                          );

                          // 3. Redirect back to table screen (replace current screen)
                          // First, fetch the tables
                          final tableDao = TableDao();
                          final tables = await tableDao.getTablesByManagerPin(pin);

// Then navigate
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TablesScreen(
                                loadedTables: tables,
                                pin: pin,
                                token: token,
                                restaurantId: restaurantId,
                                restaurantName: restaurantName,
                              ),
                            ),
                                (Route<dynamic> route) => false, // remove all previous routes
                          );




                        },
                      ),

                      const SizedBox(width: 14),
                      elevatedActionButton(
                        'Table layout',
                        'assets/icon/arrow.png',
                        onPressed: () {
                          AppLogger.info("Table layout clicked");

                          // Navigate to TablesScreen and clear navigation stack
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TablesScreen(
                                loadedTables: placedTables,   // pass from constructor
                                pin: pin,                     // pass from constructor
                                token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NTY5MDA5NzIsIm5iZiI6MTc1NjkwMDk3MiwiZXhwIjoxNzU5NDkyOTcyLCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.U1TBvAezBoMlzo3FiUUiHOEmCNlsqKMQZCyZAEPND0w",
                                restaurantId: restaurantId,
                                restaurantName: restaurantName,
                              ),
                            ),
                                (route) => false, // clears all previous screens
                          );
                        },
                      ),

                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),

              /// Date & guest info
            Row(
              children: [
                // Current Date
                iconText(
                  'assets/icon/calender.png',
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                ),
                const SizedBox(width: 10),

                // Current Time
                iconText(
                  'assets/icon/clock.png',
                  DateFormat('hh:mm a').format(DateTime.now()),
                ),
                const Spacer(),

                // Guests
                avatarName(
                  'assets/icon/person.png',
                  'Guests: ${state.guests.fold<int>(0, (sum, g) => sum + g.guestCount)}',
                ),

                // Add Guest Button
                IconButton(
                  onPressed: () {
                    AppLogger.info("Add Guest clicked");
                    showDialog(
                      context: context,
                      builder: (_) => GuestDetailsPopup(
                        index: 0,
                        tableData: {
                          'id': tableId,
                          'zoneId': zoneId,
                          'zoneName': zoneName,
                          'name': tableName,
                          'capacity': 6,
                        },
                        placedTables: [],
                        onGuestSaved: (Guestcount guest) {
                          AppLogger.info("Guest saved: ${guest.guestCount}");
                          context.read<OrderBloc>().add(CreateOrder(
                            restaurantId: restaurantId,
                            orderId: orderId,
                            tableId: tableId,
                            zoneId: zoneId,
                            tableName: tableName,
                            zoneName: zoneName,
                            guests: [guest],
                          ));
                          onGuestSaved(guest.guestCount);
                        },
                        token: token,
                        restaurantId: restaurantId,
                      ),
                    );
                  },
                  icon: Image.asset(
                    'assets/icon/add_icon.png',
                    width: 18,
                    height: 18,
                  ),
                  tooltip: 'Add Guest',
                ),
              ],
            ),

            const SizedBox(height: 6),

              /// KOT Dropdown
              ViewAllKOTDropdown(kotList: state.kotList),

              const SizedBox(height: 2),

              /// Table header row
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF989292),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: headerText('#')),
                    Expanded(child: headerText('Item Name')),
                    SizedBox(width: 80, child: headerText('Modifiers / Add-ons')),
                    SizedBox(width: 60, child: headerText('Qty')),
                    SizedBox(width: 80, child: headerText('Amount')),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              /// Order items list
              Expanded(
                child: state.orderItems.isEmpty
                    ? const Center(
                  child: Text(
                    'No items added yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
                    : OrderPanelList(
                  orderItems: state.orderItems,
                  addonPrices: addonPrices,
                  onIncreaseQuantity: (index) {
                    final item = state.orderItems[index];
                    AppLogger.info(
                        "Increase quantity: ${item.name} (was ${item.quantity})");
                    context.read<OrderBloc>().add(
                      UpdateOrderItemQuantity(
                          index, item.quantity + 1),
                    );
                  },
                  onDecreaseQuantity: (index) {
                    final item = state.orderItems[index];
                    if (item.quantity > 1) {
                      AppLogger.info(
                          "Decrease quantity: ${item.name} (was ${item.quantity})");
                      context.read<OrderBloc>().add(
                        UpdateOrderItemQuantity(
                            index, item.quantity - 1),
                      );
                    }
                  },
                  onModifiersChanged: (index, modifiers, addOns, note) {
                    AppLogger.info(
                        "Modifiers updated for item $index: $modifiers, AddOns: $addOns, Note: $note");
                    context.read<OrderBloc>().add(
                      UpdateOrderItemDetails(
                        index: index,
                        modifiers: modifiers,
                        addOns: addOns,
                        note: note,
                      ),
                    );
                  },
                  onRemoveItem: (index) {
                    final item = state.orderItems[index];
                    AppLogger.info("Remove item: ${item.name}");
                    context.read<OrderBloc>().add(RemoveOrderItem(index));
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// Total section
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5BF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Items',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      state.orderItems
                          .fold(0.0,
                              (sum, item) => sum + item.totalWithAddons(addonPrices))
                          .toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              /// Bottom action buttons
              Row(
                children: [
                  orderButton('Repeat order', const Color(0xFFF7C127)),
                  orderButton('KOT Print', const Color(0xFFFF4D20)),
                  orderButton('Generate e-Bill', Colors.green),
                  orderButton('Pay', const Color(0xFF086888)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= Widgets =================

  Widget headerBadgeRow(OrderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🟢 Zone name
          Text(
            state.zoneName.isNotEmpty ? state.zoneName : 'Unknown Zone',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(width: 16),

          // 🟢 Order ID
          Text(
            'Order ID: ${state.orderId}',
            style: const TextStyle(color: Colors.black87),
          ),

          const SizedBox(width: 16),

          // 🟢 Table name with icon
          Row(
            children: [
              Image.asset('assets/icon/table.png', width: 14, height: 14),
              const SizedBox(width: 6),
              Text(
                state.tableName.isNotEmpty ? state.tableName : 'Unknown Table',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget actionButton(String text, String iconPath, Color color,
      {required VoidCallback onPressed}) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF6F6F6),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.0),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Image.asset(iconPath, width: 16, height: 16, color: color),
        label: Text(text, style: const TextStyle(fontSize: 12)),
      );

  Widget elevatedActionButton(String text, String iconPath,
      {required VoidCallback onPressed}) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF152148),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Image.asset(iconPath, width: 8, height: 8, color: Colors.white),
        label: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.white)),
      );

  Widget iconText(String assetPath, String label) => Row(
    children: [
      Image.asset(assetPath, width: 10, height: 10),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 14)),
    ],
  );

  Widget avatarName(String imagePath, String name) => Row(
    children: [
      CircleAvatar(radius: 12, backgroundImage: AssetImage(imagePath)),
      const SizedBox(width: 4),
      Text(name),
    ],
  );

  Widget headerText(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontSize: 12),
  );

  Widget orderButton(String text, Color color) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          AppLogger.info("Order action clicked: $text");
        },
        child: Text(text,
            style:
            const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    ),
  );
}
