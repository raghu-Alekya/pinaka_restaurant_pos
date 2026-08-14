import 'all_tables_list_entity.dart';
import 'all_tables_list_repository.dart';

class AllTablesUseCase {
  final AllTablesRepository repository;

  AllTablesUseCase({required this.repository});

  Future<List<TableEntity>> call() async {
    return await repository.getTables();
  }
}