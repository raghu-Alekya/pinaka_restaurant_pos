import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/color_constants.dart';
import '../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';
import 'kots_list_bloc/kots_list_bloc.dart';
import 'kots_list_bloc/kots_list_event.dart';
import 'kots_list_bloc/kots_list_state.dart';

class KotsListWidget extends StatefulWidget {
  final int parentOrderId;
  final int restaurantId;
  final int zoneId;
  final ValueChanged<bool>? onHasKotsChanged;

  const KotsListWidget({
    Key? key,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    this.onHasKotsChanged,
  }) : super(key: key);

  @override
  State<KotsListWidget> createState() => _KotsListWidgetState();
}

class _KotsListWidgetState extends State<KotsListWidget> {
  @override
  void initState() {
    super.initState();
    // Safety: if for any reason data is missing, request it once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<KotsListBloc>().state;
      if (state is! KotsListLoaded) {
        context.read<KotsListBloc>().add(
          FetchKotsList(
            parentOrderId: widget.parentOrderId,
            restaurantId: widget.restaurantId,
            zoneId: widget.zoneId,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KotsListBloc, KotsListState>(
      listener: (context, state) {
        if (state is KotsListLoaded) {
          widget.onHasKotsChanged?.call(state.kots.isNotEmpty);
        }
      },
      builder: (context, state) {
        // ---------- Already have data → show immediately (no flicker) ----------
        if (state is KotsListLoaded) {
          final kots = state.kots;

          if (kots.isEmpty) {
            return _emptyBox('No KOTs found for this order.');
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (int i = 0; i < kots.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                  _KotExpansionTile(kot: kots[i]),
                ],
              ],
            ),
          );
        }

        // ---------- Error ----------
        if (state is KotsListError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error: ${state.message}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                TextButton(
                  onPressed: () {
                    context.read<KotsListBloc>().add(
                      FetchKotsList(
                        parentOrderId: widget.parentOrderId,
                        restaurantId: widget.restaurantId,
                        zoneId: widget.zoneId,
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // ---------- Loading / Initial → show nothing (or a tiny placeholder) ----------
        // Because we pre-fetch in CartScreen, this state is almost never seen.
        return const SizedBox.shrink();
      },
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }
}

// ---------- Expandable KOT (header + item cards) ----------
class _KotExpansionTile extends StatefulWidget {
  final KotOrder kot;

  const _KotExpansionTile({required this.kot});

  @override
  State<_KotExpansionTile> createState() => _KotExpansionTileState();
}

class _KotExpansionTileState extends State<_KotExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final kot = widget.kot;
    final hasItems = kot.lineItems.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        collapsedBackgroundColor: const Color(0xFFFFF0E8),
        backgroundColor: const Color(0xFF2C3E50),
        iconColor: _expanded ? Colors.white : Colors.grey.shade700,
        collapsedIconColor: Colors.grey.shade700,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          _expanded ? '${kot.kotNumber}   ${kot.time}' : kot.kotNumber,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _expanded ? Colors.white : Colors.black87,
          ),
        ),
        trailing: AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: _expanded ? Colors.white : Colors.grey.shade700,
          ),
        ),
        children: [
          if (!hasItems)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Text(
                'No items in this KOT',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          else
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(), // ✅ enables scrolling
                itemCount: kot.lineItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = kot.lineItems[index];
                  return _buildItemCard(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Item card matching the screenshot ----------
  Widget _buildItemCard(LineItem item) {
    // final isCancelled = item.isCancelled.toLowerCase() == 'yes';

    // Build modifier / combo subtitle
    String subtitle = '';
    if (item.modifiers.isNotEmpty) {
      subtitle = item.modifiers
          .map((m) => m is Map ? (m['name'] ?? m.toString()) : m.toString())
          .join(', ');
    } else if (item.combos.isNotEmpty) {
      subtitle = item.combos
          .map((c) => c is Map ? (c['name'] ?? c.toString()) : c.toString())
          .join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Food image (placeholder – replace with real image if available)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 52,
              height: 52,
              color: Colors.grey.shade200,
              child: Icon(Icons.restaurant, size: 24, color: Colors.grey.shade400),
              // If your LineItem / product has image URL later:
              // child: Image.network(item.imageUrl, fit: BoxFit.cover,
              //   errorBuilder: (_, __, ___) => Icon(...)),
            ),
          ),
          const SizedBox(width: 12),

          // Name + modifier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    // decoration: isCancelled ? TextDecoration.lineThrough : null,
                    // color: isCancelled ? Colors.grey : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ×',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    // color: isCancelled ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Price
          Text(
            '\$${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              // color: isCancelled ? Colors.grey : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}