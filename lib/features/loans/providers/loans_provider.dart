import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/loans_service.dart';
import '../data/digital_loan.dart';

final loansServiceProvider = Provider<LoansService>((ref) => LoansService());

final memberLoansProvider = FutureProvider.autoDispose<List<DigitalLoanItem>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null || user.memberId.isEmpty) return const [];
  final memberId = user.memberId;

  final service = ref.watch(loansServiceProvider);
  return service.getMemberLoans(memberId);
});

