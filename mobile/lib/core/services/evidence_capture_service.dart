import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:crypto/crypto.dart';

import '../network/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../features/workorders/data/workorder_service.dart';

final evidenceCaptureServiceProvider = Provider<EvidenceCaptureService>((ref) {
  return EvidenceCaptureService(
    ref.watch(workOrderServiceProvider),
    ref.watch(locationServiceProvider),
  );
});

class EvidenceCaptureService {
  final WorkOrderService _workOrderService;
  final LocationService _locationService;
  final ImagePicker _picker = ImagePicker();

  EvidenceCaptureService(this._workOrderService, this._locationService);

  Future<EvidenceCapture?> captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return await _createEvidenceCapture(photo);
    } catch (e) {
      return null;
    }
  }

  Future<EvidenceCapture?> selectFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return await _createEvidenceCapture(photo);
    } catch (e) {
      return null;
    }
  }

  Future<EvidenceCapture> _createEvidenceCapture(XFile photo) async {
    final file = File(photo.path);
    final bytes = await file.readAsBytes();
    final size = bytes.length;
    final hash = sha256.convert(bytes).toString();

    Position? position;
    try {
      position = await _locationService.getCurrentPosition();
    } catch (e) {
      position = null;
    }

    return EvidenceCapture(
      file: file,
      mimeType: photo.mimeType ?? 'image/jpeg',
      sizeBytes: size,
      sha256: hash,
      capturedAt: DateTime.now(),
      latitude: position?.latitude,
      longitude: position?.longitude,
      accuracyMeters: position?.accuracy,
    );
  }

  Future<EvidenceUploadResult> uploadEvidence({
    required String workOrderId,
    required EvidenceCapture capture,
    required String kind,
    required Function(double) onProgress,
  }) async {
    try {
      final uploadUrlData = await _workOrderService.getUploadUrl(
        workOrderId,
        kind: kind,
        mimeType: capture.mimeType,
        sizeBytes: capture.sizeBytes,
      );

      final uploadUrl = uploadUrlData['signed_url'] as String;
      final storagePath = uploadUrlData['storage_path'] as String;

      final dio = Dio();
      await dio.put(
        uploadUrl,
        data: capture.file.openRead(),
        options: Options(
          headers: {
            'Content-Type': capture.mimeType,
            'Content-Length': capture.sizeBytes.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          onProgress(sent / total);
        },
      );

      final registration = await _workOrderService.registerEvidence(
        workOrderId,
        storagePath: storagePath,
        kind: kind,
        capturedAt: capture.capturedAt,
        lat: capture.latitude,
        lon: capture.longitude,
        sha256: capture.sha256,
        mimeType: capture.mimeType,
        sizeBytes: capture.sizeBytes,
      );

      return EvidenceUploadResult.success(
        evidenceId: registration['id'] as String,
        geoValid: registration['geo_valid'] as bool? ?? false,
        distanceToLeakM: (registration['distance_to_leak_m'] as num?)
            ?.toDouble(),
      );
    } catch (e) {
      final apiError = extractApiException(e);
      final message = apiError.statusCode == 0
          ? e.toString()
          : '${apiError.statusCode}: ${apiError.displayMessage}';
      return EvidenceUploadResult.error(message);
    }
  }

  bool validateFileSize(int sizeBytes, {int maxMb = 10}) {
    return sizeBytes <= (maxMb * 1024 * 1024);
  }

  bool validateMimeType(String mimeType) {
    return mimeType.startsWith('image/');
  }
}

class EvidenceCapture {
  final File file;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  EvidenceCapture({
    required this.file,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });
}

class EvidenceUploadResult {
  final bool isSuccess;
  final String? evidenceId;
  final bool? geoValid;
  final double? distanceToLeakM;
  final String? error;

  EvidenceUploadResult.success({
    required this.evidenceId,
    required this.geoValid,
    required this.distanceToLeakM,
  }) : isSuccess = true,
       error = null;

  EvidenceUploadResult.error(this.error)
    : isSuccess = false,
      evidenceId = null,
      geoValid = null,
      distanceToLeakM = null;
}
