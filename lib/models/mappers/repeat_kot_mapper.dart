import '../order/KOT_model.dart';
import '../order/order_items.dart';
import '../order/repeat_kot_model.dart';
import '../sidebar/category_model_.dart';

extension RepeatKotMapper on RepeatKotModel {
  KotModel toKotModel() {
    return KotModel(
      kotId: parentOrderId,
      kotNumber: "KOT-$parentOrderId",
      time: DateTime.now(),
      status: "REPEAT",
      parentOrderId: parentOrderId,
      captainId: captainId,
      guestCount: null,

      items: lineItems.map((item) {
        final baseAmount = item.price * item.quantity;

        OrderItems? parsedFromRaw;
        if (item.rawJson.isNotEmpty) {
          try {
            parsedFromRaw = OrderItems.fromJson(item.rawJson);
          } catch (_) {}
        }

        final bool originalHasOptions = item.hasOptions ||
            (parsedFromRaw?.hasOptions ?? false) ||
            item.modifiers.isNotEmpty ||
            (parsedFromRaw?.modifiers.isNotEmpty ?? false) ||
            item.addOns.isNotEmpty ||
            (parsedFromRaw?.addOns.isNotEmpty ?? false);

        return OrderItems(
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          section: Category(
            id: '0',
            name: 'Unknown',
            imagepath: '',
            subCategories: const [],
          ),
          // ✅ Repeat ONLY base items without previous modifiers/add-ons/notes
          modifiers: const [],
          addOns: const {},
          note: '',
          // ✅ Keep hasOptions enabled so user can re-select modifiers if desired
          hasOptions: originalHasOptions,
          amount: baseAmount,
        );
      }).toList(),

      kotItems: [], // safe default
    );
  }
}


