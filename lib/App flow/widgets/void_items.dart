import 'package:flutter/material.dart';

class Item {
  Item({required this.name, this.quantity = 1, this.amount = 0.0, this.selected = true, this.voidRemark = ''});

// Item details
  String name;
  int quantity;
  double amount;

// If disabled, enable void remark
  bool selected;

// Void Remark
  String voidRemark;

  double get pricePerItem => amount / quantity;
}

class VoidReasonsWidget extends StatelessWidget {
  final Item item;
  final ValueChanged<String> onRemark;

  VoidReasonsWidget({required this.item, required this.onRemark, super.key});

// List of predefined void reasons
  final List<String> voidReasons = ['Poor Quality', 'Guest Rejected', 'Changed Item', 'Bad Taste', 'Wrong Order'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Void Remarks', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          onChanged: onRemark,
          decoration: InputDecoration(
            labelText: "Void reason here",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        Wrap(
          spacing: 8,
          children: voidReasons.map((reason) {
            return ActionChip(
              label: Text(reason),
              onPressed: () {
                onRemark(reason);
              },
            );
          }).toList(),
        )
      ],
    );
  }
}

class ItemWidget extends StatefulWidget {
  final Item item;

  ItemWidget({required this.item, super.key});

  @override
  ItemWidgetState createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: widget.item.selected,
                  onChanged: (val) {
                    setState(() {
                      widget.item.selected = val!;
                    });
                  },
                ),
                Expanded(
                    child: Text(widget.item.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            Row(
              children: [
                IconButton(
                    icon: Icon(Icons.remove),
                    color: Colors.red,
                    onPressed: widget.item.quantity > 0 ? () {
                      setState(() {
                        widget.item.quantity--;
                        widget.item.amount -= widget.item.pricePerItem;
                        if (widget.item.quantity == 0) {
                          widget.item.selected = false;
                        }
                      });
                    } : null),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${widget.item.quantity}')),
                IconButton(icon: Icon(Icons.add), color: Colors.red, onPressed: () {
                  setState(() {
                    widget.item.quantity++;
                    widget.item.amount += widget.item.pricePerItem;
                  });
                }),
                Spacer(),
                Text('₹${widget.item.amount.toStringAsFixed(2)}'),
              ],
            ),
            if (!widget.item.selected)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: VoidReasonsWidget(
                  item: widget.item,
                  onRemark: (remark) {
                    setState(() {
                      widget.item.voidRemark = remark;
                    });
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}

class VoidItemsScreen extends StatefulWidget {
  final List<Item> items;

  VoidItemsScreen({required this.items, super.key});

  @override
  VoidItemsScreenState createState() => VoidItemsScreenState();
}

class VoidItemsScreenState extends State<VoidItemsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Void Items")),
      body: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return ItemWidget(item: widget.items[index]);
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Handle saving
            Navigator.of(context).pop();
          },
          child: Text("Save"),
        ),
      ),
    );
  }
}

void main() {
  List<Item> items = [
    Item(name: "Paneer Tikka", quantity: 1, amount: 220),
    Item(name: "Paneer Masala", quantity: 2, amount: 300),
    Item(name: "Chicken 65", quantity: 1, amount: 220),
    Item(name: "Fish Fry", quantity: 1, amount: 300),
  ];

  runApp(MaterialApp(home: VoidItemsScreen(items: items)));
}

