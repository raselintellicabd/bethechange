import 'package:bethechange/core/network/api_client.dart';
import 'package:bethechange/core/network/mock_api_interceptor.dart';
import 'package:bethechange/features/appointment/data/appointment_api_repository.dart';
import 'package:bethechange/features/chatbot/data/chatbot_api_repository.dart';
import 'package:bethechange/features/contact/data/contact_api_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// Builds an [ApiClient] that always uses the mock interceptor (local JSON).
ApiClient createMockApiClient({
  DateTime? now,
  String chatbotApiKey = 'test-key',
  AssetBundle? bundle,
  Duration readDelay = Duration.zero,
  Duration writeDelay = Duration.zero,
}) {
  return ApiClient(
    dio: Dio(
      BaseOptions(baseUrl: 'https://mock.local'),
    ),
    useMockApi: true,
    mockInterceptor: MockApiInterceptor(
      now: now,
      chatbotApiKey: chatbotApiKey,
      bundle: bundle,
      readDelay: readDelay,
      writeDelay: writeDelay,
    ),
  );
}

AppointmentApiRepository createMockAppointmentRepository({
  DateTime? now,
}) {
  return AppointmentApiRepository(
    createMockApiClient(now: now ?? DateTime(2026, 9, 8, 10)),
  );
}

ContactApiRepository createMockContactRepository() {
  return ContactApiRepository(createMockApiClient());
}

ChatbotApiRepository createMockChatbotRepository({
  String apiKey = 'test-key',
}) {
  return ChatbotApiRepository(
    createMockApiClient(chatbotApiKey: apiKey),
  );
}
