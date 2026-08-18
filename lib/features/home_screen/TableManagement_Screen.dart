// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../ captain_pin_login/captain_login_screen.dart';
// import '../../constants/color_constants.dart';
// import '../printer/SettingsScreen.dart';
// import '../printer/printer_settings.dart';
// import '../printer/printer_setup_screen.dart';
// import 'All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
// import 'All_tables_list/All_tables_list_bloc/all_tables_list_event.dart';
// import 'All_tables_list/All_tables_list_bloc/all_tables_list_state.dart';
// import 'All_tables_list/all_tables_list_widget.dart';
// import 'Zones/Zones_bloc/zone_event.dart';
// import 'Zones/Zones_bloc/zone_state.dart';
// import 'Zones/Zones_bloc/zones_bloc.dart';
// import 'Zones/Zones_widget.dart';
// import 'order_menu/bloc/category_bloc/category_bloc.dart';
// import 'order_menu/bloc/category_bloc/category_event.dart';
//
// class TableManagementScreen extends StatefulWidget {
//   final String? captainName;
//   final String? captainRole;
//
//   const TableManagementScreen({
//     Key? key,
//     this.captainName,
//     this.captainRole,
//   }) : super(key: key);
//
//   @override
//   State<TableManagementScreen> createState() => _TableManagementScreenState();
// }
//
// class _TableManagementScreenState extends State<TableManagementScreen>
//     with SingleTickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   String? _selectedZoneId;
//
//   final ScrollController _tablesScrollController = ScrollController();
//   final Map<String, GlobalKey> _zoneSectionKeys = {};
//   bool _isProgrammaticScroll = false;
//   bool _isSyncing = false;
//
//   // ─── Store details from merchant login ───
//   String _storeLogo = '';
//   String _storeName = '';
//
//
//   @override
//   void initState() {
//     super.initState();
//     _loadStoreDetails();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final zoneBloc = context.read<ZoneBloc>();
//       if (zoneBloc.state is ZoneInitial) {
//         zoneBloc.add(FetchZones());
//       }
//       final tablesBloc = context.read<AllTablesBloc>();
//       if (tablesBloc.state is AllTablesInitial) {
//         tablesBloc.add(FetchAllTables());
//       }
//     });
//   }
//
//   Future<void> _loadStoreDetails() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _storeLogo = prefs.getString('store_logo') ?? '';
//       _storeName = prefs.getString('store_name') ?? 'Pinaka Restaurant';
//     });
//   }
//
//   GlobalKey _sectionKeyFor(String zoneId) {
//     return _zoneSectionKeys.putIfAbsent(zoneId, () => GlobalKey());
//   }
//
//   void _onZoneTabSelected(String zoneId) {
//     setState(() => _selectedZoneId = zoneId);
//     final ctx = _zoneSectionKeys[zoneId]?.currentContext;
//     if (ctx != null) {
//       _isProgrammaticScroll = true;
//       Scrollable.ensureVisible(
//         ctx,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         alignment: 0,
//       ).whenComplete(() {
//         Future.delayed(const Duration(milliseconds: 50), () {
//           _isProgrammaticScroll = false;
//         });
//       });
//     }
//   }
//
//   void _onZoneVisibleFromScroll(String zoneId) {
//     if (_isProgrammaticScroll) return;
//     if (_selectedZoneId != zoneId) {
//       setState(() => _selectedZoneId = zoneId);
//     }
//   }
//
//   Future<void> _onSyncPressed() async {
//     if (_isSyncing) return;
//     setState(() => _isSyncing = true);
//
//     _selectedZoneId = null;
//     if (_tablesScrollController.hasClients) {
//       _tablesScrollController.jumpTo(0);
//     }
//
//     // Refresh zones, tables AND categories
//     context.read<ZoneBloc>().add(FetchZones());
//     context.read<AllTablesBloc>().add(FetchAllTables());
//     context.read<CategoryBloc>().add(LoadCategories()); // 👈 new
//
//     await Future.delayed(const Duration(milliseconds: 600));
//     if (mounted) setState(() => _isSyncing = false);
//   }
//
//   Future<void> _onSyncDataFromDrawer() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const _SyncingOverlay(),
//     );
//
//     _selectedZoneId = null;
//     if (_tablesScrollController.hasClients) {
//       _tablesScrollController.jumpTo(0);
//     }
//
//     context.read<ZoneBloc>().add(FetchZones());
//     context.read<AllTablesBloc>().add(FetchAllTables());
//     context.read<CategoryBloc>().add(LoadCategories()); // 👈 new
//
//     await Future.delayed(const Duration(milliseconds: 900));
//
//     if (mounted) Navigator.of(context, rootNavigator: true).pop();
//   }
//
//   @override
//   void dispose() {
//     _tablesScrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: const Color(0xFFF7F7F7),
//       drawer: _AppDrawer(
//         captainName: widget.captainName ?? 'Captain',
//         captainRole: widget.captainRole ?? 'Captain',
//         onLogout: _handleLogout,
//         storeLogo: _storeLogo,
//         storeName: _storeName,
//         onSyncData: _onSyncDataFromDrawer,   // new
//
//       ),
//       appBar: AppBar(
//         elevation: 0.5,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () => _scaffoldKey.currentState?.openDrawer(),
//         ),
//         title: const Text(
//           'Table Management',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
//         ),
//         centerTitle: true,
//         actions: [IconButton(
//           icon: const Icon(Icons.table_bar_rounded),
//           onPressed: () {},
//         ),
//           SizedBox(width: size.width * 0.01),
//           IconButton(
//             icon: const Icon(Icons.notifications_none_rounded),
//             onPressed: () {},
//           ),
//           SizedBox(width: size.width * 0.01),
//         ],
//       ),
//       body: BlocBuilder<ZoneBloc, ZoneState>(
//         builder: (context, zoneState) {
//           return BlocBuilder<AllTablesBloc, AllTablesState>(
//             builder: (context, tableState) {
//               final zonesReady = zoneState is ZoneLoaded || zoneState is ZoneError;
//               final tablesReady =
//                   tableState is AllTablesLoaded || tableState is AllTablesError;
//               final isFirstLoad = !zonesReady || !tablesReady;
//
//               if (isFirstLoad) {
//                 return const Center(
//                   child: CupertinoActivityIndicator(radius: 16),
//                 );
//               }
//
//               return Column(
//                 children: [
//                   // Zone tabs row + sync icon, side by side
//                   Container(
//                     color: Colors.white,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: size.width * 0.03,
//                       vertical: size.height * 0.012,
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: ZoneTabs(
//                             selectedZoneId: _selectedZoneId,
//                             onZoneSelected: _onZoneTabSelected,
//                           ),
//                         ),
//                         IconButton(
//                           tooltip: 'Sync',
//                           icon: _isSyncing
//                               ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                               : const Icon(Icons.sync, color: Colors.black54),
//                           onPressed: _onSyncPressed,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   Expanded(
//                     child: Stack(
//                       children: [
//                         Positioned.fill(
//                           child: AllTablesListWidget(
//                             scrollController: _tablesScrollController,
//                             sectionKeyBuilder: _sectionKeyFor,
//                             onZoneVisible: _onZoneVisibleFromScroll,
//                           ),
//                         ),
//                         Positioned(
//                           left: 0,
//                           right: 0,
//                           bottom: 15,
//                           child: const _StatusLegendBar(),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _handleLogout() async {
//     final shouldLogout = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         elevation: 8,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Warning icon
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFFFE5E5), // light pink
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.warning_amber_rounded,
//                   color: Color(0xFFE53935), // red
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Title
//               const Text(
//                 'Log Out?',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // Message
//               const Text(
//                 'Are you sure you want to log out?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: Colors.black54,
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 28),
//
//               // Buttons
//               Row(
//                 children: [
//                   // Cancel (outlined)
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.of(context).pop(false),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: const Color(0xFFFF6B00), // orange
//                         side: const BorderSide(
//                           color: Color(0xFFFF6B00),
//                           width: 1.5,
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Cancel',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//
//                   // Log Out (filled)
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.of(context).pop(true),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFFF6B00), // orange
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Log Out',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//
//     if (shouldLogout != true || !mounted) return;
//
//     final captainStorage = context.read<CaptainLocalStorage>();
//     await captainStorage.clearCaptainData();
//
//     if (mounted) {
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const CaptainLoginScreen()),
//             (route) => false,
//       );
//     }
//   }
// }
//
// class _SyncingOverlay extends StatelessWidget {
//   const _SyncingOverlay();
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 56,
//               height: 56,
//               decoration: const BoxDecoration(
//                 color: ColorConstants.primaryColor,
//                 shape: BoxShape.circle,
//               ),
//               child: const Center(
//                 child: SizedBox(
//                   width: 26,
//                   height: 26,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2.5,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Syncing Data',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _StatusLegendBar extends StatelessWidget {
//   const _StatusLegendBar();
//
//   static const _items = [
//     _LegendItem('Available', Color(0xFF34A853)),
//     _LegendItem('Occupied', Color(0xFFE8B93A)),
//     _LegendItem('Running', Color(0xFFE64545)),
//     _LegendItem('Ready to Pay', Color(0xFF3B7DDB)),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           border: Border.all(color: Colors.grey.shade300, width: 1),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             for (int i = 0; i < _items.length; i++) ...[
//               _LegendDot(item: _items[i]),
//               if (i != _items.length - 1) const SizedBox(width: 10),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _LegendItem {
//   final String label;
//   final Color color;
//   const _LegendItem(this.label, this.color);
// }
//
// class _LegendDot extends StatelessWidget {
//   final _LegendItem item;
//   const _LegendDot({required this.item});
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 6,
//           height: 6,
//           decoration: BoxDecoration(
//             color: item.color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           item.label,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//             color: item.color,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _AppDrawer extends StatelessWidget {
//   final String captainName;
//   final String captainRole;
//   final VoidCallback onLogout;
//   final String storeLogo;
//   final String storeName;
//   final VoidCallback onSyncData;   // new
//
//   const _AppDrawer({
//     required this.captainName,
//     required this.captainRole,
//     required this.onLogout,
//     required this.storeLogo,
//     required this.storeName,
//     required this.onSyncData,   // new
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Center(
//                       child: Column(
//                         children: [
//                           // ─── Store Logo ───
//                           storeLogo.isNotEmpty
//                               ? ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.network(
//                               storeLogo,
//                               width: 50,
//                               height: 50,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) => const Icon(
//                                 Icons.store,
//                                 size: 40,
//                                 color: ColorConstants.primaryColor,
//                               ),
//                             ),
//                           )
//                               : const Icon(
//                             Icons.store,
//                             size: 40,
//                             color: ColorConstants.primaryColor,
//                           ),
//                           const SizedBox(height: 4),
//                           // ─── Store Name ───
//                           Text(
//                             storeName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                               letterSpacing: 1,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             'Table Management',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.keyboard_double_arrow_left,
//                         color: Colors.black45),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               ),
//               const Divider(height: 24),
//               _DrawerItem(
//                 icon: Icons.receipt_long_outlined,
//                 label: 'Table Management',
//                 highlighted: true,
//                 onTap: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//
//               _DrawerItem(
//                 icon: Icons.sync,
//                 label: 'Sync Data',
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   onSyncData();
//                 },
//               ),
//               _DrawerItem(
//                 icon: Icons.receipt_outlined,
//                 label: 'Update Menu',
//                 onTap: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//
//               _DrawerItem(
//                 icon: Icons.settings_outlined,
//                 label: 'Settings',
//                 onTap: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(builder: (_) => const SettingsScreen()),
//                   );
//                 },
//               ),
//               const Spacer(),
//               Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFDEDEC),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: ListTile(
//                   leading: const Icon(Icons.logout, color: Color(0xFFE64545)),
//                   title: const Text(
//                     'Log Out',
//                     style: TextStyle(
//                       color: Color(0xFFE64545),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   trailing: const Icon(
//                     Icons.chevron_right,
//                     color: Color(0xFFE64545),
//                   ),
//                   onTap: onLogout,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: ColorConstants.primaryColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     const CircleAvatar(
//                       radius: 20,
//                       backgroundColor: Colors.white24,
//                       child: Icon(Icons.person, color: Colors.white),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             captainName,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                             ),
//                           ),
//                           Text(
//                             captainRole,
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Icon(Icons.chevron_right, color: Colors.white),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _DrawerItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool highlighted;
//   final VoidCallback onTap;
//
//   const _DrawerItem({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//     this.highlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final color =
//     highlighted ? ColorConstants.primaryColor : Colors.black87;
//
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: Icon(icon, color: color, size: 22),
//       title: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
//           fontSize: 14.5,
//         ),
//       ),
//       trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
//       onTap: onTap,
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../ captain_pin_login/captain_login_screen.dart';
import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../../constants/color_constants.dart';
import '../printer/SettingsScreen.dart';
import '../printer/printer_settings.dart';
import '../printer/printer_setup_screen.dart';
import 'All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
import 'All_tables_list/All_tables_list_bloc/all_tables_list_event.dart';
import 'All_tables_list/All_tables_list_bloc/all_tables_list_state.dart';
import 'All_tables_list/all_tables_list_widget.dart';
import 'Zones/Zones_bloc/zone_event.dart';
import 'Zones/Zones_bloc/zone_state.dart';
import 'Zones/Zones_bloc/zones_bloc.dart';
import 'Zones/Zones_widget.dart';
import 'order_menu/bloc/category_bloc/category_bloc.dart';
import 'order_menu/bloc/category_bloc/category_event.dart';

class TableManagementScreen extends StatefulWidget {
  final String? captainName;
  final String? captainRole;

  const TableManagementScreen({
    Key? key,
    this.captainName,
    this.captainRole,
  }) : super(key: key);

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedZoneId;

  final ScrollController _tablesScrollController = ScrollController();
  final Map<String, GlobalKey> _zoneSectionKeys = {};
  bool _isProgrammaticScroll = false;
  bool _isSyncing = false;

  // ─── Store details from merchant login ───
  String _storeLogo = '';
  String _storeName = '';

  // ─── Captain details from captain login ───
  String _captainName = 'Captain';
  String _captainRole = 'Captain';

  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
    _loadCaptainDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final zoneBloc = context.read<ZoneBloc>();
      if (zoneBloc.state is ZoneInitial) {
        zoneBloc.add(FetchZones());
      }
      final tablesBloc = context.read<AllTablesBloc>();
      if (tablesBloc.state is AllTablesInitial) {
        tablesBloc.add(FetchAllTables());
      }
    });
  }

  // ─── Load store details from SharedPreferences ───
  Future<void> _loadStoreDetails() async {
    try {
      // 1. Try to get merchant data from storage
      final merchantStorage = context.read<MerchantLocalStorage>();
      final merchantData = await merchantStorage.getMerchantData();

      if (merchantData != null) {
        setState(() {
          _storeName = merchantData.storeName ?? 'Pinaka Restaurant';
          _storeLogo = merchantData.storeLogo ?? '';
        });
        print('🪙 Store Name (from merchant data): $_storeName');
        print('🪙 Store Logo (from merchant data): $_storeLogo');
        return;
      }

      // 2. Fallback: read raw SharedPreferences keys (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      print(' All SharedPreferences keys: ${prefs.getKeys()}');

      setState(() {
        _storeName = prefs.getString('store_name') ??
            prefs.getString('store_info') ??
            prefs.getString('restaurant_name') ??
            'Pinaka Restaurant';
        _storeLogo = prefs.getString('store_logo') ??
            prefs.getString('logo') ??
            '';
      });
      print('🪙 Store Name (fallback): $_storeName');
      print('🪙 Store Logo (fallback): $_storeLogo');
    } catch (e) {
      print('🪙 Error loading store details: $e');
      // Final fallback
      setState(() {
        _storeName = 'Pinaka Restaurant';
        _storeLogo = '';
      });
    }
  }

  // ─── Load captain details from CaptainLocalStorage ───
  Future<void> _loadCaptainDetails() async {
    try {
      final captainStorage = context.read<CaptainLocalStorage>();
      final captainData = await captainStorage.getCaptainData();

      setState(() {
        _captainName = captainData?.data?.displayName ??
            widget.captainName ??
            'Captain';
        _captainRole = captainData?.data?.role ??
            widget.captainRole ??
            'Captain';
      });
      print('🪙 Captain Name: $_captainName');
      print('🪙 Captain Role: $_captainRole');
      // print('🪙 Captain Data: ${captainData?.data?.toJson()}');
    } catch (e) {
      print('🪙 Error loading captain details: $e');
      setState(() {
        _captainName = widget.captainName ?? 'Captain';
        _captainRole = widget.captainRole ?? 'Captain';
      });
    }
  }

  GlobalKey _sectionKeyFor(String zoneId) {
    return _zoneSectionKeys.putIfAbsent(zoneId, () => GlobalKey());
  }

  void _onZoneTabSelected(String zoneId) {
    setState(() => _selectedZoneId = zoneId);
    final ctx = _zoneSectionKeys[zoneId]?.currentContext;
    if (ctx != null) {
      _isProgrammaticScroll = true;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0,
      ).whenComplete(() {
        Future.delayed(const Duration(milliseconds: 50), () {
          _isProgrammaticScroll = false;
        });
      });
    }
  }

  void _onZoneVisibleFromScroll(String zoneId) {
    if (_isProgrammaticScroll) return;
    if (_selectedZoneId != zoneId) {
      setState(() => _selectedZoneId = zoneId);
    }
  }

  Future<void> _onSyncPressed() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    _selectedZoneId = null;
    if (_tablesScrollController.hasClients) {
      _tablesScrollController.jumpTo(0);
    }

    // Refresh zones, tables AND categories
    context.read<ZoneBloc>().add(FetchZones());
    context.read<AllTablesBloc>().add(FetchAllTables());
    context.read<CategoryBloc>().add(LoadCategories());

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isSyncing = false);
  }

  Future<void> _onSyncDataFromDrawer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SyncingOverlay(),
    );

    _selectedZoneId = null;
    if (_tablesScrollController.hasClients) {
      _tablesScrollController.jumpTo(0);
    }

    context.read<ZoneBloc>().add(FetchZones());
    context.read<AllTablesBloc>().add(FetchAllTables());
    context.read<CategoryBloc>().add(LoadCategories());

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _tablesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F7F7),
      drawer: _AppDrawer(
        captainName: _captainName, // ✅ loaded from storage
        captainRole: _captainRole, // ✅ loaded from storage
        onLogout: _handleLogout,
        storeLogo: _storeLogo, // ✅ loaded from storage
        storeName: _storeName, // ✅ loaded from storage
        onSyncData: _onSyncDataFromDrawer,
      ),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Table Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_bar_rounded),
            onPressed: () {
              // TODO: table layout view
            },
          ),
          SizedBox(width: size.width * 0.01),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          SizedBox(width: size.width * 0.01),
        ],
      ),
      body: BlocBuilder<ZoneBloc, ZoneState>(
        builder: (context, zoneState) {
          return BlocBuilder<AllTablesBloc, AllTablesState>(
            builder: (context, tableState) {
              final zonesReady = zoneState is ZoneLoaded || zoneState is ZoneError;
              final tablesReady =
                  tableState is AllTablesLoaded || tableState is AllTablesError;
              final isFirstLoad = !zonesReady || !tablesReady;

              if (isFirstLoad) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 16),
                );
              }

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.height * 0.012,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ZoneTabs(
                            selectedZoneId: _selectedZoneId,
                            onZoneSelected: _onZoneTabSelected,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sync',
                          icon: _isSyncing
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.sync, color: Colors.black54),
                          onPressed: _onSyncPressed,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AllTablesListWidget(
                            scrollController: _tablesScrollController,
                            sectionKeyBuilder: _sectionKeyFor,
                            onZoneVisible: _onZoneVisibleFromScroll,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 15,
                          child: const _StatusLegendBar(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── Logout Handler ──────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53935),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B00),
                        side: const BorderSide(
                          color: Color(0xFFFF6B00),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout != true || !mounted) return;

    final captainStorage = context.read<CaptainLocalStorage>();
    await captainStorage.clearCaptainData();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CaptainLoginScreen()),
            (route) => false,
      );
    }
  }
}

// ─── Syncing Overlay ──────────────────────────────────────────────────
class _SyncingOverlay extends StatelessWidget {
  const _SyncingOverlay();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: ColorConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Syncing Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Legend ─────────────────────────────────────────────────────
class _StatusLegendBar extends StatelessWidget {
  const _StatusLegendBar();

  static const _items = [
    _LegendItem('Available', Color(0xFF34A853)),
    _LegendItem('Occupied', Color(0xFFE8B93A)),
    _LegendItem('Running', Color(0xFFE64545)),
    _LegendItem('Ready to Pay', Color(0xFF3B7DDB)),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _items.length; i++) ...[
              _LegendDot(item: _items[i]),
              if (i != _items.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}

class _LegendDot extends StatelessWidget {
  final _LegendItem item;
  const _LegendDot({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: item.color,
          ),
        ),
      ],
    );
  }
}

// ─── Drawer ────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final String captainName;
  final String captainRole;
  final VoidCallback onLogout;
  final String storeLogo;
  final String storeName;
  final VoidCallback onSyncData;

  const _AppDrawer({
    required this.captainName,
    required this.captainRole,
    required this.onLogout,
    required this.storeLogo,
    required this.storeName,
    required this.onSyncData,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // ─── Header ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Logo + Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // ← left aligned
                      children: [
                        // Store Logo
                        storeLogo.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            storeLogo,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.store,
                              size: 40,
                              color: ColorConstants.primaryColor,
                            ),
                          ),
                        )
                            : const Icon(
                          Icons.store,
                          size: 40,
                          color: ColorConstants.primaryColor,
                        ),
                        const SizedBox(height: 6),
                        // Store Name
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Table Management',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button (right side)
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_double_arrow_left,
                      color: Colors.black45,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                label: 'Table Management',
                highlighted: true,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              _DrawerItem(
                icon: Icons.sync,
                label: 'Sync Data',
                onTap: () {
                  Navigator.of(context).pop();
                  onSyncData();
                },
              ),
              _DrawerItem(
                icon: Icons.receipt_outlined,
                label: 'Update Menu',
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFE64545)),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFE64545),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFE64545),
                  ),
                  onTap: onLogout,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            captainName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            captainRole,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    highlighted ? ColorConstants.primaryColor : Colors.black87;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14.5,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
      onTap: onTap,
    );
  }
}