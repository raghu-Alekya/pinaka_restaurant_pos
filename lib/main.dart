import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/Manager%20flow/ui/splash_screen.dart';
import 'package:pinaka_restaurant_pos/repositories/auth_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/zone_repository.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/auth_bloc.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/zone_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ],
      child: MultiBlocProvider(
        providers: [
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
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Employee Login',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
