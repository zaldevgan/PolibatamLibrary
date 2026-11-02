import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_service.dart';
import '../data/member_summary.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

final memberSummaryProvider = FutureProvider.autoDispose<MemberSummary?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null || user.memberId.isEmpty) return null;
  final memberId = user.memberId;

  final service = ref.watch(profileServiceProvider);
  return service.getMemberSummary(memberId);
});

