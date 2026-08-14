import 'package:equatable/equatable.dart';
import '../All_tables_list_domain/all_tables_list_entity.dart';

abstract class AllTablesState extends Equatable {
  const AllTablesState();

  @override
  List<Object> get props => [];
}

class AllTablesInitial extends AllTablesState {}

class AllTablesLoading extends AllTablesState {}

class AllTablesLoaded extends AllTablesState {
  final List<TableEntity> tables;

  const AllTablesLoaded({required this.tables});

  @override
  List<Object> get props => [tables];
}

class AllTablesError extends AllTablesState {
  final String message;

  const AllTablesError({required this.message});

  @override
  List<Object> get props => [message];
}