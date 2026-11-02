import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import '../../../core/security/window_security.dart';
import '../../../core/constants/app_constants.dart';

class EpubReaderScreen extends StatefulWidget {
  final String bookTitle;
  final String token;
  final String memberName;
  final String memberNim;

  const EpubReaderScreen({
    super.key,
    required this.bookTitle,
    required this.token,
    required this.memberName,
    required this.memberNim,
  });

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late EpubController _epubController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _enableSecurityProtection();
    // epub_view 3.x tidak bisa membuka URL langsung, jadi berkas diunduh dulu
    _epubController = EpubController(document: _downloadEpub());
  }

  Future<EpubBook> _downloadEpub() async {
    if (widget.token.isEmpty) {
      throw Exception('Token baca tidak tersedia. Pinjam ulang e-book ini.');
    }
    final response = await Dio().get<List<int>>(
      AppConstants.getStreamUrl(widget.token),
      options: Options(responseType: ResponseType.bytes),
    );
    return EpubDocument.openData(Uint8List.fromList(response.data ?? const []));
  }

  Future<void> _enableSecurityProtection() async {
    try {
      await WindowSecurity.setSecure(true);
    } catch (_) {}
  }

  Future<void> _disableSecurityProtection() async {
    try {
      await WindowSecurity.setSecure(false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _disableSecurityProtection();
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: () {
              // Pengaturan ukuran font
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: EpubViewTableOfContents(controller: _epubController),
      ),
      body: Stack(
        children: [
          EpubView(
            controller: _epubController,
            onDocumentLoaded: (doc) {
              if (mounted) setState(() => _isLoading = false);
            },
            onDocumentError: (error) {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _errorMessage = error is DioException
                    ? 'Gagal mengunduh e-book (masa pinjam mungkin sudah habis).'
                    : error.toString().replaceFirst('Exception: ', '');
              });
            },
          ),

          if (_errorMessage != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 44, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                ],
              ),
            ),

          // Dynamic Security Watermark Overlay
          IgnorePointer(
            child: _buildDiagonalWatermark(),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

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
                color: Colors.black.withValues(alpha: 0.06),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

