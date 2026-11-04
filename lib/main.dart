import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

// ---------------------------------------------------------------------------
// THEME COLOURS (bright & vibrant)
// ---------------------------------------------------------------------------
class AppColors {
  static const bg = Color(0xFFFFF8F0);
  static const ink = Color(0xFF1E1B3A);
  static const muted = Color(0xFF7A7794);
  static const border = Color(0xFFF0E6DA);
  static const primary = Color(0xFF7C4DFF);
  static const primaryDark = Color(0xFF5B2EE6);
  static const pink = Color(0xFFFF4D8D);
  static const accent = Color(0xFFFF6B35);
  static const gold = Color(0xFFFFC830);
  static const mint = Color(0xFF00C9A7);
  static const danger = Color(0xFFFF3B5C);
}

Color alpha(Color c, double opacity) => c.withAlpha((opacity * 255).round());

/// Indian number grouping: ₹1,23,456.00
String money(double v) {
  final neg = v < 0;
  final parts = v.abs().toStringAsFixed(2).split('.');
  var ip = parts[0];
  if (ip.length > 3) {
    final last3 = ip.substring(ip.length - 3);
    final rest = ip.substring(0, ip.length - 3);
    final buf = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    ip = '$buf,$last3';
  }
  return '${neg ? '-' : ''}₹$ip.${parts[1]}';
}

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
String monthName(DateTime d) => '${_months[d.month - 1]} ${d.year}';
String shortMonth(DateTime d) => _months[d.month - 1].substring(0, 3);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d) {
  final now = DateTime.now();
  if (sameDay(d, now)) return 'Today';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return fmtDate(d);
}

// ---------------------------------------------------------------------------
// CATEGORIES
// ---------------------------------------------------------------------------
class Cat {
  final String name;
  final IconData icon;
  final String emoji;
  final Color color;
  final Color color2;
  const Cat(this.name, this.icon, this.emoji, this.color, this.color2);
}

const List<Cat> categories = [
  Cat('Food', Icons.restaurant, '🍔', Color(0xFFFF6B35), Color(0xFFFFB347)),
  Cat('Groceries', Icons.shopping_cart, '🛒', Color(0xFF00C9A7), Color(0xFF7BEFB2)),
  Cat('Travel', Icons.directions_bus, '🚌', Color(0xFF2F9BFF), Color(0xFF6DD5FA)),
  Cat('Shopping', Icons.shopping_bag, '🛍️', Color(0xFFA24BFF), Color(0xFFE08BFF)),
  Cat('Bills', Icons.receipt_long, '🧾', Color(0xFFFF3B5C), Color(0xFFFF8A9B)),
  Cat('Health', Icons.local_hospital, '💊', Color(0xFF1DD35F), Color(0xFF8DF5A8)),
  Cat('Education', Icons.school, '📚', Color(0xFFFF9F1C), Color(0xFFFFD166)),
  Cat('Entertainment', Icons.movie, '🎬', Color(0xFFFF4D8D), Color(0xFFFF9BC2)),
  Cat('Other', Icons.category, '✨', Color(0xFF7A7794), Color(0xFFB5B3C9)),
];

Cat catOf(String name) =>
    categories.firstWhere((c) => c.name == name, orElse: () => categories.last);

// ---------------------------------------------------------------------------
// PAYMENT METHODS
// ---------------------------------------------------------------------------
const List<String> payMethods = ['Cash', 'UPI', 'Card', 'Net Banking'];

IconData payIcon(String m) {
  switch (m) {
    case 'UPI':
      return Icons.qr_code_2;
    case 'Card':
      return Icons.credit_card;
    case 'Net Banking':
      return Icons.account_balance;
    default:
      return Icons.payments;
  }
}

// ---------------------------------------------------------------------------
// EXPENSE MODEL
// ---------------------------------------------------------------------------
class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final bool important;
  final String method;
  final String? image; // base64 photo (receipt / item picture)
  late final Uint8List? bytes = image == null ? null : _decode(image!);

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.important = false,
    this.method = 'UPI',
    this.image,
  });

  static Uint8List? _decode(String s) {
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Expense copyWith({bool? important}) => Expense(
        id: id,
        title: title,
        amount: amount,
        category: category,
        date: date,
        note: note,
        important: important ?? this.important,
        method: method,
        image: image,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'important': important,
        'method': method,
        'image': image,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        title: (j['title'] ?? j['category'] ?? 'Expense') as String,
        amount: (j['amount'] as num).toDouble(),
        category: (j['category'] ?? 'Other') as String,
        date: DateTime.parse(j['date'] as String),
        note: (j['note'] ?? '') as String,
        important: (j['important'] ?? false) as bool,
        method: (j['method'] ?? 'UPI') as String,
        image: j['image'] as String?,
      );
}

// ---------------------------------------------------------------------------
// SMALL REUSABLE WIDGETS
// ---------------------------------------------------------------------------
class CatArt extends StatelessWidget {
  final Cat cat;
  final double size;
  final double radius;
  const CatArt(
      {super.key, required this.cat, this.size = 54, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cat.color, cat.color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: alpha(cat.color, 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(cat.emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

class ExpenseThumb extends StatelessWidget {
  final Expense expense;
  final double size;
  const ExpenseThumb({super.key, required this.expense, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final b = expense.bytes;
    if (b == null) {
      return CatArt(cat: catOf(expense.category), size: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.memory(
        b,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            CatArt(cat: catOf(expense.category), size: size),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final total = values.fold(0.0, (s, v) => s + v);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      final gap = values.length > 1 ? 0.07 : 0.0;
      final s = math.max(sweep - gap, 0.001);
      canvas.drawArc(rect, start + gap / 2, s, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => true;
}

// ---------------------------------------------------------------------------
// APP
// ---------------------------------------------------------------------------
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME PAGE
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _expenses = [];
  double _budget = 20000;
  bool _loading = true;
  int _tab = 0;
  String _query = '';
  String _filter = 'All';
  String _sort = 'Newest';
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    _load();
  }

  // ---------- storage ----------
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // v3 first, fall back to the old v2 data so nothing is lost.
    final raw = prefs.getString('expenses_v3') ?? prefs.getString('expenses_v2');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _expenses = list
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _expenses = [];
      }
    }
    _budget = prefs.getDouble('budget_v3') ?? prefs.getDouble('budget_v2') ?? 20000;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'expenses_v3', jsonEncode(_expenses.map((e) => e.toJson()).toList()));
    await prefs.setDouble('budget_v3', _budget);
  }

  // ---------- calculations ----------
  List<Expense> get _monthExpenses => _expenses
      .where((e) => e.date.year == _month.year && e.date.month == _month.month)
      .toList();

  double get _monthTotal => _monthExpenses.fold(0.0, (s, e) => s + e.amount);

  double _totalFor(DateTime m) => _expenses
      .where((e) => e.date.year == m.year && e.date.month == m.month)
      .fold(0.0, (s, e) => s + e.amount);

  bool get _isCurrentMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  List<Expense> get _visible {
    final q = _query.toLowerCase();
    final list = _monthExpenses.where((e) {
      final matchQ = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.note.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.method.toLowerCase().contains(q);
      final matchC = _filter == 'All' || e.category == _filter;
      return matchQ && matchC;
    }).toList();

    switch (_sort) {
      case 'Highest':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'Important':
        list.sort((a, b) {
          if (a.important != b.important) return a.important ? -1 : 1;
          return b.date.compareTo(a.date);
        });
        break;
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  // ---------- actions ----------
  Future<void> _openSheet({Expense? edit}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ExpenseForm(initial: edit),
    );
    if (result == null) return;
    setState(() {
      final i = _expenses.indexWhere((x) => x.id == result.id);
      if (i >= 0) {
        _expenses[i] = result;
      } else {
        _expenses.insert(0, result);
      }
      // jump to the month of the saved expense so the user sees it
      _month = DateTime(result.date.year, result.date.month);
    });
    _save();
  }

  void _delete(Expense e) {
    final index = _expenses.indexWhere((x) => x.id == e.id);
    if (index < 0) return;
    setState(() => _expenses.removeAt(index));
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${e.title}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() => _expenses.insert(
                  index > _expenses.length ? _expenses.length : index, e));
              _save();
            },
          ),
        ),
      );
  }

  void _toggleImportant(Expense e) {
    setState(() {
      final i = _expenses.indexWhere((x) => x.id == e.id);
      if (i >= 0) _expenses[i] = _expenses[i].copyWith(important: !e.important);
    });
    _save();
  }

  Future<void> _openDetail(Expense e) async {
    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseDetailPage(expense: e)),
    );
    if (action == 'edit') {
      _openSheet(edit: e);
    } else if (action == 'delete') {
      _delete(e);
    }
  }

  Future<void> _editBudget() async {
    final controller = TextEditingController(text: _budget.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) {
      setState(() => _budget = value);
      _save();
    }
  }

  Future<void> _exportMonth() async {
    final list = _monthExpenses..sort((a, b) => a.date.compareTo(b.date));
    final buf = StringBuffer('Date,Title,Category,Method,Amount,Note\n');
    for (final e in list) {
      String q(String s) => '"${s.replaceAll('"', '""')}"';
      buf.writeln(
          '${fmtDate(e.date)},${q(e.title)},${e.category},${e.method},${e.amount.toStringAsFixed(2)},${q(e.note)}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(
              '${monthName(_month)} copied (${list.length} expenses, CSV format)')));
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: _tab == 0 ? _expensesTab() : _summaryTab(),
                ),
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.pink]),
          boxShadow: [
            BoxShadow(
                color: alpha(AppColors.pink, 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openSheet(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add expense',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: alpha(AppColors.primary, 0.16),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Expenses'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Insights'),
        ],
      ),
    );
  }

  // ================= EXPENSES TAB =================
  Widget _expensesTab() {
    final items = _visible;
    final children = <Widget>[];
    DateTime? last;
    for (final e in items) {
      if (_sort == 'Newest') {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (last == null || d != last) {
          final dayTotal = items
              .where((x) => sameDay(x.date, d))
              .fold(0.0, (s, x) => s + x.amount);
          children.add(_dayHeader(d, dayTotal));
          last = d;
        }
      }
      children.add(_tile(e));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        _header(),
        const SizedBox(height: 16),
        _monthBar(),
        const SizedBox(height: 14),
        _hero(),
        const SizedBox(height: 20),
        _searchField(),
        const SizedBox(height: 14),
        _chips(),
        const SizedBox(height: 18),
        _listHeader(items.length),
        const SizedBox(height: 8),
        if (items.isEmpty) _empty() else ...children,
      ],
    );
  }

  Widget _header() {
    final h = DateTime.now().hour;
    final greet = h < 12
        ? 'Good morning ☀️'
        : h < 17
            ? 'Good afternoon 🌤️'
            : 'Good evening 🌙';
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.pink]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: alpha(AppColors.primary, 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kharcha',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink)),
            Text(greet,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          tooltip: 'Copy this month as CSV',
          onPressed: _exportMonth,
          icon: const Icon(Icons.ios_share),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'Set monthly budget',
          onPressed: _editBudget,
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Widget _monthBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final n = DateTime.now();
                setState(() => _month = DateTime(n.year, n.month));
              },
              child: Text(
                monthName(_month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
            ),
          ),
          IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _hero() {
    final month = _monthTotal;
    final ratio = _budget > 0 ? month / _budget : 0.0;
    final over = ratio > 1;
    final warn = ratio >= 0.8 && !over;
    final monthList = _monthExpenses;
    final important = monthList.where((e) => e.important).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFFFF4D8D), Color(0xFFFF9F1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: alpha(AppColors.primary, 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEEP TRACK OF EVERY RUPEE',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: Colors.white70),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(month),
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          Text('spent in ${monthName(_month)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroStat('Transactions', '${monthList.length}'),
              const SizedBox(width: 10),
              _heroStat('Starred ⭐', '$important'),
              const SizedBox(width: 10),
              _heroStat('Left', money(math.max(_budget - month, 0))),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly budget',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              Flexible(
                child: Text('${money(month)} / ${money(_budget)}',
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                  over ? const Color(0xFFFFE0E0) : AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            over
                ? '🚨 Over budget by ${money(month - _budget)}'
                : warn
                    ? '⚠️ ${(ratio * 100).toStringAsFixed(0)}% used - slow down a little!'
                    : '🎉 ${(ratio * 100).toStringAsFixed(0)}% of this month\'s budget used',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(46),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _query = v.trim()),
      decoration: InputDecoration(
        hintText: 'Search name, note, category, UPI...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('All', Icons.apps, AppColors.primary),
          ...categories.map((c) => _chip(c.name, c.icon, c.color)),
        ],
      ),
    );
  }

  Widget _chip(String name, IconData icon, Color color) {
    final selected = _filter == name;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
        label: Text(name),
        selected: selected,
        showCheckmark: false,
        selectedColor: color,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: selected ? color : AppColors.border),
        shape: const StadiumBorder(),
        onSelected: (_) => setState(() => _filter = name),
      ),
    );
  }

  Widget _listHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Expenses ($count)',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink),
          ),
        ),
        DropdownButton<String>(
          value: _sort,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.sort, size: 20),
          items: const ['Newest', 'Highest', 'Lowest', 'Important']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _sort = v ?? 'Newest'),
        ),
      ],
    );
  }

  Widget _dayHeader(DateTime d, double total) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 4),
      child: Row(
        children: [
          Text(dayLabel(d),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary)),
          const Spacer(),
          Text(money(total),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Text('🐷', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text('No expenses here',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('Tap "Add expense" to record one.',
              style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _tile(Expense e) {
    final c = catOf(e.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(e.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _delete(e),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: alpha(c.color, 0.25)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openDetail(e),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: 'img_${e.id}',
                    child: ExpenseThumb(expense: e, size: 58),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Text('${c.emoji} ${e.category}  •  ${fmtDate(e.date)}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.color)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(payIcon(e.method),
                                size: 13, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(e.method,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                            if (e.bytes != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.photo_camera,
                                  size: 13, color: AppColors.muted),
                            ],
                            if (e.note.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(e.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('- ${money(e.amount)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger)),
                      InkWell(
                        onTap: () => _toggleImportant(e),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            e.important ? Icons.star : Icons.star_border,
                            color: e.important
                                ? AppColors.gold
                                : AppColors.muted,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= INSIGHTS TAB =================
  Widget _summaryTab() {
    final list = _monthExpenses;
    final totals = <String, double>{};
    for (final e in list) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _monthTotal;
    final highest = list.isEmpty
        ? 0.0
        : list.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final dim = DateTime(_month.year, _month.month + 1, 0).day;
    final elapsed = _isCurrentMonth ? DateTime.now().day : dim;
    final dailyAvg = total / elapsed;
    final projected = _isCurrentMonth ? dailyAvg * dim : total;

    // payment method split
    final byMethod = <String, double>{};
    for (final e in list) {
      byMethod[e.method] = (byMethod[e.method] ?? 0) + e.amount;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        const Text('Insights',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.ink)),
        const Text('See where your money goes',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 14),
        _monthBar(),
        const SizedBox(height: 16),
        Row(
          children: [
            _statTile('Spent', money(total), Icons.payments,
                AppColors.primary),
            const SizedBox(width: 12),
            _statTile('Daily average', money(dailyAvg), Icons.today,
                const Color(0xFF2F9BFF)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statTile('Biggest expense', money(highest), Icons.trending_up,
                AppColors.danger),
            const SizedBox(width: 12),
            _statTile(
                _isCurrentMonth ? 'Projected' : 'Month total',
                money(projected),
                Icons.auto_graph,
                AppColors.accent),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Spending by category',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink)),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          _empty()
        else ...[
          _donutCard(sorted, total),
          const SizedBox(height: 14),
          ...sorted.map((entry) => _categoryRow(entry, total)),
          const SizedBox(height: 14),
          const Text('Payment methods',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          _methodCard(byMethod, total),
        ],
        const SizedBox(height: 24),
        const Text('Last 6 months',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink)),
        const SizedBox(height: 12),
        _trendCard(),
      ],
    );
  }

  Widget _donutCard(List<MapEntry<String, double>> sorted, double total) {
    final colors = sorted.map((e) => catOf(e.key).color).toList();
    final values = sorted.map((e) => e.value).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                    size: const Size(200, 200),
                    painter: DonutPainter(values, colors)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(catOf(sorted.first.key).emoji,
                        style: const TextStyle(fontSize: 30)),
                    const Text('Top category',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.muted)),
                    Text(sorted.first.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.ink)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: sorted.map((e) {
              final c = catOf(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: c.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(e.key,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(MapEntry<String, double> entry, double total) {
    final c = catOf(entry.key);
    final share = total > 0 ? entry.value / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CatArt(cat: c, size: 40, radius: 13),
              const SizedBox(width: 10),
              Expanded(
                child: Text(entry.key,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.ink)),
              ),
              Text(money(entry.value),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0).toDouble(),
                    minHeight: 9,
                    backgroundColor: alpha(c.color, 0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(c.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(share * 100).toStringAsFixed(0)}%',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, color: c.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodCard(Map<String, double> byMethod, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: payMethods.map((m) {
          final v = byMethod[m] ?? 0.0;
          final share = total > 0 ? v / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(payIcon(m), color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                SizedBox(
                    width: 88,
                    child: Text(m,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0).toDouble(),
                      minHeight: 8,
                      backgroundColor: alpha(AppColors.primary, 0.12),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: Text(money(v),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _trendCard() {
    final months = List.generate(
        6, (i) => DateTime(_month.year, _month.month - (5 - i)));
    final values = months.map(_totalFor).toList();
    final maxV = values.fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        height: 170,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(6, (i) {
            final selected = i == 5;
            final h = maxV > 0 ? (values[i] / maxV) * 110 : 0.0;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    values[i] >= 1000
                        ? '${(values[i] / 1000).toStringAsFixed(1)}k'
                        : values[i].toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: math.max(h, 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selected
                            ? const [AppColors.pink, AppColors.accent]
                            : [
                                alpha(AppColors.primary, 0.55),
                                AppColors.primary
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(shortMonth(months[i]),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w600,
                          color:
                              selected ? AppColors.pink : AppColors.muted)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: alpha(color, 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alpha(color, 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADD / EDIT FORM (bottom sheet)
// ---------------------------------------------------------------------------
class ExpenseForm extends StatefulWidget {
  final Expense? initial;
  const ExpenseForm({super.key, this.initial});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late String _method;
  late DateTime _date;
  String? _image;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(
        text: e == null ? '' : e.amount.toStringAsFixed(2));
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? categories.first.name;
    _method = e?.method ?? 'UPI';
    _date = e?.date ?? DateTime.now();
    _image = e?.image;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: src, maxWidth: 720, imageQuality: 60);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _image = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the photo')));
    }
  }

  void _photoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.accent),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_image != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _image = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Expense(
        id: widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        amount: double.parse(_amount.text.trim()),
        category: _category,
        date: _date,
        note: _note.text.trim(),
        important: widget.initial?.important ?? false,
        method: _method,
        image: _image,
      ),
    );
  }

  Widget _photoPicker() {
    final cat = catOf(_category);
    Uint8List? bytes;
    if (_image != null) {
      try {
        bytes = base64Decode(_image!);
      } catch (_) {}
    }
    return InkWell(
      onTap: _photoOptions,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: alpha(cat.color, 0.4), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(bytes, fit: BoxFit.cover),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Tap to change',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CatArt(cat: cat, size: 60),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add a picture',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Receipt or item photo (optional)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(editing ? 'Edit expense' : 'Add your expense',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('Keep every rupee accounted for.',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 18),
                  _photoPicker(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec('Expense name', Icons.edit_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Amount (₹)', Icons.currency_rupee),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((c) {
                      final selected = _category == c.name;
                      return ChoiceChip(
                        avatar: Text(c.emoji,
                            style: const TextStyle(fontSize: 14)),
                        label: Text(c.name),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: c.color,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w700),
                        side: BorderSide(
                            color: selected ? c.color : AppColors.border),
                        shape: const StadiumBorder(),
                        onSelected: (_) => setState(() => _category = c.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Paid with',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: payMethods.map((m) {
                      final selected = _method == m;
                      return ChoiceChip(
                        avatar: Icon(payIcon(m),
                            size: 16,
                            color: selected ? Colors.white : AppColors.primary),
                        label: Text(m),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w700),
                        side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border),
                        shape: const StadiumBorder(),
                        onSelected: (_) => setState(() => _method = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: _dec('Date', Icons.calendar_today_outlined),
                      child: Text(fmtDate(_date),
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _note,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec('Note (optional)', Icons.notes),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.pink]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                            editing ? 'Update expense' : 'Save expense',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DETAIL PAGE
// ---------------------------------------------------------------------------
class ExpenseDetailPage extends StatelessWidget {
  final Expense expense;
  const ExpenseDetailPage({super.key, required this.expense});

  void _zoom(BuildContext context) {
    final b = expense.bytes;
    if (b == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(b, fit: BoxFit.contain),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = catOf(expense.category);
    final b = expense.bytes;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Expense details',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.color, c.color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: alpha(c.color, 0.4),
                        blurRadius: 22,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Hero(
                      tag: 'img_${expense.id}',
                      child: b != null
                          ? GestureDetector(
                              onTap: () => _zoom(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.memory(b,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover),
                              ),
                            )
                          : Container(
                              width: 96,
                              height: 96,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(60),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Text(c.emoji,
                                  style: const TextStyle(fontSize: 50)),
                            ),
                    ),
                    if (b != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Tap picture to zoom',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
                    const SizedBox(height: 14),
                    Text(expense.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(money(expense.amount),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _row(Icons.category_outlined, 'Category',
                  '${c.emoji} ${expense.category}'),
              _row(Icons.calendar_today_outlined, 'Date',
                  fmtDate(expense.date)),
              _row(payIcon(expense.method), 'Paid with', expense.method),
              _row(Icons.star_outline, 'Important',
                  expense.important ? 'Yes ⭐' : 'No'),
              _row(Icons.notes, 'Note',
                  expense.note.isEmpty ? 'No note added' : expense.note),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'delete'),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'edit'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
