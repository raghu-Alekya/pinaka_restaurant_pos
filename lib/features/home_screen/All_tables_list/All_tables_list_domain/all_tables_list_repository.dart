import 'all_tables_list_entity.dart';

abstract class AllTablesRepository {
  Future<List<TableEntity>> getTables();
}