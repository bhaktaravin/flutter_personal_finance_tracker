import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

void main() {
  runApp(const FinanceQuestApp());
}

// Theme Manager
class ThemeManager extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.green,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    primarySwatch: Colors.green,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    scaffoldBackgroundColor: Colors.grey[900],
  );

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}

class FinanceQuestApp extends StatefulWidget {
  const FinanceQuestApp({super.key});

  @override
  State<FinanceQuestApp> createState() => _FinanceQuestAppState();
}

class _FinanceQuestAppState extends State<FinanceQuestApp> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.loadThemePreference();
    _themeManager.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Quest',
      theme: _themeManager.lightTheme,
      darkTheme: _themeManager.darkTheme,
      themeMode: _themeManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(themeManager: _themeManager),
    );
  }
}

// Data Models
class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      isIncome: json['isIncome'],
    );
  }
}

class FinancialGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
  });

  double get progressPercentage =>
      (currentAmount / targetAmount * 100).clamp(0, 100);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
    };
  }

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'],
      title: json['title'],
      targetAmount: json['targetAmount'],
      currentAmount: json['currentAmount'],
      targetDate: DateTime.parse(json['targetDate']),
    );
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  final ThemeManager themeManager;

  const MainScreen({super.key, required this.themeManager});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Transaction> _transactions = [];
  final List<FinancialGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load transactions
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> transactionsList = jsonDecode(transactionsJson);
      setState(() {
        _transactions.clear();
        _transactions.addAll(
          transactionsList.map((json) => Transaction.fromJson(json)).toList(),
        );
      });
    }

    // Load goals
    final goalsJson = prefs.getString('goals');
    if (goalsJson != null) {
      final List<dynamic> goalsList = jsonDecode(goalsJson);
      setState(() {
        _goals.clear();
        _goals.addAll(
          goalsList.map((json) => FinancialGoal.fromJson(json)).toList(),
        );
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save transactions
    final transactionsJson = jsonEncode(
      _transactions.map((transaction) => transaction.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsJson);

    // Save goals
    final goalsJson = jsonEncode(_goals.map((goal) => goal.toJson()).toList());
    await prefs.setString('goals', goalsJson);
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.add(transaction);
    });
    _saveData();
  }

  void _addGoal(FinancialGoal goal) {
    setState(() {
      _goals.add(goal);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        transactions: _transactions,
        goals: _goals,
        themeManager: widget.themeManager,
      ),
      TransactionsScreen(
        transactions: _transactions,
        onAddTransaction: _addTransaction,
      ),
      GoalsScreen(goals: _goals, onAddGoal: _addGoal),
      const CalculatorScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
        ],
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final List<FinancialGoal> goals;
  final ThemeManager themeManager;

  const DashboardScreen({
    super.key,
    required this.transactions,
    required this.goals,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Quest'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeManager.toggleTheme,
            tooltip:
                themeManager.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(balance),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color:
                            balance >= 0
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.green[300]
                                    : Colors.green[700])
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.red[300]
                                    : Colors.red[700]),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Income/Expense Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[900]?.withOpacity(0.3)
                            : Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green[300]
                                    : Colors.green[700],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Income',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green[300]
                                      : Colors.green[700],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(totalIncome),
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green[300]
                                      : Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.red[900]?.withOpacity(0.3)
                            : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red[300]
                                    : Colors.red[700],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expenses',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red[300]
                                      : Colors.red[700],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(totalExpenses),
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red[300]
                                      : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Transactions
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...transactions
                .take(5)
                .map(
                  (transaction) => Card(
                    child: ListTile(
                      leading: Icon(
                        transaction.isIncome ? Icons.add : Icons.remove,
                        color:
                            transaction.isIncome
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.green[300]
                                    : Colors.green[700])
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.red[300]
                                    : Colors.red[700]),
                      ),
                      title: Text(transaction.title),
                      subtitle: Text(transaction.category),
                      trailing: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                        ).format(transaction.amount),
                        style: TextStyle(
                          color:
                              transaction.isIncome
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green[300]
                                      : Colors.green[700])
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red[300]
                                      : Colors.red[700]),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),

            if (transactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No transactions yet. Add some to get started!',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Transactions Screen
class TransactionsScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onAddTransaction;

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Card(
            child: ListTile(
              leading: Icon(
                transaction.isIncome ? Icons.add_circle : Icons.remove_circle,
                color:
                    transaction.isIncome
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[300]
                            : Colors.green[700])
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.red[300]
                            : Colors.red[700]),
              ),
              title: Text(transaction.title),
              subtitle: Text(
                '${transaction.category} • ${DateFormat.yMd().format(transaction.date)}',
              ),
              trailing: Text(
                NumberFormat.currency(symbol: '\$').format(transaction.amount),
                style: TextStyle(
                  color:
                      transaction.isIncome
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[300]
                              : Colors.green[700])
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.red[300]
                              : Colors.red[700]),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AddTransactionDialog(onAddTransaction: onAddTransaction),
    );
  }
}

// Add Transaction Dialog
class AddTransactionDialog extends StatefulWidget {
  final Function(Transaction) onAddTransaction;

  const AddTransactionDialog({super.key, required this.onAddTransaction});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isIncome = false;

  final List<String> _categories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Bills',
    'Healthcare',
    'Education',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items:
                _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(_isIncome ? 'Income' : 'Expense'),
            value: _isIncome,
            onChanged: (value) {
              setState(() {
                _isIncome = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addTransaction, child: const Text('Add')),
      ],
    );
  }

  void _addTransaction() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      return;
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: DateTime.now(),
      isIncome: _isIncome,
    );

    widget.onAddTransaction(transaction);
    Navigator.pop(context);
  }
}

// Goals Screen
class GoalsScreen extends StatelessWidget {
  final List<FinancialGoal> goals;
  final Function(FinancialGoal) onAddGoal;

  const GoalsScreen({super.key, required this.goals, required this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${NumberFormat.currency(symbol: '\$').format(goal.targetAmount)}',
                  ),
                  Text(
                    'Current: ${NumberFormat.currency(symbol: '\$').format(goal.currentAmount)}',
                  ),
                  Text(
                    'Target Date: ${DateFormat.yMd().format(goal.targetDate)}',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goal.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.progressPercentage >= 100
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(1)}% Complete',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddGoalDialog(onAddGoal: onAddGoal),
    );
  }
}

// Add Goal Dialog
class AddGoalDialog extends StatefulWidget {
  final Function(FinancialGoal) onAddGoal;

  const AddGoalDialog({super.key, required this.onAddGoal});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Financial Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetAmountController,
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentAmountController,
            decoration: const InputDecoration(
              labelText: 'Current Amount',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Target Date'),
            subtitle: Text(DateFormat.yMd().format(_targetDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addGoal, child: const Text('Add')),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() {
        _targetDate = date;
      });
    }
  }

  void _addGoal() {
    if (_titleController.text.isEmpty ||
        _targetAmountController.text.isEmpty ||
        _currentAmountController.text.isEmpty) {
      return;
    }

    final goal = FinancialGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      targetAmount: double.parse(_targetAmountController.text),
      currentAmount: double.parse(_currentAmountController.text),
      targetDate: _targetDate,
    );

    widget.onAddGoal(goal);
    Navigator.pop(context);
  }
}

// Calculator Screen
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _timeController = TextEditingController();
  double _result = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compound Interest Calculator',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _principalController,
                      decoration: const InputDecoration(
                        labelText: 'Principal Amount',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Annual Interest Rate',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time Period',
                        border: OutlineInputBorder(),
                        suffixText: 'years',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _calculateCompoundInterest,
                        child: const Text('Calculate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_result > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Future Value',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(_result),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _calculateCompoundInterest() {
    if (_principalController.text.isEmpty ||
        _rateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      return;
    }

    final principal = double.parse(_principalController.text);
    final rate = double.parse(_rateController.text) / 100;
    final time = double.parse(_timeController.text);

    // A = P(1 + r)^t
    final result = principal * math.pow(1 + rate, time);

    setState(() {
      _result = result;
    });
  }
}
