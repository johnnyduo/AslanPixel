import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/data/services/ai_service.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_event.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_state.dart';
import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';
import 'package:aslan_pixel/features/finance/data/repositories/ai_insight_repository.dart';

class AiInsightBloc extends Bloc<AiInsightEvent, AiInsightState> {
  AiInsightBloc({
    required AIService aiService,
    required AiInsightRepository repository,
  })  : _aiService = aiService,
        _repository = repository,
        super(const AiInsightInitial()) {
    on<AiInsightRequested>(_onRequested);
    on<AiInsightWatchStarted>(_onWatchStarted);
  }

  final AIService _aiService;
  final AiInsightRepository _repository;
  StreamSubscription<List<AiInsightModel>>? _watchSubscription;

  // ---------------------------------------------------------------------------
  // _onRequested
  // ---------------------------------------------------------------------------

  Future<void> _onRequested(
    AiInsightRequested event,
    Emitter<AiInsightState> emit,
  ) async {
    emit(const AiInsightLoading());

    try {
      // 1. Check Firestore for a valid cached insight.
      final cached = await _repository.getLatestInsight(event.uid, event.type);
      if (cached != null) {
        emit(AiInsightLoaded([cached]));
        return;
      }

      // 2. Cache miss — call AI service.
      final contentTh = await _aiService.generateMarketSummary(
        symbols: event.context,
        context: event.context,
      );

      // 3. Build and persist the new insight.
      final now = DateTime.now();
      final insightId = FirebaseFirestore.instance.collection('_').doc().id;
      final insight = AiInsightModel(
        insightId: insightId,
        uid: event.uid,
        type: event.type,
        content: contentTh,
        contentTh: contentTh,
        modelUsed: 'gemini-2.0-flash',
        generatedAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      if (event.uid.isNotEmpty) {
        await _repository.saveInsight(insight);
      }

      emit(AiInsightLoaded([insight]));
    } catch (e) {
      emit(AiInsightError(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // _onWatchStarted
  // ---------------------------------------------------------------------------

  Future<void> _onWatchStarted(
    AiInsightWatchStarted event,
    Emitter<AiInsightState> emit,
  ) async {
    await _watchSubscription?.cancel();

    await emit.forEach<List<AiInsightModel>>(
      _repository.watchInsights(event.uid),
      onData: (insights) => AiInsightLoaded(insights),
      onError: (error, _) => AiInsightError(error.toString()),
    );
  }

  // ---------------------------------------------------------------------------
  // close
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }
}
