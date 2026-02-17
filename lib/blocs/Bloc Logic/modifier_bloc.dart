import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc Event/modifier_event.dart';
import '../Bloc State/modifier_state.dart';

import '../../repositories/modifier_repository.dart';

class ModifierBloc extends Bloc<ModifierEvent, ModifierState> {
  final ModifierRepository repository;

  ModifierBloc(this.repository) : super(ModifierInitial()) {
    on<FetchModifiersByProductId>((event, emit) async {
      emit(ModifierLoading());
      try {
        final modifiers = await repository.fetchModifiersByProductId(event.productId);
        emit(ModifierLoaded(modifiers));
      } catch (e) {
        emit(ModifierError(e.toString()));
      }
    });
  }
}
