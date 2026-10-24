import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/work_order.dart' as models;
import '../../../core/network/api_client.dart';
import '../../../core/services/evidence_capture_service.dart';
import '../../workorders/data/workorder_provider.dart';

class RepairSubmissionScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const RepairSubmissionScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<RepairSubmissionScreen> createState() =>
      _RepairSubmissionScreenState();
}

class _RepairSubmissionScreenState
    extends ConsumerState<RepairSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workNotesController = TextEditingController();

  String _repairType = 'CLAMP';
  final List<MaterialEntry> _materials = [];
  int? _labourMinutes;
  final List<EvidenceEntry> _evidence = [];
  bool _isSubmitting = false;
  bool _allowSimulatedLocationOverride = false;

  @override
  void dispose() {
    _workNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(workOrderDetailProvider(widget.workOrderId));
    final isSimulatedTwin =
        detailAsync.valueOrNull?.leakEvent.source.toUpperCase() == 'TWIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Repair')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repair Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _repairType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CLAMP', child: Text('Clamp')),
                        DropdownMenuItem(
                          value: 'COUPLING',
                          child: Text('Coupling'),
                        ),
                        DropdownMenuItem(
                          value: 'JOINT_REPAIR',
                          child: Text('Joint Repair'),
                        ),
                        DropdownMenuItem(
                          value: 'SECTION_REPLACE',
                          child: Text('Section Replace'),
                        ),
                        DropdownMenuItem(
                          value: 'VALVE_REPLACE',
                          child: Text('Valve Replace'),
                        ),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _repairType = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before and after photos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Both are required. Take the before photo before starting '
                      'the repair and the after photo once it is complete. '
                      'Allow location access so each photo can be checked against the site.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    for (final photo in [
                      (kind: 'BEFORE_PHOTO', label: 'Before repair'),
                      (kind: 'AFTER_PHOTO', label: 'After repair'),
                    ]) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${photo.label} · ${_uploadedCount(photo.kind)} valid',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Take ${photo.label.toLowerCase()} photo',
                            onPressed: _isSubmitting
                                ? null
                                : () => _captureEvidence(photo.kind),
                            icon: const Icon(Icons.camera_alt),
                          ),
                          IconButton(
                            tooltip:
                                'Choose ${photo.label.toLowerCase()} photo',
                            onPressed: _isSubmitting
                                ? null
                                : () => _selectEvidence(photo.kind),
                            icon: const Icon(Icons.photo_library),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_evidence.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add one before-repair and one after-repair photo.',
                                style: TextStyle(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _evidence.map((e) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    e.capture.file,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 16,
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() => _evidence.remove(e));
                                    },
                                  ),
                                ),
                              ),
                              if (e.isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: e.progress,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!e.isUploading && e.geoValid == false)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_off,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    e.kind == 'BEFORE_PHOTO'
                                        ? 'BEFORE'
                                        : 'AFTER',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    if (_evidence.any((entry) => entry.geoValid == false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'A photo failed the site-location check. Retake it at '
                        'the leak location with phone location enabled.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (isSimulatedTwin) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Simulated twin work order',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'If your real phone location cannot match the '
                              'simulated leak location, you may bypass only '
                              'the photo-distance check. Before and after '
                              'photos are still required.',
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : _allowSimulatedLocationOverride
                                    ? () => setState(
                                        () => _allowSimulatedLocationOverride =
                                            false,
                                      )
                                    : _confirmLocationBypass,
                                icon: Icon(
                                  _allowSimulatedLocationOverride
                                      ? Icons.location_off
                                      : Icons.location_disabled,
                                ),
                                label: Text(
                                  _allowSimulatedLocationOverride
                                      ? 'Location bypass enabled · Turn off'
                                      : 'Bypass location check for this twin job',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Materials Used',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addMaterial,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._materials.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(m.item)),
                            Text('× ${m.qty}'),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() => _materials.remove(m));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Labour Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                        suffixText: 'min',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _labourMinutes = int.tryParse(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _workNotesController,
                      decoration: const InputDecoration(
                        hintText: 'Enter details about the repair work...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      maxLength: 2000,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRepair,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit for Operator Review'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  int _uploadedCount(String kind) => _evidence
      .where(
        (entry) =>
            entry.kind == kind &&
            entry.evidenceId != null &&
            entry.geoValid == true,
      )
      .length;

  Future<void> _confirmLocationBypass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bypass simulated location check?'),
        content: const Text(
          'This work order is from the digital twin. You can submit its '
          'photos without passing the GPS-distance check. Both before and '
          'after photos are still required, and the bypass is recorded for '
          'operator review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable bypass'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _allowSimulatedLocationOverride = true);
    }
  }

  Future<void> _captureEvidence(String kind) async {
    final service = ref.read(evidenceCaptureServiceProvider);
    EvidenceCapture? capture;
    try {
      capture = await service.captureFromCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not capture photo: $e')));
      }
      return;
    }

    if (capture == null) return;
    final selectedCapture = capture;

    if (!service.validateFileSize(selectedCapture.sizeBytes)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 10MB limit')),
        );
      }
      return;
    }

    setState(() {
      _evidence.add(
        EvidenceEntry(
          capture: selectedCapture,
          kind: kind,
          isUploading: false,
          progress: 0,
        ),
      );
    });

    await _uploadEvidence(_evidence.last);
  }

  Future<void> _selectEvidence(String kind) async {
    final service = ref.read(evidenceCaptureServiceProvider);
    EvidenceCapture? capture;
    try {
      capture = await service.selectFromGallery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not select photo: $e')));
      }
      return;
    }

    if (capture == null) return;
    final selectedCapture = capture;

    if (!service.validateFileSize(selectedCapture.sizeBytes)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 10MB limit')),
        );
      }
      return;
    }

    setState(() {
      _evidence.add(
        EvidenceEntry(
          capture: selectedCapture,
          kind: kind,
          isUploading: false,
          progress: 0,
        ),
      );
    });

    await _uploadEvidence(_evidence.last);
  }

  Future<void> _uploadEvidence(EvidenceEntry entry) async {
    setState(() {
      entry.isUploading = true;
      entry.progress = 0;
    });

    final service = ref.read(evidenceCaptureServiceProvider);
    final result = await service.uploadEvidence(
      workOrderId: widget.workOrderId,
      capture: entry.capture,
      kind: entry.kind,
      onProgress: (progress) {
        if (mounted) {
          setState(() => entry.progress = progress);
        }
      },
    );

    if (!mounted) return;
    setState(() {
      entry.isUploading = false;
      if (result.isSuccess) {
        entry.evidenceId = result.evidenceId;
        entry.geoValid = result.geoValid;
        entry.distanceToLeakM = result.distanceToLeakM;
      }
    });

    if (!result.isSuccess && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${result.error}')));
    }
    if (result.isSuccess && result.geoValid != true && mounted) {
      final distance = result.distanceToLeakM;
      final message = distance == null
          ? 'Photo uploaded, but phone location was unavailable. Enable '
                'location and retake it at the leak site.'
          : 'Photo is ${distance.toStringAsFixed(0)} m from the leak. Move '
                'closer and retake it.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _addMaterial() async {
    final result = await showDialog<MaterialEntry>(
      context: context,
      builder: (context) => _AddMaterialDialog(),
    );

    if (result != null) {
      setState(() => _materials.add(result));
    }
  }

  Future<void> _submitRepair() async {
    if (!_formKey.currentState!.validate()) return;

    if (_evidence.any((e) => e.isUploading)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for uploads to complete')),
      );
      return;
    }

    final hasBefore = _evidence.any(
      (entry) =>
          entry.kind == 'BEFORE_PHOTO' &&
          entry.evidenceId != null &&
          (entry.geoValid == true || _allowSimulatedLocationOverride),
    );
    final hasAfter = _evidence.any(
      (entry) =>
          entry.kind == 'AFTER_PHOTO' &&
          entry.evidenceId != null &&
          (entry.geoValid == true || _allowSimulatedLocationOverride),
    );
    if (!hasBefore || !hasAfter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _allowSimulatedLocationOverride
                ? 'Upload both a before-repair and an after-repair photo.'
                : 'Upload valid before and after photos at the incident location. '
                      'For a simulated twin job, use the bypass button if needed.',
          ),
        ),
      );
      return;
    }

    final uploadedEvidence = _evidence
        .where(
          (e) =>
              e.evidenceId != null &&
              (e.geoValid == true || _allowSimulatedLocationOverride),
        )
        .map((e) => e.evidenceId!)
        .toList();

    setState(() => _isSubmitting = true);

    try {
      final isSimulatedTwin =
          ref
              .read(workOrderDetailProvider(widget.workOrderId))
              .valueOrNull
              ?.leakEvent
              .source
              .toUpperCase() ==
          'TWIN';
      final notifier = ref.read(workOrderNotifierProvider.notifier);
      await notifier.submitRepair(
        widget.workOrderId,
        repairType: _repairType,
        materials: _materials
            .map((m) => models.Material(item: m.item, qty: m.qty))
            .toList(),
        labourMinutes: _labourMinutes,
        workNotes: _workNotesController.text.trim().isEmpty
            ? null
            : _workNotesController.text.trim(),
        evidenceIds: uploadedEvidence.isEmpty ? null : uploadedEvidence,
        allowSimulatedLocationOverride:
            isSimulatedTwin && _allowSimulatedLocationOverride,
      );
      final result = ref.read(workOrderNotifierProvider);
      if (result.hasError) throw result.error!;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair submitted. Waiting for operator review.'),
          ),
        );
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final apiError = extractApiException(e);
        final message = apiError.statusCode != 0
            ? '${apiError.statusCode}: ${apiError.displayMessage}'
            : e.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit: $message')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class EvidenceEntry {
  final EvidenceCapture capture;
  final String kind;
  bool isUploading;
  double progress;
  String? evidenceId;
  bool? geoValid;
  double? distanceToLeakM;

  EvidenceEntry({
    required this.capture,
    required this.kind,
    required this.isUploading,
    required this.progress,
  });
}

class MaterialEntry {
  final String item;
  final double qty;

  MaterialEntry({required this.item, required this.qty});
}

class _AddMaterialDialog extends StatefulWidget {
  @override
  State<_AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<_AddMaterialDialog> {
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Material'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _itemController,
            decoration: const InputDecoration(
              labelText: 'Item',
              hintText: 'e.g., Pipe clamp 100mm',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final item = _itemController.text.trim();
            final qty = double.tryParse(_qtyController.text);

            if (item.isEmpty || qty == null || qty <= 0) {
              return;
            }

            Navigator.of(context).pop(MaterialEntry(item: item, qty: qty));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
