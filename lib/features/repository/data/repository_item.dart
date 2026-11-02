import '../../../core/constants/app_constants.dart';

class RepositoryBitstream {
  final String id;
  final String name;
  final int sizeBytes;
  final String contentUrl;
  final String? format;

  /// null = belum diperiksa, false = dibatasi (perlu login di website DSpace)
  final bool? isAccessible;

  RepositoryBitstream({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.contentUrl,
    this.format,
    this.isAccessible,
  });

  RepositoryBitstream copyWith({bool? isAccessible}) {
    return RepositoryBitstream(
      id: id,
      name: name,
      sizeBytes: sizeBytes,
      contentUrl: contentUrl,
      format: format,
      isAccessible: isAccessible ?? this.isAccessible,
    );
  }

  String get sizeFormatted {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  factory RepositoryBitstream.fromJson(Map<String, dynamic> json) {
    final links = json['_links'] as Map<String, dynamic>? ?? {};
    final contentLink = links['content']?['href']?.toString() ?? '';

    return RepositoryBitstream(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Dokumen',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      contentUrl: contentLink,
      format: json['format']?.toString(),
    );
  }
}

class RepositoryItem {
  final String id;
  final String uuid;
  final String title;
  final String author;
  final String date;
  final String type; // Article, Thesis, dsb. (dc.type)
  final String? abstractText;
  final String? department;
  final String? advisor;
  final String? nim;
  final List<String> keywords;
  final String? handle;
  final String? handleUrl;

  /// Status akses DSpace: open.access, restricted, embargo, metadata.only
  final String? accessStatus;
  final String? citationApa;
  final String? citationIeee;
  final String? citationBibtex;

  RepositoryItem({
    required this.id,
    required this.uuid,
    required this.title,
    required this.author,
    required this.date,
    required this.type,
    this.abstractText,
    this.department,
    this.advisor,
    this.nim,
    this.keywords = const [],
    this.handle,
    this.handleUrl,
    this.accessStatus,
    this.citationApa,
    this.citationIeee,
    this.citationBibtex,
  });

  bool get isOpenAccess => accessStatus == 'open.access';

  String get accessLabel {
    switch (accessStatus) {
      case 'open.access':
        return 'Akses Terbuka';
      case 'restricted':
        return 'Akses Terbatas';
      case 'embargo':
        return 'Embargo';
      case 'metadata.only':
        return 'Hanya Metadata';
      default:
        return '';
    }
  }

  factory RepositoryItem.fromDSpaceJson(Map<String, dynamic> item) {
    final String uuid = item['uuid']?.toString() ?? item['id']?.toString() ?? '';
    final String handle = item['handle']?.toString() ?? '';
    final metadata = (item['metadata'] as Map<String, dynamic>?) ?? {};

    // Helper untuk mengambil seluruh array nilai metadata DSpace
    List<String> getMetaList(String key) {
      final list = metadata[key] as List?;
      if (list == null) return [];
      return list
          .map((m) => m['value']?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Helper untuk mengambil nilai pertama dari metadata DSpace
    String getMeta(String key, [String fallback = '']) {
      final values = getMetaList(key);
      return values.isNotEmpty ? values.first : fallback;
    }

    final String title = getMeta('dc.title', item['name']?.toString() ?? '(Tanpa Judul)');
    final List<String> authors = getMetaList('dc.contributor.author');
    final String author = authors.isNotEmpty ? authors.join('; ') : '-';
    final String advisor = getMetaList('dc.contributor.advisor').join('; ');
    final String rawDate = getMeta('dc.date.issued', '');
    final String date = rawDate.isNotEmpty ? rawDate.split('-').first : '';
    final String type = getMeta('dc.type', 'Dokumen');

    // Program Studi, format DSpace Polibatam: "KODEPRODI63314#Logistik Perdagangan Internasional"
    final String rawProdi = getMeta('dc.identifier.kodeprodi', '');
    final String department = rawProdi.contains('#') ? rawProdi.split('#').last.trim() : rawProdi;

    // NIM, format: "NIM4132211030"
    final String nim = getMeta('dc.identifier.nim', '').replaceFirst('NIM', '').trim();

    String abstractText = getMeta('dc.description.abstract', '');
    if (abstractText.isEmpty) {
      abstractText = getMeta('dc.description.abstrak', '');
    }

    final List<String> keywords = getMetaList('dc.subject');

    // dc.identifier.uri di server berisi "//handle" ganda, jadi URL dibangun dari handle
    final String handleUrl = handle.isNotEmpty
        ? '${AppConstants.repositoryBaseUrl}/handle/$handle'
        : getMeta('dc.identifier.uri', '');

    final String? accessStatus =
        item['_embedded']?['accessStatus']?['status']?.toString();

    final String year = date.isNotEmpty ? date : 'n.d.';
    final citationApa = '$author ($year). $title. Politeknik Negeri Batam. $handleUrl';
    final citationIeee = '$author, "$title," Politeknik Negeri Batam, $year. [Online]. Available: $handleUrl';
    final citationBibtex = '@misc{polibatam_${handle.replaceAll('/', '_')},\n'
        '  author = {${authors.join(' and ')}},\n'
        '  title = {$title},\n'
        '  publisher = {Politeknik Negeri Batam},\n'
        '  year = {$year},\n'
        '  url = {$handleUrl}\n'
        '}';

    return RepositoryItem(
      id: uuid,
      uuid: uuid,
      title: title,
      author: author,
      date: date,
      type: type,
      abstractText: abstractText.isNotEmpty ? abstractText : null,
      department: department.isNotEmpty ? department : null,
      advisor: advisor.isNotEmpty ? advisor : null,
      nim: nim.isNotEmpty ? nim : null,
      keywords: keywords,
      handle: handle.isNotEmpty ? handle : null,
      handleUrl: handleUrl.isNotEmpty ? handleUrl : null,
      accessStatus: accessStatus,
      citationApa: citationApa,
      citationIeee: citationIeee,
      citationBibtex: citationBibtex,
    );
  }
}
