import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/brightness_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reader/presentation/pdf_reader_screen.dart';
import '../../reader/presentation/epub_reader_screen.dart';
import '../providers/profile_provider.dart';
import '../data/member_summary.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0; // 0: Buku Dipinjam, 1: Riwayat, 2: Denda, 3: Info Akun

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Menampilkan popup QR code anggota dengan kecerahan layar maksimal otomatis
  Future<void> _showBarcodePopup({
    required BuildContext context,
    required String memberName,
    required String memberId,
    required String memberType,
    required String rfid,
  }) async {
    // 1. Auto High Brightness ke 100%
    await BrightnessHelper.setMaxBrightness();

    if (!mounted) {
      await BrightnessHelper.resetBrightness();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KARTU SCANNER SIRKULASI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Perpustakaan Polibatam',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Indicator Kecerahan Layar Maksimal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.brightness_high_rounded, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kecerahan layar maksimal aktif untuk pemindaian QR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Identitas Anggota
                Text(
                  memberName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    memberType,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code anggota
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: QrImageView(
                    data: rfid,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  memberId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontFamily: 'monospace',
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Dekatkan QR Code ke pemindai di anjungan sirkulasi mandiri perpustakaan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 2. Kembalikan kecerahan layar ke normal setelah popup ditutup
    await BrightnessHelper.resetBrightness();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final summaryAsync = ref.watch(memberSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Sirkulasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sinkronisasi Data',
            onPressed: () => ref.refresh(memberSummaryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(memberSummaryProvider);
          await ref.read(memberSummaryProvider.future);
        },
        child: summaryAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat data keanggotaan & sirkulasi...'),
              ],
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Gagal memuat sirkulasi: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(memberSummaryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (summary) {
            final profile = summary?.profile;
            final stats = summary?.statistics;
            final memberName = profile?.memberName ?? user?.name ?? 'Civitas Polibatam';
            final memberId = profile?.memberId ?? user?.memberId ?? '-';
            // QR berisi RFID anggota, sama dengan QR di Member Area web SIPP
            final rfid = (profile?.rfid ?? user?.rfid ?? '').trim();
            final memberType = profile?.memberType ?? user?.memberType ?? 'Mahasiswa';
            final expireDate = profile?.expireDate ?? '-';

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Digital Member Card (QR RFID, ketuk untuk popup Auto Max Brightness)
                  _buildDigitalMemberCard(
                    context: context,
                    memberName: memberName,
                    memberId: memberId,
                    memberType: memberType,
                    rfid: rfid,
                    expireDate: expireDate,
                    isExpired: profile?.isExpired ?? false,
                  ),
                  const SizedBox(height: 16),

                  // 2. Quick Stat Counters (Buku Dipinjam, Riwayat, Denda)
                  if (stats != null) _buildQuickStatsRow(stats),
                  const SizedBox(height: 20),

                  // 3. Tab Selector
                  _buildSegmentedTabSelector(stats),
                  const SizedBox(height: 16),

                  // 4. Tab Content View
                  _buildSelectedTabContent(summary, memberName, memberId),

                  const SizedBox(height: 24),

                  // 5. Action Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- KARTU ANGGOTA DIGITAL ---
  Widget _buildDigitalMemberCard({
    required BuildContext context,
    required String memberName,
    required String memberId,
    required String memberType,
    required String rfid,
    required String expireDate,
    required bool isExpired,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KARTU ANGGOTA PERPUSTAKAAN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    'POLITEKNIK NEGERI BATAM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memberType,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detail Nama & NIM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID / NIM: $memberId',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExpired ? 'Masa Berlaku: Kedaluwarsa' : 'Berlaku s/d: $expireDate',
                      style: TextStyle(
                        color: isExpired ? Colors.redAccent : Colors.white60,
                        fontSize: 11,
                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code Card (Interaktif, Ketuk -> Popup Auto High Brightness)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: rfid.isEmpty
                  ? null
                  : () => _showBarcodePopup(
                        context: context,
                        memberName: memberName,
                        memberId: memberId,
                        memberType: memberType,
                        rfid: rfid,
                      ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Mini QR Code (RFID)
                    if (rfid.isNotEmpty)
                      QrImageView(
                        data: rfid,
                        version: QrVersions.auto,
                        size: 46.0,
                      )
                    else
                      const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(Icons.qr_code_2_rounded, size: 40, color: Color(0xFFCBD5E1)),
                      ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (rfid.isNotEmpty)
                            const Row(
                              children: [
                                Icon(Icons.touch_app_rounded, size: 12, color: AppTheme.primaryBlue),
                                SizedBox(width: 4),
                                Text(
                                  'Ketuk untuk memperbesar QR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'RFID belum terdaftar. Hubungi petugas perpustakaan.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- QUICK STATS ROW ---
  Widget _buildQuickStatsRow(MemberStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            title: 'Dipinjam',
            value: '${stats.totalActiveLoans}',
            unit: 'buku',
            icon: Icons.bookmark_added_rounded,
            color: AppTheme.primaryBlue,
            onTap: () => setState(() => _selectedTab = 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            title: 'Riwayat',
            value: '${stats.totalHistoryCount}',
            unit: 'selesai',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            title: 'Denda',
            value: stats.hasUnpaidFines ? _formatRupiah(stats.totalUnpaidFines) : 'Rp 0',
            unit: stats.hasUnpaidFines ? 'Tertunggak' : 'Bebas Denda',
            icon: stats.hasUnpaidFines ? Icons.warning_amber_rounded : Icons.verified_rounded,
            color: stats.hasUnpaidFines ? Colors.red : Colors.green.shade700,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              unit,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB SELECTOR ---
  Widget _buildSegmentedTabSelector(MemberStatistics? stats) {
    final activeCount = stats?.totalActiveLoans ?? 0;
    final historyCount = stats?.totalHistoryCount ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabPill(index: 0, title: 'Buku Dipinjam ($activeCount)', icon: Icons.book_rounded),
          const SizedBox(width: 8),
          _buildTabPill(index: 1, title: 'Riwayat ($historyCount)', icon: Icons.history_rounded),
          const SizedBox(width: 8),
          _buildTabPill(index: 2, title: 'Denda & Bebas Pustaka', icon: Icons.receipt_long_rounded),
          const SizedBox(width: 8),
          _buildTabPill(index: 3, title: 'Info Akun', icon: Icons.badge_outlined),
        ],
      ),
    );
  }

  Widget _buildTabPill({required int index, required String title, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB CONTENT VIEW ---
  Widget _buildSelectedTabContent(MemberSummary? summary, String memberName, String memberNim) {
    switch (_selectedTab) {
      case 0:
        return _buildCurrentLoansTab(summary, memberName, memberNim);
      case 1:
        return _buildLoanHistoryTab(summary);
      case 2:
        return _buildFinesTab(summary);
      case 3:
      default:
        return _buildAccountInfoTab(summary);
    }
  }

  // TAB 0: SEDANG DIPINJAM (Buku Fisik & Digital)
  Widget _buildCurrentLoansTab(MemberSummary? summary, String memberName, String memberNim) {
    final physicalLoans = summary?.currentLoans ?? [];
    final digitalLoans = summary?.digitalLoans ?? [];

    if (physicalLoans.isEmpty && digitalLoans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.menu_book_rounded, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'Tidak Ada Peminjaman Aktif',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            SizedBox(height: 4),
            Text(
              'Anda sedang tidak memiliki pinjaman buku fisik maupun e-book di perpustakaan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinjaman Buku Fisik SLiMS
        if (physicalLoans.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.shelves, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Buku Fisik Dipinjam (${physicalLoans.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...physicalLoans.map((loan) => _buildPhysicalLoanCard(loan)),
          const SizedBox(height: 16),
        ],

        // Pinjaman Digital (E-Book CDL)
        if (digitalLoans.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.tablet_mac_rounded, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                'E-Book Digital Aktif (${digitalLoans.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...digitalLoans.map((dl) => _buildDigitalLoanCard(dl, memberName, memberNim)),
        ],
      ],
    );
  }

  Widget _buildPhysicalLoanCard(PhysicalLoanItem loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: loan.isOverdue ? Colors.red.shade200 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    loan.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: loan.isOverdue ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: loan.isOverdue ? Colors.red.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    loan.isOverdue ? 'Terlambat ${loan.overdueDays} Hari' : 'Aktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: loan.isOverdue ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Barcode: ${loan.itemCode}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'monospace'),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Text(
                  'Rak: ${loan.callNumber}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tgl. Pinjam', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    Text(loan.loanDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Jatuh Tempo', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    Text(
                      loan.dueDate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: loan.isOverdue ? Colors.red : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalLoanCard(ActiveDigitalLoanItem dl, String memberName, String memberNim) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFC7D2FE)),
      ),
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dl.format.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dl.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Penulis: ${dl.author} • Tempo: ${dl.dueDate}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => dl.format == 'epub'
                          ? EpubReaderScreen(
                              bookTitle: dl.title,
                              token: dl.accessToken,
                              memberName: memberName,
                              memberNim: memberNim,
                            )
                          : PdfReaderScreen(
                              bookTitle: dl.title,
                              token: dl.accessToken,
                              memberName: memberName,
                              memberNim: memberNim,
                            ),
                    ),
                  );
                },
                icon: const Icon(Icons.chrome_reader_mode_rounded, size: 16),
                label: const Text('Buka & Baca E-Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: RIWAYAT PEMINJAMAN (History)
  Widget _buildLoanHistoryTab(MemberSummary? summary) {
    final history = summary?.loanHistory ?? [];

    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'Belum Ada Riwayat Selesai',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            SizedBox(height: 4),
            Text(
              'Riwayat buku yang telah selesai Anda kembalikan akan dicatat di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Pengembalian (${history.length} Buku)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
            const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
          ],
        ),
        const SizedBox(height: 10),
        ...history.map((h) => _buildHistoryCard(h)),
      ],
    );
  }

  Widget _buildHistoryCard(LoanHistoryItem h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    h.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Barcode: ${h.itemCode}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                ),
                if (h.callNumber != null && h.callNumber!.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'No: ${h.callNumber}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue),
                  ),
                ],
              ],
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pinjam: ${h.loanDate}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Text(
                  'Dikembalikan: ${h.returnDate}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: DENDA & BEBAS PUSTAKA
  Widget _buildFinesTab(MemberSummary? summary) {
    final stats = summary?.statistics;
    final fines = summary?.fines ?? [];
    final hasUnpaid = stats?.hasUnpaidFines ?? false;
    final unpaidAmount = stats?.totalUnpaidFines ?? 0;
    final paidAmount = stats?.totalPaidFines ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Bebas Pustaka Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasUnpaid ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnpaid ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasUnpaid ? Icons.cancel_rounded : Icons.verified_user_rounded,
                    color: hasUnpaid ? Colors.red : Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasUnpaid ? 'Terdapat Tunggakan Denda' : 'Status Bebas Pustaka Terpenuhi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hasUnpaid ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasUnpaid
                    ? 'Total denda keterlambatan sirkulasi yang belum dibayar adalah ${_formatRupiah(unpaidAmount)}. Harap selesaikan administrasi denda di loket perpustakaan.'
                    : 'Selamat! Akun perpustakaan Anda bersih dari tunggakan denda keterlambatan sirkulasi. Surat Bebas Pustaka siap diterbitkan bila diperlukan.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: hasUnpaid ? Colors.red.shade900 : Colors.green.shade900,
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Denda Pernah Dibayar:',
                    style: TextStyle(fontSize: 12, color: hasUnpaid ? Colors.red.shade700 : Colors.green.shade700),
                  ),
                  Text(
                    _formatRupiah(paidAmount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: hasUnpaid ? Colors.red.shade900 : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rincian Riwayat Denda
        Text(
          'Rincian Denda Sirkulasi (${fines.length} Catatan)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        const SizedBox(height: 10),

        if (fines.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'Tidak ada catatan histori denda.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ...fines.map((f) => _buildFineCard(f)),
      ],
    );
  }

  Widget _buildFineCard(FineRecord f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: f.isPaid ? const Color(0xFFE2E8F0) : Colors.red.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  f.date,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: f.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    f.isPaid ? 'Lunas' : 'Belum Lunas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: f.isPaid ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              f.description,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nominal: ${_formatRupiah(f.amount)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                if (f.paymentDate != null && f.paymentDate!.isNotEmpty)
                  Text(
                    'Tgl Bayar: ${f.paymentDate}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: DETAIL INFORMASI AKUN (TANPA RFID)
  Widget _buildAccountInfoTab(MemberSummary? summary) {
    final p = summary?.profile;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Keanggotaan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
            const Divider(height: 20),
            _buildProfileTile(Icons.person_outline, 'Nama Lengkap', p?.memberName ?? '-'),
            _buildProfileTile(Icons.badge_outlined, 'Nomor Anggota / NIM', p?.memberId ?? '-'),
            _buildProfileTile(Icons.card_membership_rounded, 'Tipe Keanggotaan', p?.memberType ?? '-'),
            _buildProfileTile(Icons.school_outlined, 'Program Studi / Jabatan', p?.programStudi ?? '-'),
            _buildProfileTile(Icons.apartment_rounded, 'Institusi / Unit', p?.institution ?? 'Politeknik Negeri Batam'),
            _buildProfileTile(Icons.email_outlined, 'Email Resmi', p?.email ?? '-'),
            _buildProfileTile(Icons.phone_outlined, 'No. Telepon / WhatsApp', p?.phone ?? '-'),
            _buildProfileTile(Icons.home_outlined, 'Alamat Domisili', p?.address ?? '-'),
            _buildProfileTile(Icons.date_range_outlined, 'Tanggal Terdaftar', p?.registerDate ?? '-'),
            _buildProfileTile(Icons.event_available_outlined, 'Masa Berlaku Akun', p?.expireDate ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda akan keluar dari sesi perpustakaan mobile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
