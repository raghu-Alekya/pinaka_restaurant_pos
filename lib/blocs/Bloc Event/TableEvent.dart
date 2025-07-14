import 'dart:ui';

abstract class TableEvent {}

class AddTableEvent extends TableEvent {
  final Map<String, dynamic> tableData;
  final Offset position;
  final String token;
  final int pin;

  AddTableEvent({
    required this.tableData,
    required this.position,
    required this.token,
    required this.pin,
  });
}
class LoadTablesEvent extends TableEvent {
  final String token;

  LoadTablesEvent(this.token);
}
class DeleteTableEvent extends TableEvent {
  final Map<String, dynamic> table;
  final String token;

  DeleteTableEvent({required this.table, required this.token});
}
