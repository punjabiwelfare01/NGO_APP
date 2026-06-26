import 'package:flutter/material.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import '../../../../repositories/certificate_repository.dart';
import '../../../../app_state.dart';
import '../widgets/certificate_card.dart';
import 'certificate_preview_screen.dart';
import 'certificate_request_screen.dart';

class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Certificate> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final certs = await CertificateRepository.getMyCertificates();
      if (mounted) setState(() => _all = certs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Certificate> get _active =>
      _all.where((c) => c.status.isActive).toList();
  List<Certificate> get _ready =>
      _all.where((c) => c.status.canGeneratePdf).toList();
  List<Certificate> get _pending =>
      _all.where((c) => c.status == CertificateStatus.pending).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Certificates',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'All (${_all.length})'),
            Tab(text: 'Ready (${_ready.length})'),
            Tab(text: 'Pending (${_pending.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CertificateRequestScreen(),
            ),
          );
          if (created == true) _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Request Certificate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _all.isEmpty
                  ? const _EmptyView()
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _CertList(
                          certs: _all,
                          onRefresh: _load,
                          onGenerate: _openPreview,
                        ),
                        _CertList(
                          certs: _ready,
                          onRefresh: _load,
                          onGenerate: _openPreview,
                          emptyMessage: 'No certificates ready to generate yet.',
                        ),
                        _CertList(
                          certs: _pending,
                          onRefresh: _load,
                          onGenerate: _openPreview,
                          emptyMessage:
                              'No pending requests.\nTap "+ Request Certificate" to submit one.',
                        ),
                      ],
                    ),
    );
  }

  void _openPreview(Certificate cert) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificatePreviewScreen(
          certificate: cert,
          recipientName:
              AppState.studentName ?? cert.studentName ?? 'Certificate Holder',
        ),
      ),
    );
  }
}

class _CertList extends StatelessWidget {
  const _CertList({
    required this.certs,
    required this.onRefresh,
    required this.onGenerate,
    this.emptyMessage,
  });

  final List<Certificate> certs;
  final VoidCallback onRefresh;
  final void Function(Certificate) onGenerate;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (certs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage ?? 'No certificates found.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.6),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: certs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => CertificateCard(
          certificate: certs[i],
          onGenerate: certs[i].status.canGeneratePdf
              ? () => onGenerate(certs[i])
              : null,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No certificates yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete NGO work or events, then request a certificate. Admin will review and approve it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.softRed,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load certificates',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
