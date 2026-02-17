import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc Event/variant_evnts.dart';
import '../Bloc State/variant_states.dart';
// import '../events/variant_evnts.dart';
// import '../models/category/items_model.dart';
// import '../states/variant_states.dart';

class VariantBloc extends Bloc<VariantEvent, VariantState> {
  VariantBloc() : super(VariantInitial()) {
    on<LoadProductVariants>(_onLoadProductVariants);
    on<SelectVariant>(_onSelectVariant);
    on<ResetVariantSelection>(_onResetVariantSelection);
  }

  void _onLoadProductVariants(
      LoadProductVariants event, Emitter<VariantState> emit) {
    if (event.product.variants.isEmpty) {
      emit(VariantError("No variants available"));
    } else {
      emit(VariantLoaded(product: event.product));
    }
  }

  void _onSelectVariant(SelectVariant event, Emitter<VariantState> emit) {
    if (state is VariantLoaded) {
      final current = state as VariantLoaded;
      emit(current.copyWith(
        selectedVariantId: event.variantId,
        selectedQuantity: event.quantity,
      ));
    }
  }

  void _onResetVariantSelection(
      ResetVariantSelection event, Emitter<VariantState> emit) {
    if (state is VariantLoaded) {
      final current = state as VariantLoaded;
      emit(current.copyWith(selectedVariantId: -1, selectedQuantity: 1));
    }
  }
}
