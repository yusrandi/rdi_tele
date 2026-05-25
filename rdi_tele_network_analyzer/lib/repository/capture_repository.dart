import 'package:realspeed_analyzer/model/capture_model.dart';
import 'package:realspeed_analyzer/utils/api_client.dart';
import 'package:realspeed_analyzer/utils/api_constants.dart';

abstract class ICaptureRepository {
  Future<CaptureFullResponse> submitCapture(CaptureFullPayload payload);
}

class CaptureRepository implements ICaptureRepository {
  CaptureRepository({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const _tag = 'CaptureRepository';

  @override
  Future<CaptureFullResponse> submitCapture(CaptureFullPayload payload) async {
    // print('[$_tag] Submitting capture with payload: ${payload.toJson()}');
    final json = await _client.post(
      ApiConstants.capturesFull,
      payload.toJson(),
    );
    return CaptureFullResponse.fromJson(json);
  }
}
