import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Logic/inventory_bloc.dart';
import '../../local database/table_dao.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/inventory_repository/beverage_iventory_repository.dart';
// import '../App flow/ui/inventory_screen.dart';
// import '../App flow/widgets/NavigationHelper.dart';
// import '../App flow/widgets/bottom_nav_bar.dart';
// import '../App flow/widgets/top_bar.dart';
// import '../blocs/Bloc Logic/inventory_bloc.dart';
// import '../models/UserPermissions.dart';
// import '../repositories/beverage_inventory_repository.dart';
import '../../utils/SessionManager.dart';
import '../ui/tables_screen.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'custom_box.dart';


class Dashboard extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const Dashboard({
    super.key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
  });
  @override
  State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  UserPermissions? _userPermissions;

  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),
      body: SafeArea(

        child: Column(
          children: [
            // Container(
            //   color: Colors.white,
            //   padding: const EdgeInsets.symmetric(horizontal: 8),
            //   height: 60,
            //   child: TopBar(
            //     token: widget.token,
            //     pin: widget.pin,
            //     userPermissions: _userPermissions,
            //     onPermissionsReceived: (permissions) {
            //       setState(() {
            //         _userPermissions = permissions;
            //       });
            //     },
            //   ),
            // ),

            // const SizedBox(height: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: size.height * 0.75,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE6ECFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: BlocProvider(
                    create: (context) => ProductBloc(ProductRepository(token:  widget.token,)),
                    child: CustomBox(token: widget.token),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        selectedIndex: 5,
        userPermissions: _userPermissions,
        onItemTapped: (int index) {
          NavigationHelper.handleNavigation(
            context,
            5,
            index,
            widget.pin,
            widget.token,
            widget.restaurantId,
            widget.restaurantName,
            _userPermissions,
          );
        },
      ),
    );
  }
}