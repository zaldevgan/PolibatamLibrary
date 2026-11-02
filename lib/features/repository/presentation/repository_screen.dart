import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/repository_provider.dart';
import '../data/repository_item.dart';
import 'repository_detail_screen.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      // Muat halaman berikutnya saat mendekati akhir daftar
      // Setelah gagal, jangan ulangi otomatis; pengguna memakai tombol "Coba lagi"
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 400 &&
          ref.read(repositoryListProvider).errorMessage == null) {
        ref.read(repositoryListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    ref.read(repositoryListProvider.notifier).search(query.trim());
  }

  void _navigateToDetail(RepositoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryListProvider);
    final notifier = ref.read(repositoryListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository Polibatam'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Repositori',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Repositori Institusi Polibatam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppTheme.primaryBlue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repository Politeknik Negeri Batam',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        'repository.polibatam.ac.id',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (state.totalElements > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${NumberFormat.decimalPattern('id').format(state.totalElements)} dokumen',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari judul, penulis, NIM, kata kunci...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
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
              onSubmitted: _search,
            ),
          ),

          // Content List
          Expanded(child: _buildContent(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildContent(RepositoryListState state, RepositoryListNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty && state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.red),
              const SizedBox(height: 12),
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: notifier.refresh,
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'Tidak ada dokumen untuk "${state.query}".',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _searchCtrl.clear();
                _search('');
              },
              child: const Text('Reset Pencarian'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index < state.items.length) {
            return _buildRepoCard(context, state.items[index]);
          }
          return _buildListFooter(state, notifier);
        },
      ),
    );
  }

  Widget _buildListFooter(RepositoryListState state, RepositoryListNotifier notifier) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.errorMessage != null) {
      return Center(
        child: TextButton.icon(
          onPressed: notifier.loadMore,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Gagal memuat. Coba lagi'),
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'Semua dokumen sudah ditampilkan',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return const SizedBox(height: 32);
  }

  Widget _buildAccessBadge(RepositoryItem item) {
    if (item.accessLabel.isEmpty) return const SizedBox.shrink();
    final color = item.isOpenAccess ? Colors.green.shade700 : Colors.orange.shade800;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          item.isOpenAccess ? Icons.lock_open_rounded : Icons.lock_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          item.accessLabel,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildRepoCard(BuildContext context, RepositoryItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3730A3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAccessBadge(item),
                  const Spacer(),
                  Text(
                    item.date,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.nim != null && item.nim!.isNotEmpty
                          ? '${item.author} • NIM ${item.nim}'
                          : item.author,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (item.department != null && item.department!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.domain_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.department!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.abstractText != null && item.abstractText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.abstractText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
