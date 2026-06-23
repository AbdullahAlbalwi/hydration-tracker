import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydration_tracker/feature/hydration/data/models/daily_summary_dto.dart';
import 'package:hydration_tracker/feature/hydration/data/models/water_log_dto.dart';
import 'package:hydration_tracker/feature/hydration/data/models/weekly_insights_dto.dart';
import 'package:hydration_tracker/feature/hydration/domain/hydration_exception.dart';

/// The only place that talks to Firestore / Cloud Functions for hydration data.
class HydrationRemoteDataSource {
  HydrationRemoteDataSource(this._firestore, this._auth, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const HydrationException('You are not signed in.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('users').doc(_uid).collection('water_logs');

  DocumentReference<Map<String, dynamic>> _summaryDoc(String dateKey) =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('daily_summaries')
          .doc(dateKey);

  /// Emits the summary document, or `null` when it does not exist yet.
  Stream<DailySummaryDto?> watchDailySummary(String dateKey) =>
      _summaryDoc(dateKey).snapshots().map(
        (doc) => doc.exists ? DailySummaryDto.fromSnapshot(doc) : null,
      );

  /// Emits that day's logs. Sorted newest-first on the client (single-field
  /// query) so no composite index is required; a day holds few logs.
  Stream<List<WaterLogDto>> watchLogsForDay(String dateKey) =>
      _logs.where('dateKey', isEqualTo: dateKey).snapshots().map((query) {
        final logs = query.docs.map(WaterLogDto.fromSnapshot).toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
        return logs;
      });

  Future<void> addWaterLog({
    required int amountMl,
    required String dateKey,
  }) async {
    try {
      await _logs.add({
        'amountMl': amountMl,
        'dateKey': dateKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw HydrationException(e.message ?? 'Could not add water. Try again.');
    }
  }

  Future<void> deleteWaterLog(String logId) async {
    try {
      await _logs.doc(logId).delete();
    } on FirebaseException catch (e) {
      throw HydrationException(e.message ?? 'Could not remove the entry.');
    }
  }

  Future<WeeklyInsightsDto> getWeeklyInsights({required String today}) async {
    try {
      final callable = _functions.httpsCallable('getWeeklyInsights');
      final result = await callable.call<Object?>(<String, dynamic>{
        'today': today,
      });
      // Normalize platform-channel maps (Map<Object?, Object?>) into a clean
      // Map<String, dynamic> tree for json_serializable.
      final json = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      return WeeklyInsightsDto.fromJson(json);
    } on FirebaseFunctionsException catch (e) {
      throw HydrationException(
        e.message ?? 'Could not load your weekly insights.',
      );
    }
  }
}
