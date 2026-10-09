import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/repositories/expense_repository.dart';
import 'ui/features/expenses/view_models/expense_view_model.dart';
import 'ui/features/expenses/views/expense_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseViewModel(repository: ExpenseRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Receipt Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF00897B), // Modern Teal Seed
          brightness: Brightness.light,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1.0,
          ),
          cardTheme: const CardThemeData(
            elevation: 2.0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF00897B),
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1.0,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const ExpenseListScreen(),
      ),
    );
  }
}
