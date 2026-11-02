import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/security/window_security.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PdfReaderScreen extends StatefulWidget {
  final String bookTitle;
  final String? token;
  final String? directPdfUrl;
  final String memberName;
  final String memberNim;

  const PdfReaderScreen({
    super.key,
    required this.bookTitle,
    this.token,
    this.directPdfUrl,
    required this.memberName,
    required this.memberNim,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _enableSecurityProtection();
  }

  /// Mengaktifkan FLAG_SECURE di Android untuk mencegah screenshot & screen record
  Future<void> _enableSecurityProtection() async {
    try {
      await WindowSecurity.setSecure(true);
    } catch (_) {}
  }

  /// Menghapus FLAG_SECURE saat keluar dari reader
  Future<void> _disableSecurityProtection() async {
    try {
      await WindowSecurity.setSecure(false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _disableSecurityProtection();
    _pdfController.dispose();
    super.dispose();
  }

  String _resolveStreamUrl() {
    if (widget.directPdfUrl != null && widget.directPdfUrl!.isNotEmpty) {
      return widget.directPdfUrl!;
    }
    if (widget.token != null && widget.token!.isNotEmpty) {
      return AppConstants.getStreamUrl(widget.token!);
    }
    return '';
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final streamUrl = _resolveStreamUrl();

    if (streamUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.bookTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Akses Dokumen Tidak Ditemukan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Token sesi pembaca atau URL naskah telah kedaluwarsa. Silakan pinjam ulang atau buka kembali naskah dari katalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _hasError
                  ? 'Gagal memuat'
                  : (_totalPages > 0 ? 'Halaman $_currentPage dari $_totalPages' : 'Menyiapkan naskah...'),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (!_hasError) ...[
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'Halaman Pertama',
              onPressed: () => _pdfController.firstPage(),
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Halaman Terakhir',
              onPressed: () => _pdfController.lastPage(),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // PDF Rendering Engine (Streaming Chunk via HTTP Range)
          if (!_hasError)
            SfPdfViewer.network(
              streamUrl,
              controller: _pdfController,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                  _isLoading = false;
                  _hasError = false;
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = details.description;
                });
              },
            ),

          // Error UI if document fails to load
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Memuat Dokumen PDF',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage.isNotEmpty ? _errorMessage : 'Terjadi kendala saat mengunduh aliran naskah PDF.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _retryLoading,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Dynamic Security Watermark Overlay
          // Melayang di atas dokumen dengan NIM dan Nama Mahasiswa semi-transparan
          if (!_hasError)
            IgnorePointer(
              child: _buildDiagonalWatermark(),
            ),

          if (_isLoading && !_hasError)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Menyiapkan naskah akademik terenkripsi...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Membuat watermark diagonal berulang di seluruh layar
  Widget _buildDiagonalWatermark() {
    final watermarkText = '${widget.memberNim} - ${widget.memberName}\nPerpustakaan Polibatam';

    return Center(
      child: Transform.rotate(
        angle: -pi / 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (index) => Text(
              watermarkText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.06), // Sangat samar sehingga tidak mengganggu membaca
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
