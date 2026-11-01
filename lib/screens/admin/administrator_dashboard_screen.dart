import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
import 'administrator_report_detail_screen.dart';

class AdministratorDashboardScreen extends StatefulWidget {
  const AdministratorDashboardScreen({
    required this.repository,
    required this.profile,
    required this.onSignedOut,
    super.key,
  });

  final AdminRepository repository;
  final AdministratorProfile profile;
  final VoidCallback onSignedOut;

  @override
  State<AdministratorDashboardScreen> createState() =>
      _AdministratorDashboardScreenState();
}

class _AdministratorDashboardScreenState
    extends State<AdministratorDashboardScreen> {
  final _resourceController = TextEditingController();
  AdminReportFilter _filter = const AdminReportFilter();
  AdminReportPage? _result;
  bool _loading = true;
  AdminRepositoryErrorType? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _resourceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.fetchReports(_filter);
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on AdminRepositoryException catch (error) {
      if (!mounted || generation != _generation) return;
      if (error.type == AdminRepositoryErrorType.unauthorized) {
        widget.onSignedOut();
        return;
      }
      setState(() {
        _error = error.type;
        _loading = false;
      });
    }
  }

  void _applyFilter(AdminReportFilter filter) {
    setState(() => _filter = filter.copyWith(page: 1));
    _load();
  }

  Future<void> _logout() async {
    await widget.repository.logout();
    if (mounted) widget.onSignedOut();
  }

  Future<void> _openReport(AdminReport report) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdministratorReportDetailScreen(
          repository: widget.repository,
          reportId: report.id,
          onUnauthorized: widget.onSignedOut,
        ),
      ),
    );
    if (changed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Report review'),
        backgroundColor: const Color(0xFF176B5B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('admin-logout-button'),
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            key: const Key('admin-report-dashboard'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Signed in as ${widget.profile.email}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _ReportFilters(
                filter: _filter,
                resourceController: _resourceController,
                onApply: _applyFilter,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      key: Key('admin-reports-loading'),
                    ),
                  ),
                )
              else if (_error != null)
                _DashboardError(error: _error!, onRetry: _load)
              else if (_result!.items.isEmpty)
                const _EmptyReports()
              else ...[
                Text(
                  '${_result!.totalCount} reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._result!.items.map(
                  (report) => Card(
                    child: ListTile(
                      key: Key('admin-report-${report.id}'),
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        report.resource.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(report.reason.label),
                            Text(_formatDateTime(report.submittedAtUtc)),
                            const SizedBox(height: 6),
                            Chip(label: Text(report.status.label)),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openReport(report),
                    ),
                  ),
                ),
                _Pagination(
                  result: _result!,
                  onPage: (page) {
                    setState(() => _filter = _filter.copyWith(page: page));
                    _load();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportFilters extends StatefulWidget {
  const _ReportFilters({
    required this.filter,
    required this.resourceController,
    required this.onApply,
  });
  final AdminReportFilter filter;
  final TextEditingController resourceController;
  final ValueChanged<AdminReportFilter> onApply;

  @override
  State<_ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends State<_ReportFilters> {
  late AdminReportStatus? _status = widget.filter.status;
  late AdminReportReason? _reason = widget.filter.reason;
  late DateTime? _from = widget.filter.submittedFromUtc;
  late DateTime? _to = widget.filter.submittedToUtc;
  late int _pageSize = widget.filter.pageSize;

  Future<void> _selectDate(bool isFrom) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
    );
    if (selected == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime.utc(selected.year, selected.month, selected.day);
      } else {
        _to = DateTime.utc(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
          59,
        );
      }
    });
  }

  AdminReportFilter get _value => AdminReportFilter(
    pageSize: _pageSize,
    status: _status,
    reason: _reason,
    resourceId: widget.resourceController.text.trim().isEmpty
        ? null
        : widget.resourceController.text.trim(),
    submittedFromUtc: _from,
    submittedToUtc: _to,
  );

  void _clear() {
    widget.resourceController.clear();
    setState(() {
      _status = null;
      _reason = null;
      _from = null;
      _to = null;
      _pageSize = 25;
    });
    widget.onApply(const AdminReportFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: const Key('admin-report-filters'),
        title: const Text('Filters'),
        leading: const Icon(Icons.filter_list),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          DropdownButtonFormField<AdminReportStatus?>(
            key: const Key('admin-status-filter'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any status')),
              ...AdminReportStatus.values.map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              ),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          DropdownButtonFormField<AdminReportReason?>(
            key: const Key('admin-reason-filter'),
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any reason')),
              ...AdminReportReason.values.map(
                (reason) =>
                    DropdownMenuItem(value: reason, child: Text(reason.label)),
              ),
            ],
            onChanged: (value) => setState(() => _reason = value),
          ),
          TextField(
            key: const Key('admin-resource-filter'),
            controller: widget.resourceController,
            decoration: const InputDecoration(labelText: 'Resource ID'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('admin-from-date-filter'),
                onPressed: () => _selectDate(true),
                child: Text(_from == null ? 'From date' : _formatDate(_from!)),
              ),
              OutlinedButton(
                key: const Key('admin-to-date-filter'),
                onPressed: () => _selectDate(false),
                child: Text(_to == null ? 'To date' : _formatDate(_to!)),
              ),
              DropdownButton<int>(
                key: const Key('admin-page-size-filter'),
                value: _pageSize,
                items: const [10, 25, 50, 100]
                    .map(
                      (size) => DropdownMenuItem(
                        value: size,
                        child: Text('$size per page'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _pageSize = value ?? 25),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _clear, child: const Text('Clear')),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('admin-apply-filters'),
                onPressed: () => widget.onApply(_value),
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.result, required this.onPage});
  final AdminReportPage result;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('admin-previous-page'),
          tooltip: 'Previous page',
          onPressed: result.page > 1 ? () => onPage(result.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page ${result.page}'),
        IconButton(
          key: const Key('admin-next-page'),
          tooltip: 'Next page',
          onPressed: result.hasNextPage ? () => onPage(result.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});
  final AdminRepositoryErrorType error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 12),
          Text(
            error == AdminRepositoryErrorType.validation
                ? 'Review the selected filters and try again.'
                : 'Unable to load reports.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('admin-reports-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 56),
        SizedBox(height: 12),
        Text('No reports match these filters.'),
      ],
    ),
  );
}

String _formatDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';

String _formatDateTime(DateTime value) =>
    '${_formatDate(value.toLocal())} '
    '${value.toLocal().hour.toString().padLeft(2, '0')}:'
    '${value.toLocal().minute.toString().padLeft(2, '0')}';
