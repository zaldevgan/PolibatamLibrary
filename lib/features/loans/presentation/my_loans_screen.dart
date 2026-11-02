import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reader/presentation/pdf_reader_screen.dart';
import '../../reader/presentation/epub_reader_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/loans_provider.dart';
import '../data/digital_loan.dart';

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(memberLoansProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(memberLoansProvider),
          ),
        ],
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat pinjaman: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(memberLoansProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (loans) {
          if (loans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda tidak memiliki peminjaman aktif.',
                    style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jelajahi katalog e-book untuk mulai membaca.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = loans[index];
              return _buildLoanCard(context, ref, item, user?.memberId ?? '', user?.name ?? '');
            },
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, WidgetRef ref, DigitalLoanItem item, String memberId, String memberName) {
    final bool isActive = item.isActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: item.fileFormat == 'epub'
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      item.fileFormat == 'epub'
                          ? Icons.menu_book_rounded
                          : Icons.picture_as_pdf_rounded,
                      color: item.fileFormat == 'epub'
                          ? const Color(0xFFD97706)
                          : const Color(0xFFDC2626),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.author ?? 'Tanpa Pengarang',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Due date badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'Sisa waktu: ${item.remainingFormatted}' : 'Status: ${item.status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Kembalikan E-Book?'),
                          content: const Text('Kuota lisensi akan langsung dikembalikan ke perpustakaan agar bisa dibaca mahasiswa lain.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kembalikan')),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final ok = await ref.read(loansServiceProvider).returnLoan(item.loanId, memberId);
                        if (ok) {
                          ref.invalidate(memberLoansProvider);
                          ref.invalidate(memberSummaryProvider);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'E-book berhasil dikembalikan.'
                                  : 'Gagal mengembalikan e-book. Coba lagi.'),
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Kembalikan'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final token = (item.accessToken ?? '').trim();
                      if (token.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Token akses pinjaman ini tidak valid.')),
                        );
                        return;
                      }

                      final actualMemberId = memberId;
                      final actualMemberName = memberName;

                      if (item.fileFormat == 'epub') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EpubReaderScreen(
                              bookTitle: item.title,
                              token: token,
                              memberName: actualMemberName,
                              memberNim: actualMemberId,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfReaderScreen(
                              bookTitle: item.title,
                              token: token,
                              memberName: actualMemberName,
                              memberNim: actualMemberId,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chrome_reader_mode_rounded, size: 18),
                    label: const Text('Buka Reader'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

