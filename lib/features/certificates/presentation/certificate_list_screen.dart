import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import 'certificate_provider.dart';

class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CertificateProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificateProvider>();
    if (provider.loading && provider.certificates.isEmpty) {
      return const LoadingShimmer();
    }
    if (provider.error != null && provider.certificates.isEmpty) {
      return AppErrorView(
        message: provider.error!,
        onRetry: () => provider.load(refresh: true),
      );
    }
    if (provider.certificates.isEmpty) {
      return const EmptyState(
        title: 'No certificates',
        subtitle: 'Completed course certificates will appear here.',
        icon: Icons.workspace_premium_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.certificates.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final certificate = provider.certificates[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const CircleAvatar(
                child: Icon(Icons.workspace_premium_rounded),
              ),
              title: Text(
                certificate.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(certificate.courseTitle ?? 'THC Learning'),
              trailing: IconButton(
                tooltip: 'Open certificate',
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: certificate.fileUrl == null
                    ? null
                    : () => launchUrl(
                        Uri.parse(certificate.fileUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
