abstract class TableState {}

class TableInitial extends TableState {}

class TableAddingState extends TableState {}

class TableAddedState extends TableState {
  final Map<String, dynamic> tableData;

  TableAddedState(this.tableData);
}

class TableAddErrorState extends TableState {
  final String message;

  TableAddErrorState(this.message);
}
