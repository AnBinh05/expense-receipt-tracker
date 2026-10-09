import 'package:flutter/foundation.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../domain/models/expense.dart';

class ExpenseViewModel extends ChangeNotifier {
  final IExpenseRepository _repository;

  ExpenseViewModel({IExpenseRepository? repository})
      : _repository = repository ?? ExpenseRepository();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  ExpenseCategory? _selectedCategory;

  List<Expense> get expenses {
    if (_selectedCategory == null) return _expenses;
    return _expenses.where((e) => e.category == _selectedCategory).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ExpenseCategory? get selectedCategory => _selectedCategory;

  double get totalSpent {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _repository.getAllExpenses();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách chi tiêu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final id = await _repository.addExpense(expense);
      final newExpense = expense.copyWith(id: id);
      _expenses.insert(0, newExpense);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi lưu chi tiêu: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa chi tiêu: $e';
      notifyListeners();
      return false;
    }
  }

  void filterByCategory(ExpenseCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
