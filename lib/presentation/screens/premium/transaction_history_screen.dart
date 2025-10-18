import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/pulse_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/payment_transaction.dart';
import '../../../data/services/payment_history_service.dart';
import '../../../data/services/token_service.dart';
import '../../widgets/common/pulse_toast.dart';

/// Transaction History Screen
/// 
/// Displays user's transaction history with:
/// - Current coin balance
/// - Grouped transaction list (Today, Yesterday, This Week, etc.)
/// - Empty state handling
/// - Pull-to-refresh functionality
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late PaymentHistoryService _paymentHistoryService;
  final TokenService _tokenService = TokenService();
  List<PaymentTransaction> _transactions = [];
  List<PaymentTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _error;
  int _currentBalance = 0;

  // Filter state
  PaymentTransactionType? _selectedType;
  DateRange _selectedDateRange = DateRange.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadTransactions();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final accessToken = await _tokenService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      final response = await _paymentHistoryService.getCoinBalance(accessToken);

      setState(() {
        _currentBalance = response['totalCoins'] ?? 0;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load balance: $e';
      });
    }
  }

  Future<void> _initializeService() async {
    final accessToken = await _tokenService.getAccessToken();
    _paymentHistoryService = PaymentHistoryService(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _paymentHistoryService.getPaymentHistory(
      page: 1,
      limit: 100,
    );

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _transactions = response.data!;
        _applyFilters();
      } else {
        _error = response.error ?? 'Failed to load transactions';
      }
    });
  }

  void _applyFilters() {
    List<PaymentTransaction> filtered = List.from(_transactions);

    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Apply date range filter
    DateTime? startDate = _customStartDate;
    DateTime? endDate = _customEndDate;

    if (_selectedDateRange != DateRange.custom) {
      startDate = _selectedDateRange.startDate;
      endDate = null; // End date is now for non-custom ranges
    }

    if (startDate != null) {
      filtered = filtered.where((t) => t.processedAt.isAfter(startDate!)).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((t) => t.processedAt.isBefore(endDate!)).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Map<String, List<PaymentTransaction>> _groupTransactionsByDate() {
    final groups = <String, List<PaymentTransaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    // Use filtered transactions instead of all transactions
    final transactionsToGroup = _filteredTransactions.isEmpty && _selectedType == null && _selectedDateRange == DateRange.all
        ? _transactions
        : _filteredTransactions;

    for (final transaction in transactionsToGroup) {
      final transactionDate = DateTime(
        transaction.processedAt.year,
        transaction.processedAt.month,
        transaction.processedAt.day,
      );

      String groupKey;
      if (transactionDate.isAtSameMomentAs(today)) {
        groupKey = 'Today';
      } else if (transactionDate.isAtSameMomentAs(yesterday)) {
        groupKey = 'Yesterday';
      } else if (transactionDate.isAfter(weekAgo)) {
        groupKey = 'This Week';
      } else {
        groupKey = DateFormat('MMMM yyyy').format(transactionDate);
      }

      groups.putIfAbsent(groupKey, () => []);
      groups[groupKey]!.add(transaction);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _showExportOptions,
              tooltip: 'Export Transactions',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildBalanceCard(),
        if (_transactions.isNotEmpty) _buildSummaryCard(),
        _buildFilterChips(),
        Expanded(
          child: _buildTransactionsList(),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary,
            PulseColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PulseColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_currentBalance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'coins',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final transactions = _filteredTransactions.isEmpty ? _transactions : _filteredTransactions;
    
    // Calculate totals
    double totalSpent = 0;
    double totalPurchased = 0;
    
    for (var transaction in transactions) {
      if (transaction.type == PaymentTransactionType.payment) {
        totalPurchased += transaction.amount;
      } else {
        totalSpent += transaction.amount;
      }
    }
    
    final netBalance = totalPurchased - totalSpent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Spent',
              totalSpent,
              Icons.arrow_downward_rounded,
              Colors.red,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildSummaryItem(
              'Purchased',
              totalPurchased,
              Icons.arrow_upward_rounded,
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildSummaryItem(
              'Net',
              netBalance,
              Icons.account_balance_wallet_rounded,
              netBalance >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${amount >= 0 ? '' : '-'}${amount.abs().toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  int _calculateRunningBalance(PaymentTransaction transaction, List<PaymentTransaction> allTransactions) {
    // Find the index of this transaction
    final index = allTransactions.indexOf(transaction);
    if (index == -1) return _currentBalance;

    // Calculate running balance up to this transaction
    int balance = _currentBalance;
    
    // Process transactions in reverse order (oldest to newest)
    // Since allTransactions is already sorted newest first, we need to reverse
    final reversedTransactions = allTransactions.reversed.toList();
    final reversedIndex = reversedTransactions.length - 1 - index;
    
    for (int i = reversedTransactions.length - 1; i > reversedIndex; i--) {
      final t = reversedTransactions[i];
      if (t.type == PaymentTransactionType.payment) {
        balance -= t.amount.toInt();
      } else {
        balance += t.amount.toInt();
      }
    }
    
    return balance;
  }


  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Type Filters
          const Text(
            'Transaction Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip('All', null),
                const SizedBox(width: 8),
                _buildTypeChip('Purchases', PaymentTransactionType.payment),
                const SizedBox(width: 8),
                _buildTypeChip('Subscriptions', PaymentTransactionType.subscription),
                const SizedBox(width: 8),
                _buildTypeChip('Refunds', PaymentTransactionType.refund),
                const SizedBox(width: 8),
                _buildTypeChip('Upgrades', PaymentTransactionType.upgrade),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Date Range Filters
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRange.values.map((range) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildDateRangeChip(range),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, PaymentTransactionType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
          _applyFilters();
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: PulseColors.primary.withValues(alpha: 0.2),
      checkmarkColor: PulseColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? PulseColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateRangeChip(DateRange range) {
    final isSelected = _selectedDateRange == range;
    return FilterChip(
      label: Text(range.label),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected && range == DateRange.custom) {
          await _showCustomDatePicker();
        } else {
          setState(() {
            _selectedDateRange = selected ? range : DateRange.all;
            if (_selectedDateRange != DateRange.custom) {
              _customStartDate = null;
              _customEndDate = null;
            }
            _applyFilters();
          });
        }
      },
      backgroundColor: Colors.grey[100],
      selectedColor: PulseColors.primary.withValues(alpha: 0.2),
      checkmarkColor: PulseColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? PulseColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PulseColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = DateRange.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _applyFilters();
      });
    }
  }

  // Export Functionality
  
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose format to export ${_filteredTransactions.isEmpty ? _transactions.length : _filteredTransactions.length} transaction(s)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('Professional format for printing'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: Colors.green),
              ),
              title: const Text('Export as CSV'),
              subtitle: const Text('Open in Excel or spreadsheet apps'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      // Show loading indicator
      if (mounted) {
        PulseToast.info(
          context,
          message: 'Generating PDF...',
          duration: const Duration(seconds: 10),
        );
      }

      final pdf = pw.Document();
      final transactions = _filteredTransactions.isEmpty ? _transactions : _filteredTransactions;

      // Calculate totals
      double totalSpent = 0;
      double totalPurchased = 0;
      for (var transaction in transactions) {
        if (transaction.type == PaymentTransactionType.payment) {
          totalPurchased += transaction.amount;
        } else {
          totalSpent += transaction.amount;
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Transaction History',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on ${DateFormat('MMMM dd, yyyy at HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Transactions', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${transactions.length}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Spent', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${totalSpent.toStringAsFixed(0)} coins',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Purchased', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${totalPurchased.toStringAsFixed(0)} coins',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Transactions Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
                headers: ['Date', 'Description', 'Amount', 'Type', 'Status'],
                data: transactions.map((t) {
                  return [
                    DateFormat('MMM dd, yyyy').format(t.processedAt),
                    t.description,
                    '${t.type == PaymentTransactionType.payment ? '+' : '-'}${t.amount.toStringAsFixed(0)} coins',
                    _getTypeLabel(t.type),
                    _getStatusLabel(t.status),
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      // Save and share
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/pulse_transactions_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Transaction History - Pulse Dating',
          text: 'My transaction history from Pulse Dating app',
        );
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(
          context,
          message: 'Failed to export PDF: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Show loading indicator
      if (mounted) {
        PulseToast.info(
          context,
          message: 'Generating CSV...',
          duration: const Duration(seconds: 10),
        );
      }

      final transactions = _filteredTransactions.isEmpty ? _transactions : _filteredTransactions;
      
      // Build CSV content
      final StringBuffer csvContent = StringBuffer();
      
      // Header
      csvContent.writeln('Date,Time,Description,Type,Status,Amount,Currency');
      
      // Data rows
      for (var transaction in transactions) {
        final date = DateFormat('yyyy-MM-dd').format(transaction.processedAt);
        final time = DateFormat('HH:mm:ss').format(transaction.processedAt);
        final description = '"${transaction.description.replaceAll('"', '""')}"'; // Escape quotes
        final type = _getTypeLabel(transaction.type);
        final status = _getStatusLabel(transaction.status);
        final amount = transaction.type == PaymentTransactionType.payment 
            ? '+${transaction.amount.toStringAsFixed(2)}' 
            : '-${transaction.amount.toStringAsFixed(2)}';
        final currency = transaction.currency;
        
        csvContent.writeln('$date,$time,$description,$type,$status,$amount,$currency');
      }

      // Save and share
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/pulse_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Transaction History - Pulse Dating',
          text: 'My transaction history from Pulse Dating app',
        );
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(
          context,
          message: 'Failed to export CSV: ${e.toString()}',
        );
      }
    }
  }

  String _getTypeLabel(PaymentTransactionType type) {
    switch (type) {
      case PaymentTransactionType.payment:
        return 'Purchase';
      case PaymentTransactionType.refund:
        return 'Refund';
      case PaymentTransactionType.subscription:
        return 'Subscription';
      case PaymentTransactionType.upgrade:
        return 'Upgrade';
      case PaymentTransactionType.cancellation:
        return 'Cancellation';
    }
  }

  String _getStatusLabel(PaymentTransactionStatus status) {
    switch (status) {
      case PaymentTransactionStatus.pending:
        return 'Pending';
      case PaymentTransactionStatus.completed:
        return 'Completed';
      case PaymentTransactionStatus.failed:
        return 'Failed';
      case PaymentTransactionStatus.cancelled:
        return 'Cancelled';
      case PaymentTransactionStatus.refunded:
        return 'Refunded';
      case PaymentTransactionStatus.partiallyRefunded:
        return 'Partial Refund';
    }
  }


  Widget _buildTransactionsList() {
    final groupedTransactions = _groupTransactionsByDate();
    final sortedKeys = groupedTransactions.keys.toList();

    // Sort keys to ensure proper ordering
    sortedKeys.sort((a, b) {
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;
      if (a == 'This Week') return -1;
      if (b == 'This Week') return 1;
      return b.compareTo(a);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final groupKey = sortedKeys[index];
        final transactions = groupedTransactions[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                groupKey,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...transactions.map((transaction) => _buildTransactionItem(transaction)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(PaymentTransaction transaction) {
    final isCredit = transaction.type == PaymentTransactionType.payment ||
        transaction.type == PaymentTransactionType.refund;
    
    // Get all transactions for running balance calculation
    final allTransactions = _filteredTransactions.isEmpty ? _transactions : _filteredTransactions;
    final runningBalance = _calculateRunningBalance(transaction, allTransactions);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            _buildTransactionIcon(transaction.type),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.processedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(transaction.status),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Amount and Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Transaction amount
                Text(
                  '${isCredit ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Running balance
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$runningBalance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(PaymentTransactionType type) {
    IconData icon;
    Color color;

    switch (type) {
      case PaymentTransactionType.payment:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case PaymentTransactionType.refund:
        icon = Icons.undo;
        color = Colors.blue;
        break;
      case PaymentTransactionType.subscription:
        icon = Icons.card_membership;
        color = PulseColors.primary;
        break;
      case PaymentTransactionType.upgrade:
        icon = Icons.arrow_circle_up;
        color = Colors.orange;
        break;
      case PaymentTransactionType.cancellation:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge(PaymentTransactionStatus status) {
    Color color;
    String text;

    switch (status) {
      case PaymentTransactionStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case PaymentTransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case PaymentTransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case PaymentTransactionStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
      case PaymentTransactionStatus.refunded:
        color = Colors.blue;
        text = 'Refunded';
        break;
      case PaymentTransactionStatus.partiallyRefunded:
        color = Colors.blue;
        text = 'Partial Refund';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date range filter options
enum DateRange {
  all,
  last7Days,
  last30Days,
  custom,
}

extension DateRangeExtension on DateRange {
  String get label {
    switch (this) {
      case DateRange.all:
        return 'All Time';
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.custom:
        return 'Custom Range';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRange.all:
        return null;
      case DateRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case DateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case DateRange.custom:
        return null; // Will use custom dates
    }
  }
}
