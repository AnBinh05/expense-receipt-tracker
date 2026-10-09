import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/expense.dart';
import '../../analytics/views/analytics_view.dart';
import '../../scan/views/scan_receipt_screen.dart';
import '../view_models/expense_view_model.dart';
import 'expense_summary_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseViewModel>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatVND(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<ExpenseViewModel>();

    // Lọc theo tìm kiếm
    final filteredExpenses = viewModel.expenses.where((e) {
      if (_searchQuery.trim().isEmpty) return true;
      return e.merchant.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 20.0),
            ),
            const SizedBox(width: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Tracker',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18.0),
                ),
                Text(
                  'Smart OCR & Analytics',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => viewModel.loadExpenses(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Danh Sách Hóa Đơn'),
            Tab(icon: Icon(Icons.pie_chart_rounded), text: 'Thống Kê Biểu Đồ'),
          ],
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Danh sách hóa đơn & Thẻ Hero
                RefreshIndicator(
                  onRefresh: () => viewModel.loadExpenses(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Hero Fintech Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                          child: _buildHeroCard(theme, viewModel),
                        ),
                      ),

                      // Thanh tìm kiếm
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên cửa hàng...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ),

                      // Thanh lọc danh mục
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 52.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: viewModel.selectedCategory == null,
                                onSelected: (_) => viewModel.filterByCategory(null),
                              ),
                              const SizedBox(width: 8.0),
                              ...ExpenseCategory.values.map((cat) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    avatar: Icon(cat.icon, size: 16.0, color: cat.color),
                                    label: Text(cat.displayName),
                                    selected: viewModel.selectedCategory == cat,
                                    onSelected: (_) => viewModel.filterByCategory(cat),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8.0)),

                      // Danh sách chi tiêu
                      if (filteredExpenses.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64.0,
                                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Không tìm thấy hóa đơn nào khớp'
                                      : 'Chưa có hóa đơn nào',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredExpenses[index];
                              return Dismissible(
                                key: Key('expense_${item.id ?? index}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24.0),
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                                onDismissed: (_) {
                                  if (item.id != null) {
                                    viewModel.deleteExpense(item.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã xóa hóa đơn ${item.merchant}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: ExpenseSummaryCard.fromExpense(
                                  expense: item,
                                  onTap: () => _showExpenseDetails(context, item),
                                ),
                              );
                            },
                            childCount: filteredExpenses.length,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 88.0)),
                    ],
                  ),
                ),

                // Tab 2: Phân tích biểu đồ
                AnalyticsView(expenses: viewModel.expenses),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Quét hóa đơn'),
        onPressed: () async {
          final result = await Navigator.push<Expense>(
            context,
            MaterialPageRoute(
              builder: (context) => const ScanReceiptScreen(),
            ),
          );
          if (result != null && mounted) {
            viewModel.loadExpenses();
          }
        },
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, ExpenseViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00695C), // Rich Deep Teal
            Color(0xFF00897B), // Vibrant Teal
            Color(0xFF004D40), // Forest Teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withValues(alpha: 0.35),
            blurRadius: 20.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tổng chi tiêu tháng này',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pie_chart, color: Colors.white, size: 14.0),
                    const SizedBox(width: 4.0),
                    Text(
                      '${viewModel.expenses.length} hóa đơn',
                      style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            _formatVND(viewModel.totalSpent),
            style: const TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              _buildPillAction(
                icon: Icons.camera_alt_outlined,
                label: 'Chụp biên lai',
                onTap: () async {
                  final result = await Navigator.push<Expense>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanReceiptScreen(),
                    ),
                  );
                  if (result != null && mounted) {
                    viewModel.loadExpenses();
                  }
                },
              ),
              const SizedBox(width: 10.0),
              _buildPillAction(
                icon: Icons.analytics_outlined,
                label: 'Xem biểu đồ',
                onTap: () {
                  _tabController.animateTo(1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16.0),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: expense.category.color.withValues(alpha: 0.15),
                    child: Icon(expense.category.icon, color: expense.category.color),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.merchant,
                          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          expense.category.displayName,
                          style: TextStyle(color: expense.category.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_money),
                title: const Text('Số tiền'),
                trailing: Text(
                  _formatVND(expense.amount),
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Ngày thanh toán'),
                trailing: Text(DateFormat('dd/MM/yyyy HH:mm').format(expense.date)),
              ),
              if (expense.note != null && expense.note!.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notes_rounded),
                  title: const Text('Ghi chú'),
                  subtitle: Text(expense.note!),
                ),
              if (expense.imagePath != null &&
                  !kIsWeb &&
                  File(expense.imagePath!).existsSync()) ...[
                const SizedBox(height: 12.0),
                const Text(
                  'Ảnh hóa đơn (Đã lưu vào bộ nhớ ứng dụng):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                ),
                const SizedBox(height: 8.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    height: 180.0,
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.file(
                      File(expense.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              if (expense.rawOcrText != null && expense.rawOcrText!.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                const Text(
                  'Văn bản OCR trích xuất được:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                ),
                const SizedBox(height: 6.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    expense.rawOcrText!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11.0),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
