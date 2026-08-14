import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../search_products_domain/search_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchUseCase useCase;
  Timer? _debounceTimer;
  Completer<void>? _completer;

  SearchBloc({required this.useCase}) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event,
      Emitter<SearchState> emit,
      ) async {
    _debounceTimer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError('Cancelled');
    }

    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Create a completer that will complete when the timer fires
    _completer = Completer<void>();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_completer!.isCompleted) {
        _completer!.complete();
      }
    });

    try {
      // Wait for the timer to complete
      await _completer!.future;
    } catch (_) {
      // Timer was cancelled, do nothing
      return;
    }

    // If the bloc is closed, don't emit
    if (isClosed) return;

    try {
      emit(SearchLoading());
      final results = await useCase(event.query);
      if (!isClosed) {
        emit(SearchLoaded(results: results));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SearchError(message: e.toString()));
      }
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError('Cancelled');
    }
    emit(SearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError('Closed');
    }
    return super.close();
  }
}