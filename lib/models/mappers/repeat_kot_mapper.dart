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
        return OrderItems(
          productId: item.productId,
          // variationId: -1,/ // or item.variantId if exists

          name: item.name,
          price: item.price,
          quantity: item.quantity,

          section: Category(
            id: '0',
            name: 'Unknown',
            imagepath: '',
            subCategories: const [],
          ),

          // optional fields
          modifiers: const [],
          addOns: const {},
          note: '',
          hasOptions: false,
          // variantId: -1,
        );
      }).toList(),



      kotItems: [], // safe default
    );
  }
}


