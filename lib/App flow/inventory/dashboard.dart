import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Logic/inventory_bloc.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/inventory_repository/beverage_iventory_repository.dart';
// import '../App flow/ui/inventory_screen.dart';
// import '../App flow/widgets/NavigationHelper.dart';
// import '../App flow/widgets/bottom_nav_bar.dart';
// import '../App flow/widgets/top_bar.dart';
// import '../blocs/Bloc Logic/inventory_bloc.dart';
// import '../models/UserPermissions.dart';
// import '../repositories/beverage_inventory_repository.dart';
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
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE6E6E6),

      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 60,
              child: const TopBar(token: '', pin: '',),
            ),

            const SizedBox(height: 12),
            // 📦 CustomBox
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE6ECFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: BlocProvider(
                    create: (context) => ProductBloc(ProductRepository()),
                    child: CustomBox(),
                  ),


                ),
              ),

            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 8, // Inventory index
        userPermissions: null,
        onItemTapped: (int index) {
          NavigationHelper.handleNavigation(
            context,
            8,                 // currentIndex
            index,             // tappedIndex
            widget.pin,
            widget.token,
            widget.restaurantId,
            widget.restaurantName,
            null,              // userPermissions
          );
        },
      ),

    );
  }
}