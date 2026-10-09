import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.study:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Đi lại';
      case ExpenseCategory.gear:
        return 'Thiết bị/Đồ dùng';
      case ExpenseCategory.entertainment:
        return 'Giải trí/CLB';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.study:
        return Icons.school_rounded;
      case ExpenseCategory.travel:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.gear:
        return Icons.build_circle_rounded;
      case ExpenseCategory.entertainment:
        return Icons.celebration_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFF57C00); // Vibrant Warm Orange
      case ExpenseCategory.study:
        return const Color(0xFF3F51B5); // Indigo Academic
      case ExpenseCategory.travel:
        return const Color(0xFF0288D1); // Cyan Blue Transit
      case ExpenseCategory.gear:
        return const Color(0xFF00897B); // Teal Gear
      case ExpenseCategory.entertainment:
        return const Color(0xFF8E24AA); // Purple Event
      case ExpenseCategory.other:
        return const Color(0xFF607D8B); // Slate Grey
    }
  }

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.other;
    final lower = name.toLowerCase();
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () {
        if (lower.contains('shop') || lower.contains('mua')) return ExpenseCategory.gear;
        if (lower.contains('bill') || lower.contains('hóa')) return ExpenseCategory.study;
        if (lower.contains('trans') || lower.contains('xe')) return ExpenseCategory.travel;
        return ExpenseCategory.other;
      },
    );
  }
}

class Expense {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? rawOcrText;
  final String? imagePath;
  final String? note;

  const Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category = ExpenseCategory.food,
    this.rawOcrText,
    this.imagePath,
    this.note,
  });

  Expense copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? rawOcrText,
    String? imagePath,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          merchant == other.merchant &&
          amount == other.amount &&
          date == other.date &&
          category == other.category;

  @override
  int get hashCode =>
      id.hashCode ^
      merchant.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      category.hashCode;
}
