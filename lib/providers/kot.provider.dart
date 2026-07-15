// import 'package:flutter/foundation.dart';
//
// import '../models/kitchen_order.dart';
// // import '../models/kitchen_status.dart';
// import '../services/api_services.dart';
// // import '../services/kitchen_apiservice.dart';
// import '../utils/kds_logger.dart';
//
// class KotProvider extends ChangeNotifier {
//   final OrderApiService _apiService;
//
//   KotProvider(this._apiService);
//
//   final List<KitchenOrder> _allKots = [];
//
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;
//
//   List<KitchenOrder> get allKots => List.unmodifiable(_allKots);
//
//   Future<void> loadKotsFromApi() async {
//     try {
//       _isLoading = true;
//       notifyListeners();
//
//       final response = await _apiService.getKitchenDisplayOrders();
//
//       _allKots.clear();
//
//       _allKots.addAll(
//         response.map<KitchenOrder>(
//               (e) => KitchenOrder.fromJson(e),
//         ),
//       );
//
//       KdsDebugLog.info(
//         'Loaded ${_allKots.length} KOTs from API',
//       );
//     } catch (e) {
//       KdsDebugLog.error('loadKotsFromApi: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   List<KitchenOrder> get pendingKots =>
//       _allKots.where(
//             (e) => e.kotStatus == 'KOT Processed',
//       ).toList();
//
//   List<KitchenOrder> get activeKots =>
//       _allKots.where(
//             (e) => ['Preparing', 'Ready', 'Served']
//             .contains(e.kotStatus),
//       ).toList();
//
//   List<KitchenOrder> get preparingKots =>
//       _allKots.where(
//             (e) => e.kotStatus == 'Preparing',
//       ).toList();
//
//   List<KitchenOrder> get readyKots =>
//       _allKots.where(
//             (e) => e.kotStatus == 'Ready',
//       ).toList();
//
//   List<KitchenOrder> get servedKots =>
//       _allKots.where(
//             (e) => e.kotStatus == 'Served',
//       ).toList();
// }