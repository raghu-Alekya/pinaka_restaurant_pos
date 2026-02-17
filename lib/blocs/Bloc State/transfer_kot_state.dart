abstract class TransferKotState {}

class TransferKotInitial extends TransferKotState {}

class KotTransferLoading extends TransferKotState {}

class KotTransferSuccess extends TransferKotState {
  final String message;
  final int newParentId;
  final int toTableId;

  KotTransferSuccess({
    required this.message,
    required this.newParentId,
    required this.toTableId,
  });
}

class KotTransferFailure extends TransferKotState {
  final String error;

  KotTransferFailure(this.error);
}
