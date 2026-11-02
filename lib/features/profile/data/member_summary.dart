class MemberSummary {
  final MemberProfileInfo profile;
  final MemberStatistics statistics;
  final List<PhysicalLoanItem> currentLoans;
  final List<ActiveDigitalLoanItem> digitalLoans;
  final List<LoanHistoryItem> loanHistory;
  final List<FineRecord> fines;

  MemberSummary({
    required this.profile,
    required this.statistics,
    required this.currentLoans,
    required this.digitalLoans,
    required this.loanHistory,
    required this.fines,
  });

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    return MemberSummary(
      profile: MemberProfileInfo.fromJson(json['profile'] ?? {}),
      statistics: MemberStatistics.fromJson(json['statistics'] ?? {}),
      currentLoans: (json['current_loans'] as List? ?? [])
          .map((item) => PhysicalLoanItem.fromJson(item))
          .toList(),
      digitalLoans: (json['digital_loans'] as List? ?? [])
          .map((item) => ActiveDigitalLoanItem.fromJson(item))
          .toList(),
      loanHistory: (json['loan_history'] as List? ?? [])
          .map((item) => LoanHistoryItem.fromJson(item))
          .toList(),
      fines: (json['fines'] as List? ?? [])
          .map((item) => FineRecord.fromJson(item))
          .toList(),
    );
  }
}

class MemberProfileInfo {
  final String memberId;
  final String memberName;
  final String gender;
  final String memberType;
  final String? email;
  final String? phone;
  final String? address;
  final String institution;
  final String? programStudi;
  final String? rfid;
  final String? registerDate;
  final String? expireDate;
  final bool isExpired;

  MemberProfileInfo({
    required this.memberId,
    required this.memberName,
    required this.gender,
    required this.memberType,
    this.email,
    this.phone,
    this.address,
    required this.institution,
    this.programStudi,
    this.rfid,
    this.registerDate,
    this.expireDate,
    required this.isExpired,
  });

  factory MemberProfileInfo.fromJson(Map<String, dynamic> json) {
    return MemberProfileInfo(
      memberId: json['member_id']?.toString() ?? '',
      memberName: json['member_name']?.toString() ?? 'Anggota Perpustakaan',
      gender: json['gender']?.toString() ?? '-',
      memberType: json['member_type']?.toString() ?? 'Mahasiswa',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      institution: json['institution']?.toString() ?? 'Politeknik Negeri Batam',
      programStudi: json['program_studi']?.toString(),
      rfid: json['rfid']?.toString(),
      registerDate: json['register_date']?.toString(),
      expireDate: json['expire_date']?.toString(),
      isExpired: json['is_expired'] == true,
    );
  }
}

class MemberStatistics {
  final int currentPhysicalCount;
  final int currentDigitalCount;
  final int totalActiveLoans;
  final int totalHistoryCount;
  final int totalUnpaidFines;
  final int totalPaidFines;
  final bool hasUnpaidFines;

  MemberStatistics({
    required this.currentPhysicalCount,
    required this.currentDigitalCount,
    required this.totalActiveLoans,
    required this.totalHistoryCount,
    required this.totalUnpaidFines,
    required this.totalPaidFines,
    required this.hasUnpaidFines,
  });

  factory MemberStatistics.fromJson(Map<String, dynamic> json) {
    return MemberStatistics(
      currentPhysicalCount: (json['current_physical_count'] as num?)?.toInt() ?? 0,
      currentDigitalCount: (json['current_digital_count'] as num?)?.toInt() ?? 0,
      totalActiveLoans: (json['total_active_loans'] as num?)?.toInt() ?? 0,
      totalHistoryCount: (json['total_history_count'] as num?)?.toInt() ?? 0,
      totalUnpaidFines: (json['total_unpaid_fines'] as num?)?.toInt() ?? 0,
      totalPaidFines: (json['total_paid_fines'] as num?)?.toInt() ?? 0,
      hasUnpaidFines: json['has_unpaid_fines'] == true,
    );
  }
}

class PhysicalLoanItem {
  final int loanId;
  final String itemCode;
  final String title;
  final String author;
  final String callNumber;
  final String loanDate;
  final String dueDate;
  final int renewed;
  final bool isOverdue;
  final int overdueDays;

  PhysicalLoanItem({
    required this.loanId,
    required this.itemCode,
    required this.title,
    required this.author,
    required this.callNumber,
    required this.loanDate,
    required this.dueDate,
    required this.renewed,
    required this.isOverdue,
    required this.overdueDays,
  });

  factory PhysicalLoanItem.fromJson(Map<String, dynamic> json) {
    return PhysicalLoanItem(
      loanId: (json['loan_id'] as num?)?.toInt() ?? 0,
      itemCode: json['item_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Koleksi Perpustakaan',
      author: json['author']?.toString() ?? 'Perpustakaan Polibatam',
      callNumber: json['call_number']?.toString() ?? '-',
      loanDate: json['loan_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      renewed: (json['renewed'] as num?)?.toInt() ?? 0,
      isOverdue: json['is_overdue'] == true,
      overdueDays: (json['overdue_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class ActiveDigitalLoanItem {
  final int loanId;
  final int bookId;
  final String title;
  final String author;
  final String format;
  final String loanDate;
  final String dueDate;
  final int secondsRemaining;
  final String accessToken;

  ActiveDigitalLoanItem({
    required this.loanId,
    required this.bookId,
    required this.title,
    required this.author,
    required this.format,
    required this.loanDate,
    required this.dueDate,
    required this.secondsRemaining,
    required this.accessToken,
  });

  factory ActiveDigitalLoanItem.fromJson(Map<String, dynamic> json) {
    return ActiveDigitalLoanItem(
      loanId: (json['loan_id'] as num?)?.toInt() ?? 0,
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'E-Book Digital',
      author: json['author']?.toString() ?? '-',
      format: (json['format'] ?? 'pdf').toString().toLowerCase(),
      loanDate: json['loan_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      secondsRemaining: (json['seconds_remaining'] as num?)?.toInt() ?? 0,
      accessToken: json['access_token']?.toString() ?? '',
    );
  }
}

class LoanHistoryItem {
  final int loanId;
  final String itemCode;
  final String title;
  final String author;
  final String? callNumber;
  final String loanDate;
  final String dueDate;
  final String returnDate;

  LoanHistoryItem({
    required this.loanId,
    required this.itemCode,
    required this.title,
    required this.author,
    this.callNumber,
    required this.loanDate,
    required this.dueDate,
    required this.returnDate,
  });

  factory LoanHistoryItem.fromJson(Map<String, dynamic> json) {
    return LoanHistoryItem(
      loanId: (json['loan_id'] as num?)?.toInt() ?? 0,
      itemCode: json['item_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Koleksi Perpustakaan',
      author: json['author']?.toString() ?? '',
      callNumber: json['call_number']?.toString(),
      loanDate: json['loan_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      returnDate: json['return_date']?.toString() ?? '',
    );
  }
}

class FineRecord {
  final int finesId;
  final String date;
  final int amount;
  final int paidAmount;
  final String description;
  final bool isPaid;
  final String? paymentDate;

  FineRecord({
    required this.finesId,
    required this.date,
    required this.amount,
    required this.paidAmount,
    required this.description,
    required this.isPaid,
    this.paymentDate,
  });

  factory FineRecord.fromJson(Map<String, dynamic> json) {
    return FineRecord(
      finesId: (json['fines_id'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? 'Denda keterlambatan buku',
      isPaid: json['is_paid'] == true,
      paymentDate: json['payment_date']?.toString(),
    );
  }
}

