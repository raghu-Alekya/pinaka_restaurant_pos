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

import '../kots_list/kots_list_domin/kots_list_usecase.dart';
import '../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchKots();
    _loadTablesFromBloc();
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
        _kotsLoaded = true; // show error message
      });
    }
  }

  void _loadTablesFromBloc() {
    // Read zones from ZoneBloc
    final zoneState = context.read<ZoneBloc>().state;
    if (zoneState is ZoneLoaded) {
      _zones = zoneState.zones;
    }

    // Read tables from AllTablesBloc
    final tableState = context.read<AllTablesBloc>().state;
    if (tableState is AllTablesLoaded) {
      final allTables = tableState.tables;
      final filteredTables = allTables.where((table) {
        final status = table.status?.toLowerCase() ?? '';
        return table.zoneId == widget.zoneId &&
            status != 'available' &&
            status.isNotEmpty &&
            table.tableId != widget.fromTableId;
      }).toList();
      _tables = filteredTables;
      _tablesLoaded = true;
    } else {
      // If not loaded yet, we'll show a message
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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

              // KOT selection – no spinner, just text
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
                else if (_kots.length > 1)
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    '\$${kot.total.toStringAsFixed(2)}',
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
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('KOT: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(_kots.first.kotNumber),
                          const Spacer(),
                          Text('\$${_kots.first.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),

              // Table grid – no spinner, just content or message
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
                final status = table.status ?? 'Occupied';
                final color = status.toLowerCase() == 'dine in'
                    ? const Color(0xFFE64545)
                    : status.toLowerCase() == 'ready to pay'
                    ? const Color(0xFF3B7DDB)
                    : const Color(0xFFE8B93A);
                return _TransferTableCard(
                  tableName: table.tableName ?? 'Unnamed',
                  status: status,
                  color: color,
                  onTap: () => _transferKot(table.tableId!),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _TransferTableCard extends StatelessWidget {
  final String tableName;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _TransferTableCard({
    required this.tableName,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tableName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              Icons.table_restaurant_outlined,
              color: color,
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}