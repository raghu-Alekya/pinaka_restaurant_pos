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
  String _selectedStatusFilter = 'All';

  final GlobalKey _filterIconKey = GlobalKey();

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

  // void _onZoneTabSelected(String zoneId) {
  //   setState(() => _selectedZoneId = zoneId);
  //   final ctx = _zoneSectionKeys[zoneId]?.currentContext;
  //   if (ctx != null) {
  //     _isProgrammaticScroll = true;
  //     Scrollable.ensureVisible(
  //       ctx,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeInOut,
  //       alignment: 0,
  //     ).whenComplete(() {
  //       Future.delayed(const Duration(milliseconds: 50), () {
  //         _isProgrammaticScroll = false;
  //       });
  //     });
  //   }
  // }

  void _onZoneTabSelected(String zoneId) {
    setState(() => _selectedZoneId = zoneId);
    // Force a fresh pass (skip any stale cached context) so a single
    // tap always lands correctly, even right after a drawer transition.
    _scrollToZoneSection(zoneId, attempt: 0, forceFreshScroll: true);
  }

  void _scrollToZoneSection(
      String zoneId, {
        int attempt = 0,
        bool forceFreshScroll = false,
      }) {
    const maxAttempts = 25;

    final ctx = (forceFreshScroll && attempt == 0)
        ? null
        : _zoneSectionKeys[zoneId]?.currentContext;

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
      return;
    }

    if (attempt >= maxAttempts || !_tablesScrollController.hasClients) {
      _isProgrammaticScroll = false;
      return;
    }

    _isProgrammaticScroll = true;
    final position = _tablesScrollController.position;

    // ── Attempt 0: ONLY seed the scroll position (jumpTo top or the
    // estimated offset for the target zone). Do NOT also nudge forward
    // in the same pass — that's what was overshooting past zone 1 on
    // first load and causing it to land near the last zone instead. ──
    if (attempt == 0) {
      final zoneState = context.read<ZoneBloc>().state;
      int idx = -1;
      if (zoneState is ZoneLoaded && zoneState.zones.isNotEmpty) {
        final ids =
        zoneState.zones.map((z) => (z.zoneId ?? '0').toString()).toList();
        idx = ids.indexOf(zoneId);
        if (idx > 0 && position.maxScrollExtent > 0) {
          final ratio = idx / (ids.length - 1);
          final estimated = (position.maxScrollExtent * ratio)
              .clamp(0.0, position.maxScrollExtent);
          _tablesScrollController.jumpTo(estimated);
        } else {
          _tablesScrollController.jumpTo(0);
        }
      } else {
        _tablesScrollController.jumpTo(0);
      }

      // Re-check next frame with a real ctx lookup before doing any
      // forward nudging — the seed jump alone is often enough (e.g.
      // for the first zone, jumpTo(0) already reveals it).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedZoneId == zoneId) {
          _scrollToZoneSection(zoneId, attempt: attempt + 1);
        } else {
          _isProgrammaticScroll = false;
        }
      });
      return;
    }

    // ── attempt >= 1: seed already happened, ctx still not found ──
    // nudge forward a bit to force nearby sections to lay out.
    final target = (position.pixels + position.viewportDimension * 0.9)
        .clamp(0.0, position.maxScrollExtent);

    _tablesScrollController
        .animateTo(
      target,
      duration: const Duration(milliseconds: 80),
      curve: Curves.linear,
    )
        .then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedZoneId == zoneId) {
          _scrollToZoneSection(zoneId, attempt: attempt + 1);
        } else {
          _isProgrammaticScroll = false;
        }
      });
    });
  }

  bool _suppressVisibilityUpdates = false;

  void _onZoneVisibleFromScroll(String zoneId) {
    if (_isProgrammaticScroll || _suppressVisibilityUpdates) return;
    if (_selectedZoneId != zoneId) {
      setState(() => _selectedZoneId = zoneId);
    }
  }
  void _suppressVisibilityBriefly() {
    _suppressVisibilityUpdates = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _suppressVisibilityUpdates = false;
    });
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

  void _showStatusFilterMenu(BuildContext context) {
    final RenderBox? renderBox =
    _filterIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size btnSize = renderBox.size;
    final Size screenSize = MediaQuery.of(context).size;

    showMenu<String>(
      context: context,
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx - 150, // shift left so it doesn't clip off screen edge
        offset.dy + btnSize.height + 6,
        screenSize.width - (offset.dx + btnSize.width),
        0,
      ),
      items: [
        _buildFilterMenuItem('All', Icons.view_list),
        _buildFilterMenuItem('Available', Icons.check_circle_outline),
        _buildFilterMenuItem('Occupied', Icons.circle_outlined),
        _buildFilterMenuItem('Running', Icons.timelapse),
        _buildFilterMenuItem('Ready to pay', Icons.payment_outlined),
      ],
    ).then((value) {
      if (value != null) {
        // 👇 same exact logic you already had, just moved out of the sheet's onTap
        setState(() => _selectedStatusFilter = value);
      }
    });
  }

  PopupMenuItem<String> _buildFilterMenuItem(String label, IconData icon) {
    final isSelected = _selectedStatusFilter == label;
    return PopupMenuItem<String>(
      value: label,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? ColorConstants.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String label) {
    final isSelected = _selectedStatusFilter == label;
    const selectedColor = Color(0xFFFF6B00); // matches your app's orange accent

    return PopupMenuItem<String>(
      value: label,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? selectedColor : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? selectedColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTile(String label, IconData icon) {
    final isSelected = _selectedStatusFilter == label;
    return ListTile(
      leading: Icon(icon, color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade600),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? ColorConstants.primaryColor : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: ColorConstants.primaryColor) : null,
      onTap: () {
        setState(() => _selectedStatusFilter = label);
        Navigator.pop(context);
      },
    );
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
      onDrawerChanged: (isOpen) {
        if (!isOpen) _suppressVisibilityBriefly();
      },
      drawer: _AppDrawer(
        captainName: _captainName,
        captainRole: _captainRole,
        onLogout: _handleLogout,
        storeLogo: _storeLogo,
        storeName: _storeName,
        onSyncData: _onSyncDataFromDrawer,
      ),
      appBar: AppBar(
        toolbarHeight: 38,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,

        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          icon: const Icon(Icons.menu, size: 18),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),

        title: const Text(
          'Table Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),

        actions: [
          IconButton(
            key: _filterIconKey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(Icons.table_bar_rounded, size: 18),
            onPressed: () {
              _showStatusFilterMenu(context);
            },
          ),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 18),
            onPressed: () {},
          ),

          const SizedBox(width: 4),
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
                            statusFilter: _selectedStatusFilter, // 👈 new parameter

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
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              // ─── Header ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Logo (smaller)
                        storeLogo.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            storeLogo,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store,
                              size: 32,
                              color: ColorConstants.primaryColor,
                            ),
                          ),
                        )
                            : Icon(
                          Icons.store,
                          size: 32,
                          color: ColorConstants.primaryColor,
                        ),
                        const SizedBox(height: 4),
                        // Store Name (smaller font)
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.3,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Table Management',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button (smaller)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(
                      Icons.keyboard_double_arrow_left,
                      color: Colors.black45,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),
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
              // Logout button (compact)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDEC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: const Icon(Icons.logout, color: Color(0xFFE64545), size: 20),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFE64545),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFE64545),
                    size: 18,
                  ),
                  onTap: onLogout,
                ),
              ),
              const SizedBox(height: 10),
              // Captain profile card (compact)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
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
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            captainRole,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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