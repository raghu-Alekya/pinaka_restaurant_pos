import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/order_list_event.dart';
import '../../blocs/Bloc Logic/order_list_bloc.dart';
// import '../../blocs/Bloc Logic/orders_list_bloc.dart';
import '../../repositories/order_list_repository.dart';
// import '../../repositories/orders_list_repository.dart';
import '../inventory/dashboard.dart';
import '../ui/KitchenStatusScreen.dart';
import '../../local database/table_dao.dart';
import '../ui/orderstatus_screen.dart';
import '../ui/tables_screen.dart';
import '../ui/reservation_list_screen.dart';
import '../ui/Merchant_dashboard_screen.dart';
import '../../models/UserPermissions.dart';

class NavigationHelper {
  static void handleNavigation(
      BuildContext context,
      int currentIndex,
      int tappedIndex,
      String pin,
      String token,
      String restaurantId,
      String restaurantName,
      UserPermissions? userPermissions,
      ) async {
    if (tappedIndex == currentIndex) return;

    if (tappedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            userPermissions: userPermissions,
          ),
        ),
      );
    } else if (tappedIndex == 1) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(pin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TablesScreen(
            loadedTables: tables,
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            userPermissions: userPermissions,
            restaurantName: restaurantName,
          ),
        ),
      );
    } else if (tappedIndex == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KitchenStatusScreen(
            pin: pin,
            associatedManagerPin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    } else if (tappedIndex == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReservationListScreen(
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    }
    else if (tappedIndex == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => OrderstatusBloc(OrderstatusRepository())..add(FetchOrders(token: token)),
            child: OrdersListTable(
              token: token,
              pin: pin,
              restaurantId: restaurantId,
              restaurantName: restaurantName,
              userPermissions: userPermissions,
              // orders: [], // you can pass empty; Bloc will fetch
            ),
          ),
        ),
      );
    }

    else if (tappedIndex == 8) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen not implemented yet')),
      );
    }
  }
}