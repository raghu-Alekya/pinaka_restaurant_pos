abstract class OrderstatusEvent {}

class FetchOrders extends OrderstatusEvent {
  final String token;

  FetchOrders({required this.token});
}