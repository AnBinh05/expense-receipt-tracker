import '../../domain/models/expense.dart';
import '../services/database_service.dart';

abstract class IExpenseRepository {
  Future<List<Expense>> getAllExpenses();
  Future<int> addExpense(Expense expense);
  Future<int> updateExpense(Expense expense);
  Future<int> deleteExpense(int id);
}

class ExpenseRepository implements IExpenseRepository {
  final DatabaseService _databaseService;

  ExpenseRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  @override
  Future<List<Expense>> getAllExpenses() async {
    return await _databaseService.getAllExpenses();
  }

  @override
  Future<int> addExpense(Expense expense) async {
    return await _databaseService.insertExpense(expense);
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    return await _databaseService.updateExpense(expense);
  }

  @override
  Future<int> deleteExpense(int id) async {
    return await _databaseService.deleteExpense(id);
  }
}
