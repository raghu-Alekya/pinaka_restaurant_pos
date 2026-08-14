import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../All_tables_list_domain/all_tables_list_usecase.dart';
import 'all_tables_list_event.dart';
import 'all_tables_list_state.dart';

class AllTablesBloc extends Bloc<AllTablesEvent, AllTablesState> {
  final AllTablesUseCase useCase;

  AllTablesBloc({required this.useCase}) : super(AllTablesInitial()) {
    on<FetchAllTables>(_onFetchTables);
  }

  Future<void> _onFetchTables(
      FetchAllTables event,
      Emitter<AllTablesState> emit,
      ) async {
    emit(AllTablesLoading());
    try {
      final tables = await useCase();
      emit(AllTablesLoaded(tables: tables));
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      emit(AllTablesError(message: errorMsg));
    }
  }
}