import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
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
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
    // Safety: if for any reason data is missing, request it once
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final state = context.read<KotsListBloc>().state;
    //   if (state is! KotsListLoaded) {
    //     context.read<KotsListBloc>().add(
    //       FetchKotsList(
    //         parentOrderId: widget.parentOrderId,
    //         restaurantId: widget.restaurantId,
    //         zoneId: widget.zoneId,
    //       ),
    //     );
    //   }
    // });

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

  Future<void> _loadCurrencySymbol() async {
    try {
      final symbol = await context.read<CaptainLocalStorage>().getCurrencySymbol();
      if (symbol != null && mounted) {
        setState(() {
          _currencySymbol = symbol;
        });
        print('🪙 KotsListWidget currency symbol: $symbol');
      }
    } catch (_) {}
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
        if (state is KotsListLoaded) {
          final kots = state.kots;

          if (kots.isEmpty) {
            return _emptyBox('No KOTs found for this order.');
          }

          // return Container(
          //   clipBehavior: Clip.antiAlias, // 👈 clips children so header corners follow the container radius instead of showing white square corners
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(8),
          //     // 👈 Fixed: border removed entirely per request — no border color, just white
          //   ),
          //   child: Column(
          //     children: [
          //       for (int i = 0; i < kots.length; i++) ...[
          //         if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
          //         _KotExpansionTile(
          //           kot: kots[i],
          //           currencySymbol: _currencySymbol, // 👈 pass symbol
          //         ),
          //       ],
          //     ],
          //   ),
          // );
          return Column(
            children: [
              for (int i = 0; i < kots.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _KotExpansionTile(
                    kot: kots[i],
                    currencySymbol: _currencySymbol,
                  ),
                ),
              ],
            ],
          );

        }

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


class _KotExpansionTile extends StatefulWidget {
  final KotOrder kot;
  final String currencySymbol;

  const _KotExpansionTile({
    required this.kot,
    required this.currencySymbol,
  });

  @override
  State<_KotExpansionTile> createState() => _KotExpansionTileState();
}

class _KotExpansionTileState extends State<_KotExpansionTile> {
  bool _expanded = false;

  static const Color _kotCollapsedBg = Color(0xFFFCE4D6);   // light peach
  static const Color _kotCollapsedText = Color(0xFFE8600C); // orange
  static const Color _kotExpandedBg = Color(0xFF2B3358);    // dark navy
  static const Color _kotExpandedText = Colors.white;

  @override
  Widget build(BuildContext context) {
    final kot = widget.kot;
    final hasItems = kot.lineItems.isNotEmpty;

    // 👇 Rebuilt without ExpansionTile: ExpansionTile's internal ListTile
    // always reserves space for a trailing-icon area even when trailing is
    // SizedBox.shrink(), which was leaving a white gap on the right of the
    // header. A plain Column + GestureDetector header gives full,
    // guaranteed edge-to-edge width with no reserved icon space.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header (tap to expand/collapse) ──
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            color: _expanded ? _kotExpandedBg : _kotCollapsedBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _expanded
                        ? '${kot.kotNumber}   ${kot.time}'
                        : kot.kotNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _expanded ? _kotExpandedText : _kotCollapsedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: _expanded ? _kotExpandedText : _kotCollapsedText,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body (animates open/closed) ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
          crossFadeState:
          _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: !hasItems
              ? Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'No items in this KOT',
              style: TextStyle(
                fontSize: 13,
                color: ColorConstants.hintColor,
              ),
            ),
          )
              : Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kot.lineItems.length,
              separatorBuilder: (_, __) => const SizedBox(height:3),
              itemBuilder: (context, index) {
                final item = kot.lineItems[index];
                return _buildItemCard(item, widget.currencySymbol);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Item card (unchanged, border is already good) ───
  Widget _buildItemCard(LineItem item, String currencySymbol) {
    final bool isCancelled = item.isCancelled.toLowerCase() == 'yes';
    final bool isZeroPrice = item.amount == 0;
    final bool shouldStrike = isCancelled || isZeroPrice;

    final double unitPrice =
    item.originalPrice > 0 ? item.originalPrice : item.price;
    final double displayPrice = unitPrice * item.quantity;

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: shouldStrike
            ? ColorConstants.errorColor.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: shouldStrike
              ? ColorConstants.errorColor.withOpacity(0.25)
              : Colors.grey.shade300, // visible soft border
        ),
        boxShadow: shouldStrike
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: shouldStrike
                        ? ColorConstants.errorColor
                        : ColorConstants.textColor,
                    decoration:
                    shouldStrike ? TextDecoration.lineThrough : null,
                    decorationColor: ColorConstants.errorColor,
                    decorationThickness: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: shouldStrike
                          ? ColorConstants.errorColor.withOpacity(0.7)
                          : ColorConstants.hintColor,
                      decoration:
                      shouldStrike ? TextDecoration.lineThrough : null,
                      decorationColor: ColorConstants.errorColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: shouldStrike
                        ? ColorConstants.errorColor.withOpacity(0.7)
                        : ColorConstants.hintColor,
                    decoration:
                    shouldStrike ? TextDecoration.lineThrough : null,
                    decorationColor: ColorConstants.errorColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$currencySymbol${unitPrice.toStringAsFixed(2)} ×${item.quantity}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: shouldStrike
                      ? ColorConstants.errorColor.withOpacity(0.7)
                      : ColorConstants.hintColor,
                  decoration:
                  shouldStrike ? TextDecoration.lineThrough : null,
                  decorationColor: ColorConstants.errorColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currencySymbol${displayPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: shouldStrike
                      ? ColorConstants.errorColor
                      : ColorConstants.textColor,
                  decoration:
                  shouldStrike ? TextDecoration.lineThrough : null,
                  decorationColor: ColorConstants.errorColor,
                  decorationThickness: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}