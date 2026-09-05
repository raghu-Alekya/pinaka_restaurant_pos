import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_captain_app/constants/color_constants.dart';
import 'package:restaurant_captain_app/features/home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
import 'package:restaurant_captain_app/features/home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_state.dart';
import 'package:restaurant_captain_app/features/home_screen/All_tables_list/All_tables_list_domain/all_tables_list_entity.dart';
import 'package:restaurant_captain_app/features/home_screen/Zones/Zones_bloc/zone_state.dart';
import 'package:restaurant_captain_app/features/home_screen/Zones/Zones_bloc/zones_bloc.dart';
import 'package:restaurant_captain_app/features/home_screen/Zones/zones_domain/zone_entity.dart';
import 'package:restaurant_captain_app/features/transfer_kot/transfer_kot_domani/transfer_kot_usecase.dart';

import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../kots_list/kots_list_domin/kots_list_usecase.dart';
import '../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';

// ─── Status handling (mirrors main TableManagement screen) ──────────
enum _TableStatusKind { available, running, readyToSettle, occupied }

_TableStatusKind _statusKind(String rawStatus) {
  final s = rawStatus.toLowerCase().trim();
  if (s == 'dine in' || s == 'dine-in' || s == 'running') {
    return _TableStatusKind.running;
  }
  if (s == 'ready to pay' || s == 'ready to settle') {
    return _TableStatusKind.readyToSettle;
  }
  if (s == 'occupied') {
    return _TableStatusKind.occupied;
  }
  return _TableStatusKind.available;
}

String _statusLabel(_TableStatusKind kind) {
  switch (kind) {
    case _TableStatusKind.running:
      return 'Running';
    case _TableStatusKind.readyToSettle:
      return 'Ready to pay';
    case _TableStatusKind.occupied:
      return 'Occupied';
    case _TableStatusKind.available:
      return 'Available';
  }
}

Color _statusColor(_TableStatusKind kind) {
  switch (kind) {
    case _TableStatusKind.running:
      return const Color(0xFFE64545);
    case _TableStatusKind.readyToSettle:
      return const Color(0xFF3B7DDB);
    case _TableStatusKind.occupied:
      return const Color(0xFFE8B93A);
    case _TableStatusKind.available:
      return const Color(0xFF34A853);
  }
}

// ─── Custom dashed border painter ──────────────────────────────────────────
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        final double extent = next.clamp(0, metric.length).toDouble();
        if (extent > distance) {
          final segment = metric.extractPath(distance, extent);
          canvas.drawPath(segment, paint);
        }
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const DashedBorder({
    Key? key,
    required this.child,
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: child,
    );
  }
}

// ─── TransferKotBottomSheet ──────────────────────────────────────────────

class TransferKotBottomSheet extends StatefulWidget {
  final int orderId;
  final int fromTableId;
  final int restaurantId;
  final int zoneId;
  final VoidCallback onSuccess;

  const TransferKotBottomSheet({
    Key? key,
    required this.orderId,
    required this.fromTableId,
    required this.restaurantId,
    required this.zoneId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<TransferKotBottomSheet> createState() => _TransferKotBottomSheetState();
}

class _TransferKotBottomSheetState extends State<TransferKotBottomSheet> {
  List<KotOrder> _kots = [];
  int? _selectedKotId;
  bool _kotsLoaded = false;
  String? _kotError;

  List<ZoneEntity> _zones = [];
  List<TableEntity> _tables = [];
  bool _tablesLoaded = false;

  bool _transferring = false;

  // ─── Currency symbol ────────────────────────────────────────────────────
  final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier<String>('\$');

  @override
  void initState() {
    super.initState();
    _fetchKots();
    _loadTablesFromBloc();
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    try {
      final symbol = await context.read<CaptainLocalStorage>().getCurrencySymbol();
      if (symbol != null && mounted) {
        _currencySymbolNotifier.value = symbol;
        print('🪙 Transfer KOT currency symbol: $symbol');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _currencySymbolNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchKots() async {
    try {
      final useCase = context.read<KotsListUseCase>();
      final kots = await useCase(
        parentOrderId: widget.orderId,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
      );
      setState(() {
        _kots = kots;
        _kotsLoaded = true;
        if (_kots.isNotEmpty) {
          _selectedKotId = _kots.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _kotError = e.toString();
        _kotsLoaded = true;
      });
    }
  }

  void _loadTablesFromBloc() {
    final zoneState = context.read<ZoneBloc>().state;

    if (zoneState is ZoneLoaded) {
      _zones = zoneState.zones;
    }

    final tableState = context.read<AllTablesBloc>().state;

    if (tableState is AllTablesLoaded) {
      final allTables = tableState.tables;

      final filteredTables = allTables.where((table) {
        final status = table.status?.toLowerCase().trim() ?? '';

        return table.zoneId == widget.zoneId &&
            status.isNotEmpty &&
            status != 'available' &&
            status != 'ready to pay' &&
            status != 'ready to settle' &&
            table.tableId != widget.fromTableId;
      }).toList();

      _tables = filteredTables;
      _tablesLoaded = true;
    } else {
      _tablesLoaded = false;
    }
  }

  Future<void> _transferKot(int toTableId) async {
    if (_selectedKotId == null || _transferring) return;
    setState(() => _transferring = true);
    try {
      final useCase = context.read<TransferKotUseCase>();
      await useCase(
        orderId: widget.orderId,
        kotId: _selectedKotId!,
        fromTableId: widget.fromTableId,
        toTableId: toTableId,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
      );
      if (!mounted) return;
      widget.onSuccess();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KOT transferred successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('════════════ TRANSFER KOT ERROR ═════════════');
      debugPrint('Error: $e');
      debugPrint('orderId: ${widget.orderId}');
      debugPrint('kotId: $_selectedKotId');
      debugPrint('fromTableId: ${widget.fromTableId}');
      debugPrint('toTableId: $toTableId');
      debugPrint('restaurantId: ${widget.restaurantId}');
      debugPrint('zoneId: ${widget.zoneId}');
      debugPrint('════════════════════════════════════════════');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.red),
      // );
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Transfer KOT',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // ── KOT Selection Section ──
              if (!_kotsLoaded)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Loading KOTs...')),
                )
              else if (_kotError != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Error: $_kotError', style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _fetchKots,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_kots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No KOTs found for this order.'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID
                        Text(
                          'Order ID: #${widget.orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Horizontal KOT list
                        ValueListenableBuilder<String>(
                          valueListenable: _currencySymbolNotifier,
                          builder: (context, currencySymbol, _) {
                            return SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _kots.length,
                                itemBuilder: (_, index) {
                                  final kot = _kots[index];
                                  final selected = _selectedKotId == kot.id;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedKotId = kot.id),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected ? ColorConstants.primaryColor : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selected ? ColorConstants.primaryColor : Colors.transparent,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            kot.kotNumber,
                                            style: TextStyle(
                                              color: selected ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$currencySymbol${kot.total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: selected ? Colors.white70 : Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

              // ── Table Grid ──
              if (_selectedKotId != null) ...[
                const Divider(),
                Expanded(
                  child: !_tablesLoaded
                      ? const Center(
                    child: Text(
                      'Loading tables...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : _tables.isEmpty
                      ? const Center(
                    child: Text('No occupied tables available in this zone to transfer to.'),
                  )
                      : _buildTableGrid(scrollController),
                ),
              ],
              if (_transferring)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableGrid(ScrollController scrollController) {
    final Map<int, List<TableEntity>> tablesByZone = {};
    final Map<int, ZoneEntity> zoneMap = {for (var z in _zones) z.zoneId!: z};

    for (final table in _tables) {
      final zoneId = table.zoneId ?? 0;
      tablesByZone.putIfAbsent(zoneId, () => []).add(table);
    }

    return ValueListenableBuilder<String>(
      valueListenable: _currencySymbolNotifier,
      builder: (context, currencySymbol, _) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: tablesByZone.entries.map((entry) {
            final zone = zoneMap[entry.key];
            final tables = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (zone != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      zone.zoneName ?? 'Unnamed Zone',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (_, index) {
                    final table = tables[index];
                    return _TransferTableCard(
                      table: table,
                      currencySymbol: currencySymbol,
                      onTap: () => _transferKot(table.tableId!),
                    );
                  },
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Table Card with Dashed Border + Order Amount / Image ──────────────

class _TransferTableCard extends StatelessWidget {
  final TableEntity table;
  final String currencySymbol;
  final VoidCallback onTap;

  const _TransferTableCard({
    required this.table,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = table.status ?? 'Occupied';
    final kind = _statusKind(status);
    final color = _statusColor(kind);
    final label = _statusLabel(kind);

    // Parse order amount (may be null, empty, or "0")
    double? orderAmount;
    if (table.orderAmount != null && table.orderAmount!.isNotEmpty) {
      orderAmount = double.tryParse(table.orderAmount!.replaceAll(',', ''));
    }
    final hasOrderAmount = orderAmount != null && orderAmount > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: DashedBorder(
        color: color,
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table name
              Text(
                table.tableName ?? 'Unnamed',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              // Order amount OR table image
              if (hasOrderAmount)
                Text(
                  '$currencySymbol${orderAmount!.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              else
                Image.asset(
                  'assets/images/Table_img.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  color: color,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.table_restaurant_outlined,
                    color: color,
                    size: 30,
                  ),
                ),
              const SizedBox(height: 6),
              // Status label
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}