import 'package:flutter/material.dart';
import '../../../../constants/color_constants.dart';
import '../entities/product_entity.dart';
import 'product_card.dart' show isNonVegProduct;

class AddOnItem {
  final String name;
  final double price;

  AddOnItem({required this.name, required this.price});
}

class AddOnBottomSheet extends StatefulWidget {
  final ProductEntity product;
  final Function(ProductEntity? selectedVariant, List<AddOnItem> selectedAddOns, int quantity)
  onAddToCart;

  const AddOnBottomSheet({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<AddOnBottomSheet> createState() => _AddOnBottomSheetState();
}

class _AddOnBottomSheetState extends State<AddOnBottomSheet> {
  // TODO: replace with real variants from product.attributes / your variations API
  final List<ProductEntity> _variants = [
    ProductEntity(id: 0, name: 'Regular', price: '0'),
    ProductEntity(id: 1, name: 'Large', price: '2.00'),
    ProductEntity(id: 2, name: 'Extra Large', price: '4.00'),
  ];

  // TODO: replace with real add-ons from product.meta / your add-ons API
  final List<AddOnItem> _availableAddOns = [
    AddOnItem(name: 'Extra Ghee', price: 1.00),
    AddOnItem(name: 'Extra Karam Podi', price: 1.00),
    AddOnItem(name: 'Extra Chutney', price: 1.00),
  ];

  ProductEntity? _selectedVariant;
  final Set<String> _selectedAddOns = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (_variants.isNotEmpty) {
      _selectedVariant = _variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonVeg = isNonVegProduct(widget.product);
    final variantPrice = _selectedVariant != null
        ? double.tryParse(_selectedVariant!.price ?? '0') ?? 0
        : double.tryParse(widget.product.price ?? '0') ?? 0;
    final addOnsTotal = _selectedAddOns.fold<double>(0, (sum, name) {
      final addon = _availableAddOns.firstWhere((a) => a.name == name);
      return sum + addon.price;
    });
    final totalPrice = (variantPrice + addOnsTotal) * _quantity;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: veg/non-veg dot + name + close ──
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nonVeg ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFEAEA),
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Variants — 2-column card grid ──
              if (_variants.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _variants.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    final isSelected = _selectedVariant?.name == variant.name;

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedVariant = variant;
                        if (!isSelected) _quantity = 1;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorConstants.primaryColor.withOpacity(0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            Text(
                              variant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${variant.price}',
                                  style: const TextStyle(
                                    color: ColorConstants.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                isSelected
                                    ? _VariantStepper(
                                  quantity: _quantity,
                                  onAdd: () => setState(() => _quantity++),
                                  onRemove: () => setState(() {
                                    if (_quantity > 1) _quantity--;
                                  }),
                                )
                                    : GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedVariant = variant;
                                    _quantity = 1;
                                  }),
                                  child: const Icon(
                                    Icons.add_circle,
                                    color: ColorConstants.primaryColor,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // ── Modifiers ──
              if (_availableAddOns.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Text('Modifiers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(child: Divider()),
                  ],
                ),
                ..._availableAddOns.map((addon) {
                  final isChecked = _selectedAddOns.contains(addon.name);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    value: isChecked,
                    title: Text(addon.name, style: const TextStyle(fontSize: 14)),
                    secondary: Text('+ \$${addon.price.toStringAsFixed(2)}'),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedAddOns.add(addon.name);
                        } else {
                          _selectedAddOns.remove(addon.name);
                        }
                      });
                    },
                  );
                }),
              ],

              const SizedBox(height: 8),

              // ── Add to Cart ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selectedAddOns = _selectedAddOns
                        .map((name) => _availableAddOns.firstWhere((a) => a.name == name))
                        .toList();
                    widget.onAddToCart(_selectedVariant, selectedAddOns, _quantity);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _VariantStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorConstants.primaryColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const SizedBox(
              width: 22,
              child: Icon(Icons.remove, size: 14, color: ColorConstants.primaryColor),
            ),
          ),
          SizedBox(
            width: 18,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const SizedBox(
              width: 22,
              child: Icon(Icons.add, size: 14, color: ColorConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}