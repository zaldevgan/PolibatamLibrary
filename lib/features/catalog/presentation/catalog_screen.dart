import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/catalog_provider.dart';
import '../data/digital_book.dart';
import 'book_detail_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(digitalBooksProvider);
    final filter = ref.watch(catalogFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Perpustakaan Polibatam'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari judul, pengarang, ISBN, atau rak...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(catalogFilterProvider.notifier).state =
                                  filter.copyWith(query: '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (val) {
                    ref.read(catalogFilterProvider.notifier).state =
                        filter.copyWith(query: val.trim());
                  },
                ),
                const SizedBox(height: 12),

                // Format Filter Chips (Semua, PDF, EPUB, Buku Cetak)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua Koleksi', '', filter.format),
                      const SizedBox(width: 8),
                      _buildFilterChip('E-Book (PDF)', 'pdf', filter.format),
                      const SizedBox(width: 8),
                      _buildFilterChip('E-Book (EPUB)', 'epub', filter.format),
                      const SizedBox(width: 8),
                      _buildFilterChip('Buku Cetak (Fisik)', 'printed', filter.format),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Books List
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Gagal memuat katalog: $err'),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Tidak ada koleksi buku digital atau cetak yang ditemukan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _buildBookCard(context, book);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue) {
    final isSelected = (currentValue == value);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(catalogFilterProvider.notifier).state =
            ref.read(catalogFilterProvider).copyWith(format: value);
      },
      selectedColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textDark,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, DigitalBook book) {
    final bool canBorrow = book.concurrency.canBorrowNow;
    final int available = book.concurrency.available;
    final int maxLicense = book.concurrency.maxLicense;
    final bool isPrinted = !book.isDigital;

    // Warna & Ikon format
    Color bgColor;
    Color iconColor;
    IconData iconData;
    String formatLabel;

    if (isPrinted) {
      bgColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFB45309);
      iconData = Icons.import_contacts_rounded;
      formatLabel = 'CETAK';
    } else if (book.format == 'epub') {
      bgColor = const Color(0xFFE0E7FF);
      iconColor = const Color(0xFF4338CA);
      iconData = Icons.menu_book_rounded;
      formatLabel = 'EPUB';
    } else {
      bgColor = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      iconData = Icons.picture_as_pdf_rounded;
      formatLabel = 'PDF';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              bookId: book.id,
              book: book,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail / Icon
              Container(
                width: 68,
                height: 94,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, color: iconColor, size: 30),
                      const SizedBox(height: 4),
                      Text(
                        formatLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
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
                      book.author ?? 'Perpustakaan Polibatam',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Badge Ketersediaan / No. Panggil Rak
                    if (isPrinted) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_outline, size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  book.callNumber ?? 'Di Rak',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: canBorrow ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              canBorrow ? '$available eks. di rak' : 'Habis dipinjam',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: canBorrow ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Concurrency Badge untuk E-Book
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: canBorrow
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              canBorrow
                                  ? '$available dari $maxLicense lisensi tersedia'
                                  : 'Kuota Lisensi Penuh (0)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: canBorrow
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
