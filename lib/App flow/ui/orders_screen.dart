import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/payment_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';

import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/kot_event.dart' as kot_evt;
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc Logic/discount_bloc.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/void_item_bloc.dart';
import '../../blocs/Bloc State/checkin_state.dart';
import '../../blocs/Bloc State/kot_state.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../local database/login_dao.dart';
import '../../local database/table_dao.dart';
import '../../models/order/order_items.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../printer/printer_settings.dart';
import '../../repositories/checkin_repository.dart';
import '../../repositories/discount_repository.dart';
import '../../repositories/kot_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/payment_summary_repository.dart';
import '../../repositories/void_item_repository.dart';
import '../../services/kds_seivices.dart';
import '../../utils/SessionManager.dart';
import '../../utils/logger.dart';
import '../widgets/orderlist_widget.dart';
import '../widgets/view_all_kots.dart';
import 'guest_details_popup.dart';
// import '../blocs/Bloc Event/order_event.dart' as order_evt;
// import '../blocs/Bloc Event/kot_event.dart' as kot_evt;

class OrderPanel extends StatefulWidget {
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
  final List<OrderItems>? existingOrderItems;
  final List<KotModel>? existingKots;
  final String userId;
  final List<Map<String, dynamic>> loadedTables;

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
    this.existingOrderItems,
    this.existingKots,
    required this.userId,
    required this.loadedTables,
  });

  @override
  State<OrderPanel> createState() => _OrderPanelState();
}

class _OrderPanelState extends State<OrderPanel> {
  StreamSubscription? _mqttSubscription;
  bool _isRepeatingOrder = false;

  @override
  void initState() {
    super.initState();
    _initMqttStatusListener();
  }

  Future<void> _initMqttStatusListener() async {
    await KdsMqttPublisher.listenForKdsStatusUpdates(
      restaurantId: widget.restaurantId,
    );

    _mqttSubscription = KdsMqttPublisher.statusUpdates.listen((data) {
      print('MQTT Status Received => $data');

      context.read<OrderBloc>().add(
        UpdateKotStatusInOrder(
          kotNumber: data['kot_number'].toString(),
          status: data['status'].toString(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    super.dispose();
  }

  Future<void> printKot({
    required String kotNo,
    required String orderId,
    required String tableName,
    required String captainName,
    required List<Map<String, dynamic>> items,
    required KotModel kot,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];
    final displayKotNo = kotNo.replaceAll('KOT#', '');

    bytes += generator.text(
      "KOT - $displayKotNo",
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      "Dine In",
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.hr();
    // table row

    bytes += generator.row([
      PosColumn(
        width: 7,
        text:
        "Date : ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}",
      ),
      PosColumn(
        width: 5,
        text: "Dine In : $tableName",
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    // order /captain row

    bytes += generator.row([
      PosColumn(width: 6, text: "Order Id : $orderId"),
      PosColumn(
        width: 6,
        text: "Captain : $captainName",
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();
    //  header

    bytes += generator.row([
      PosColumn(width: 1, text: "S", styles: const PosStyles(bold: true)),
      PosColumn(
        width: 8,
        text: "Item Name",
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        width: 3,
        text: "Qty",
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

    // items
    int index = 1;

    for (final item in items) {
      bytes += generator.row([
        PosColumn(width: 1, text: index.toString()),
        PosColumn(width: 8, text: item['name'].toString()),
        PosColumn(
          width: 3,
          text: "x ${item['qty']}",
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Modifiers
      if (item['modifiers'] != null && (item['modifiers'] as List).isNotEmpty) {
        bytes += generator.text(
          "  + ${(item['modifiers'] as List).join(', ')}",
        );
      }

      // Addons
      if (item['addons'] != null && (item['addons'] as Map).isNotEmpty) {
        final addons = item['addons'] as Map<String, dynamic>;

        addons.forEach((name, details) {
          bytes += generator.text("   * $name x${details['quantity']}");
        });
      }

      index++;
    }
    //  footer

    bytes += generator.hr();

    bytes += generator.text(
      "Note :",
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    final printerSettings = PrinterSettings();
    await printerSettings.loadPrinter();

    if (printerSettings.selectedPrinter != null) {
      await printerSettings.printTicket(bytes, generator);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Trigger KOT loading for existing order
    final orderBloc = context.read<OrderBloc>();
    final kotBloc = context.read<KotBloc>();

    // ✅ Initialize OrderBloc with existing order items if not already loaded
    if (widget.orderId != 0 && orderBloc.state.orderId != widget.orderId) {
      orderBloc.add(
        LoadExistingOrder(
          orderId: widget.orderId,
          tableId: widget.tableId,
          zoneId: widget.zoneId,
          tableName: widget.tableName,
          zoneName: widget.zoneName,
          kotList: widget.existingKots ?? [],
          // guests: [guestcount],
          // orderItems: existingOrderItems ?? [],
          restaurantId: widget.restaurantId,
          guestDetails: widget.guestcount,
        ),
      );
    }

    // ✅ Initialize KotBloc with existing KOTs if not already loaded
    if (widget.orderId != 0 &&
        widget.existingKots != null &&
        (kotBloc.state is! KotLoaded ||
            (kotBloc.state as KotLoaded).kots.isEmpty)) {
      context.read<KotBloc>().add(SetExistingKots(kots: widget.existingKots!));
    }
    return BlocListener<KotBloc, KotState>(
        listener: (context, kotState) {

          if (kotState is KotLoaded) {
            debugPrint("KotLoaded: ${kotState.kots.length}");
            context.read<OrderBloc>().add(
              RefreshKotList(kotState.kots),
            );
          }
        },
        child: BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        // disable buttons
        final bool hasCartItems = state.orderItems.isNotEmpty;

        final activeKots =
        state.kotList.where((kot) {
          final status = (kot.status ?? '').toLowerCase();

          return status != 'served' &&
              status != 'voided' &&
              status != 'transferred';
        }).toList();

        final bool hasActiveKot = activeKots.isNotEmpty;
        debugPrint("========== KOTS ==========");
        for (final kot in state.kotList) {
          debugPrint("KOT: ${kot.kotNumber} | Status: ${kot.status}");
        }

        debugPrint("Total KOTs: ${state.kotList.length}");
        debugPrint("Active KOTs: ${activeKots.length}");

        /// Repeat Order -> only if active KOT exists
        final bool canRepeatOrder = hasActiveKot;

        /// KOT Print -> only if cart contains items
        final bool canPrintKot = hasCartItems;

        /// Pay -> only if active KOT exists
        final bool canPay = hasActiveKot;
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
              /// Header row with badges & actions (FIXED ALIGNMENT)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// LEFT SIDE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// Order ID
                          Row(
                            children: [
                              Image.asset(
                                "assets/order.png",
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(width: 6),

                              Text(
                                "Order Id #${state.orderId}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff404040),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// Table + Guests
                          Row(
                            children: [

                              Image.asset(
                                "assets/dine.png",
                                width: 25,
                                height: 25,
                              ),

                              const SizedBox(width: 6),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),

                                child: Text(
                                  "${state.zoneName}-${state.tableName}",
                                  style: const TextStyle(
                                    color: Color(0xff002053),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              const SizedBox(width: 10),

                              const Icon(
                                Icons.people,
                                size: 18,
                                color: Colors.black54,
                              ),

                              const SizedBox(width: 4),

                              BlocBuilder<OrderBloc, OrderState>(
                                builder: (context, state) {
                                  return Text(
                                    "${state.guestDetails.guestCount}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// RIGHT SIDE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.black54,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              "${DateFormat('MMM dd, yyyy').format(DateTime.now())} | ${DateFormat('h:mm a').format(DateTime.now())}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        InkWell(
                          onTap: () async {
                            final currentOrderId = context.read<OrderBloc>().state.orderId;

                            if (currentOrderId == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 1),
                                  content: Text("No active order to cancel"),
                                ),
                              );
                              return;
                            }

                            AppLogger.info(
                              "Cancel order clicked → Order ID: $currentOrderId",
                            );

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              final orderRepo = OrderRepository(
                                baseUrl: 'https://merchantrestaurant.alektasolutions.com',
                              );

                              final responseJson = await orderRepo.cancelOrder(
                                parentOrderId: currentOrderId,
                                token: widget.token,
                                restaurantId: widget.restaurantId,
                                zoneId: widget.zoneId,
                              );

                              if (context.mounted && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              if (responseJson['status'] == 'cancelled') {
                                context.read<OrderBloc>().add(
                                  CancelOrder(
                                    parentOrderId: currentOrderId,
                                    token: widget.token,
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 1),
                                    content: Text(
                                      "Order ${responseJson['order_id']} cancelled successfully",
                                    ),
                                  ),
                                );

                                final tableDao = TableDao();
                                final tables =
                                await tableDao.getTablesByManagerPin(widget.pin);

                                if (!context.mounted) return;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TablesScreen(
                                      loadedTables: tables,
                                      pin: widget.pin,
                                      token: widget.token,
                                      restaurantId: widget.restaurantId,
                                      restaurantName: widget.restaurantName,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    duration: Duration(seconds: 1),
                                    content: Text("Failed to cancel order"),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              AppLogger.error("Cancel order API error: $e");

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 1),
                                  content: Text(
                                    e.toString().replaceFirst("Exception: ", ""),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xffF2F2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/icon/delete.png",
                                width: 18,
                                height: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    /// Base Layout
                    Column(
                      children: [
                        const SizedBox(height: 36),

                        // Header
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF989292),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 7),
                              SizedBox(width: 40, child: headerText('#')),
                              const SizedBox(width: 6),
                              Expanded(child: headerText('Item Name')),
                              const SizedBox(width: 40),
                              headerText('Modifiers'),
                              SizedBox(
                                width: 70,
                                child: headerText(
                                  'Price',
                                  align: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 30),
                              SizedBox(
                                width: 80,
                                child: headerText(
                                  'Qty',
                                  align: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 5),
                              SizedBox(
                                width: 70,
                                child: headerText(
                                  'Amount',
                                  align: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 2),

                        /// Order List
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF1F1F3),
                            child: OrderPanelList(
                              orderItems: state.orderItems,
                              addonPrices: widget.addonPrices,
                              onIncreaseQuantity: (index) {
                                final item = state.orderItems[index];
                                context.read<OrderBloc>().add(
                                  UpdateOrderItemQuantity(index, item.quantity + 1),
                                );
                              },
                              onDecreaseQuantity: (index) {
                                final item = state.orderItems[index];
                                if (item.quantity > 1) {
                                  context.read<OrderBloc>().add(
                                    UpdateOrderItemQuantity(index, item.quantity - 1),
                                  );
                                }
                              },
                              onModifiersChanged: (index, modifiers, addOns, note) {
                                final fullAddOns = <String, Map<String, dynamic>>{};
                                addOns.forEach((name, qty) {
                                  fullAddOns[name] = {
                                    'quantity': qty,
                                    'price': widget.addonPrices[name] ?? 0,
                                  };
                                });

                                context.read<OrderBloc>().add(
                                  UpdateOrderItemDetails(
                                    index: index,
                                    modifiers: modifiers,
                                    addOns: fullAddOns,
                                    note: note,
                                  ),
                                );
                              },
                              onRemoveItem: (index) {
                                context.read<OrderBloc>().add(RemoveOrderItem(index));
                              },
                              token: widget.token,
                            ),
                          ),
                        ),

                        /// TOTAL INSIDE STACK
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5BF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Items: ${state.orderItems.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                state.orderItems
                                    .fold(
                                  0.0,
                                      (sum, item) => sum + item.totalWithAddons,
                                )
                                    .toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// DROPDOWN OVERLAY
                    if (state.kotList.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Material(
                          elevation: 30,
                          color: Colors.transparent,
                          child: MultiBlocProvider(
                            providers: [
                              BlocProvider<KotLineItemsBloc>(
                                create: (_) => KotLineItemsBloc(
                                  repository: VoidItemRepository(),
                                ),
                              ),
                              BlocProvider<UpdatekotBloc>(
                                create: (_) => UpdatekotBloc(
                                  repository: UpdatekotRepository(),
                                ),
                              ),
                              BlocProvider.value(
                                value: context.read<KotBloc>(),
                              ),
                            ],
                            child: ViewAllKOTDropdown(
                              kots: state.kotList,
                              parentOrderId: state.orderId,
                              restaurantId: int.parse(widget.restaurantId),
                              zoneId: state.zoneId,
                              token: widget.token,
                              tableNo: state.tableName,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),


              /// Bottom action buttons
        Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Builder(
                    builder: (scaffoldContext) {
                      return BlocListener<OrderBloc, OrderState>(
                        listenWhen: (prev, curr) => prev.error != curr.error,
                        listener: (context, state) {
                          if (state.error != null && state.error!.isNotEmpty) {
                            ScaffoldMessenger.of(scaffoldContext)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(state.error!),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                          }
                        },
                        child: orderButton(
                          'Repeat order',
                          canRepeatOrder
                              ? const Color(0xFF2563EB)
                              : Colors.grey,
                          isLoading: _isRepeatingOrder,
                          onPressed:
                          canRepeatOrder
                              ? () {
                            setState(() {
                              _isRepeatingOrder = true;
                            });

                            final bloc = context.read<OrderBloc>();

                            if (bloc.state.orderId == 0) {
                              ScaffoldMessenger.of(
                                scaffoldContext,
                              ).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 1),
                                  content: Text("Order not found"),
                                ),
                              );
                              setState(() {
                                _isRepeatingOrder = false;
                              });
                              return;
                            }

                            bloc.add(
                              RepeatKotOrder(
                                orderId: bloc.state.orderId,
                                restaurantId: int.parse(
                                  bloc.state.restaurantId,
                                ),
                                zoneId: bloc.state.zoneId,
                                token: widget.token,
                              ),
                            );

                            Future.delayed(
                              const Duration(seconds: 2),
                                  () {
                                if (mounted) {
                                  setState(() {
                                    _isRepeatingOrder = false;
                                  });
                                }
                              },
                            );
                          }
                              : null,
                        ),
                      );
                    },
                  ),

                  orderButton(
                    'KOT Print',
                    canPrintKot ? const Color(0xFFF97316) : Colors.grey,
                    onPressed:
                    canPrintKot
                        ? () async {
                      final orderBloc = context.read<OrderBloc>();
                      final kotBloc = context.read<KotBloc>();
                      final orderRepo = OrderRepository(
                        baseUrl:
                        'https://merchantrestaurant.alektasolutions.com',
                      );

                      if (state.orderItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text('No items to create KOT!'),
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (_) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final captainId = int.tryParse(
                          this.widget.userId,
                        );
                        if (captainId == null || widget.token.isEmpty) {
                          throw Exception(
                            'Invalid user session. Please check in again.',
                          );
                        }

                        final KotModel? kot = await orderRepo.createKOT(
                          parentOrderId: state.orderId,
                          kotId: "",
                          items: state.orderItems,
                          token: widget.token,
                          restaurantId:
                          orderBloc.state.restaurantId.toString(),
                          zoneId: orderBloc.state.zoneId,
                          captainId: captainId,
                        );

                        Navigator.of(context).pop();

                        final permissions =
                        await SessionManager.loadPermissions();
                        final captainName =
                            permissions?.displayName ?? '';
                        if (kot != null) {
                          await printKot(
                            kotNo: kot.kotNumber ?? '',
                            orderId: kot.parentOrderId.toString(),
                            tableName: orderBloc.state.tableName,
                            captainName: captainName,
                            items:
                            state.orderItems
                                .map(
                                  (e) => {
                                "name": e.name,
                                "qty": e.quantity,
                                "modifiers":
                                e.modifiers.toList(),
                                "addons": e.addOns,
                              },
                            )
                                .toList(),
                            kot: kot,
                          );
                          await KdsMqttPublisher.notifyKotCreated(
                            restaurantId:
                            orderBloc.state.restaurantId.toString(),
                            parentOrderId: state.orderId,
                            zoneId: orderBloc.state.zoneId,
                            zoneName: orderBloc.state.zoneName,
                            orderType: 'Dine-In',
                            kot: kot,
                            tableName: orderBloc.state.tableName,
                          );
                          orderBloc.add(AddKOT(kot));
                          kotBloc.add(AddKotToList(kot));
                          orderBloc.add(ClearOrder());

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: SizedBox(
                                width: 400,
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'KOT Created: ${kot.kotNumber}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(
                                left: 400,
                                right: 400,
                                bottom:
                                MediaQuery.of(context).size.height *
                                    0.90,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.green,
                              elevation: 6,
                            ),
                          );
                        }
                      } catch (e) {
                        if (Navigator.of(
                          context,
                          rootNavigator: true,
                        ).canPop()) {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop();
                        }
                        final message = e.toString().replaceFirst(
                          "Exception: ",
                          "",
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        AppLogger.error(message);
                      }
                    }
                        : null,
                  ),

                  orderButton(
                    'Pay',
                    canPay ? const Color(0xFF16A34A) : Colors.grey,
                    onPressed:
                    canPay
                        ? () {
                      AppLogger.info("Pay clicked");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<OrderBloc>(),
                              ),
                              BlocProvider.value(
                                value: context.read<PaymentBloc>(),
                              ),
                              BlocProvider.value(
                                value:
                                context
                                    .read<RemoveDiscountBloc>(),
                              ),
                            ],
                            child: PaymentScreen(
                              loadedTables: widget.loadedTables,
                              pin: widget.pin,
                              token: widget.token,
                              restaurantId: widget.restaurantId,
                              restaurantName: widget.restaurantName,
                              zoneId: widget.zoneId,
                            ),
                          ),
                        ),
                      );
                    }
                        : null,
                  ),
                ],
              ),
        )],
          ),
        );


      },
    ));
  }
  // ================= Widgets =================

  Widget headerBadgeRow(OrderState state) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECEEFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // ✅ shrink to content
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                state.zoneName.isNotEmpty ? state.zoneName : 'Loading...',
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
                    state.tableName.isNotEmpty ? state.tableName : 'Loading...',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget actionButton(
      String text,
      String iconPath,
      Color color, {
        required VoidCallback onPressed,
      }) => OutlinedButton.icon(
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

  Widget elevatedActionButton(
      String text,
      String iconPath, {
        required VoidCallback onPressed,
      }) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF152148),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    onPressed: onPressed,
    icon: Image.asset(iconPath, width: 8, height: 8, color: Colors.white),
    label: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.white),
    ),
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
      CircleAvatar(
        radius: 12,
        backgroundColor: Colors.transparent, // ❌ no background
        foregroundImage: AssetImage(imagePath),
      ),
      const SizedBox(width: 4),
      Text(name),
    ],
  );

  Widget headerText(String text, {TextAlign align = TextAlign.left}) => Text(
    text,
    textAlign: align,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget orderButton(
      String text,
      Color color, {
        VoidCallback? onPressed,
        bool isLoading = false,
      }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 55, // increased height
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null ? Colors.grey : color,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ), // optional: increase padding too
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}