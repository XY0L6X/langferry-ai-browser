import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../core/services/translation_service.dart';
import '../core/services/database_service.dart';
import 'database_provider.dart';

/// 翻译状态枚举
enum TranslationStatus {
  idle,
  loading,
  success,
  failed,
}

/// 翻译模式
enum TranslationMode {
  original, // 原文
  translated, // 译文
  bilingual, // 对照
}

/// 翻译状态
class TranslationState {
  final TranslationStatus status;
  final String? originalText;
  final String? translatedText;
  final double progress;
  final String? error;
  final TranslationMode mode;

  const TranslationState({
    this.status = TranslationStatus.idle,
    this.originalText,
    this.translatedText,
    this.progress = 0,
    this.error,
    this.mode = TranslationMode.translated,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? originalText,
    String? translatedText,
    double? progress,
    String? error,
    TranslationMode? mode,
  }) {
    return TranslationState(
      status: status ?? this.status,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      progress: progress ?? this.progress,
      error: error,
      mode: mode ?? this.mode,
    );
  }
}

/// 翻译状态通知器
class TranslationNotifier extends StateNotifier<TranslationState> {
  final TranslationService _translationService;

  TranslationNotifier(this._translationService)
      : super(const TranslationState());

  /// 开始翻译
  Future<void> translate(String text,
      {String targetLanguage = 'zh-CN'}) async {
    state = state.copyWith(
      status: TranslationStatus.loading,
      originalText: text,
      progress: 0,
    );

    try {
      final result = await _translationService.translate(
        text: text,
        targetLanguage: targetLanguage,
      );

      state = state.copyWith(
        status: TranslationStatus.success,
        translatedText: result.translatedText,
        progress: 1,
      );
    } catch (e) {
      state = state.copyWith(
        status: TranslationStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// 流式翻译
  Future<void> translateStream(String text,
      {String targetLanguage = 'zh-CN'}) async {
    state = state.copyWith(
      status: TranslationStatus.loading,
      originalText: text,
      translatedText: '',
      progress: 0,
    );

    try {
      String translatedText = '';
      int chunkCount = 0;

      await for (final chunk in _translationService.translateStream(
        text: text,
        targetLanguage: targetLanguage,
      )) {
        if (chunk.isComplete) break;

        translatedText += chunk.text;
        chunkCount++;

        state = state.copyWith(
          translatedText: translatedText,
          progress: (chunkCount / 10).clamp(0.0, 0.9),
        );
      }

      state = state.copyWith(
        status: TranslationStatus.success,
        translatedText: translatedText,
        progress: 1,
      );
    } catch (e) {
      state = state.copyWith(
        status: TranslationStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// 切换翻译模式
  void setMode(TranslationMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// 重置状态
  void reset() {
    state = const TranslationState();
  }
}

/// API客户端提供者
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// 翻译服务提供者
final translationServiceProvider = Provider<TranslationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final database = ref.watch(databaseServiceProvider);
  return TranslationService(
    apiClient: apiClient,
    database: database,
  );
});

/// 翻译状态提供者
final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  final translationService = ref.watch(translationServiceProvider);
  return TranslationNotifier(translationService);
});

/// 当前翻译模式提供者
final translationModeProvider = Provider<TranslationMode>((ref) {
  final translationState = ref.watch(translationProvider);
  return translationState.mode;
});

/// 翻译是否正在加载
final isTranslatingProvider = Provider<bool>((ref) {
  final translationState = ref.watch(translationProvider);
  return translationState.status == TranslationStatus.loading;
});

/// 翻译是否成功
final translationSuccessProvider = Provider<bool>((ref) {
  final translationState = ref.watch(translationProvider);
  return translationState.status == TranslationStatus.success;
});

/// 翻译结果提供者
final translatedTextProvider = Provider<String?>((ref) {
  final translationState = ref.watch(translationProvider);
  return translationState.translatedText;
});