import 'package:flutter/material.dart';

import 'stock_register.dart';

class StockRegisterScreen extends StatefulWidget {
  const StockRegisterScreen({
    super.key,
    required this.repository,
    this.title = 'Stock register',
  });
  final StockRegisterRepository repository;
  final String title;
  @override
  State<StockRegisterScreen> createState() => _StockRegisterScreenState();
}

class _StockRegisterScreenState extends State<StockRegisterScreen> {
  List<StockRegisterEntry>? entries;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loaded = await widget.repository.list();
      if (mounted) setState(() => entries = loaded);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Stock register unavailable. Pull to refresh to retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error!),
                  ),
                ],
              )
            : rows == null
            ? const Center(child: CircularProgressIndicator())
            : rows.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No batches captured yet. Entries saved from receiving show up here for every staff member and vendor.',
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('UPC')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Batch')),
                    DataColumn(label: Text('Expiration')),
                    DataColumn(label: Text('Days left')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Captured by')),
                  ],
                  rows: [
                    for (final e in rows)
                      DataRow(
                        cells: [
                          DataCell(Text(e.title)),
                          DataCell(Text(e.description)),
                          DataCell(Text(e.upc)),
                          DataCell(Text(e.sku)),
                          DataCell(Text(e.batchLabel)),
                          DataCell(
                            Text(
                              e.expiryDate == null
                                  ? '—'
                                  : e.expiryDate!.toIso8601String().substring(
                                      0,
                                      10,
                                    ),
                            ),
                          ),
                          DataCell(
                            Text(
                              e.daysRemaining == null
                                  ? '—'
                                  : e.daysRemaining.toString(),
                              style:
                                  e.daysRemaining != null &&
                                      e.daysRemaining! < 0
                                  ? const TextStyle(color: Colors.red)
                                  : null,
                            ),
                          ),
                          DataCell(Text('${e.quantity} ${e.unitCode}'.trim())),
                          DataCell(Text(e.capturedBy)),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
