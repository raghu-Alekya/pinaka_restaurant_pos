import 'package:flutter/material.dart';
import '../../../../constants/color_constants.dart';
import '../entities/product_entity.dart';

class AddOnItem {
  final String name;
  final double price;

  AddOnItem({required this.name, required this.price});
}

class AddOnBottomSheet extends StatefulWidget {
  final ProductEntity product;
  final Function(ProductEntity? selectedVariant, List<AddOnItem> selectedAddOns)
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
  // Mock variants – replace with real data from product.attributes if available
  final List<ProductEntity> _variants = [
    ProductEntity(id: 0, name: 'Regular', price: '0'),
    ProductEntity(id: 0, name: 'Large', price: '2.00'),
    ProductEntity(id: 0, name: 'Extra Large', price: '4.00'),
  ];

  // Mock add-ons – replace with real data from product.meta or attributes
  final List<AddOnItem> _availableAddOns = [
    AddOnItem(name: 'Extra Ghee', price: 1.00),
    AddOnItem(name: 'Extra Karam Podi', price: 1.00),
    AddOnItem(name: 'Extra Chutney', price: 1.00),
  ];

  ProductEntity? _selectedVariant;
  final Map<String, bool> _selectedAddOns = {};

  @override
  void initState() {
    super.initState();
    // Initially select the first variant (if any)
    if (_variants.isNotEmpty) {
      _selectedVariant = _variants.first;
    }
    // Initially none selected
    for (var addon in _availableAddOns) {
      _selectedAddOns[addon.name] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = double.tryParse(widget.product.price ?? '0') ?? 0;
    final variantPrice = _selectedVariant != null
        ? double.tryParse(_selectedVariant!.price ?? '0') ?? 0
        : 0;
    final addOnsTotal = _selectedAddOns.entries
        .where((e) => e.value)
        .fold(0.0, (sum, e) {
      final addon = _availableAddOns.firstWhere((a) => a.name == e.key);
      return sum + addon.price;
    });
    final totalPrice = basePrice + variantPrice + addOnsTotal;

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Base Price: \$${basePrice.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Divider(height: 24),
          // Variants section
          if (_variants.isNotEmpty) ...[
            const Text(
              'Variants',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _variants.map((variant) {
                final isSelected = _selectedVariant == variant;
                return ChoiceChip(
                  label: Text(
                    '${variant.name} (+\$${variant.price})',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedVariant = selected ? variant : null;
                    });
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: ColorConstants.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // Add-ons section
          if (_availableAddOns.isNotEmpty) ...[
            const Text(
              'Add Ons',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._availableAddOns.map((addon) {
              final isSelected = _selectedAddOns[addon.name] ?? false;
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedAddOns[addon.name] = value ?? false;
                  });
                },
                title: Text(addon.name),
                subtitle: Text('+\$${addon.price.toStringAsFixed(2)}'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
          // Total and button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  final selectedAddOns = _selectedAddOns.entries
                      .where((e) => e.value)
                      .map((e) => _availableAddOns.firstWhere((a) => a.name == e.key))
                      .toList();
                  widget.onAddToCart(_selectedVariant, selectedAddOns);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Add to Cart'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}