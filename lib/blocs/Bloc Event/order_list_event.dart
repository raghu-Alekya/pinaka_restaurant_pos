abstract class OrderstatusEvent {}

class FetchOrders extends OrderstatusEvent {
  final String token;
  final String? date;
  final String? restaurantId;
  final bool forceRefresh;

  FetchOrders({
    required this.token,
    this.date,
    this.restaurantId,
    this.forceRefresh = false,
  });
}