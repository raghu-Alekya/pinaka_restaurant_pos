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

/// 🔹 Create a new KOT (when user presses 'KOT Print')
// class CreateKot extends KotEvent {
//   final int parentOrderId;
//   final List<Map<String, dynamic>> items; // Can be OrderItems.toJson()
//   final String token;
//
//   const CreateKot({
//     required this.parentOrderId,
//     required this.items,
//     required this.token,
//   });
//
//   @override
//   List<Object?> get props => [parentOrderId, items, token];
// }

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

/// 🔹 Optional: Update an existing KOT (e.g., for void or transfer)
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

/// 🔹 Optional: Remove a KOT from the list
class RemoveKot extends KotEvent {
  final int kotId;

  const RemoveKot({required this.kotId});

  @override
  List<Object?> get props => [kotId];
}

/// 🔹 New event to load existing KOTs directly
class LoadKots extends KotEvent {
  final List<KotModel> kots;
  final int parentOrderId;

  LoadKots({required this.kots, required this.parentOrderId});
}
class SetExistingKots extends KotEvent {
  final List<KotModel> kots;
  SetExistingKots({required this.kots});
}

/// 🔹 Prepare a new KOT (adds an empty KOT to the list)
class PrepareNewKot extends KotEvent {
  final int parentOrderId; // Optional, link to existing order

  const PrepareNewKot({required this.parentOrderId});

  @override
  List<Object?> get props => [parentOrderId];
}
