import 'package:flutter/material.dart';
import '../../models/inventory/bev_model.dart';
// import '../../models/inventory/bevmodel.dart';
// import '../../models/inventory/manage_stock.dart';
import '../../repositories/inventory_repository/manage_stock _repository.dart';
// import '../../repositories/manage_stock_inventory.dart';



class ManageStockDialog extends StatefulWidget {
  final Products beverage;
  // final  beverage;

  const ManageStockDialog({Key? key, required this.beverage}) : super(key: key);

  @override
  State<ManageStockDialog> createState() => _ManageStockDialogState();
}

class _ManageStockDialogState extends State<ManageStockDialog> {
  final TextEditingController quantityController = TextEditingController();
  final ManageStockRepository _repository = ManageStockRepository();

  bool isAddingStock = true;
  bool isLoading = false;

  final List<String> reduceReasons = ['Damage', 'Expiry', 'Adjustment Entry', 'Manual Sale'];
  final List<String> addReasons = ['Restock', 'Transfer', 'Supplier', 'Return', 'Promotional'];

  late Map<String, bool> reduceSelected;
  late Map<String, bool> addSelected;


  @override
  void initState() {
    super.initState();
    reduceSelected = {for (var r in reduceReasons) r: false};
    addSelected = {for (var r in addReasons) r: false};
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  List<String> _getSelectedReasons() {
    if (isAddingStock) {
      return addSelected.entries.where((e) => e.value).map((e) => e.key).toList();
    } else {
      return reduceSelected.entries.where((e) => e.value).map((e) => e.key).toList();
    }
  }

  Future<void> _handleSave() async {
    final quantity = int.tryParse(quantityController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    final reasons = _getSelectedReasons();
    if (reasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one reason.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _repository.updateStock(
        itemId: widget.beverage.id!,   //  item_id (NOT productId)
        qty: quantity,                 // qty
        isAdd: isAddingStock,           // Add / Reduce
        reason: reasons.first,          // API expects SINGLE reason
      );

      if (response.success) {
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Stock update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Center(
                            child: Text(
                              'Manage Stock',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(false), // Return false on cancel
                              child: Image.asset(
                                'assets/cross manage.png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Center(child: Image.asset('assets/Corona-Extra-Beer-355ml-1 2.png', height: 60)),
                      const SizedBox(height: 8),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.beverage.itemName ?? 'Unnamed',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 4),
                            // Text(
                            //   '${widget.beverage.sku}ml',
                            //   style: const TextStyle(color: Colors.grey, fontSize: 14),
                            // ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text('Enter Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter number of units',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  isAddingStock = false;
                                  reduceSelected.updateAll((key, value) => false);
                                  addSelected.updateAll((key, value) => false);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text("Reduce Stock"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAddingStock ? Colors.white : Colors.redAccent,
                                foregroundColor: isAddingStock ? Colors.redAccent : Colors.white,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  isAddingStock = true;
                                  reduceSelected.updateAll((key, value) => false);
                                  addSelected.updateAll((key, value) => false);
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text("Add Stock"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAddingStock ? Colors.green : Colors.white,
                                foregroundColor: isAddingStock ? Colors.white : Colors.green,
                                side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reduce Reasons Column
                          Expanded(
                            child: Opacity(
                              opacity: isAddingStock ? 0.4 : 1.0, // dull when disabled
                              child: IgnorePointer(
                                ignoring: isAddingStock, // block taps
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Reason',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ...reduceReasons.map((reason) {
                                      return CheckboxListTile(
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                                        dense: true,
                                        title: Text(reason, style: const TextStyle(fontSize: 12)),
                                        value: reduceSelected[reason],
                                        onChanged: (value) {
                                          setState(() {
                                            reduceSelected[reason] = value ?? false;
                                          });
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),


                          Container(
                            height: 200,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: Colors.grey.shade300,
                          ),

                          // Add Reasons Column
                          Expanded(
                            child: Opacity(
                              opacity: isAddingStock ? 1.0 : 0.4, // dull when disabled
                              child: IgnorePointer(
                                ignoring: !isAddingStock, // block taps
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Reason',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ...addReasons.map((reason) {
                                      return CheckboxListTile(
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                                        dense: true,
                                        title: Text(reason, style: const TextStyle(fontSize: 12)),
                                        value: addSelected[reason],
                                        onChanged: (value) {
                                          setState(() {
                                            addSelected[reason] = value ?? false;
                                          });
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSave,
                          child: isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6CF7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}