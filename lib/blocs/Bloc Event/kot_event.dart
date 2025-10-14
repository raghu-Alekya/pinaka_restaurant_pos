import 'package:equatable/equatable.dart';
import '../../models/order/KOT_model.dart';

abstract class KotEvent extends Equatable {
  const KotEvent();

  @override
  List<Object?> get props => [];
}

/// 🔹 Fetch all KOTs for a specific order
class FetchKots extends KotEvent {
  final int parentOrderId;
  final int restaurantId;
  final int zoneId;
  final String token;

  const FetchKots({
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    required this.token,
  });

  @override
  List<Object?> get props => [parentOrderId, restaurantId, zoneId, token];
}

/// 🔹 Refresh KOT list (UI only, no API call)
class RefreshKots extends KotEvent {
  const RefreshKots();
}

/// 🔹 Add a KOT to the local list (UI update)
class AddKotToList extends KotEvent {
  final KotModel kot;

  const AddKotToList(this.kot);

  @override
  List<Object?> get props => [kot];
}

/// 🔹 Update an existing KOT (optional)
class UpdateKot extends KotEvent {
  final int kotId;
  final Map<String, dynamic> updatedData;

  const UpdateKot({
    required this.kotId,
    required this.updatedData,
  });

  @override
  List<Object?> get props => [kotId, updatedData];
}

/// 🔹 Remove a KOT from the list (optional)
class RemoveKot extends KotEvent {
  final int kotId;

  const RemoveKot({required this.kotId});

  @override
  List<Object?> get props => [kotId];
}

/// 🔹 Load existing KOTs directly
class LoadKots extends KotEvent {
  final List<KotModel> kots;
  final int parentOrderId;

  const LoadKots({required this.kots, required this.parentOrderId});
}

/// 🔹 Set existing KOTs (used on table load)
class SetExistingKots extends KotEvent {
  final List<KotModel> kots;

  const SetExistingKots({required this.kots});
}

/// 🔹 Collapse KOT dropdown (auto-collapse when adding items)
class CollapseKOT extends KotEvent {}

/// 🔹 Toggle KOT dropdown manually
class ToggleKOTDropdown extends KotEvent {}
