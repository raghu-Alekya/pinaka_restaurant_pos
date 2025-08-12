import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../App flow/ui/guest_details_popup.dart';
import '../App flow/widgets/orderlist_widget.dart';
import '../App flow/widgets/view_all_kots.dart';
import '../blocs/order_bloc.dart';
import '../models/order/KOT_model.dart';
import '../models/order/guest_details.dart';
import '../models/order/order_model.dart';
// import '../bloc/order_bloc.dart';
// import '../widgets/view_all_kots.dart';
// import '../widgets/orderlist_widget.dart'; // adjust the path as needed


class OrderPanel extends StatelessWidget {
   final Guestcount? guestcount;
  // final Guestcount guestDetails;
    final Function(int) onGuestSaved;
   const OrderPanel({
     Key? key,
     required this.guestcount,
     required this.onGuestSaved,
     // required this.guestDetails,
   }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        return Container(
          width: 400,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header row with badges & actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  headerBadgeRow(),
                  Row(
                    children: [
                      actionButton('Cancel', 'assets/icon/delete.png', Colors.red),
                      const SizedBox(width: 14),
                      elevatedActionButton('Table layout', 'assets/icon/arrow.png'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 4),

              /// Date & staff info
              Row(
                children: [
                  iconText('assets/icon/person.png', 'Guest: ${guestcount?.guestCount ?? 0}'),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => GuestDetailsPopup(
                          index: 0,
                          tableData: {'capacity': 6},
                          placedTables: [], onGuestSaved: (Guestcount ) {  },
                        ),
                      );
                    },
                    icon: Image.asset('assets/icon/add_icon.png', width: 18, height: 18),
                  ),
                ],
              ),



              const SizedBox(height: 6),

              /// KOT Dropdown
              ViewAllKOTDropdown(kotList: state.kotList),

              const SizedBox(height: 2),

              /// Table header row
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF989292),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: headerText('#')),
                    SizedBox(width: 130, child: headerText('Item Name')),
                    SizedBox(width: 100, child: headerText('Modifier')),
                    SizedBox(width: 100, child: headerText('Quantity')),
                    SizedBox(width: 75, child: headerText('Amount')),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              /// Order items list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: state.orderItems.isEmpty
                      ? const Center(
                    child: Text(
                      'No items added yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                      : OrderPanelList(
                    orderItems: state.orderItems,
                    onIncreaseQuantity: (index) {
                      context.read<OrderBloc>().add(UpdateOrderItemQuantity(
                        index,
                        state.orderItems[index].quantity + 1,
                      ));
                    },
                    onDecreaseQuantity: (index) {
                      context.read<OrderBloc>().add(UpdateOrderItemQuantity(
                        index,
                        state.orderItems[index].quantity - 1,
                      ));
                    },
                    onModifiersChanged: (index, modifiers) {
                      context.read<OrderBloc>().add(UpdateOrderItemModifiers(
                        index,
                        modifiers,
                      ));
                    }, guestDetails: state.guest,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// Total section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5BF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      state.orderItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              /// Bottom action buttons
              Row(
                children: [
                  orderButton('Repeat order', const Color(0xFFF7C127)),
                  orderButton('KOT Print', const Color(0xFFFF4D20)),
                  orderButton('Generate e-Bill', Colors.green),
                  orderButton('Pay', const Color(0xFF086888)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Badge Row - All in one container
  Widget headerBadgeRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFECEEFB),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text('Main Dining', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,color: const Color(0xFF152148),)),
        const SizedBox(width: 10),
        Text('Order id #25876', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,color: const Color(0xFF152148),)),
        const SizedBox(width: 10),
        Row(
          children: [
            Image.asset('assets/icon/table.png', width: 14, height: 14),
            const SizedBox(width: 8),
            Text('# T8', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,color: const Color(0xFF152148),)),
          ],
        ),
      ],
    ),
  );

  /// Small action button (Cancel)
  Widget actionButton(String text, String iconPath, Color color) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      backgroundColor: const Color(0xFFF6F6F6),
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    onPressed: () {},
    icon: Image.asset(iconPath, width: 16, height: 16, color: color),
    label: Text(text, style: const TextStyle(fontSize: 12)),
  );

  /// Elevated action button (Table Layout)
  Widget elevatedActionButton(String text, String iconPath) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF152148),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    onPressed: () {},
    icon: Image.asset(iconPath, width: 8, height: 8, color: Colors.white),
    label: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
  );

  /// Icon with text row
  Widget iconText(String assetPath, String label) => Row(
    children: [
      Image.asset(assetPath, width: 10, height: 10),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 14)),
    ],
  );

  /// Avatar and name
  Widget avatarName(String imagePath, String name) => Row(
    children: [
      CircleAvatar(radius: 12, backgroundImage: AssetImage(imagePath)),

      const SizedBox(width: 4),
      Text(name),
    ],
  );

  /// Header text style
  static Widget headerText(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontSize: 12),
  );

  /// Order bottom buttons
  static Widget orderButton(String text, Color color) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {},
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    ),
  );
}
