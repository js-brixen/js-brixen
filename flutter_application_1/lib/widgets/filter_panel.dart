import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookings_provider.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  final List<String> _selectedStatuses = [];
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BookingsProvider>();
    _selectedStatuses.addAll(provider.selectedStatuses);
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _applyFilters() {
    final provider = context.read<BookingsProvider>();
    provider.setStatusFilter(_selectedStatuses);
    if (_dateRange != null) {
      provider.setDateRange(_dateRange!.start, _dateRange!.end);
    }
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatuses.clear();
      _dateRange = null;
    });
    context.read<BookingsProvider>().clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter Bookings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status filters
          const Text(
            'Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('new', 'New', Colors.orange),
              _buildStatusChip('contacted', 'Contacted', Colors.blue),
              _buildStatusChip('follow_up', 'Follow Up', Colors.purple),
              _buildStatusChip('scheduled', 'Scheduled', Colors.cyan),
              _buildStatusChip('closed', 'Closed', Colors.grey),
            ],
          ),
          const SizedBox(height: 24),

          // Date range
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              _dateRange == null
                  ? 'Select date range'
                  : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatuses.contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleStatus(value),
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.3),
      ),
    );
  }
}
