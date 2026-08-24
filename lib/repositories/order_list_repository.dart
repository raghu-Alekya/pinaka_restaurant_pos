import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order_list/edit_order_list_model.dart';
import '../models/order_list/order_list_model.dart';
import '../utils/logger.dart';

List<OrderlistModel> _parseOrdersJson(String responseBody) {
  final dynamic jsonResponse = jsonDecode(responseBody);
  List<dynamic> dataList = [];

  if (jsonResponse is List) {
    dataList = jsonResponse;
  } else if (jsonResponse is Map<String, dynamic>) {
    if (jsonResponse.containsKey('orders')) {
      dataList = jsonResponse['orders'] as List<dynamic>;
    } else if (jsonResponse.containsKey('data')) {
      dataList = jsonResponse['data'] as List<dynamic>;
    } else {
      return [];
    }
  }
  return dataList
      .map((orderJson) => OrderlistModel.fromJson(orderJson))
      .toList();
}

class OrderstatusRepository {
  static final Map<String, List<OrderlistModel>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  static final Map<String, Future<List<OrderlistModel>>> _inFlightRequests = {};
  // ---------------------------------------------------------------------------

  List<OrderlistModel>? getCachedOrders(String cacheKey) {
    return _cache[cacheKey];
  }

  OrderlistModel? findCachedOrder(int orderId) {
    if (orderId == 0) return null;
    for (final list in _cache.values) {
      for (final o in list) {
        if (o.orderId == orderId) return o;
      }
    }
    return null;
  }

  /// Fetch all orders with detailed KOT and line item info
  Future<List<OrderlistModel>> fetchOrders(
    String token, {
    String? date,
    String? restaurantId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = "${restaurantId ?? ''}_${date ?? ''}";

    // ---------------- CACHE-FIRST CHECK ----------------
    if (!forceRefresh && _cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      final cachedAt = _cacheTimestamps[cacheKey];
      final isFresh =
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _cacheValidDuration;
      if (isFresh) {
        AppLogger.info('Returning cached orders for key: $cacheKey (instant)');
        return _cache[cacheKey]!;
      }
    }
    // -------------------------------------------------------

    // ---------------- ADDED: reuse an in-flight request for the same key ----------------
    if (!forceRefresh && _inFlightRequests.containsKey(cacheKey)) {
      AppLogger.info('Joining in-flight orders request for key: $cacheKey');
      return _inFlightRequests[cacheKey]!;
    }
    // ----------------------------------------------------------------------------------------

    final future = _doFetchOrders(
      token,
      date: date,
      restaurantId: restaurantId,
      cacheKey: cacheKey,
    );
    _inFlightRequests[cacheKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlightRequests.remove(
        cacheKey,
      ); // ADDED: clear the marker once the request settles
    }
  }

  // ---------------- ADDED: actual network fetch, extracted so it can be shared/awaited ----------------
  Future<List<OrderlistModel>> _doFetchOrders(
    String token, {
    String? date,
    String? restaurantId,
    required String cacheKey,
  }) async {
    var urlStr = AppConstants.getAllOrdersList;
    List<String> queryParams = [];
    if (restaurantId != null && restaurantId.isNotEmpty) {
      queryParams.add('restaurant_id=$restaurantId');
    }
    if (date != null && date.isNotEmpty) {
      queryParams.add('date=$date');
    }
    if (queryParams.isNotEmpty) {
      urlStr += '?${queryParams.join('&')}';
    }
    final uri = Uri.parse(urlStr);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      AppLogger.info('Order API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<OrderlistModel> orders = await compute(_parseOrdersJson, response.body);

        // ── ONLINE ORDER ENRICHMENT ──────────────────────────────────────────
        // For WooCommerce online orders (created via REST API), the Pinaka POS
        // custom endpoint returns empty kot_orders and no line_items.
        // We identify genuine online orders and enrich them in PARALLEL.
        const ck = 'ck_74739e5d026eb9c45628548c65dfa35a057cf0bb';
        const cs = 'cs_41bccfc9f218445664eca0ba008294959f14af49';
        final basicAuth = 'Basic ${base64Encode(utf8.encode('$ck:$cs'))}';
        final baseDomain = AppConstants.baseDomain;

        // Only enrich orders that are genuine online orders (no KOTs, valid ID, and
        // order type or created_via indicates online/WooCommerce origin).
        final enrichIndexes = <int>[];
        for (int i = 0; i < orders.length; i++) {
          final o = orders[i];
          if (o.orderId == null) continue;
          if (o.kotOrders != null && o.kotOrders!.isNotEmpty) continue;

          final ot = (o.orderType ?? '').toLowerCase();
          final createdVia = (o.createdVia ?? '').toLowerCase();

          final isOnline = ot.contains('online') ||
              ot.contains('shop') ||
              ot.contains('woo') ||
              ot.contains('doordash') ||
              ot.contains('ubereats') ||
              ot.contains('delivery') ||
              createdVia == 'online' ||
              createdVia == 'rest-api' ||
              (o.externalOrderId != null && o.externalOrderId!.isNotEmpty);

          if (isOnline) enrichIndexes.add(i);
        }

        // Limit to max 10 most recent online orders to ensure fetch time stays under 1.5 seconds
        final limitedEnrichIndexes = enrichIndexes.take(10).toList();

        if (limitedEnrichIndexes.isNotEmpty) {
          AppLogger.info('Enriching ${limitedEnrichIndexes.length} online orders in parallel...');

          await Future.wait(
            limitedEnrichIndexes.map((i) async {
              final order = orders[i];
              try {
                final wcUrl = Uri.parse('$baseDomain/wp-json/wc/v3/orders/${order.orderId}');
                final wcResp = await http.get(wcUrl, headers: {
                  'Authorization': basicAuth,
                  'Content-Type': 'application/json',
                }).timeout(const Duration(seconds: 2));

                if (wcResp.statusCode == 200) {
                  final wcJson = jsonDecode(wcResp.body) as Map<String, dynamic>;
                  final rawLineItems = wcJson['line_items'] as List?;

                  if (rawLineItems != null && rawLineItems.isNotEmpty) {
                    final mergedJson = <String, dynamic>{
                      'order_id': order.orderId,
                      'order_type': order.orderType?.isNotEmpty == true ? order.orderType : 'Online Order',
                      'status': wcJson['status'] ?? order.status,
                      'date': order.date,
                      'customer_name': order.customerName,
                      'customer_phone': order.customerPhone,
                      'payment_type': order.paymentType,
                      'total': wcJson['total'],
                      'net_payable': wcJson['total'],
                      'gross_total': wcJson['total'],
                      'sub_total': wcJson['total'],
                      'total_tax': wcJson['total_tax'],
                      'restaurant_id': order.restaurantId,
                      'zone_id': order.zoneId,
                      'table_id': order.tableId,
                      'is_parent': true,
                      'kot_orders': [],
                      'line_items': rawLineItems,
                      'billing': wcJson['billing'],
                      'created_via': wcJson['created_via'],
                    };
                    orders[i] = OrderlistModel.fromJson(mergedJson);
                    AppLogger.info('✅ Enriched order #${order.orderId}: total=${wcJson["total"]}, items=${rawLineItems.length}');
                  }
                }
              } catch (e) {
                AppLogger.error('⚠️ Enrich order #${order.orderId} failed (skipping): $e');
              }
            }),
          );
        }
        // ─────────────────────────────────────────────────────────────────────

        _cache[cacheKey] = orders;
        _cacheTimestamps[cacheKey] = DateTime.now();
        AppLogger.info('Fetched ${orders.length} orders successfully');
        return orders;
      } else {
        AppLogger.error(
          'Failed to fetch orders. Status: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in fetchOrders: $e\n$stackTrace');
    }

    return _cache[cacheKey] ?? [];
  }
  // -----------------------------------------------------------------------------------------------------

  static void updateCachedOrderStatus(int orderId, String newStatus) {
    for (final list in _cache.values) {
      for (final order in list) {
        if (order.orderId == orderId) {
          order.status = newStatus;
        }
      }
    }
    _cacheTimestamps.clear();
  }

  static void invalidateCache([String? cacheKey]) {
    if (cacheKey == null) {
      _cache.clear();
      _cacheTimestamps.clear();
    } else {
      _cache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    }
  }

  void primeCache(List<OrderlistModel> orders, {String cacheKey = '_'}) {
    _cache[cacheKey] = orders;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  Future<VoidedItemsResponse> fetchVoidedItems({
    required int kotOrderId,
    required String token,
  }) async {
    try {
      final url =
          'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/orders/voided-items?order_id=$kotOrderId';

      AppLogger.info('[FETCH VOIDED ITEMS] URL => $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      AppLogger.info('[FETCH VOIDED ITEMS] STATUS => ${response.statusCode}');
      AppLogger.info('[FETCH VOIDED ITEMS] RESPONSE => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('items')) {
          for (var item in data['items']) {
            AppLogger.info(
              'LogID: ${item['log_id']}, '
              'ItemID: ${item['item_id']}, '
              'Product: ${item['product']}, '
              'OrigQty: ${item['orig_qty']} → NewQty: ${item['new_qty']}, '
              'Total: ${item['item_total']}',
            );
          }
        }

        return VoidedItemsResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to fetch voided items (status: ${response.statusCode})',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Fetch voided items error: $e\n$stackTrace');
      rethrow;
    }
  }
}
