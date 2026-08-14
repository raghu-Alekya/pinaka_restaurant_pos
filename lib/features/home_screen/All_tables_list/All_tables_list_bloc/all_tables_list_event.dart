import 'package:equatable/equatable.dart';

abstract class AllTablesEvent extends Equatable {
  const AllTablesEvent();

  @override
  List<Object> get props => [];
}

class FetchAllTables extends AllTablesEvent {}