import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/transer_kot.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/void_items.dart';
import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/void_item_evnts.dart';
import '../../blocs/Bloc Logic/auth_bloc.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/transfer_kot_bloc.dart';
import '../../blocs/Bloc Logic/void_item_bloc.dart';
import '../../blocs/Bloc State/kot_state.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/order_list_state.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../blocs/Bloc State/void_item_state.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/void_kot_items.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/kot_repository.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import '../../printer/printer_settings.dart';

const Color kHeaderBlue = Color(0xFF152148);
const Color kKotHeaderBg = Color(0xFFECEEFB);
const Color kCardBg = Color(0xFFF1F1F3);
const Color kDivider = Color(0xFFE6E6E6);
const Color kTotalBg = Color(0xFFFFE4B8);


class ViewAllKOTDropdown extends StatefulWidget {
  final int parentOrderId;
  final int restaurantId;
  final int zoneId;
  final String token;
  final String tableNo;
  final List<KotModel> kots; // ✅ ADD THIS
  // ✅ NEW: notifies the parent whenever this dropdown expands/collapses,
  // so the parent can hide/show its own order list accordingly.
  final ValueChanged<bool>? onToggle;

  const ViewAllKOTDropdown({
    super.key,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    required this.tableNo,
    required this.token,
    required this.kots, // ✅ FIXED
    this.onToggle, // ✅ NEW
  });

  @override
  State<ViewAllKOTDropdown> createState() => _ViewAllKOTDropdownState();
}

class _ViewAllKOTDropdownState extends State<ViewAllKOTDropdown> {
  bool _expanded = true;
  final Map<String, bool> _kotExpanded = {};
  int _previousOrderItemCount = 0;

  // 🔴 FIX: local mirror of the KOT list, kept in sync with the bloc's
  // latest state so cancel/void status updates show up automatically,
  // without waiting for the parent to pass a new `widget.kots`.
  late List<KotModel> _kots;

  // 🔴 FIX: lightweight auto-refresh timer so KOT statuses (e.g. an item
  // getting voided/cancelled from elsewhere) stay "live" without the
  // user needing to tap/expand anything.
  Timer? _refreshTimer;
  static const Duration _autoRefreshInterval = Duration(seconds: 5);
  String _currency = "₹";
  @override
  void initState() {
    super.initState();
    _kots = widget.kots; // seed with whatever the parent gave us initially
    _fetchKots();
    _loadCurrency();
    _startAutoRefresh(); // 🔴 FIX
    // ✅ NEW: report initial expansion state to the parent on first build
    // so the parent's _showKotList stays in sync from the start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onToggle?.call(_expanded);
    });
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }
  // 🔴 FIX: starts a periodic silent refetch so status changes (void/cancel/
  // preparing/ready/served) reflect automatically, live.
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (mounted) {
        _fetchKots();
      }
    });
  }

  void _fetchKots() {
    context.read<KotBloc>().add(FetchKots(
      parentOrderId: widget.parentOrderId,
      restaurantId: widget.restaurantId,
      zoneId: widget.zoneId,
      token: widget.token,
    ));
  }

  @override
  void didUpdateWidget(covariant ViewAllKOTDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentOrderId != widget.parentOrderId) {
      _kots = widget.kots; // 🔴 FIX: reseed local mirror on order change
      _fetchKots();
      _kotExpanded.clear();
      _expanded = false;
      // ✅ NEW: keep parent in sync when we reset expansion on order change
      widget.onToggle?.call(_expanded);
    } else if (!identical(oldWidget.kots, widget.kots)) {
      // 🔴 FIX: parent handed us a fresh list (e.g. it refetched) — take it.
      _kots = widget.kots;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // 🔴 FIX: stop polling when widget goes away
    super.dispose();
  }

  Map<String, String> extractZoneNames(dynamic zoneResponse) {
    // ✅ CASE 1: API already returns List<Map>
    if (zoneResponse is List) {
      return buildZoneNameMapFromZones(
        List<Map<String, dynamic>>.from(zoneResponse),
      );
    }

    // ✅ CASE 2: API returns Map with zone_details
    if (zoneResponse is Map<String, dynamic> &&
        zoneResponse['zone_details'] is List) {
      return buildZoneNameMapFromZones(
        List<Map<String, dynamic>>.from(zoneResponse['zone_details']),
      );
    }

    return {};
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'served':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _printKot(KotModel kot) async {
    try {
      final profile = await CapabilityProfile.load(name: 'XP-N160I');
      final generator = Generator(PaperSize.mm80, profile);

      List<int> bytes = [];
      bytes += [27, 32, 0]; // Reset character spacing
      final displayKotNo = (kot.kotNumber ?? '').replaceAll('KOT#', '');

      bytes += generator.text(
        "COPY OF KOT - $displayKotNo",
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size3,
          width: PosTextSize.size2,
        ),
      );

      final tableName = widget.tableNo;
      final dineInTitle =
      tableName.isNotEmpty ? "Dine In: $tableName" : "Dine In";

      bytes += generator.text(
        dineInTitle,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size3,
          width: PosTextSize.size2,
        ),
      );

      bytes += generator.hr();

      final dateText = "Date: ${DateFormat('dd/MM/yyyy').format(kot.time)}";
      final timeText = "Time: ${DateFormat('hh:mm a').format(kot.time)}";

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: dateText,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          width: 6,
          text: timeText,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += [27, 74, 16]; // spacing

      final orderIdText = "Order Id: ${kot.parentOrderId}";
      bytes += generator.row([
        PosColumn(
          width: 5,
          text: orderIdText,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          width: 7,
          text: "",
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.hr();
      bytes += [27, 32, 3]; // Set character spacing to 3 dots for items and headers

      bytes += generator.row([
        PosColumn(width: 2, text: "S.No", styles: const PosStyles(bold: true)),
        PosColumn(
          width: 8,
          text: "Item Name",
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          width: 2,
          text: "Qty",
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      bytes += [27, 74, 16];
      bytes += [27, 32, 0];
      bytes += generator.hr();
      bytes += [27, 32, 3];

      int index = 1;

      List<String> wrapText(String text, int maxLength) {
        if (text.isEmpty) return [''];
        List<String> words = text.split(' ');
        List<String> lines = [];
        String currentLine = '';

        for (String word in words) {
          if (word.isEmpty) continue;
          if (word.length > maxLength) {
            if (currentLine.isNotEmpty) {
              lines.add(currentLine);
              currentLine = '';
            }
            int start = 0;
            while (start < word.length) {
              int end = start + maxLength;
              if (end > word.length) end = word.length;
              lines.add(word.substring(start, end));
              start = end;
            }
            continue;
          }

          if (currentLine.isEmpty) {
            currentLine = word;
          } else if (currentLine.length + 1 + word.length <= maxLength) {
            currentLine += ' ' + word;
          } else {
            lines.add(currentLine);
            currentLine = word;
          }
        }
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        return lines.isEmpty ? [''] : lines;
      }

      for (final item in kot.items) {
        final nameLines = wrapText(item.name, 22);

        bytes += generator.row([
          PosColumn(
            width: 2,
            text: index.toString(),
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(
            width: 8,
            text: nameLines.first,
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(
            width: 2,
            text: "x ${item.quantity}",
            styles: const PosStyles(
              align: PosAlign.right,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
        ]);

        for (int i = 1; i < nameLines.length; i++) {
          bytes += generator.row([
            PosColumn(
              width: 2,
              text: "",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
            PosColumn(
              width: 8,
              text: nameLines[i],
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
            PosColumn(
              width: 2,
              text: "",
              styles: const PosStyles(
                align: PosAlign.right,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        }

        if (item.modifiers.isNotEmpty) {
          bytes += generator.row([
            PosColumn(width: 2, text: ""),
            PosColumn(
              width: 10,
              text: " + ${item.modifiers.join(', ')}",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        }

        if (item.addOns.isNotEmpty) {
          item.addOns.forEach((name, details) {
            bytes += generator.row([
              PosColumn(width: 2, text: ""),
              PosColumn(
                width: 10,
                text: "   * $name x${details['quantity']}",
                styles: const PosStyles(
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size1,
                ),
              ),
            ]);
          });
        }

        final note = item.note;
        if (note.isNotEmpty) {
          bytes += generator.row([
            PosColumn(width: 2, text: ""),
            PosColumn(
              width: 10,
              text: " Note: $note",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        }

        bytes += [27, 74, 16];
        index++;
      }

      bytes += [27, 32, 0];
      bytes += generator.hr();
      bytes += generator.feed(3);
      bytes += generator.cut();

      final printerSettings = PrinterSettings();
      await printerSettings.loadPrinter();

      if (printerSettings.selectedPrinter != null) {
        await printerSettings.printTicket(bytes, generator);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No printer selected. Please set up a printer in settings."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("KOT print failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  /// zoneId -> zoneName
  Map<String, String> buildZoneNameMapFromZones(
      List<Map<String, dynamic>> zones) {

    final Map<String, String> zoneNames = {};

    for (final zone in zones) {
      final zoneId = zone['zone_id']?.toString();
      final zoneName = zone['zone_name']?.toString();

      if (zoneId == null || zoneName == null) continue;

      zoneNames[zoneId] = zoneName;
    }

    return zoneNames;
  }

  /// zoneId -> tableNames
  Map<String, List<String>> buildZoneTableMap(
      List<Map<String, dynamic>> tables) {

    final Map<String, List<String>> zoneMap = {};

    for (final table in tables) {
      final zoneId = table['zone_id']?.toString();
      final tableName = table['table_name']?.toString();

      if (zoneId == null || tableName == null) continue;

      zoneMap.putIfAbsent(zoneId, () => []);
      zoneMap[zoneId]!.add(tableName);
    }

    return zoneMap;
  }

  String getDisplayStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'kot processed':
      case 'kot created':
      case 'yet to prepare':
      case 'yet_to_prepare':
        return 'YET TO PREPARE';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      case 'served':
        return 'SERVED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    if (_kots.isEmpty && widget.kots.isEmpty) {
      return const SizedBox.shrink();
    }
    return MultiBlocListener(
      listeners: [
        // Listen to OrderBloc to close dropdown when new item added
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            final currentItemCount = state.orderItems.length;
            if (currentItemCount > _previousOrderItemCount && _expanded) {
              setState(() => _expanded = false);
              // ✅ NEW: report the auto-collapse to the parent
              widget.onToggle?.call(_expanded);
            }
            _previousOrderItemCount = currentItemCount;
          },
        ),
        // ✅ NEW: Refresh KOT list when KOT created
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            // whenever kotList length changes, fetch again
            // (or you can check a success flag)
            if (state.kotList.length > 0) {
              // _fetchKots();
            }
          },
        ),
        // 🔴 FIX: whenever KotBloc emits a fresh list (from _fetchKots(),
        // whether triggered by our own timer, a void action, a transfer,
        // etc.) mirror it into `_kots` so the UI updates live — no manual
        // action required.
        BlocListener<KotBloc, KotState>(
          listener: (context, state) {
            final freshKots = _extractKotsFromState(state);
            if (freshKots != null) {
              setState(() {
                _kots = freshKots;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<KotBloc, KotState>(
        builder: (context, state) {
          // 🔴 FIX: prefer the bloc's live state over the (possibly stale)
          // widget.kots/​_kots mirror, falling back gracefully.
          final sourceKots = _extractKotsFromState(state) ?? _kots;

          final kotList = sourceKots.where((kot) {
            final status = kot.status.toLowerCase().trim();
            return status != 'cancelled' && status != 'cancel';
          }).toList();

          // Initialize expansion state for each KOT
          for (var kot in kotList) {
            _kotExpanded.putIfAbsent(kot.kotId.toString(), () => false);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown header
              GestureDetector(
                onTap: () {
                  setState(() => _expanded = !_expanded);
                  // ✅ NEW: notify parent every time the header is tapped
                  widget.onToggle?.call(_expanded);
                },
                child: Container(
                  height: 30,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4A527A) // Dark mode
                        : const Color(0xFF1A3C71), // Light mode
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(_expanded ? 0 : 8),
                      bottomRight: Radius.circular(_expanded ? 0 : 8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'View All KOTs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Transform.rotate(
                        angle: _expanded ? 3.14 : 0,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded KOT content
              if (_expanded)
              // const SizedBox(height: 10),
                if (_expanded)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: Material(
                      elevation: 8,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF202433)
                              : kCardBg,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF4A527A)
                                : const Color(0xFF1A3C71),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 0,
                              spreadRadius: 0,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: kotList.isEmpty
                            ? const Center(
                          child: Text(
                            "No KOTs Available",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                            : SingleChildScrollView(
                          child: Column(
                            children: kotList.map((kot) {
                              print(
                                'KOT => ${kot.kotNumber} kotStatus => ${kot.status}',
                              );
                              final kotKey = kot.kotId.toString();
                              final isOpen = _kotExpanded[kotKey] ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2F45)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF5A5A5A)
                                        : const Color(0xFFC6D4F5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // ─────────── KOT HEADER (Top Row) ───────────
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _kotExpanded[kotKey] = !isOpen;
                                        });
                                      },
                                      child: Container(
                                        height: 52,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF34384F)
                                              : const Color(0xffEEF2FF),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(14),
                                            topRight: Radius.circular(14),
                                            bottomLeft: Radius.circular(isOpen ? 0 : 14),
                                            bottomRight: Radius.circular(isOpen ? 0 : 14),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            /// KOT Number
                                            Container(
                                              padding:  EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff0D47A1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                (kot.kotNumber?.isNotEmpty ?? false)
                                                    ? kot.kotNumber!
                                                    : "KOT#${kot.kotId}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            /// Time and Print Icon
                                            Row(
                                              children: [
                                                Text(
                                                  DateFormat('hh:mm a').format(kot.time),
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () => _printKot(kot),
                                                  child: const Icon(
                                                    Icons.print_outlined,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            /// Status
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.black87
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _getStatusColor(kot.status),
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height: 8,
                                                    width: 8,
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(kot.status),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    getDisplayStatus(kot.status),
                                                    style: TextStyle(
                                                      color: _getStatusColor(kot.status),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            /// Void Button
                                            InkWell(
                                              onTap: () async {
                                                if (kot.kotId == null) {
                                                  debugPrint("❌ kotId is null");
                                                  return;
                                                }

                                                final bloc = context.read<KotLineItemsBloc>();

                                                bloc.add(
                                                  FetchKotLineItems(
                                                    kotId: kot.kotId!,
                                                    restaurantId: widget.restaurantId,
                                                    zoneId: widget.zoneId,
                                                    token: widget.token,
                                                  ),
                                                );

                                                final state = await bloc.stream.firstWhere(
                                                      (state) =>
                                                  state is KotLineItemsLoaded ||
                                                      state is KotLineItemsError,
                                                );

                                                if (!context.mounted) return;

                                                if (state is KotLineItemsLoaded) {
                                                  final response = state.response;

                                                  await showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) {
                                                      return MultiBlocProvider(
                                                        providers: [
                                                          BlocProvider.value(
                                                            value: context.read<UpdatekotBloc>(),
                                                          ),
                                                          BlocProvider.value(
                                                            value: context.read<KotBloc>(),
                                                          ),
                                                        ],
                                                        child: VoidItemsDialog(
                                                          items: response.items,
                                                          tableNo: widget.tableNo,
                                                          kotNo: response.kotNumber,
                                                          kotId: response.kotId,
                                                          restaurantId: response.restaurantId,
                                                          zoneId: response.zoneId,
                                                          token: widget.token,
                                                          parentOrderId:
                                                          context.read<KotBloc>().currentParentOrderId,
                                                          item: kot,
                                                          onRemark: (value) {
                                                            debugPrint(value);
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                                  // 🔴 FIX: after the void dialog closes (whatever the
                                                  // outcome), immediately refetch so the status/strike-through
                                                  // reflects without needing another manual action.
                                                  if (context.mounted) {
                                                    _fetchKots();
                                                  }
                                                } else if (state is KotLineItemsError) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(state.message),
                                                      duration: const Duration(seconds: 1),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                height: 28,
                                                width: 28,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    "assets/icon/Void.png",
                                                    height: 18,
                                                    width: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            /// Transfer Button
                                            InkWell(
                                              onTap: () async {
                                                debugPrint("🔥 STEP 0: Transfer KOT button tapped");

                                                try {
                                                  final token = await SessionManager.getToken();
                                                  if (token == null || token.isEmpty) return;

                                                  final transferItems = kot.items.map((e) {
                                                    return TransferKotItem(
                                                      name: e.itemName ?? "",
                                                      note: e.note.isNotEmpty
                                                          ? e.note
                                                          : (e.modifiers.isNotEmpty
                                                          ? e.modifiers.join(", ")
                                                          : ""),
                                                      qty: e.quantity ?? 1,
                                                      amount: e.totalWithAddons,
                                                    );
                                                  }).toList();

                                                  final zoneRepository = ZoneRepository();
                                                  final zoneResponse = await zoneRepository.getAllZones(token);

                                                  final Map<String, String> zoneNames =
                                                  extractZoneNames(zoneResponse);

                                                  final tableRepository = TableRepository();
                                                  final tableResponse =
                                                  await tableRepository.getAllTables(token);

                                                  final Map<String, List<String>> zoneTables = {};
                                                  final Map<String, int> tableIds = {};
                                                  final Map<String, int> zoneIds = {};
                                                  final Map<String, String> tableStatus = {};

                                                  for (final table in tableResponse) {
                                                    final zoneId = table['zone_id'];
                                                    final tableName = table['table_name'];
                                                    final tableId = table['table_id'];
                                                    final status = table['status'];

                                                    if (zoneId != null && tableName != null) {
                                                      zoneTables.putIfAbsent(zoneId.toString(), () => []);
                                                      zoneTables[zoneId.toString()]!.add(tableName);
                                                    }

                                                    if (tableName != null && tableId != null) {
                                                      tableIds[tableName] = tableId;
                                                    }

                                                    if (zoneId != null) {
                                                      zoneIds[zoneId.toString()] = zoneId;
                                                    }

                                                    if (tableName != null && status != null) {
                                                      tableStatus[tableName] = status;
                                                    }
                                                  }

                                                  String getZoneFromTable(
                                                      String tableName,
                                                      Map<String, List<String>> zoneTables) {
                                                    for (final entry in zoneTables.entries) {
                                                      if (entry.value.contains(tableName)) {
                                                        return entry.key;
                                                      }
                                                    }
                                                    return '';
                                                  }

                                                  final kotZone =
                                                  getZoneFromTable(widget.tableNo, zoneTables);

                                                  final result = await showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) => BlocProvider(
                                                      create: (_) => TransferKotBloc(
                                                        repository: KotTransferRepository(),
                                                      ),
                                                      child: TransferKOTDialog(
                                                        tableName: widget.tableNo,
                                                        kotNo: (kot.kotNumber?.isNotEmpty ?? false)
                                                            ? kot.kotNumber!
                                                            : "KOT#${kot.kotId}",
                                                        dateTime: kot.time ?? DateTime.now(),
                                                        items: transferItems,
                                                        zoneTables: zoneTables,
                                                        orderId: widget.parentOrderId!,
                                                        kotId: kot.kotId!,
                                                        fromTableId: tableIds[widget.tableNo]!,
                                                        restaurantId: widget.restaurantId!,
                                                        authToken: widget.token,
                                                        zoneIds: zoneIds,
                                                        tableIds: tableIds,
                                                        tableStatus: tableStatus,
                                                        kotZone: kotZone,
                                                        zoneNames: zoneNames,
                                                      ),
                                                    ),
                                                  );

                                                  if (result != null) {
                                                    context.read<KotBloc>().add(
                                                      FetchKots(
                                                        parentOrderId: widget.parentOrderId,
                                                        restaurantId: widget.restaurantId!,
                                                        zoneId: widget.zoneId,
                                                        token: widget.token,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint(e.toString());
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                height: 28,
                                                width: 28,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4CAF50),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    "assets/transfer.png",
                                                    height: 14,
                                                    width: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            /// Expand Icon
                                            Icon(
                                              isOpen
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // ─────────── KOT BODY ───────────
                                    if (isOpen)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 45,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              decoration:  BoxDecoration(
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [

                                                  Text(
                                                    "Total Items: ${kot.items.length}",
                                                    style: TextStyle(
                                                      color: isDark ? const Color(0xFFE2ECFA) : const Color(0xff5a81bd),
                                                      // color: Color(0xff5a81bd),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),

                                                  Text(
                                                    kot.items
                                                        .fold<double>(
                                                        0,
                                                            (sum,e)=>sum+(e.totalWithAddons??0))
                                                        .toStringAsFixed(2),
                                                    style: TextStyle(
                                                      color: isDark ? const Color(0xFFE2ECFA) : const Color(0xff5a81bd),

                                                      // color: Color(0xff0D47A1),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize:18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // const SizedBox(height: 10),
                                            // Items Table Container
                                            Container(
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                                borderRadius: const BorderRadius.only(
                                                  bottomLeft: Radius.circular(10),
                                                  bottomRight: Radius.circular(10),
                                                ),
                                                border: Border(
                                                  top: BorderSide(
                                                    color: isDark
                                                        ? const Color(0xFF5A5A5A)
                                                        : const Color(0xFFE4E4E4),
                                                    width: 1,
                                                  ),
                                                  bottom: BorderSide(
                                                    color: isDark
                                                        ? const Color(0xFF5A5A5A)
                                                        : const Color(0xFFE4E4E4),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  ...kot.items.asMap().entries.map((entry) {
                                                    final index = entry.key;
                                                    final item = entry.value;

                                                    // ✅ CHECK IF ITEM IS CANCELLED
                                                    final bool isCancelled = (item.isCancelled?.toLowerCase() == 'yes');

                                                    return Column(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 5,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: isCancelled ? Colors.red.shade50 : Colors.transparent,
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: isCancelled
                                                                ? Border.all(color: Colors.red.shade200, width: 0.5)
                                                                : null,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              // Serial Number
                                                              SizedBox(
                                                                width: 30,
                                                                child: Text(
                                                                  "${index + 1}",
                                                                  style: TextStyle(
                                                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                                    color: isCancelled
                                                                        ? Colors.red.shade700
                                                                        : (isDark ? Colors.white : Colors.black87),
                                                                    fontWeight: isCancelled ? FontWeight.w700 : FontWeight.w500,
                                                                    fontSize: isCancelled ? 13 : 14,
                                                                  ),
                                                                ),
                                                              ),

                                                              // Item Name
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Text(
                                                                      item.itemName ?? item.name ?? '',
                                                                      style: TextStyle(
                                                                        fontSize: 14,
                                                                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                                        color: isCancelled
                                                                            ? Colors.red.shade700
                                                                            : (isDark ? Colors.white : Colors.black87),
                                                                        fontWeight: isCancelled ? FontWeight.w600 : FontWeight.normal,
                                                                      ),
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),

                                                                    // Modifiers
                                                                    if ((item.modifiers ?? []).isNotEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(top: 2),
                                                                        child: Wrap(
                                                                          spacing: 4,
                                                                          runSpacing: 2,
                                                                          children: item.modifiers!
                                                                              .map(
                                                                                (modifier) => Text(
                                                                              modifier,
                                                                              style: TextStyle(
                                                                                fontSize: 11,
                                                                                color: isCancelled
                                                                                    ? Colors.red.shade400
                                                                                    : (isDark ? Colors.white70 : Colors.blueGrey),
                                                                                fontStyle: FontStyle.italic,
                                                                                decoration: isCancelled
                                                                                    ? TextDecoration.lineThrough
                                                                                    : null,
                                                                              ),
                                                                            ),
                                                                          )
                                                                              .toList(),
                                                                        ),
                                                                      ),

                                                                    // Add-ons
                                                                    if (item.addOns != null && item.addOns!.isNotEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(top: 2),
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: item.addOns!.entries.map((entry) {
                                                                            final addon = entry.value;

                                                                            return Text(
                                                                              "+ ${entry.key}"
                                                                                  "${addon['quantity'] != null ? ' x${addon['quantity']}' : ''}"
                                                                              // "${addon['price'] != null ? ' (₹${addon['price']})' : ''}",
                                                                                  "${addon['price'] != null ? ' ($_currency${addon['price']})' : ''}",
                                                                              style: TextStyle(
                                                                                fontSize: 11,
                                                                                color: isCancelled
                                                                                    ? Colors.red.shade400
                                                                                    : Colors.green.shade700,
                                                                                decoration: isCancelled
                                                                                    ? TextDecoration.lineThrough
                                                                                    : null,
                                                                              ),
                                                                            );
                                                                          }).toList(),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),

                                                              // Quantity
                                                              SizedBox(
                                                                width: 40,
                                                                child: Center(
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      color: isCancelled ? Colors.red.shade100 : Colors.transparent,
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                    padding: isCancelled ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : null,
                                                                    child: Text(
                                                                      "${item.quantity ?? 0}",
                                                                      style: TextStyle(
                                                                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                                        color: isCancelled
                                                                            ? Colors.red.shade700
                                                                            : (isDark ? Colors.white : Colors.black87),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),

                                                              // Amounts
                                                              SizedBox(
                                                                width: 80,
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                                  children: [
                                                                    Text(
                                                                      // (item.totalWithAddons ?? 0).toStringAsFixed(2),
                                                                      "$_currency${(item.totalWithAddons ?? 0).toStringAsFixed(2)}",
                                                                      style: TextStyle(
                                                                        fontWeight: isCancelled ? FontWeight.w800 : FontWeight.bold,
                                                                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                                        color: isCancelled
                                                                            ? Colors.red.shade700
                                                                            : (isDark ? Colors.white : Colors.black87),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      "$_currency${(item.amount ?? 0).toStringAsFixed(2)}",
                                                                      // (item.amount ?? 0).toStringAsFixed(2),
                                                                      style: TextStyle(
                                                                        fontSize: 11,
                                                                        color: isCancelled
                                                                            ? Colors.red.shade700
                                                                            : (isDark ? Colors.white : Colors.black87),
                                                                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (index != kot.items.length - 1)
                                                          Divider(
                                                            color: isDark
                                                                ? const Color(0xFF444A63)
                                                                : const Color(0xffECECEC),
                                                          )
                                                      ],
                                                    );                                                }),
                                                ],
                                              ),
                                            ),
                                            // Container(
                                            //   height: 52,
                                            //   padding: const EdgeInsets.symmetric(horizontal: 18),
                                            //   decoration: const BoxDecoration(
                                            //     color: Colors.white,
                                            //   ),
                                            //   child: Row(
                                            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            //     children: [
                                            //
                                            //       Text(
                                            //         "Total Items: ${kot.items.length}",
                                            //         style: const TextStyle(
                                            //           color: Color(0xff0D47A1),
                                            //           fontWeight: FontWeight.bold,
                                            //           fontSize: 16,
                                            //         ),
                                            //       ),
                                            //
                                            //       Text(
                                            //         kot.items
                                            //             .fold<double>(
                                            //             0,
                                            //                 (sum,e)=>sum+(e.totalWithAddons??0))
                                            //             .toStringAsFixed(2),
                                            //         style: const TextStyle(
                                            //           color: Color(0xff0D47A1),
                                            //           fontWeight: FontWeight.bold,
                                            //           fontSize:18,
                                            //         ),
                                            //       ),
                                            //     ],
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  // 🔴 FIX: single place to pull a fresh List<KotModel> out of KotState,
  // whatever its concrete success subclass is called. Adjust the class
  // name / field name below to match your actual kot_state.dart if it
  // differs from this guess (e.g. `KotLoaded`, `KotFetchSuccess`, etc.
  // with a `.kots` field).
  List<KotModel>? _extractKotsFromState(KotState state) {
    try {
      final dynamic dynState = state;
      final dynamic maybeKots = dynState.kots;
      if (maybeKots is List<KotModel>) {
        return maybeKots;
      }
    } catch (_) {
      // state doesn't carry a `.kots` field (e.g. Loading/Initial/Error) —
      // fall back to whatever we already have.
    }
    return null;
  }

  Widget _kotActionButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Image.asset(
          "assets/icon/Void.png",
          height: 16,
          width: 16,
          color: iconColor,
        ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

  }
}