class DigitalLoanItem {
  final int loanId;
  final int bookId;
  final String title;
  final String? author;
  final String? isbn;
  final String? publisher;
  final String? coverImage;
  final String fileFormat;
  final String loanDate;
  final String dueDate;
  final String status;
  final int secondsRemaining;
  final String? accessToken;
  final String? streamUrl;

  DigitalLoanItem({
    required this.loanId,
    required this.bookId,
    required this.title,
    this.author,
    this.isbn,
    this.publisher,
    this.coverImage,
    required this.fileFormat,
    required this.loanDate,
    required this.dueDate,
    required this.status,
    required this.secondsRemaining,
    this.accessToken,
    this.streamUrl,
  });

  factory DigitalLoanItem.fromJson(Map<String, dynamic> json) {
    return DigitalLoanItem(
      loanId: int.tryParse(json['loan_id']?.toString() ?? '') ?? 0,
      bookId: int.tryParse(json['book_id']?.toString() ?? '') ?? 0,
      title: json['title'] ?? 'Tanpa Judul',
      author: json['author'],
      isbn: json['isbn'],
      publisher: json['publisher'],
      coverImage: json['cover_image'],
      fileFormat: (json['file_format'] ?? 'pdf').toString().toLowerCase(),
      loanDate: json['loan_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'expired',
      secondsRemaining: int.tryParse(json['seconds_remaining']?.toString() ?? '') ?? 0,
      accessToken: json['access_token']?.toString(),
      streamUrl: json['stream_url']?.toString(),
    );
  }

  bool get isActive => status == 'active' && secondsRemaining > 0;

  String get remainingFormatted {
    if (!isActive) return 'Waktu Habis';
    final hours = secondsRemaining ~/ 3600;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    if (days > 0) {
      return '$days hari $remainingHours jam lagi';
    } else if (hours > 0) {
      final mins = (secondsRemaining % 3600) ~/ 60;
      return '$hours jam $mins mnt lagi';
    } else {
      final mins = secondsRemaining ~/ 60;
      return '$mins menit lagi';
    }
  }
}

