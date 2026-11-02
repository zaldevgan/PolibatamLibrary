class AppConstants {
  // Base URLs Server SIPP (Menggunakan server aktif saat ini: devgan.biz.id)
  static const String sippBaseUrl = 'https://devgan.biz.id/sipp';
  static const String repositoryBaseUrl = 'https://repository.polibatam.ac.id';
  static const String dspaceServerUrl = 'https://repository.polibatam.ac.id/server';
  static const String dspaceApiUrl = '$dspaceServerUrl/api';
  static const String dspaceSearchUrl = '$dspaceApiUrl/discover/search/objects';
  static const String dspaceItemsUrl = '$dspaceApiUrl/core/items';

  // SIPP API Endpoints (Gunakan path tanpa leading slash agar Uri.resolve tidak memotong subfolder /sipp)
  static const String apiPrefix = 'index.php?p=api';
  static const String apiAuthLogin = '$apiPrefix/digital/auth/login';
  static const String apiAuthLogout = '$apiPrefix/digital/auth/logout';
  static const String apiAuthMe = '$apiPrefix/digital/auth/me';
  static const String apiDigitalBooks = '$apiPrefix/digital/books';
  static const String apiDigitalBorrow = '$apiPrefix/digital/borrow';
  static const String apiDigitalReturn = '$apiPrefix/digital/return';
  static const String apiDigitalReserve = '$apiPrefix/digital/reserve';
  static const String apiDigitalLoans = '$apiPrefix/digital/loans';
  static const String apiDigitalStream = '$apiPrefix/digital/stream';
  static const String apiMemberSummary = '$apiPrefix/digital/member/summary';

  /// Helper untuk mendapatkan URL streaming PDF/EPUB secara presisi
  static String getStreamUrl(String token) =>
      '$sippBaseUrl/index.php?p=api/digital/stream/$token';

  /// Helper untuk mendapatkan URL ringkasan anggota SLiMS (devgan.biz.id/sipp/index.php?p=member)
  static String getMemberSummaryUrl(String memberId) =>
      '$sippBaseUrl/$apiMemberSummary/$memberId';

  // Storage Keys
  static const String keyAccessToken = 'auth_access_token';
  static const String keyUserProfile = 'user_profile_json';
}


