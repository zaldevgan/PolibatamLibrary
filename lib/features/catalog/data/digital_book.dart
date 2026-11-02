class BookConcurrency {
  final int maxLicense;
  final int currentlyBorrowed;
  final int available;
  final bool canBorrowNow;
  final int queueCount;

  BookConcurrency({
    required this.maxLicense,
    required this.currentlyBorrowed,
    required this.available,
    required this.canBorrowNow,
    this.queueCount = 0,
  });

  factory BookConcurrency.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return BookConcurrency(
        maxLicense: 1,
        currentlyBorrowed: 0,
        available: 1,
        canBorrowNow: true,
        queueCount: 0,
      );
    }
    final json = Map<String, dynamic>.from(rawJson);

    final maxLicense = int.tryParse(json['max_license']?.toString() ?? '') ?? 1;
    final currentlyBorrowed = int.tryParse(json['currently_borrowed']?.toString() ?? '') ?? 0;
    final available = int.tryParse(json['available']?.toString() ?? '') ?? (maxLicense - currentlyBorrowed);
    final canBorrowVal = json['can_borrow_now'];
    final canBorrowNow = (canBorrowVal is bool)
        ? canBorrowVal
        : (canBorrowVal?.toString().toLowerCase() == 'true' ||
            canBorrowVal?.toString() == '1' ||
            available > 0);
    final queueCount = int.tryParse(json['queue_count']?.toString() ?? '') ?? 0;

    return BookConcurrency(
      maxLicense: maxLicense,
      currentlyBorrowed: currentlyBorrowed,
      available: available,
      canBorrowNow: canBorrowNow,
      queueCount: queueCount,
    );
  }
}

class DigitalBook {
  final int id;
  final int? biblioId;
  final String title;
  final String? author;
  final String? isbn;
  final String? publisher;
  final String? publishYear;
  final String? classification;
  final String? callNumber;
  final String? location;
  final String format; // 'pdf', 'epub', 'printed'
  final bool isDigital;
  final String sourceType; // 'local', 'external_api', 'physical_library'
  final String? providerName;
  final String? coverImage;
  final String? description;
  final BookConcurrency concurrency;
  final int maxLoanDays;
  final List<dynamic>? shelfItems;

  DigitalBook({
    required this.id,
    this.biblioId,
    required this.title,
    this.author,
    this.isbn,
    this.publisher,
    this.publishYear,
    this.classification,
    this.callNumber,
    this.location,
    required this.format,
    required this.isDigital,
    required this.sourceType,
    this.providerName,
    this.coverImage,
    this.description,
    required this.concurrency,
    required this.maxLoanDays,
    this.shelfItems,
  });

  factory DigitalBook.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return DigitalBook(
        id: 0,
        title: 'Buku',
        format: 'pdf',
        isDigital: true,
        sourceType: 'local',
        concurrency: BookConcurrency(
          maxLicense: 1,
          currentlyBorrowed: 0,
          available: 1,
          canBorrowNow: true,
        ),
        maxLoanDays: 3,
      );
    }
    final json = Map<String, dynamic>.from(rawJson);
    final formatStr = (json['format'] ?? 'pdf').toString().toLowerCase();
    final isDigitalVal = (json['is_digital'] is bool)
        ? json['is_digital'] as bool
        : (json['is_digital']?.toString() == '1' ||
            (formatStr != 'printed' && formatStr != 'physical'));

    return DigitalBook(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      biblioId: json['biblio_id'] != null
          ? int.tryParse(json['biblio_id'].toString())
          : null,
      title: json['title']?.toString() ?? 'Tanpa Judul',
      author: json['author']?.toString(),
      isbn: json['isbn']?.toString(),
      publisher: json['publisher']?.toString(),
      publishYear: json['publish_year']?.toString(),
      classification: json['classification']?.toString(),
      callNumber: json['call_number']?.toString(),
      location: json['location']?.toString(),
      format: formatStr,
      isDigital: isDigitalVal,
      sourceType: json['source_type']?.toString() ?? 'local',
      providerName: json['provider_name']?.toString(),
      coverImage: json['cover_image']?.toString(),
      description: json['description']?.toString(),
      concurrency: BookConcurrency.fromJson(json['concurrency']),
      maxLoanDays: int.tryParse(json['max_loan_days']?.toString() ?? '') ?? 3,
      shelfItems: json['shelf_items'] is List ? json['shelf_items'] : null,
    );
  }
}
