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
class TableLoadingState extends TableState {}

class TableLoadedState extends TableState {
  final List<Map<String, dynamic>> tables;
  final Set<String> usedTableNames;
  final Set<String> usedAreaNames;

  TableLoadedState({
    required this.tables,
    required this.usedTableNames,
    required this.usedAreaNames,
  });
}

class TableLoadErrorState extends TableState {
  final String error;

  TableLoadErrorState(this.error);
}
class TableDeletingState extends TableState {}

class TableDeletedState extends TableState {
  final String tableName;
  TableDeletedState(this.tableName);
}

class TableDeleteErrorState extends TableState {
  final String message;
  TableDeleteErrorState(this.message);
}

