// import 'package:flutter/material.dart';
//
// import '../../models/UserPermissions.dart';
// import '../widgets/top_bar.dart';
//
// // import 'active_order.dart';
//
// class KitchendisplayScreen extends StatefulWidget {
//   final String pin;
//   final String associatedManagerPin;
//   final String token;
//   final String restaurantId;
//   final String restaurantName;
//   final UserPermissions? userPermissions; // ADD
//
//   const KitchendisplayScreen({
//     Key? key,
//     required this.pin,
//     required this.associatedManagerPin,
//     required this.token,
//     required this.restaurantId,
//     required this.restaurantName,
//     this.userPermissions, // ADD
//   }) : super(key: key);
//
//   @override
//   State<KitchendisplayScreen> createState() =>
//       _KitchenDashboardScreenState();
// }
//
// class _KitchenDashboardScreenState
//     extends State<KitchendisplayScreen> {
//   String selectedOrderType = "All";
//   // Add these variables
//   UserPermissions? _userPermissions;
//
//   Map<String, dynamic>? _selectedUser;
//
//   int? _selectedTableIndex;
//
//   dynamic _selectedTable;
//
//   dynamic _selectedKot;
//
//   final List<dynamic> _kotItems = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     _userPermissions = widget.userPermissions;
//   }
//
//
//   final List<Map<String, dynamic>> orders = [
//     {
//       "id": "#24367",
//       "type": "Dine-In",
//       "status": "Pending",
//       "isCancelled": false,
//       "headerColor": const Color(0xff6C74B8),
//       "items": [
//         {
//           "name": "Paneer Tikka",
//           "qty": 1,
//           "status": "Preparing",
//         },
//         {
//           "name": "Tandoori Naan",
//           "qty": 2,
//           "status": "Preparing",
//         },
//       ]
//     },
//
//     {
//       "id": "#24368",
//       "type": "Takeaway",
//       "status": "Pending",
//       "isCancelled": false,
//       "headerColor": const Color(0xffE67E50),
//       "items": [
//         {
//           "name": "Veg Fried Rice",
//           "qty": 1,
//           "status": "Preparing",
//         },
//         {
//           "name": "Noodles",
//           "qty": 2,
//           "status": "Preparing",
//         },
//       ]
//     },
//
//     {
//       "id": "#24369",
//       "type": "Online",
//       "status": "Pending",
//       "isCancelled": false,
//       "headerColor": const Color(0xff4CAF50),
//       "items": [
//         {
//           "name": "Burger",
//           "qty": 2,
//           "status": "Preparing",
//         },
//         {
//           "name": "French Fries",
//           "qty": 1,
//           "status": "Preparing",
//         },
//       ]
//     },
//
//     {
//       "id": "#24370",
//       "type": "Dine-In",
//       "status": "Pending",
//       "isCancelled": false,
//       "headerColor": const Color(0xff6C74B8),
//       "items": [
//         {
//           "name": "Butter Chicken",
//           "qty": 1,
//           "status": "Preparing",
//         },
//         {
//           "name": "Naan",
//           "qty": 3,
//           "status": "Preparing",
//         },
//       ]
//     },
//   ];
//   @override
//   Widget build(BuildContext context) {
//     List<Map<String, dynamic>> filteredOrders =
//     orders.where((order) {
//       if (selectedOrderType == "All") {
//         return true;
//       }
//
//       return order["type"] == selectedOrderType;
//     }).toList();
//
//     return Scaffold(
//       // backgroundColor: const Color(0xffF4F4F4),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(2),
//           child: Column(
//             children: [
//
//               // =======================
//               // TOP BAR
//               // =======================
//               TopBar(
//                 token: widget.token,
//                 pin: widget.pin,
//                 userPermissions: _userPermissions,
//                 onPermissionsReceived: (permissions) async {
//                   setState(() {
//                     _userPermissions = permissions;
//
//                     _selectedUser = {
//                       "id": permissions.userId,
//                       "name": permissions.displayName,
//                       "role": permissions.role,
//                     };
//
//                     _selectedTableIndex = null;
//                     _selectedTable = null;
//                     _selectedKot = null;
//                     _kotItems.clear();
//                   });
//
//                   // await _fetchOrders();
//                 },
//               ),
//
//               const SizedBox(height: 15),
//
//               // =======================
//               // BODY
//               // =======================
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     // border: Border.all(
//                     //   color: Colors.blue,
//                     //   width: 2,
//                     // ),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//
//                       // =======================
//                       // FILTER HEADER
//                       // =======================
//                       Row(
//                         children: [
//                           Container(
//                             height: 45,
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             child: Row(
//                               children: [
//                                 _filterChip("All"),
//                                 _filterChip("Dine-In"),
//                                 _filterChip("Takeaway"),
//                                 _filterChip("Online"),
//                               ],
//                             ),
//                           ),
//
//                           const Spacer(),
//
//                           Container(
//                             height: 45,
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: const Color(0xff6C74B8),
//                               ),
//                               borderRadius:
//                               BorderRadius.circular(30),
//                             ),
//                             child: Row(
//                               children: [
//                                 GestureDetector(
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             ActiveOrdersScreen(
//                                               orders: orders
//                                                   .where(
//                                                     (o) =>
//                                                 o["status"] ==
//                                                     "Preparing",
//                                               )
//                                                   .toList(),
//                                             ),
//                                       ),
//                                     );
//                                   },
//                                   child: _statusTab(
//                                     "Active Orders",
//                                     false,
//                                   ),
//                                 ),
//                                 _statusTab(
//                                   "Pending Orders",
//                                   true,
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                           const SizedBox(width: 20),
//
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor:
//                               const Color(0xffFF5B4F),
//                               padding:
//                               const EdgeInsets.symmetric(
//                                 horizontal: 25,
//                                 vertical: 15,
//                               ),
//                               shape:
//                               RoundedRectangleBorder(
//                                 borderRadius:
//                                 BorderRadius.circular(
//                                   25,
//                                 ),
//                               ),
//                             ),
//                             onPressed: () {},
//                             child: const Text(
//                               "Completed Orders →",
//                               style: TextStyle(
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // =======================
//                       // ORDERS GRID
//                       // =======================
//                       Expanded(
//                         child: GridView.builder(
//                           itemCount:
//                           filteredOrders.length,
//                           gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 4,
//                             crossAxisSpacing: 15,
//                             mainAxisSpacing: 15,
//                             childAspectRatio: 0.85,
//                           ),
//                           itemBuilder:
//                               (context, index) {
//
//                             final order =
//                             filteredOrders[index];
//
//                             return _buildOrderCard(
//                               order,
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   Widget _buildOrderCard(Map<String, dynamic> order) {
//     return Stack(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 4,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 height: 32,
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: order["headerColor"],
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(8),
//                     topRight: Radius.circular(8),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Text(
//                       order["id"],
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       order["type"],
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Icon(
//                       Icons.access_time,
//                       color: Colors.white,
//                       size: 14,
//                     ),
//                     const SizedBox(width: 2),
//                     const Text(
//                       "10:17",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               "Dine In - Garden-T4",
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             "Thu, Feb 12, 2026 | 11:30 AM",
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.black45,
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const Divider(),
//
//                       const Row(
//                         children: [
//                           Text(
//                             "Items",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.black54,
//                             ),
//                           ),
//                           Spacer(),
//                           Text(
//                             "KOT No: 29",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: order["items"].length,
//                           itemBuilder: (context, index) {
//                             final item = order["items"][index];
//
//                             return Container(
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 8,
//                               ),
//                               decoration: const BoxDecoration(
//                                 border: Border(
//                                   bottom: BorderSide(
//                                     color: Color(0xffEEEEEE),
//                                   ),
//                                 ),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       "${item["name"]} × ${item["qty"]}",
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                   const Text(
//                                     "• New",
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.black54,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       const Text(
//                         "Ready: 0 / 4",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//
//                       const SizedBox(height: 10),
//
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton(
//                               style: OutlinedButton.styleFrom(
//                                 side: const BorderSide(
//                                   color: Color(0xffFF5B4F),
//                                 ),
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   order["isCancelled"] = true;
//                                 });
//                               },
//                               child: const Text(
//                                 "Cancel",
//                                 style: TextStyle(
//                                   color: Color(0xffFF5B4F),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 10),
//
//                           Expanded(
//                             child:  ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xffFF5B4F),
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   order["status"] = "Preparing";
//                                 });
//
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => ActiveOrdersScreen(
//                                       orders: orders
//                                           .where((o) => o["status"] == "Preparing")
//                                           .toList(),
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: const Text(
//                                 "Start",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // Cancel Overlay
//         if (order["isCancelled"] == true)
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       "KOT order cancelled",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//
//                     const SizedBox(height: 15),
//
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         setState(() {
//                           order["isCancelled"] = false;
//                         });
//                       },
//                       icon: const Icon(Icons.refresh),
//                       label: const Text("Recall"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: Colors.blue,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//   Widget _filterChip(String title) {
//     bool isSelected =
//         selectedOrderType == title;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedOrderType = title;
//         });
//       },
//       child: Container(
//         margin:
//         const EdgeInsets.symmetric(horizontal: 3),
//         padding: const EdgeInsets.symmetric(
//           horizontal: 15,
//         ),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? const Color(0xffFFF2ED)
//               : Colors.white,
//           borderRadius:
//           BorderRadius.circular(20),
//           border: isSelected
//               ? Border.all(
//               color: Colors.orange)
//               : null,
//         ),
//         alignment: Alignment.center,
//         child: Text(title),
//       ),
//     );
//   }
//
//   Widget _statusTab(
//       String title, bool selected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//       ),
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: selected
//             ? const Color(0xff6C74B8)
//             : Colors.white,
//         borderRadius:
//         BorderRadius.circular(25),
//       ),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: selected
//               ? Colors.white
//               : const Color(0xff6C74B8),
//         ),
//       ),
//     );
//   }
//
// }
// class ActiveOrdersScreen extends StatefulWidget {
//   final List<Map<String, dynamic>> orders;
//
//   const ActiveOrdersScreen({
//     super.key,
//     required this.orders,
//   });
//
//   @override
//   State<ActiveOrdersScreen> createState() =>
//       _ActiveOrdersScreenState();
// }
// class _ActiveOrdersScreenState
//     extends State<ActiveOrdersScreen> {
//
//   late List<Map<String, dynamic>> preparingOrders;
//   List<Map<String, dynamic>> readyOrders = [];
//   List<Map<String, dynamic>> servedOrders = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     preparingOrders =
//     List<Map<String, dynamic>>.from(
//       widget.orders,
//     );
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF5F5F5),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // Header
//               Row(
//                 children: [
//                   Container(
//                     height: 45,
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius:
//                       BorderRadius.circular(30),
//                       boxShadow: const [
//                         BoxShadow(
//                           blurRadius: 5,
//                           color: Colors.black12,
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         _filterChip("All", true),
//                         _filterChip(
//                             "Dine-In", false),
//                         _filterChip(
//                             "Takeaways", false),
//                         _filterChip(
//                             "Online Orders",
//                             false),
//                       ],
//                     ),
//                   ),
//
//                   const Spacer(),
//
//                   Container(
//                       height: 45,
//                       padding:
//                       const EdgeInsets.all(3),
//                       decoration: BoxDecoration(
//                         border: Border.all(
//                           color:
//                           const Color(0xff5D78C8),
//                         ),
//                         borderRadius:
//                         BorderRadius.circular(
//                             25),
//                       ),
//                       child: Row(
//                         children: [
//                           _statusChip(
//                             "Active Orders",
//                             true,
//                           ),
//
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pop(context);
//                             },
//                             child: _statusChip(
//                               "Pending Orders",
//                               false,
//                             ),
//                           ),
//                         ],
//                       )
//                   ),
//
//                   const SizedBox(width: 20),
//
//                   ElevatedButton(
//                     style:
//                     ElevatedButton.styleFrom(
//                       backgroundColor:
//                       const Color(
//                           0xffFF5B4F),
//                       shape:
//                       RoundedRectangleBorder(
//                         borderRadius:
//                         BorderRadius.circular(
//                             25),
//                       ),
//                       padding:
//                       const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 15,
//                       ),
//                     ),
//                     onPressed: () {},
//                     child: const Text(
//                       "Completed Orders →",
//                       style: TextStyle(
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 20),
//
//               Expanded(
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: _buildSection(
//                         title: "Preparing",
//                         color: Colors.orange,
//                         child: ListView.builder(
//                           itemCount: preparingOrders.length,
//                           itemBuilder: (context, index) {
//                             final order =
//                             preparingOrders[index];
//
//                             return Padding(
//                               padding:
//                               const EdgeInsets.only(
//                                   bottom: 12),
//                               child: Draggable<
//                                   Map<String, dynamic>>(
//                                 data: order,
//                                 feedback: Material(
//                                   child: SizedBox(
//                                     width: 250,
//                                     child:
//                                     _buildOrderCard(
//                                         order),
//                                   ),
//                                 ),
//                                 childWhenDragging:
//                                 Opacity(
//                                   opacity: 0.3,
//                                   child:
//                                   _buildOrderCard(
//                                       order),
//                                 ),
//                                 child:
//                                 _buildOrderCard(
//                                     order),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(width: 12),
//
//                     Expanded(
//                       child: _buildSection(
//                         title: "Ready",
//                         color: Colors.green,
//                         child: DragTarget<Map<String, dynamic>>(
//                           onAccept: (order) {
//                             setState(() {
//                               preparingOrders.remove(order);
//                               readyOrders.add(order);
//                             });
//                           },
//                           builder: (
//                               context,
//                               candidateData,
//                               rejectedData,
//                               ) {
//                             return ListView.builder(
//                               itemCount: readyOrders.length,
//                               itemBuilder: (_, index) {
//                                 final order = readyOrders[index];
//
//                                 return Padding(
//                                   padding: const EdgeInsets.only(
//                                     bottom: 12,
//                                   ),
//                                   child: Draggable<Map<String, dynamic>>(
//                                     data: order,
//                                     feedback: Material(
//                                       child: SizedBox(
//                                         width: 250,
//                                         child: _buildOrderCard(order),
//                                       ),
//                                     ),
//                                     childWhenDragging: Opacity(
//                                       opacity: 0.3,
//                                       child: _buildOrderCard(order),
//                                     ),
//                                     child: _buildOrderCard(order),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(width: 12),
//
//                     Expanded(
//                       child: _buildSection(
//                         title: "Served",
//                         color: Colors.red,
//                         child: DragTarget<
//                             Map<String, dynamic>>(
//                           onAccept: (order) {
//                             setState(() {
//                               readyOrders
//                                   .remove(order);
//
//                               servedOrders
//                                   .add(order);
//                             });
//                           },
//                           builder: (
//                               context,
//                               candidateData,
//                               rejectedData,
//                               ) {
//                             return ListView.builder(
//                               itemCount:
//                               servedOrders.length,
//                               itemBuilder:
//                                   (_, index) {
//                                 return _buildOrderCard(
//                                   servedOrders[
//                                   index],
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSection({
//     required String title,
//     required Color color,
//     required Widget child,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Container(
//             height: 50,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: color,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: child,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderCard(
//       Map<String, dynamic> order) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             blurRadius: 4,
//             color: Colors.black12,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             height: 45,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 12,
//             ),
//             decoration: const BoxDecoration(
//               color: Color(0xff6C74B8),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(10),
//                 topRight: Radius.circular(10),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   order["id"]?.toString() ?? "",
//                   style: const TextStyle(
//                     color: Colors.white,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   order["type"]?.toString() ?? "",
//                   style: const TextStyle(
//                     color: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               children: [
//                 ...((order["items"] ?? []) as List)
//                     .map<Widget>(
//                       (item) {
//                     if (item is! Map<String, dynamic>) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 6),
//                         child: Text(item.toString()),
//                       );
//                     }
//
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 6),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               item["name"]?.toString() ?? "",
//                             ),
//                           ),
//                           Text(
//                             "x ${item["qty"] ?? 0}",
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ).toList(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _filterChip(
//       String title,
//       bool selected) {
//     return Container(
//       margin:
//       const EdgeInsets.symmetric(
//           horizontal: 3),
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 15,
//       ),
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: selected
//             ? const Color(0xffFFF2ED)
//             : Colors.white,
//         borderRadius:
//         BorderRadius.circular(20),
//         border: selected
//             ? Border.all(
//             color: Colors.orange)
//             : null,
//       ),
//       child: Text(title),
//     );
//   }
//
//   Widget _statusChip(
//       String title,
//       bool selected) {
//     return Container(
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 18,
//       ),
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: selected
//             ? const Color(0xff5D78C8)
//             : Colors.white,
//         borderRadius:
//         BorderRadius.circular(20),
//       ),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: selected
//               ? Colors.white
//               : const Color(
//               0xff5D78C8),
//           fontWeight:
//           FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }