abstract class OrderstatusEvent {}

class FetchOrders extends OrderstatusEvent {
  final String token;
  final String? date;

  FetchOrders({required this.token, this.date});
}