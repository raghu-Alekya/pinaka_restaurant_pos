import 'package:flutter/material.dart';
class Mainscreen extends StatelessWidget {
  final Map<String, dynamic> tableData;

  const Mainscreen({Key? key, required this.tableData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guest Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Area Name: ${tableData['areaName']}'),
            Text('Table Name: ${tableData['tableName']}'),
            Text('Guest Count: ${tableData['guestCount']}'),
            Text('Customer Name: ${tableData['customerName']}'),
            Text('Captain: ${tableData['captain']}'),
            Text('Capacity: ${tableData['capacity']}'),
          ],
        ),
      ),
    );
  }
}
