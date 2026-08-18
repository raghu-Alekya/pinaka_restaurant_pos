import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/color_constants.dart';
import '../order_menu/order_menu_screen.dart';
import 'create_order_bloc/create_order_bloc.dart';
import 'create_order_bloc/create_order_event.dart';
import 'create_order_bloc/create_order_state.dart';
import 'create_order_domain/create_order_entity.dart';

class GuestCountBottomSheet extends StatefulWidget {
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final int restaurantId;
  final String restaurantName;

  const GuestCountBottomSheet({
    Key? key,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<GuestCountBottomSheet> createState() => _GuestCountBottomSheetState();
}

class _GuestCountBottomSheetState extends State<GuestCountBottomSheet> {
  final TextEditingController _guestController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Rebuilds the sheet as the guest field changes, so the Continue
    // button can live-toggle between grey (invalid) and orange (valid),
    // matching the two reference screenshots.
    _guestController.addListener(_onGuestFieldChanged);
  }

  void _onGuestFieldChanged() => setState(() {});

  @override
  void dispose() {
    _guestController.removeListener(_onGuestFieldChanged);
    _guestController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  int get _guestCount {
    return int.tryParse(_guestController.text.trim()) ?? 0;
  }

  bool get _isValidGuestCount => _guestCount >= 1 && _guestCount <= 99;

  void _onContinue(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final request = CreateOrderRequestEntity(
      flagType: 'parent_order',
      tableId: widget.tableId,
      tableName: widget.tableName,
      zoneId: widget.zoneId,
      zoneName: widget.zoneName,
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      guestCount: _guestCount,
      guestDetails: [GuestDetailEntity(guestCount: _guestCount)],
      reservationId: null,
      orderDatetime: now,
      // NOTE: if CreateOrderRequestEntity has (or you add) a
      // `customerName` field, pass it here, e.g.:
      // customerName: _customerNameController.text.trim().isEmpty
      //     ? null
      //     : _customerNameController.text.trim(),
    );
    context.read<CreateOrderBloc>().add(CreateOrder(request: request));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keeps the sheet above the keyboard when typing
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: "Table No {n}"  +  circular red close button ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Table No ${widget.tableName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE64545),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── No of Guests ──
              const Text(
                'No of Guests',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _guestController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'No of Guests',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: ColorConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  final n = int.tryParse(value?.trim() ?? '');
                  if (n == null || n < 1) {
                    return 'Enter at least 1 guest';
                  }
                  if (n > 99) {
                    return 'Guest count too high';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Name of Customer (Optional) ──
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  children: [
                    const TextSpan(text: 'Name of Customer '),
                    TextSpan(
                      text: '(Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customerNameController,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Name of Customer',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: ColorConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                onFieldSubmitted: (_) {
                  if (_isValidGuestCount) _onContinue(context);
                },
              ),
              const SizedBox(height: 28),

              // ── Continue button: grey when invalid, orange when valid ──
              // BlocConsumer<CreateOrderBloc, CreateOrderState>(
              //   listener: (context, state) {
              //     if (state is CreateOrderSuccess) {
              //       Navigator.of(context).pop(); // close bottom sheet
              //       Navigator.of(context).push(
              //         MaterialPageRoute(
              //           builder: (_) => OrderMenuScreen(
              //             orderId: state.response.orderId,
              //             tableName: state.response.tableName,
              //             orderType: state.response.orderType,
              //             restaurantId: state.response.restaurantId,
              //             zoneId: state.response.zoneId,
              //           ),
              //         ),
              //       );
              //     } else if (state is CreateOrderError) {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(
              //           content: Text(state.message),
              //           backgroundColor: ColorConstants.errorColor,
              //         ),
              //       );
              //     }
              //   },
              //   builder: (context, state) {
              //     if (state is CreateOrderLoading) {
              //       return const SizedBox(
              //         height: 48,
              //         child: Center(child: CircularProgressIndicator()),
              //       );
              //     }
              //     return ElevatedButton(
              //       onPressed: _isValidGuestCount ? () => _onContinue(context) : null,
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: ColorConstants.primaryColor,
              //         foregroundColor: Colors.white,
              //         disabledBackgroundColor: Colors.grey.shade300,
              //         disabledForegroundColor: Colors.grey.shade600,
              //         padding: const EdgeInsets.symmetric(vertical: 15),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(10),
              //         ),
              //         elevation: 0,
              //       ),
              //       child: const Text(
              //         'Continue',
              //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              //       ),
              //     );
              //   },
              // ),

              BlocConsumer<CreateOrderBloc, CreateOrderState>(
                listener: (context, state) {
                  if (state is CreateOrderSuccess) {
                    // Close the sheet
                    Navigator.of(context).pop();
                    // Navigate to OrderMenuScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderMenuScreen(
                          orderId: state.response.orderId,
                          tableName: state.response.tableName,
                          orderType: state.response.orderType,
                          restaurantId: state.response.restaurantId,
                          zoneId: state.response.zoneId,
                        ),
                      ),
                    );
                  } else if (state is CreateOrderError) {
                    // Show error snackbar (no navigation)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: ColorConstants.errorColor,
                      ),
                    );
                  }
                },
                  builder: (context, state) {
                    if (state is CreateOrderLoading) {
                      return const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _isValidGuestCount ? () => _onContinue(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}