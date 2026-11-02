import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../loans/providers/loans_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reader/presentation/pdf_reader_screen.dart';
import '../../reader/presentation/epub_reader_screen.dart';
import '../providers/catalog_provider.dart';
import '../data/digital_book.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final int bookId;
  final DigitalBook? book;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.book,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  DigitalBook? _book;
  bool _isLoading = false;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    if (_book == null) {
      _fetchBookDetail();
    } else {
      // Background silent refresh agar kuota concurrency selalu terupdate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshBookDetail();
      });
    }
  }

  Future<void> _fetchBookDetail() async {
    setState(() => _isLoading = true);
    final catalogService = ref.read(catalogServiceProvider);
    final detail = await catalogService.getBookDetail(widget.bookId);
    if (mounted) {
      setState(() {
        _book = detail;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBookDetail() async {
    final catalogService = ref.read(catalogServiceProvider);
    final detail = await catalogService.getBookDetail(widget.bookId);
    if (mounted && detail != null) {
      setState(() {
        _book = detail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Koleksi Buku'),
      ),
      body: _buildContent(context, user),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user) {
    if (_isLoading && _book == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final book = _book;
    if (book == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 56, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Data buku tidak ditemukan atau sedang diperbarui.',
                style: TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchBookDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final bool isPrinted = !book.isDigital;
    final bool canBorrow = book.concurrency.canBorrowNow;
    final int available = book.concurrency.available;
    final int maxLicense = book.concurrency.maxLicense;

    // Warna & Ikon format
    Color bgColor;
    Color iconColor;
    IconData iconData;
    String formatText;

    if (isPrinted) {
      bgColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFB45309);
      iconData = Icons.import_contacts_rounded;
      formatText = 'BUKU CETAK (FISIK)';
    } else if (book.format == 'epub') {
      bgColor = const Color(0xFFE0E7FF);
      iconColor = const Color(0xFF4338CA);
      iconData = Icons.menu_book_rounded;
      formatText = 'E-BOOK (EPUB)';
    } else {
      bgColor = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      iconData = Icons.picture_as_pdf_rounded;
      formatText = 'E-BOOK (PDF)';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Book Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 95,
                height: 130,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, size: 44, color: iconColor),
                      const SizedBox(height: 6),
                      Text(
                        isPrinted ? 'CETAK' : book.format.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author ?? 'Perpustakaan Polibatam',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(formatText),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('${book.maxLoanDays} Hari Masa Pinjam'),
                          backgroundColor: const Color(0xFFEFF6FF),
                          labelStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Availability / Status Box
          if (isPrinted) ...[
            // Box Ketersediaan Buku Cetak di Rak
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: canBorrow ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canBorrow ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        canBorrow ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: canBorrow ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          canBorrow
                              ? 'Tersedia di Rak Perpustakaan ($available dari $maxLicense eksemplar)'
                              : 'Sedang Dipinjam Semua ($maxLicense eksemplar)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: canBorrow ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Nomor Panggil (Call No): ',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      Text(
                        book.callNumber ?? 'Tersedia di Rak',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Text(
                        'Lokasi: ',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      Text(
                        'Gedung Perpustakaan Politeknik Negeri Batam',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Box Concurrency E-Book
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: canBorrow
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canBorrow
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canBorrow ? Icons.check_circle : Icons.warning_rounded,
                    color: canBorrow
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canBorrow
                              ? 'Lisensi E-Book Tersedia'
                              : 'Kuota Lisensi Simultan Penuh',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: canBorrow
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                        Text(
                          canBorrow
                              ? 'Tersedia $available dari total $maxLicense lisensi aktif simultan.'
                              : 'Semua $maxLicense lisensi sedang aktif dipinjam mahasiswa lain. Anda dapat melakukan reservasi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: canBorrow
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Metadata Section
          const Text(
            'Informasi Bibliografi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (book.callNumber != null) _buildMetaRow('No. Panggil', book.callNumber!),
          _buildMetaRow('Penerbit', book.publisher ?? 'Perpustakaan Polibatam'),
          _buildMetaRow('Tahun Terbit', book.publishYear ?? '-'),
          _buildMetaRow('ISBN', book.isbn ?? '-'),
          _buildMetaRow('Klasifikasi', book.classification ?? '-'),
          _buildMetaRow('Jenis Koleksi', isPrinted ? 'Buku Cetak (Fisik)' : 'E-Book Digital'),
          const SizedBox(height: 24),

          // Description
          const Text(
            'Sinopsis / Ringkasan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description?.isNotEmpty == true
                ? book.description!
                : 'Koleksi resmi Perpustakaan Politeknik Negeri Batam.',
            style: const TextStyle(
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          // Action Area
          if (_isLoadingAction)
            const Center(child: CircularProgressIndicator())
          else if (isPrinted) ...[
            // Panduan Peminjaman Buku Cetak Fisik
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.pin_drop_rounded, color: AppTheme.primaryBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Peminjaman di Perpustakaan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan catat Nomor Panggil di atas dan ambil buku pada rak terkait di Perpustakaan Polibatam. Lakukan peminjaman mandiri menggunakan kartu anggota digital di profil Anda atau hubungi meja sirkulasi.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ] else if (canBorrow) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleBorrow(context, book, user?.memberId ?? '', user?.name ?? ''),
                icon: const Icon(Icons.book_online_rounded),
                label: const Text('Pinjam Digital & Mulai Membaca'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleReserve(context, book, user?.memberId ?? '', user?.name ?? ''),
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text('Reservasi Antrean E-Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBorrow(BuildContext context, DigitalBook book, String memberId, String memberName) async {
    setState(() => _isLoadingAction = true);
    final catalogService = ref.read(catalogServiceProvider);

    final actualMemberId = memberId;
    final actualMemberName = memberName;

    final res = await catalogService.borrowBook(
      bookId: book.id,
      memberId: actualMemberId,
      memberName: actualMemberName,
    );

    if (!mounted) return;
    setState(() => _isLoadingAction = false);

    if (mounted) {
      if (res['status'] == 'success' && res['data'] != null) {
        ref.invalidate(memberLoansProvider);
        ref.invalidate(memberSummaryProvider);
        final loanData = (res['data'] is Map) ? res['data'] as Map : {};
        // Ambil access_token atau stream_token secara fleksibel
        final streamToken = (loanData['access_token'] ??
                loanData['stream_token'] ??
                loanData['token'] ??
                '')
            .toString()
            .trim();

        if (streamToken.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal memperoleh token baca e-book.')),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peminjaman berhasil! Membuka e-book...')),
        );

        if (book.format == 'epub') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EpubReaderScreen(
                token: streamToken,
                bookTitle: book.title,
                memberNim: actualMemberId,
                memberName: actualMemberName,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PdfReaderScreen(
                token: streamToken,
                bookTitle: book.title,
                memberNim: actualMemberId,
                memberName: actualMemberName,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal meminjam buku')),
        );
      }
    }
  }

  Future<void> _handleReserve(BuildContext context, DigitalBook book, String memberId, String memberName) async {
    setState(() => _isLoadingAction = true);
    final catalogService = ref.read(catalogServiceProvider);

    final res = await catalogService.reserveBook(
      bookId: book.id,
      memberId: memberId,
      memberName: memberName,
    );

    if (!mounted) return;
    setState(() => _isLoadingAction = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Status antrean diproses.')),
      );
    }
  }
}
