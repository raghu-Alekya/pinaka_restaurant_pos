import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';

import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/checkin_state.dart';
import '../../blocs/Bloc State/kot_state.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../local database/login_dao.dart';
import '../../local database/table_dao.dart';
import '../../models/order/order_items.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../repositories/checkin_repository.dart';
import '../../repositories/kot_repository.dart';
import '../../repositories/order_repository.dart';
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
    required this.zoneName,
    required this.placedTables,
    required this.pin,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        return Container(
          width: 700,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header row with badges & actions
              Center(
                child: SizedBox(
                  width: 480, // Total desired width for the row
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left side: header badges
                      Flexible(
                        fit: FlexFit.loose, // 👈 allows it to take only as much width as needed
                        child: headerBadgeRow(state),
                      ),

                      // Right side: action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 80, // Set desired width for Cancel button
                            child: actionButton(
                              'Cancel',
                              'assets/icon/delete.png',
                              Colors.red,
                              onPressed: () async {
                                final currentOrderId = context.read<OrderBloc>().state.orderId;

                                if (currentOrderId == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("No active order to cancel")),
                                  );
                                  return;
                                }

                                AppLogger.info("Cancel order clicked → Order ID: $currentOrderId");

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );

                                try {
                                  final orderRepo = OrderRepository(baseUrl: 'https://merchantrestaurant.alektasolutions.com');

                                  final responseJson = await orderRepo.cancelOrder(
                                    parentOrderId: currentOrderId,
                                    token: token,
                                    restaurantId: restaurantId,
                                    zoneId: zoneId,
                                  );

                                  Navigator.of(context).pop(); // close loader

                                  if (responseJson['status'] == 'cancelled') {
                                    AppLogger.info("Order ${responseJson['order_id']} cancelled successfully");

                                    // update bloc
                                    context.read<OrderBloc>().add(
                                      CancelOrder(
                                        parentOrderId: currentOrderId,
                                        token: token,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Order ${responseJson['order_id']} cancelled successfully")),
                                    );

                                    // navigate back to tables
                                    final tableDao = TableDao();
                                    final tables = await tableDao.getTablesByManagerPin(pin);

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
                                          (Route<dynamic> route) => false,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Failed to cancel order")),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  AppLogger.error("Cancel order API error: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error cancelling order: $e")),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100, // Set desired width for Table layout button
                            child: elevatedActionButton(
                              'Table layout',
                              'assets/icon/arrow.png',
                              onPressed: () {
                                AppLogger.info("Table layout clicked");

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TablesScreen(
                                      loadedTables: placedTables,
                                      pin: pin,
                                      token: token,
                                      restaurantId: restaurantId,
                                      restaurantName: restaurantName,
                                    ),
                                  ),
                                      (route) => false,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // const SizedBox(height: 1),

              /// Date & guest info
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, // vertically center
                mainAxisSize: MainAxisSize.min, // prevent extra space
                children: [
                  iconText(
                    'assets/icon/calender.png',
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  ),
                  const SizedBox(width: 10),
                  iconText(
                    'assets/icon/clock.png',
                    DateFormat('hh:mm a').format(DateTime.now()),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        avatarName(
                          'assets/icon/person.png',
                          'Guests: ${state.guests.fold<int>(0, (sum, g) => sum + g.guestCount)}',
                        ),
                        const SizedBox(width: 1),
                        IconButton(
                          onPressed: () async {
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
                                onGuestSaved: (Guestcount guest) async {
                                  AppLogger.info("Guest saved: ${guest.guestCount}");
                                  final orderRepository = OrderRepository(
                                      baseUrl:
                                      'https://merchantrestaurant.alektasolutions.com');
                                  final order = await orderRepository.createOrder(
                                    tableId: tableId,
                                    zoneId: zoneId,
                                    restaurantId: restaurantId,
                                    guestCount: guest.guestCount,
                                    token: token,
                                    tableName: tableName,
                                    zoneName: zoneName,
                                    restaurantName: restaurantName,
                                    guests: [guest],
                                  );

                                  context.read<OrderBloc>().add(
                                    CreateOrderSuccess(
                                      orderId: orderId,
                                      // tableId: tableId,
                                      // zoneId: zoneId,
                                      // tableName: tableName,
                                      // zoneName: zoneName,
                                      // restaurantId: restaurantId,
                                      // guests: [guest], // or existing guests list
                                      // kotList: [],            // empty initially or fetched KOTs
                                      // orderItems: [],         // empty initially or fetched order items
                                    ),
                                  );

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
                                restaurantId: restaurantId, pin: pin,
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
                  ),
                ],
              ),


              // const SizedBox(height: 4),

              Expanded(
                child: Stack(
                  children: [
                    // 1️⃣ Base: Order items list
                    Column(
                      children: [
                        // Spacer equal to dropdown collapsed height
                        SizedBox(height: 36),
                        const SizedBox(height:6),// collapsed dropdown height

                        // Table header (always visible)
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF989292),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 50, child: headerText('#')),
                              Expanded(child: headerText('Item Name')),
                              SizedBox(width: 120, child: headerText('Modifiers')),
                              SizedBox(width: 75, child: headerText('Qty')),
                              SizedBox(width: 50, child: headerText('Amount')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Order items list
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF1F1F3), // set background color
                            child: OrderPanelList(
                              orderItems: state.orderItems,
                              addonPrices: addonPrices,
                              onIncreaseQuantity: (index) {
                                final item = state.orderItems[index];
                                context.read<OrderBloc>().add(UpdateOrderItemQuantity(index, item.quantity + 1));
                              },
                              onDecreaseQuantity: (index) {
                                final item = state.orderItems[index];
                                if (item.quantity > 1) {
                                  context.read<OrderBloc>().add(UpdateOrderItemQuantity(index, item.quantity - 1));
                                }
                              },
                              onModifiersChanged: (index, modifiers, addOns, note) {
                                final fullAddOns = <String, Map<String, dynamic>>{};
                                addOns.forEach((name, qty) {
                                  fullAddOns[name] = {'quantity': qty, 'price': addonPrices[name] ?? 0.0};
                                });
                                context.read<OrderBloc>().add(UpdateOrderItemDetails(
                                  index: index,
                                  modifiers: modifiers,
                                  addOns: fullAddOns,
                                  note: note,
                                ));
                              },
                              onRemoveItem: (index) {
                                context.read<OrderBloc>().add(RemoveOrderItem(index));
                              },
                              token: token,
                            ),
                          ),
                        )

                      ],
                    ),
                    const SizedBox(height:2),

                    // 2️⃣ Overlay: ViewAllKOTDropdown
                    BlocBuilder<KotBloc, KotState>(
                      builder: (context, kotState) {
                        final kots = kotState is KotLoaded ? kotState.kots : <KotModel>[];
                        return Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ViewAllKOTDropdown(
                            kots: kots,
                            parentOrderId: state.orderId,
                            restaurantId: int.parse(restaurantId),
                            zoneId: zoneId,
                            token: token,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 10),

              /// Total section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5BF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      state.orderItems.fold(0.0, (sum, item) => sum + item.totalWithAddons).toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              /// Bottom action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  orderButton('Repeat order', const Color(0xFFF7C127), onPressed: () {
                    AppLogger.info("Repeat order clicked");
                  }),
                  orderButton(
                    'KOT Print',
                    const Color(0xFFFF4D20),
                    onPressed: () async {
                      final orderBloc = context.read<OrderBloc>();
                      final kotBloc = context.read<KotBloc>();
                      final orderRepo = OrderRepository(
                        baseUrl: 'https://merchantrestaurant.alektasolutions.com',
                      );
                      final checkInRepo = context.read<CheckInRepository>();

                      if (state.orderItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No items to create KOT!')),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final login = await checkInRepo.getSavedLogin();
                        if (login == null) throw Exception('No login found!');

                        final token = login['token'] as String?;
                        final captainId = login['captainId'] as int? ?? 0;

                        if (token == null || captainId == 0) throw Exception('Login expired or invalid.');

                        // 1️⃣ Create KOT
                        final KotModel? kot = await orderRepo.createKOT(
                          parentOrderId: state.orderId,
                          kotId: "",  // new KOT
                          items: state.orderItems,
                          token: token,
                          restaurantId: state.restaurantId,
                          zoneId: state.zoneId,
                          captainId: captainId,
                        );

                        Navigator.of(context).pop(); // close loader

                        if (kot != null) {
                          // Add KOT to OrderBloc
                          orderBloc.add(AddKOT(kot));

                          // Add KOT to KotBloc for immediate dropdown update
                          kotBloc.add(AddKotToList(kot));

                          // ✅ Clear current order items
                          context.read<OrderBloc>().add(ClearOrder());  // <-- dispatch the event

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('KOT Created: ${kot.kotNumber}')),
                          );
                        }
                        else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to create KOT')),
                          );
                        }
                      } catch (e) {
                        Navigator.of(context).pop();
                        AppLogger.error("Error creating KOT: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
                  ),


                  orderButton('Generate e-Bill', Colors.green, onPressed: () {
                    AppLogger.info("Generate e-Bill clicked");
                  }),
                  orderButton('Pay', const Color(0xFF086888), onPressed: () {
                    AppLogger.info("Pay clicked");
                  }),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEFB), //  background only for container
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, //  keeps width only as per content
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            state.zoneName.isNotEmpty ? state.zoneName : 'Unknown Zone',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            'Order ID: ${state.orderId}',
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icon/table.png', width: 18, height: 18),
              const SizedBox(width: 4),
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

  Widget actionButton(String text, String iconPath, Color color, {required VoidCallback onPressed}) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF6F6F6),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Image.asset(iconPath, width: 16, height: 16, color: color),
        label: Text(text, style: const TextStyle(fontSize: 12)),
      );

  Widget elevatedActionButton(String text, String iconPath, {required VoidCallback onPressed}) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF152148),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Image.asset(iconPath, width: 8, height: 8, color: Colors.white),
        label: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
      );

  Widget iconText(String assetPath, String label) => Row(
    children: [
      Image.asset(assetPath, width: 18, height: 18),
      const SizedBox(width: 2),
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
    style: const TextStyle(color: Colors.white, fontSize: 13),
  );

  Widget orderButton(String text, Color color, {required VoidCallback onPressed}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 55, // increased height
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16), // optional: increase padding too
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    ),
  );

}
