/// workers table model - Phase 3 section 7.1.
library;

import 'package:kaamwala/core/constants/app_constants.dart';
import 'dart:math';

enum ApprovalStatus { pending, approved, rejected }

class Worker {
  const Worker({
    required this.id,
    required this.userId,
    required this.category,
    this.name = '',
    this.city = '',
    this.area = '',
    this.bio = '',
    this.skills = const [],
    this.priceMin = 0,
    this.priceMax = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isAvailable = false,
    this.approvalStatus = ApprovalStatus.pending,
    this.rejectionReason,
    this.photoUrl,
    this.phone,
    this.portfolioUrls = const [],
    this.lat,
    this.lng,
  });

  final String id;
  final String userId;
  final ServiceCategory category;
  final String name;
  final String city;
  final String area;
  final String bio;
  final List<String> skills;
  final num priceMin;
  final num priceMax;
  final num ratingAvg;
  final int ratingCount;
  final bool isAvailable;

  /// Gate: workers cannot receive jobs until admin approves (FR-WORKER-02).
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;
  final String? photoUrl;

  /// Shown only on the worker's own profile page for tap-to-call.
  final String? phone;

  /// Max 5 in MVP (CS-05).
  final List<String> portfolioUrls;

  /// Location for distance-based search (nullable - not all workers have it set).
  final double? lat;
  final double? lng;

  bool get isVerified => approvalStatus == ApprovalStatus.approved;

  /// Computes distance in km from a given point (Haversine formula).
  /// Returns null if either this worker or the reference point lacks coordinates.
  double? distanceKmFrom(double refLat, double refLng) {
    if (lat == null || lng == null) return null;
    const r = 6371; // Earth radius in km
    final dLat = _toRad(refLat - lat!);
    final dLng = _toRad(refLng - lng!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat!)) * cos(_toRad(refLat)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  factory Worker.fromMap(Map<String, dynamic> map) {
    final user = map['users'];
    return Worker(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: ServiceCategory.fromDb(map['category'] as String? ?? 'plumber'),
      name: user is Map ? ((user['name'] ?? '') as String) : '',
      photoUrl: user is Map<String, dynamic>
          ? user['photo_url'] as String?
          : null,
      phone: user is Map<String, dynamic> ? user['phone'] as String? : null,
      city: (map['city'] ?? '') as String,
      area: (map['area'] ?? '') as String,
      bio: (map['bio'] ?? '') as String,
      skills: [
        for (final s in (map['skills'] as List<dynamic>? ?? const []))
          s as String,
      ],
      priceMin: (map['price_min'] ?? 0) as num,
      priceMax: (map['price_max'] ?? 0) as num,
      ratingAvg: (map['rating_avg'] ?? 0) as num,
      ratingCount: (map['rating_count'] ?? 0) as int,
      isAvailable: (map['is_available'] ?? false) as bool,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (a) => a.name == (map['approval_status'] ?? 'pending'),
        orElse: () => ApprovalStatus.pending,
      ),
      rejectionReason: map['rejection_reason'] as String?,
      portfolioUrls: [
        for (final s in (map['portfolio_urls'] as List<dynamic>? ?? const []))
          s as String,
      ],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
}
