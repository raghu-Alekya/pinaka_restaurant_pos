import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/kitchen_order.dart';
import '../utils/AppConstant.dart';
import '../utils/kds_logger.dart';

class OrderApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  const OrderApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() =>
      'OrderApiException($statusCode): $message${body != null ? ' | $body' : ''}';
}

class KotApiStatus {
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const served = 'served';
  static const cancelled = 'cancelled';
  static const kotProcessed = 'Yet To Prepare';

  static String fromLocal(String localStatus) {
    switch (localStatus.trim().toLowerCase()) {
      case 'cancel':
      case 'cancelled':
        return cancelled;

      case 'recall':
      case 'kot-processed':
        return kotProcessed;

      case 'preparing':
        return preparing;

      case 'ready':
        return ready;

      case 'served':
        return served;

      default:
        return localStatus.trim().toLowerCase();
    }
  }
}

class OrderApiService {
  OrderApiService({
    required this.getToken,
    this.restaurantId = 1,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final Future<String?> Function() getToken;
  final int restaurantId;
  // final String baseUrl;
  final http.Client _client;
  final Map<String, String> productCategoryById = {};

  final Map<String, String> productCategoryByName = {};


  static const _flagUpdateKotStatus = 'update_kot_order_status';

  //─────────────────────────────────────────────
  // Status Actions
  //─────────────────────────────────────────────

  Future<Map<String, dynamic>> startOrder(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.preparing);
  }

  Future<Map<String, dynamic>> cancelOrder(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.cancelled);
  }

  Future<Map<String, dynamic>> recallOrder(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.kotProcessed);
  }

  Future<Map<String, dynamic>> markReady(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.ready);
  }

  Future<Map<String, dynamic>> markServed(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.served);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      KitchenOrder order,
      String localStatus,
      ) {
    return _updateStatus(
      order,
      KotApiStatus.fromLocal(localStatus),
    );
  }

  //─────────────────────────────────────────────
  // Main API Call
  //─────────────────────────────────────────────

  Future<Map<String, dynamic>> updateKotOrderStatus({
    required int orderId,
    required int parentId,
    int? zoneId,
    required int restaurantId,
    required String status,
  }) async {
    final token = await _requireToken();

    final url = Uri.parse(
      '${AppConstants.ordersEndpoint}/$orderId',
    );

    final payload = {
      'flag_type': _flagUpdateKotStatus,
      'restaurant_id': restaurantId,
      'parent_id': parentId,
      'status': KotApiStatus.fromLocal(status),
    };

    if (zoneId != null && zoneId > 0) {
      payload['zone_id'] = zoneId;
    }

    KdsDebugLog.info('PUT $url');
    KdsDebugLog.info('Payload => $payload');

    final response = await _client.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _parseResponse(response);
  }

  void dispose() {
    _client.close();
  }

  //─────────────────────────────────────────────
  // Helpers
  //─────────────────────────────────────────────

  Future<Map<String, dynamic>> _updateStatus(
      KitchenOrder order,
      String apiStatus,
      ) {
    return updateKotOrderStatus(
      orderId: _requireKotId(order),
      parentId: _requireParentOrderId(order),
      zoneId: order.zoneId,
      restaurantId: restaurantId,
      status: apiStatus,
    );
  }

  Future<String> _requireToken() async {
    final token = await getToken();

    KdsDebugLog.info('Retrieved token: $token');

    if (token == null || token.trim().isEmpty) {
      throw const OrderApiException(
        statusCode: 401,
        message: 'Missing auth token',
      );
    }

    return token.trim();
  }

  int _requireKotId(KitchenOrder order) {
    final kotId = order.kotId;

    if (kotId == null || kotId <= 0) {
      throw OrderApiException(
        statusCode: 0,
        message: 'Missing kotId for order ${order.id}',
      );
    }

    return kotId;
  }

  int _requireParentOrderId(KitchenOrder order) {
    final parentId = order.parentOrderId;

    if (parentId == null || parentId <= 0) {
      throw OrderApiException(
        statusCode: 0,
        message: 'Missing parentOrderId for order ${order.id}',
      );
    }

    return parentId;
  }

  int? _requireZoneId(KitchenOrder order) {
    // Zone ID is required only for Dine-In orders
    if (order.type.toLowerCase().contains('dine')) {
      final zoneId = order.zoneId;

      if (zoneId == null || zoneId <= 0) {
        throw OrderApiException(
          statusCode: 0,
          message: 'Missing zoneId for Dine-In order ${order.id}',
        );
      }

      return zoneId;
    }

    // Takeaway / Online orders don't require zoneId
    return null;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    final rawBody = response.body.trim();

    Map<String, dynamic>? jsonBody;

    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);

        if (decoded is Map<String, dynamic>) {
          jsonBody = decoded;
        }
      } catch (_) {}
    }

    if (statusCode < 200 || statusCode >= 300) {
      final message =
          jsonBody?['message']?.toString() ??
              jsonBody?['error']?.toString() ??
              'Request failed';

      KdsDebugLog.error('API failed: $statusCode');
      KdsDebugLog.error(rawBody);

      throw OrderApiException(
        statusCode: statusCode,
        message: message,
        body: rawBody.isEmpty ? null : rawBody,
      );
    }

    KdsDebugLog.info('update API success: $statusCode');
    KdsDebugLog.info('Response Status Code: ${response.statusCode}');
    KdsDebugLog.info('Response Body: ${response.body}');
    return jsonBody ?? {'success': true};
  }
  String _normalizeProductName(String name) {
    String normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');

    // =====================================================
    // REMOVE COMMON VARIANT / SIZE SUFFIXES
    // =====================================================

    normalized = normalized.replaceFirst(
      RegExp(
        r'\s*-\s*'
        r'(single|family|jumbo|half|full|small|medium|large)$',
        caseSensitive: false,
      ),
      '',
    );

    // =====================================================
    // REMOVE ML / L / KG / G SIZE
    // Examples:
    // Budweiser - 750 ml -> budweiser
    // Bira - 60 ml        -> bira
    // Product - 1 kg     -> product
    // =====================================================

    normalized = normalized.replaceFirst(
      RegExp(
        r'\s*-\s*\d+(?:\.\d+)?\s*(ml|l|kg|g)$',
        caseSensitive: false,
      ),
      '',
    );

    return normalized.trim();
  }
  Future<List<dynamic>> getKitchenDisplayOrders() async {
    final token = await _requireToken();

    final url = Uri.parse(
      '${AppConstants.kitchenDisplayOrdersEndpoint}?restaurant_id=$restaurantId',
    );

    KdsDebugLog.info('GET $url');

    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('');
    print('==============================================');
    print('       KITCHEN DISPLAY ORDERS API');
    print('==============================================');
    print('Status Code: ${response.statusCode}');
    print('==============================================');

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw OrderApiException(
        statusCode: response.statusCode,
        message: 'Failed to load kitchen display orders',
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return [];
    }

    // ==========================================================
    // PRODUCT MAPS
    //
    // product_id -> isVeg
    // product_id -> category
    // ==========================================================

    final Map<String, bool?> vegByProductId = {};

    productCategoryById.clear();
    productCategoryByName.clear();
    // Map<String, String> productCategoryById = {};
    //
    // Map<String, String> productCategoryByName = {};
    //
    // final Map<String, String> productCategoryById = {};
    //
    // final Map<String, String> productCategoryByName = {};
    // ==========================================================
    // CATEGORY PRODUCTS
    // ==========================================================

    final categoryProducts =
    decoded['category_products'];

    if (categoryProducts is List) {
      for (final category in categoryProducts) {
        if (category is! Map) {
          continue;
        }

        // --------------------------------------------------------
        // CATEGORY NAME
        // --------------------------------------------------------

        final categoryName =
            category['category_name']
                ?.toString()
                .trim() ??
                category['categoryName']
                    ?.toString()
                    .trim() ??
                '';

        final products =
        category['products'];

        if (products is! List) {
          continue;
        }

        // --------------------------------------------------------
        // PRODUCTS
        // --------------------------------------------------------

        for (final product in products) {
          if (product is! Map) {
            continue;
          }

          // ======================================================
          // PRODUCT ID
          // ======================================================

          final productId =
              product['product_id'] ??
                  product['productId'];

          final productIdString =
              productId?.toString().trim() ?? '';

          // ======================================================
          // PRODUCT NAME
          // ======================================================

          final productName =
              product['item_name']
                  ?.toString()
                  .trim() ??
                  product['name']
                      ?.toString()
                      .trim() ??
                  product['product_name']
                      ?.toString()
                      .trim() ??
                  '';

          // ======================================================
          // PRODUCT ID → CATEGORY
          // ======================================================

          if (categoryName.isNotEmpty &&
              productIdString.isNotEmpty) {
            productCategoryById[
            productIdString
            ] = categoryName;
          }

          // ======================================================
          // PRODUCT NAME → CATEGORY
          // IMPORTANT FOR VARIANTS
          // ======================================================
//
          if (categoryName.isNotEmpty &&
              productName.isNotEmpty) {

            final normalizedProductName =
            _normalizeProductName(productName);

            productCategoryByName[
            normalizedProductName
            ] = categoryName;

            print(
              'NAME CATEGORY MAP => '
                  '$productName -> '
                  '$normalizedProductName -> '
                  '$categoryName',
            );
          }

          // ======================================================
          // VEG / NON VEG
          // ======================================================

          final dynamic rawIsVeg;

          if (product.containsKey('is_veg')) {
            rawIsVeg = product['is_veg'];
          } else if (product.containsKey('isVeg')) {
            rawIsVeg = product['isVeg'];
          } else {
            rawIsVeg = null;
          }

          bool? isVeg;

          if (rawIsVeg == null) {
            isVeg = null;
          } else {
            final normalized =
            rawIsVeg
                .toString()
                .trim()
                .toLowerCase();

            isVeg =
                rawIsVeg == true ||
                    rawIsVeg == 1 ||
                    normalized == 'true' ||
                    normalized == '1';
          }

          vegByProductId[
          productIdString
          ] = isVeg;

          print(
            'PRODUCT MAP: '
                '$productIdString -> '
                '$productName -> '
                '$categoryName -> '
                '$isVeg',
          );
        }
      }
    }

    // ==========================================================
    // PRINT PRODUCT CATEGORY MAP
    // ==========================================================

    print('');
    print('========== PRODUCT CATEGORY MAP ==========');

    productCategoryById.forEach(
          (productId, category) {
        print(
          '$productId -> $category',
        );
      },
    );

    print('==========================================');

    // ==========================================================
    // PRINT VEG MAP
    // ==========================================================

    print('');
    print('========== VEG MAP ==========');
    print(vegByProductId);
    print('=============================');

    // ==========================================================
    // ORDERS
    // ==========================================================

    final rawOrders =
    decoded['response'];

    if (rawOrders is! List) {
      return [];
    }

    final List<Map<String, dynamic>> orders = [];

    // ==========================================================
    // LOOP ORDERS
    // ==========================================================

    for (final rawOrder in rawOrders) {
      if (rawOrder is! Map) {
        continue;
      }

      final order =
      Map<String, dynamic>.from(rawOrder);



// KOT ORDER STATUS
// ==========================================================

    final kotOrderStatus =
    order['kot_order_status']?.toString().trim() ?? '';

    if (kotOrderStatus.isNotEmpty) {
    order['kot_order_status'] = kotOrderStatus;
    }

      // ========================================================
      // KOT ITEMS
      // ========================================================

      final rawKotItems =
      order['kot_items'];

      if (rawKotItems is List) {
        final List<Map<String, dynamic>>
        enrichedItems = [];

        // ======================================================
        // LOOP KOT ITEMS
        // ======================================================

        for (final rawItem in rawKotItems) {
          if (rawItem is! Map) {
            continue;
          }

          final item =
          Map<String, dynamic>.from(rawItem);

          // ====================================================
          // PRODUCT ID
          // ====================================================

          final productId =
              item['product_id'] ??
                  item['productId'];

          final productIdString =
              productId?.toString() ?? '';

          // ====================================================
          // CATEGORY
          // ====================================================

          // ====================================================
// CATEGORY
// ====================================================

          String categoryName = '';

// ====================================================
// 1. PRODUCT ID → CATEGORY
// ====================================================

          categoryName =
              productCategoryById[productIdString] ??
                  '';

// ====================================================
// 2. PRODUCT NAME → CATEGORY
// IMPORTANT FOR VARIANTS
// ====================================================

          if (categoryName.isEmpty) {
            final itemName =
                item['name']?.toString().trim() ??
                    item['item_name']?.toString().trim() ??
                    item['product_name']?.toString().trim() ??
                    '';

            final normalizedName =
            _normalizeProductName(itemName);

            categoryName =
                productCategoryByName[
                normalizedName] ??
                    '';

            print(
              'CATEGORY NAME LOOKUP => '
                  'name=$itemName | '
                  'normalized=$normalizedName | '
                  'category=$categoryName',
            );
          }

// ====================================================
// 3. CATEGORY DIRECTLY FROM KOT ITEM
// ====================================================

          if (categoryName.isEmpty) {
            categoryName =
                item['category_name']
                    ?.toString()
                    .trim() ??
                    '';
          }

          if (categoryName.isEmpty) {
            categoryName =
                item['categoryName']
                    ?.toString()
                    .trim() ??
                    '';
          }

          if (categoryName.isEmpty) {
            categoryName =
                item['category']
                    ?.toString()
                    .trim() ??
                    '';
          }

// ====================================================
// 4. FINAL FALLBACK
// ====================================================

          if (categoryName.isEmpty) {
            categoryName = 'OTHER';
          }

          item['category_name'] = categoryName;
          item['categoryName'] = categoryName;
          // ====================================================
          // ITEM NAME
          // ====================================================

          item['name'] =
              item['name'] ??
                  item['item_name'] ??
                  item['product_name'] ??
                  'Unknown';

          // ====================================================
          // QUANTITY
          // ====================================================

          item['quantity'] =
              item['quantity'] ??
                  item['qty'] ??
                  1;

          item['qty'] =
              item['qty'] ??
                  item['quantity'];

          // ====================================================
          // VEG / NON VEG
          //
          // Priority:
          // 1. item-level is_veg
          // 2. category_products map
          // 3. false
          // ====================================================
// ====================================================
// VEG / NON VEG
//
// Priority:
// 1. item-level is_veg
// 2. product map
// 3. null
//
// IMPORTANT:
// Never convert null to false.
// ====================================================

          final dynamic rawIsVeg;

          if (item.containsKey('is_veg')) {
            rawIsVeg = item['is_veg'];
          } else if (item.containsKey('isVeg')) {
            rawIsVeg = item['isVeg'];
          } else {
            rawIsVeg = null;
          }

          bool? isVeg;

          if (rawIsVeg != null) {
            final normalized =
            rawIsVeg.toString().trim().toLowerCase();

            isVeg =
                rawIsVeg == true ||
                    rawIsVeg == 1 ||
                    normalized == 'true' ||
                    normalized == '1';
          } else {
            // Only use product map if item-level field
            // does NOT contain a value.
            isVeg = vegByProductId[productIdString];
          }

// Keep NULL as NULL.
          item['is_veg'] = isVeg;
          item['isVeg'] = isVeg;

          print(
            'FINAL VEG => '
                'product=$productIdString | '
                'raw=$rawIsVeg | '
                'final=$isVeg',
          );
          // ====================================================
          // MODIFIERS
          // ====================================================

          final rawModifiers =
          item['modifiers'];

          if (rawModifiers is List) {
            item['modifiers'] =
                rawModifiers
                    .map(
                      (e) => e.toString(),
                )
                    .toList();
          } else {
            item['modifiers'] = [];
          }

          // ====================================================
          // ADDONS
          // ====================================================

          dynamic rawAddons =
              item['addons'] ??
                  item['addOns'];

          if (rawAddons is List) {
            item['addons'] = rawAddons;
            item['addOns'] = rawAddons;
          } else if (rawAddons is Map) {
            item['addons'] = rawAddons;
            item['addOns'] = rawAddons;
          } else {
            item['addons'] = [];
            item['addOns'] = [];
          }

          // ====================================================
          // NOTE
          //
          // Supports:
          // note
          // notes
          // modifier_note
          // modifier_notes
          // ====================================================

          String note =
              item['note']
                  ?.toString()
                  .trim() ??
                  '';

          if (note.isEmpty) {
            note =
                item['notes']
                    ?.toString()
                    .trim() ??
                    '';
          }

          if (note.isEmpty) {
            note =
                item['modifier_note']
                    ?.toString()
                    .trim() ??
                    '';
          }

          if (note.isEmpty) {
            note =
                item['modifier_notes']
                    ?.toString()
                    .trim() ??
                    '';
          }

          item['note'] = note;

          // ====================================================
          // DEBUG
          // ====================================================

          print('');
          print('========== API KOT ITEM ==========');
          print('NAME       : ${item['name']}');
          print('PRODUCT ID : $productIdString');
          print('CATEGORY   : $categoryName');
          print('IS VEG     : ${item['is_veg']}');
          print('MODIFIERS  : ${item['modifiers']}');
          print('ADDONS     : ${item['addons']}');
          print('NOTE       : ${item['note']}');
          print('==================================');

          enrichedItems.add(item);
        }

        // ========================================================
        // SAVE ENRICHED KOT ITEMS
        // ========================================================

        order['kot_items'] =
            enrichedItems;
      }

      // ==========================================================
      // ADD ORDER
      // ==========================================================

      orders.add(order);
    }

    // ==========================================================
    // FINAL DEBUG
    // ==========================================================

    print('');
    print('==============================================');
    print(
      'TOTAL KITCHEN ORDERS: ${orders.length}',
    );
    print('==============================================');

    return orders;
  }

}