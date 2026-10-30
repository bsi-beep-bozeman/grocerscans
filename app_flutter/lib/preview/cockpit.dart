import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shelflife/preview/catalog.dart';

const ink = Color(0xFF192A35);
const muted = Color(0xFF65737C);
const line = Color(0xFFE7EBEE);
const orange = Color(0xFFAD511F);
const green = Color(0xFF26735A);

TextStyle type(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = ink,
  double? spacing,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: spacing,
  fontFeatures: const [FontFeature.tabularFigures()],
);

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key});
  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  int tab = 0;
  String query = '';
  final checked = <String>{};
  final activity = <String>[];

  Future<void> scan() async {
    final saved = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (saved != null && mounted) setState(() => activity.insert(0, saved));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1050;
      final phone = constraints.maxWidth < 600;
      return Scaffold(
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFE8EEF0),
                selectedIndex: tab,
                onDestinationSelected: (value) => setState(() => tab = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard),
                    label: 'Cockpit',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    label: 'Inventory',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist_rounded),
                    label: 'Rounds',
                  ),
                ],
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (wide) sidebar(),
              Expanded(
                child: Column(
                  children: [
                    header(phone),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(phone ? 20 : 36),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1320),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'AL SAFA MARKET  /  MAIN BRANCH',
                                        style: type(
                                          10,
                                          weight: FontWeight.w700,
                                          color: muted,
                                          spacing: 1.7,
                                        ),
                                      ),
                                    ),
                                    if (!phone)
                                      const Pill(
                                        'DESIGN PREVIEW · SAMPLE DATA',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  [
                                    'A little attention.\nA lot less waste.',
                                    'Every item.\nIn clear view.',
                                    'Fresh eyes.\nEvery aisle.',
                                  ][tab],
                                  style: type(
                                    phone ? 36 : 46,
                                    weight: FontWeight.w700,
                                    spacing: -1.8,
                                  ).copyWith(height: 1.08),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  [
                                    'Your store, with the important things up front.',
                                    'Find a product by name, UPC or internal SKU.',
                                    'A simple checklist for your daily freshness walk.',
                                  ][tab],
                                  style: type(
                                    14,
                                    color: muted,
                                  ).copyWith(height: 1.5),
                                ),
                                const SizedBox(height: 26),
                                if (tab == 0) dashboard(wide, phone),
                                if (tab == 1) inventory(),
                                if (tab == 2) rounds(),
                                const SizedBox(height: 24),
                                Text(
                                  'EARLY DESIGN PREVIEW  /  Sample data · Changes last for this session',
                                  style: type(10, color: muted, spacing: .5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget sidebar() => Container(
    width: 218,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: line)),
    ),
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        brand(),
        const SizedBox(height: 52),
        Text(
          'WORKSPACE',
          style: type(10, color: muted, weight: FontWeight.w700, spacing: 1.8),
        ),
        const SizedBox(height: 14),
        for (final (index, label, icon) in [
          (0, 'Cockpit', Icons.space_dashboard_outlined),
          (1, 'Inventory', Icons.inventory_2_outlined),
          (2, 'Daily rounds', Icons.checklist_rounded),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: tab == index ? ink : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => tab = index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: tab == index ? Colors.white : muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: type(
                            13,
                            weight: FontWeight.w600,
                            color: tab == index ? Colors.white : muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco_outlined, color: green),
              const SizedBox(height: 12),
              Text(
                'Good stock.\nLess waste.',
                style: type(19, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'A fresher way to run\nyour everyday.',
                style: type(12, color: muted).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'SHELFLIFE  /  CONCEPT 01',
          style: type(9, spacing: 1.3, color: muted),
        ),
      ],
    ),
  );

  Widget brand() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.view_in_ar_rounded,
          color: Colors.white,
          size: 21,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'shelflife',
          maxLines: 1,
          style: type(23, weight: FontWeight.w700, spacing: -1),
        ),
      ),
    ],
  );

  Widget header(bool phone) => Container(
    padding: EdgeInsets.symmetric(horizontal: phone ? 20 : 36, vertical: 18),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        if (phone)
          Expanded(child: brand())
        else
          Text('Store operations', style: type(13, weight: FontWeight.w600)),
        if (!phone) const Spacer(),
        if (!phone) ...[const Pill('PREVIEW MODE'), const SizedBox(width: 18)],
        if (phone)
          const Pill('SAMPLE DATA')
        else
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF0F2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('AS', style: type(12, weight: FontWeight.w700)),
          ),
      ],
    ),
  );

  Widget dashboard(bool wide, bool phone) {
    final left = Column(
      children: [
        Container(
          padding: EdgeInsets.all(phone ? 22 : 26),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF0E5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 18, color: orange),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY’S FRESHNESS BRIEF',
                    style: type(
                      10,
                      color: orange,
                      weight: FontWeight.w700,
                      spacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${previewDueSoonUnits + previewDueTodayUnits}',
                    style: type(
                      76,
                      weight: FontWeight.w600,
                      spacing: -5,
                    ).copyWith(height: 1),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'units to check\nwithin 2 days',
                        style: type(
                          17,
                          weight: FontWeight.w500,
                        ).copyWith(height: 1.35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Review the products in your attention queue.\nStart there. Keep the rest of your day moving.',
                style: type(
                  13,
                  color: const Color(0xFF725D4D),
                ).copyWith(height: 1.6),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => setState(() => tab = 2),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Start freshness round'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: stat(
                '$previewTotalUnits',
                'Units on shelf',
                Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: stat(
                '${activity.length}',
                'Batches tried',
                Icons.qr_code_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Attention queue',
                      style: type(19, weight: FontWeight.w700, spacing: -.5),
                    ),
                  ),
                  Pill('$previewAttentionCount PRODUCTS', warm: true),
                ],
              ),
              const SizedBox(height: 4),
              Text('Soonest expiry first', style: type(12, color: muted)),
              const SizedBox(height: 18),
              for (final item in [
                ...previewCatalog.where((p) => p.days <= 2),
              ]..sort((a, b) => a.days.compareTo(b.days)))
                productRow(item),
            ],
          ),
        ),
      ],
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scannerCard(),
        const SizedBox(height: 22),
        panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'The shelf at a glance',
                    style: type(17, weight: FontWeight.w700, spacing: -.5),
                  ),
                  const Spacer(),
                  const Icon(Icons.bar_chart_rounded, size: 20, color: muted),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${previewTotalUnits == 0 ? 0 : (100 * previewFreshUnits / previewTotalUnits).round()}',
                    style: type(42, weight: FontWeight.w600, spacing: -2),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('%', style: type(22, color: muted)),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Text(
                      'outside the alert window',
                      style: type(11, color: muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Row(
                  children: [
                    Expanded(
                      flex: previewFreshUnits,
                      child: const ColoredBox(
                        color: green,
                        child: SizedBox(height: 10),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: previewDueSoonUnits,
                      child: const ColoredBox(
                        color: Color(0xFFE1AD62),
                        child: SizedBox(height: 10),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: previewDueTodayUnits,
                      child: const ColoredBox(
                        color: Color(0xFFBB624C),
                        child: SizedBox(height: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              legend('Fresh', '$previewFreshUnits units', green),
              legend(
                'Due in 1–2 days',
                '$previewDueSoonUnits units',
                const Color(0xFFAC772B),
              ),
              legend(
                'Due today',
                '$previewDueTodayUnits units',
                const Color(0xFFBB624C),
              ),
            ],
          ),
        ),
        if (activity.isNotEmpty) ...[
          const SizedBox(height: 22),
          panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just logged · preview',
                  style: type(17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                for (final entry in activity.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(entry, style: type(13, color: muted)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: left),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: right),
        ],
      );
    }
    return Column(
      children: [
        scannerCard(compact: true),
        const SizedBox(height: 20),
        left,
        const SizedBox(height: 20),
        if (activity.isNotEmpty)
          panel(child: Text(activity.first, style: type(14))),
      ],
    );
  }

  Widget scannerCard({bool compact = false}) => Container(
    padding: EdgeInsets.all(compact ? 20 : 24),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.center_focus_strong_rounded,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'The quick capture',
                style: type(17, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
            Text('01', style: type(11, color: const Color(0xFF99ADB8))),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 26),
          SizedBox(
            height: 155,
            child: CustomPaint(
              painter: LensPainter(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 70,
                      color: Color(0xFFDCE5E9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'UPC  /  EAN  /  SKU',
                      style: type(
                        9,
                        color: const Color(0xFFB6C7D0),
                        spacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (compact) const SizedBox(height: 14),
        Text(
          'Point. Recognize. Keep moving.',
          style: type(compact ? 13 : 15, color: const Color(0xFFCAD5DB)),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ink,
          ),
          onPressed: scan,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 21),
          label: const Text('Scan a product'),
        ),
        const SizedBox(height: 10),
        Text(
          'Camera barcode scan + catalog SKU lookup',
          textAlign: TextAlign.center,
          style: type(10, color: const Color(0xFFB6C7D0)),
        ),
      ],
    ),
  );

  Widget stat(String value, String label, IconData icon) => panel(
    padding: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: muted),
        const SizedBox(height: 14),
        Text(value, style: type(34, weight: FontWeight.w600, spacing: -1.5)),
        const SizedBox(height: 4),
        Text(label, style: type(12, color: muted)),
      ],
    ),
  );

  Widget inventory() => panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search name, UPC or SKU',
          ),
        ),
        const SizedBox(height: 20),
        for (final item in previewCatalog.where(
          (p) => '${p.name} ${p.upc} ${p.sku}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        ))
          productRow(item, showSku: true),
        if (!previewCatalog.any(
          (p) => '${p.name} ${p.upc} ${p.sku}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        ))
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matching product in the preview catalog.'),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan or enter a code'),
        ),
      ],
    ),
  );

  Widget rounds() => panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${checked.length} of $previewAttentionCount checked',
          style: type(20, weight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: previewAttentionCount == 0
              ? 0
              : checked.length / previewAttentionCount,
          color: green,
          backgroundColor: line,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 20),
        for (final item in previewCatalog.where((p) => p.days <= 2))
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: checked.contains(item.sku),
            onChanged: (value) => setState(() {
              if (value == true) {
                checked.add(item.sku);
              } else {
                checked.remove(item.sku);
              }
            }),
            title: Text(item.name, style: type(16, weight: FontWeight.w600)),
            subtitle: Text(
              '${item.units} units · ${item.days == 0 ? 'Due today' : '${item.days} days left'} · Check date and condition',
              style: type(12, color: muted),
            ),
          ),
        if (checked.length == 3)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Preview round complete. All three products checked.'),
          ),
      ],
    ),
  );
}

Widget panel({required Widget child, double padding = 24}) => Container(
  width: double.infinity,
  padding: EdgeInsets.all(padding),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: line),
    borderRadius: BorderRadius.circular(22),
  ),
  child: child,
);

Widget legend(String label, String value, Color color) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 9),
      Text(label, style: type(12, color: muted)),
      const Spacer(),
      Text(value, style: type(12, weight: FontWeight.w600)),
    ],
  ),
);

Widget productRow(CatalogItem item, {bool showSku = false}) => Container(
  padding: const EdgeInsets.symmetric(vertical: 14),
  decoration: const BoxDecoration(
    border: Border(bottom: BorderSide(color: line)),
  ),
  child: Row(
    children: [
      ProductMark(item: item),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: type(14, weight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(
              showSku
                  ? '${item.sku} · ${item.upc}'
                  : '${item.detail} · ${item.units} units',
              style: type(11, color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.days == 0 ? 'Today' : '${item.days}d',
            style: type(
              item.days == 0 ? 16 : 23,
              weight: FontWeight.w600,
              color: item.days <= 2 ? orange : green,
            ),
          ),
          Text('remaining', style: type(9, color: muted)),
        ],
      ),
    ],
  ),
);

class ProductMark extends StatelessWidget {
  const ProductMark({super.key, required this.item});
  final CatalogItem item;
  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (item.symbol) {
      'milk' => (
        Icons.water_drop_outlined,
        const Color(0xFF608798),
        const Color(0xFFEAF2F5),
      ),
      'meat' => (
        Icons.restaurant_rounded,
        const Color(0xFFB77973),
        const Color(0xFFF8ECE9),
      ),
      'bread' => (
        Icons.bakery_dining_outlined,
        const Color(0xFFB38A4D),
        const Color(0xFFF6F0E4),
      ),
      'can' => (Icons.kitchen_outlined, green, const Color(0xFFEEF4EE)),
      _ => (Icons.medication_outlined, muted, const Color(0xFFEEF0F5)),
    };
    return Container(
      width: 45,
      height: 51,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 26, color: color),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.warm = false});
  final String label;
  final bool warm;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: warm ? const Color(0xFFFCF0E5) : const Color(0xFFF0F3F5),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: type(
        9,
        weight: FontWeight.w600,
        color: warm ? orange : muted,
        spacing: .5,
      ),
    ),
  );
}

class LensPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF30434F)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    paint
      ..color = const Color(0xFFA5C5C4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(20, 6, size.width - 40, size.height - 12);
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final dx = corner.dx == rect.left ? 1 : -1;
      final dy = corner.dy == rect.top ? 1 : -1;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy * 19)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx * 19, corner.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final code = TextEditingController();
  final quantity = TextEditingController(text: '1');
  bool camera = false;
  CatalogItem? item;
  String? error;
  DateTime? expiry;

  @override
  void dispose() {
    code.dispose();
    quantity.dispose();
    super.dispose();
  }

  void lookup(String value) {
    final found = lookupPreviewItem(value);
    setState(() {
      camera = false;
      item = found;
      expiry = null;
      error = found == null
          ? 'No catalog match for “${value.trim()}”. Try a listed demo code or another barcode.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Quick capture', style: type(18, weight: FontWeight.w600)),
      backgroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Pill(
                  'PREVIEW CATALOG · ${previewCatalog.length} PRODUCTS',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Meet your next\nthree-tap habit.',
                style: type(
                  34,
                  weight: FontWeight.w700,
                  spacing: -1.2,
                ).copyWith(height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan a UPC / EAN barcode or look up a store SKU. Review the product, then add its date.',
                style: type(14, color: muted).copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              if (item == null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 240,
                    child: camera
                        ? MobileScanner(
                            onDetect: (capture) {
                              if (!camera) return;
                              for (final barcode in capture.barcodes) {
                                final value = barcode.rawValue;
                                if (value != null && value.isNotEmpty) {
                                  lookup(value);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, exception) => Container(
                              color: ink,
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: const Text(
                                'Camera unavailable. Allow camera access in your browser or phone settings, or use the code field below. Mobile web camera requires HTTPS.',
                                style: TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Container(
                            color: ink,
                            padding: const EdgeInsets.all(30),
                            child: CustomPaint(
                              painter: LensPainter(),
                              child: Center(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: ink,
                                  ),
                                  onPressed: () =>
                                      setState(() => camera = true),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Open camera'),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: code,
                  autocorrect: false,
                  onSubmitted: lookup,
                  decoration: const InputDecoration(
                    labelText: 'UPC barcode or store SKU',
                    hintText: 'e.g. DAI-001',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => lookup(code.text),
                  child: const Text('Find product'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(error ?? '', style: type(13, color: orange)),
                  ),
                const SizedBox(height: 20),
                Text(
                  'TRY THE SAMPLE CATALOG',
                  style: type(
                    10,
                    color: muted,
                    weight: FontWeight.w700,
                    spacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final sample in previewCatalog.take(3))
                      ActionChip(
                        label: Text(sample.sku),
                        onPressed: () {
                          code.text = sample.sku;
                          lookup(sample.sku);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SKU recognition matches a barcode value or typed code to catalog data. Printed product names and expiry-date OCR are planned separately.',
                  style: type(12, color: muted).copyWith(height: 1.5),
                ),
              ],
              if (item case final product?) ...[
                panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Pill('CATALOG MATCH'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ProductMark(item: product),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: type(22, weight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product.detail,
                                  style: type(13, color: muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${product.sku}  /  ${product.upc}',
                        style: type(12, color: muted),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity received',
                          suffixText: 'units',
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: expiry ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (date != null && mounted) {
                            setState(() => expiry = date);
                          }
                        },
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(
                          expiry == null
                              ? 'Choose the printed expiry date'
                              : 'Expiry: ${expiry?.month}/${expiry?.day}/${expiry?.year}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Confirm the date on the package. A UPC does not contain an expiry date.',
                        style: type(12, color: muted).copyWith(height: 1.5),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error ?? '',
                            style: type(13, color: orange),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final units = int.tryParse(quantity.text.trim());
                            if (units == null ||
                                units <= 0 ||
                                units > 100000 ||
                                expiry == null) {
                              setState(
                                () => error = 'Choose an expiry date and enter 1–100,000 units.',
                              );
                              return;
                            }
                            Navigator.of(context).pop(
                              '${product.name} · $units units · expires ${expiry?.month}/${expiry?.day}/${expiry?.year}',
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Save preview batch'),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    item = null;
                    error = null;
                  }),
                  child: const Text('Scan another product'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
