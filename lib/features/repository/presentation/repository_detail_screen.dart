import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reader/presentation/pdf_reader_screen.dart';
import '../data/repository_item.dart';
import '../providers/repository_provider.dart';

class RepositoryDetailScreen extends ConsumerStatefulWidget {
  final RepositoryItem item;

  const RepositoryDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<RepositoryDetailScreen> createState() => _RepositoryDetailScreenState();
}

class _RepositoryDetailScreenState extends ConsumerState<RepositoryDetailScreen> {
  List<RepositoryBitstream> _bitstreams = [];
  bool _isLoadingBitstreams = true;
  String? _bitstreamError;

  @override
  void initState() {
    super.initState();
    _loadBitstreams();
  }

  Future<void> _loadBitstreams() async {
    setState(() {
      _isLoadingBitstreams = true;
      _bitstreamError = null;
    });

    // Ambil berkas asli dari server DSpace 9.2
    final service = ref.read(repositoryServiceProvider);
    try {
      final files = await service.fetchItemBitstreams(widget.item.uuid);
      if (mounted) {
        setState(() {
          _bitstreams = files;
          _isLoadingBitstreams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bitstreamError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingBitstreams = false;
        });
      }
    }
  }

  /// Berkas yang dibatasi hanya bisa diunduh setelah login di website repository
  Future<void> _openInBrowser() async {
    final url = widget.item.handleUrl ?? AppConstants.repositoryBaseUrl;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka browser.')),
      );
    }
  }

  void _openReader(BuildContext context, {required String pdfUrl, String? title}) {
    final user = ref.read(authProvider).user;
    final String bookTitle = title ?? widget.item.title;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          bookTitle: bookTitle,
          directPdfUrl: pdfUrl,
          memberName: user?.name ?? '',
          memberNim: user?.memberId ?? '',
        ),
      ),
    );
  }

  void _showCitationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sitasi Karya Ilmiah',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCitationTile(
                ctx,
                styleName: 'APA (American Psychological Association)',
                citationText: widget.item.citationApa ??
                    '${widget.item.author} (${widget.item.date}). ${widget.item.title}. ${widget.item.type}, Politeknik Negeri Batam.',
              ),
              const Divider(height: 20),
              _buildCitationTile(
                ctx,
                styleName: 'IEEE',
                citationText: widget.item.citationIeee ??
                    '${widget.item.author}, "${widget.item.title}," ${widget.item.type}, Politeknik Negeri Batam, ${widget.item.date}.',
              ),
              const Divider(height: 20),
              _buildCitationTile(
                ctx,
                styleName: 'BibTeX',
                citationText: widget.item.citationBibtex ??
                    '@thesis{polibatam_${widget.item.id},\n  author = {${widget.item.author}},\n  title = {${widget.item.title}},\n  year = {${widget.item.date}}\n}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCitationTile(BuildContext context, {required String styleName, required String citationText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              styleName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryBlue),
              tooltip: 'Salin sitasi $styleName',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: citationText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sitasi $styleName disalin ke papan klip!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            citationText,
            style: const TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textDark),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // PDF pertama yang bisa dibuka tanpa login DSpace
    final readablePdfs =
        _bitstreams.where((b) => b.isPdf && b.isAccessible == true).toList();
    final RepositoryBitstream? primaryPdf =
        readablePdfs.isNotEmpty ? readablePdfs.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.type),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_quote_rounded),
            tooltip: 'Salin Sitasi',
            onPressed: () => _showCitationModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Salin Tautan Handle',
            onPressed: () {
              final link = item.handleUrl ?? 'https://repository.polibatam.ac.id';
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan dokumen DSpace berhasil disalin!')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isLoadingBitstreams
                ? null
                : primaryPdf != null
                    ? () => _openReader(context, pdfUrl: primaryPdf.contentUrl, title: primaryPdf.name)
                    : _openInBrowser,
            icon: Icon(primaryPdf != null ? Icons.menu_book_rounded : Icons.open_in_browser_rounded),
            label: Text(
              primaryPdf != null ? 'Baca Naskah (PDF)' : 'Buka di Website Repository',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Jenis Dokumen & Tanggal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    item.type,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tahun ${item.date}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (item.accessLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isOpenAccess ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isOpenAccess ? Icons.lock_open_rounded : Icons.lock_rounded,
                          size: 14,
                          color: item.isOpenAccess ? Colors.green.shade700 : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.accessLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isOpenAccess ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Judul Naskah
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Penulis, Pembimbing, Prodi Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildMetaRow(
                      icon: Icons.person_rounded,
                      label: 'Penulis / Mahasiswa',
                      value: item.nim != null && item.nim!.isNotEmpty
                          ? '${item.author} (NIM: ${item.nim})'
                          : item.author,
                    ),
                    if (item.advisor != null && item.advisor!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildMetaRow(
                        icon: Icons.school_rounded,
                        label: 'Dosen Pembimbing',
                        value: item.advisor!,
                      ),
                    ],
                    if (item.department != null && item.department!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildMetaRow(
                        icon: Icons.domain_rounded,
                        label: 'Program Studi / Jurusan',
                        value: item.department!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Berkas Naskah Digital DSpace (Bitstreams)
            const Text(
              'Berkas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),

            if (_isLoadingBitstreams)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text(
                      'Memuat daftar berkas...',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              )
            else if (_bitstreamError != null)
              _buildInfoBox(
                icon: Icons.cloud_off_rounded,
                text: _bitstreamError!,
                action: TextButton(onPressed: _loadBitstreams, child: const Text('Coba Lagi')),
              )
            else if (_bitstreams.isNotEmpty)
              ..._bitstreams.map((b) => _buildBitstreamTile(context, b))
            else
              _buildInfoBox(
                icon: Icons.insert_drive_file_outlined,
                text: 'Dokumen ini tidak memiliki berkas yang dapat diunduh.',
              ),

            const SizedBox(height: 20),

            // Abstrak Dokumen
            const Text(
              'Abstrak / Ringkasan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                item.abstractText ?? 'Tidak ada ringkasan abstrak yang tersedia untuk naskah ini.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),

            // Kata Kunci (Keywords)
            if (item.keywords.isNotEmpty) ...[
              const Text(
                'Kata Kunci (Keywords)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.keywords.map((k) {
                  return Chip(
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    label: Text(
                      k,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                    ),
                    avatar: const Icon(Icons.tag_rounded, size: 14, color: AppTheme.primaryBlue),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Identifikasi DSpace Polibatam
            const Text(
              'Identitas Repositori Institusi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMetaRow(
                    icon: Icons.link_rounded,
                    label: 'URI Handle',
                    value: item.handleUrl ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({required IconData icon, required String text, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildBitstreamTile(BuildContext context, RepositoryBitstream bitstream) {
    final bool canOpen = bitstream.isPdf && bitstream.isAccessible == true;
    final bool restricted = bitstream.isAccessible == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              bitstream.isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bitstream.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    if (bitstream.sizeFormatted.isNotEmpty) bitstream.sizeFormatted,
                    if (restricted) 'Akses terbatas',
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: 11,
                    color: restricted ? Colors.orange.shade800 : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: canOpen
                ? () => _openReader(context, pdfUrl: bitstream.contentUrl, title: bitstream.name)
                : _openInBrowser,
            icon: Icon(
              canOpen ? Icons.chrome_reader_mode_rounded : (restricted ? Icons.lock_rounded : Icons.open_in_new_rounded),
              size: 14,
            ),
            label: Text(canOpen ? 'Baca' : 'Web', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
