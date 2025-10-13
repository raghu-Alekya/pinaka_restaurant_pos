import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:pinaka_restaurant_pos/repositories/category_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/checkin_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/kot_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/minisubcategory_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/order_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/product_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/subcategory_repository.dart';
import 'package:pinaka_restaurant_pos/utils/GlobalReservationMonitor.dart';
import 'package:pinaka_restaurant_pos/utils/ShiftMonitor.dart';
import 'package:pinaka_restaurant_pos/utils/global_navigator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'App flow/ui/splash_screen.dart';

// Bloc Logic
import 'App flow/widgets/view_all_kots.dart';
import 'blocs/Bloc Event/kot_event.dart';
import 'blocs/Bloc Logic/auth_bloc.dart';
import 'blocs/Bloc Logic/category_bloc.dart';
import 'blocs/Bloc Logic/kot_bloc.dart';
import 'blocs/Bloc Logic/minisubcategory_bloc.dart';
import 'blocs/Bloc Logic/order_bloc.dart';
import 'blocs/Bloc Logic/product_bloc.dart';
import 'blocs/Bloc Logic/subcategory_bloc.dart';
import 'blocs/Bloc Logic/table_bloc.dart';
import 'blocs/Bloc Logic/zone_bloc.dart';
import 'blocs/Bloc Logic/attendance_bloc.dart';
import 'blocs/Bloc Logic/checkin_bloc.dart';

// Repositories
import 'repositories/auth_repository.dart';
import 'repositories/table_repository.dart';
import 'repositories/zone_repository.dart';
import 'repositories/employee_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final dbPath = await getDatabasesPath();
  await deleteDatabase(join(dbPath, 'tables.db'));
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final orderRepo = OrderRepository(
    baseUrl: "https://merchantrestaurant.alektasolutions.com",

  );

  if (token != null && token.isNotEmpty) {
    final employeeRepo = EmployeeRepository();
    final shiftMonitor = ShiftMonitor(
      token: token,
      employeeRepository: employeeRepo,
    );
    shiftMonitor.startMonitoring();
    GlobalReservationMonitor().start(token);
  }

  runApp(MyApp(
    orderRepo: orderRepo,
    token: token,
  ));
}

class MyApp extends StatelessWidget {
  final OrderRepository orderRepo;
  final String token;

  const MyApp({super.key, required this.orderRepo, required this.token});


  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<ZoneRepository>(
          create: (context) => ZoneRepository(),
        ),
        RepositoryProvider<TableRepository>(
          create: (context) => TableRepository(),
        ),
        RepositoryProvider<EmployeeRepository>(
          create: (context) => EmployeeRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // 1️⃣ MiniSubCategoryBloc first
          BlocProvider<MiniSubCategoryBloc>(
            create: (_) => MiniSubCategoryBloc(
              repository: MiniSubCategoryRepository(
                baseUrl: "https://merchantrestaurant.alektasolutions.com",
                token: token, // use your actual token
              ),
            ),
          ),

          // 2️⃣ SubCategoryBloc depends on MiniSubCategoryBloc
          BlocProvider<SubCategoryBloc>(
            create: (context) => SubCategoryBloc(
              subCategoryRepository: SubCategoryRepository(
                baseUrl: "https://merchantrestaurant.alektasolutions.com",
              ),
              miniSubCategoryBloc: context.read<MiniSubCategoryBloc>(), // ✅ works now
            ),
          ),

          // 3️⃣ Other blocs
          BlocProvider<CategoryBloc>(
            create: (_) => CategoryBloc(
              repository: CategoryRepository(
                baseUrl: "https://merchantrestaurant.alektasolutions.com",
              ),
            ),
          ),
          BlocProvider<ProductBloc>(
            create: (_) => ProductBloc(ProductRepository as ProductRepository),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(orderRepo, token),
          ),
          BlocProvider<KotBloc>(
            create: (_) => KotBloc(
                KotRepository(baseUrl: 'https://merchantrestaurant.alektasolutions.com')),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              RepositoryProvider.of<AuthRepository>(context),
            ),
          ),
          BlocProvider<ZoneBloc>(
            create: (context) => ZoneBloc(
              zoneRepository: RepositoryProvider.of<ZoneRepository>(context),
            ),
          ),
          BlocProvider<TableBloc>(
            create: (context) => TableBloc(
              zoneRepository: RepositoryProvider.of<ZoneRepository>(context),
              tableRepository: RepositoryProvider.of<TableRepository>(context),
            ),
          ),
          BlocProvider<AttendanceBloc>(
            create: (context) => AttendanceBloc(
              RepositoryProvider.of<EmployeeRepository>(context),
            ),
          ),
          BlocProvider<CheckInBloc>(
            create: (context) => CheckInBloc(CheckInRepository()),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Employee Login',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const SplashScreen(),
        ),
      )
      ,
    );
  }
}
