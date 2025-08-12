import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:pinkapos_restar/bloc/minisubcategory_bloc.dart';
import 'package:pinkapos_restar/bloc/subcategory_bloc.dart';
import 'package:pinkapos_restar/repository/subcategory_repository.dart';
import 'package:pinkapos_restar/screens/dashboard%20screen.dart';
import 'package:pinkapos_restar/bloc/category_bloc.dart';
import 'package:pinkapos_restar/bloc/order_bloc.dart';
 // import 'package:pinkapos_restar/bloc/category_bloc.dart'; // Make sure this path is correct
import 'models/theme/theme_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (_, currentMode, __) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<SubCategoryBloc>(
              create: (_) => SubCategoryBloc(
                subCategoryRepository: SubCategoryRepository(baseUrl: "https://merchantrestaurant.alektasolutions.com"),
              ),
            ),

            BlocProvider<OrderBloc>(
              create: (_) => OrderBloc(),
            ),
            BlocProvider<CategoryBloc>(
              create: (_) => CategoryBloc(),
            ),
            // BlocProvider<MiniSubCategoryBloc>(
            //   create: (_) => MiniSubCategoryBloc(),
            // ),

          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pinaka POS',
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.deepOrange,
              scaffoldBackgroundColor: Colors.white,
              fontFamily: 'Poppins',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1C1C1E),
              fontFamily: 'Poppins',
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2C2C2E),
                elevation: 0,
              ),
            ),
            themeMode: currentMode,
            home: const DashboardScreen(token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NTQ5Nzk4NTAsIm5iZiI6MTc1NDk3OTg1MCwiZXhwIjoxNzU3NTcxODUwLCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.l7uGF5K_SOChmA50VcKbQ21VBJp9dRM-uZUBEwNvWh8"),
          ),
        );
      },
    );
  }
}
