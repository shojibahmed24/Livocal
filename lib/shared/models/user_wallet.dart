import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's prepaid minute wallet for AI live-translated calls.
class UserWallet {
  /// Paid purchased minutes (never expire).
  final int balanceMinutes;

  /// Complimentary trial minutes granted upon registration (default: 20 mins).
  final int trialMinutes;

  /// Whether the trial period is currently active.
  final bool trialActive;

  /// The exact expiration timestamp of the free trial (14 days from signup).
  final DateTime trialExpiresAt;

  /// Lifetime counter of translated call minutes consumed.
  final int totalMinutesUsed;

  /// Lifetime counter of paid minutes purchased.
  final int totalMinutesPurchased;

  /// User's preferred pricing currency ('BDT' or 'USD').
  final String currency;

  /// Wallet account creation timestamp.
  final DateTime createdAt;

  /// Last wallet modification or transaction timestamp.
  final DateTime updatedAt;

  const UserWallet({
    required this.balanceMinutes,
    required this.trialMinutes,
    required this.trialActive,
    required this.trialExpiresAt,
    this.totalMinutesUsed = 0,
    this.totalMinutesPurchased = 0,
    this.currency = 'BDT',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for a brand new user receiving a 14-day 20-minute freemium trial.
  factory UserWallet.newTrial({
    DateTime? now,
    int initialTrialMinutes = 20,
    int trialDays = 14,
    String currency = 'BDT',
  }) {
    final current = now ?? DateTime.now();
    return UserWallet(
      balanceMinutes: 0,
      trialMinutes: initialTrialMinutes,
      trialActive: true,
      trialExpiresAt: current.add(Duration(days: trialDays)),
      totalMinutesUsed: 0,
      totalMinutesPurchased: 0,
      currency: currency,
      createdAt: current,
      updatedAt: current,
    );
  }

  /// Factory for users whose device has already claimed trial on another account.
  factory UserWallet.noTrial({
    DateTime? now,
    String currency = 'BDT',
  }) {
    final current = now ?? DateTime.now();
    return UserWallet(
      balanceMinutes: 0,
      trialMinutes: 0,
      trialActive: false,
      trialExpiresAt: current,
      totalMinutesUsed: 0,
      totalMinutesPurchased: 0,
      currency: currency,
      createdAt: current,
      updatedAt: current,
    );
  }

  /// True if current time has passed the 14-day trial window.
  bool get isTrialExpired => DateTime.now().isAfter(trialExpiresAt);

  /// Usable trial minutes (0 if trial expired or inactive).
  int get effectiveTrialMinutes => (trialActive && !isTrialExpired) ? trialMinutes : 0;

  /// Total minutes available to initiate or sustain translated calls (Paid + Valid Trial).
  int get effectiveRemainingMinutes => balanceMinutes + effectiveTrialMinutes;

  /// True if caller has at least 1 minute remaining for translated calls.
  bool get hasMinutes => effectiveRemainingMinutes > 0;

  /// Number of days remaining in the 14-day trial period (0 if expired).
  int get daysRemainingInTrial {
    if (isTrialExpired || !trialActive) return 0;
    final diff = trialExpiresAt.difference(DateTime.now()).inSeconds;
    if (diff <= 0) return 0;
    return (diff / 86400).ceil();
  }

  UserWallet copyWith({
    int? balanceMinutes,
    int? trialMinutes,
    bool? trialActive,
    DateTime? trialExpiresAt,
    int? totalMinutesUsed,
    int? totalMinutesPurchased,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserWallet(
      balanceMinutes: balanceMinutes ?? this.balanceMinutes,
      trialMinutes: trialMinutes ?? this.trialMinutes,
      trialActive: trialActive ?? this.trialActive,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      totalMinutesUsed: totalMinutesUsed ?? this.totalMinutesUsed,
      totalMinutesPurchased: totalMinutesPurchased ?? this.totalMinutesPurchased,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balanceMinutes': balanceMinutes,
      'trialMinutes': trialMinutes,
      'trialActive': trialActive,
      'trialExpiresAt': Timestamp.fromDate(trialExpiresAt),
      'totalMinutesUsed': totalMinutesUsed,
      'totalMinutesPurchased': totalMinutesPurchased,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserWallet.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();

    return UserWallet(
      balanceMinutes: (map['balanceMinutes'] as num?)?.toInt() ?? 0,
      trialMinutes: (map['trialMinutes'] as num?)?.toInt() ?? 0,
      trialActive: map['trialActive'] as bool? ?? false,
      trialExpiresAt: parseDate(map['trialExpiresAt'], now),
      totalMinutesUsed: (map['totalMinutesUsed'] as num?)?.toInt() ?? 0,
      totalMinutesPurchased: (map['totalMinutesPurchased'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'BDT',
      createdAt: parseDate(map['createdAt'], now),
      updatedAt: parseDate(map['updatedAt'], now),
    );
  }
}
