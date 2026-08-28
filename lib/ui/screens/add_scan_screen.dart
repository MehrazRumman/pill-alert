import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import 'add_flow_common.dart';
import 'pack_parser.dart';

/// Scan & confirm (3b). Captures the pack with the camera and extracts its printed name and
/// strength on-device. The patient can fall back to a gallery photo, or to typing, whenever the
/// pack text cannot be read reliably.
class AddScanScreen extends StatefulWidget {
  const AddScanScreen({super.key});

  @override
  State<AddScanScreen> createState() => _AddScanScreenState();
}

class _AddScanScreenState extends State<AddScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _hasPermission = false;
  bool _permissionDenied = false;
  bool _scanning = false;
  String? _scanError;

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestAndStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    // The camera must be released while backgrounded or another app cannot open it.
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _requestAndStart();
    }
  }

  Future<void> _requestAndStart() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _permissionDenied = status.isDenied || status.isPermanentlyDenied;
    });
    if (status.isGranted) await _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        // The pack's small print needs resolution; ML Kit reads a high-res still far better.
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(() => _scanError =
            context.tr('ক্যামেরাটি চালু করা যাচ্ছে না', 'Camera is unavailable'));
      }
    }
  }

  /// Runs autofocus on the middle of the frame and waits for the lens to settle before firing the
  /// shutter — capturing the instant the button is pressed is what hands the recogniser blurry
  /// frames. Some sensors never report a focus result, so the wait is capped.
  Future<void> _focusThenCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      try {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
        await controller.setExposurePoint(const Offset(0.5, 0.5));
        await controller.setFocusMode(FocusMode.auto);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      } catch (_) {
        // Fixed-focus lenses reject these; the capture below is still worth taking.
      }
      final shot = await controller.takePicture();
      await _recognize(shot.path);
    } catch (_) {
      if (!mounted) return;
      _failScan(
        context.tr(
          'ছবি পড়া যায়নি — আবার চেষ্টা করুন',
          "Couldn't read that photo — please try again",
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      await _recognize(picked.path);
    } catch (_) {
      if (!mounted) return;
      _failScan(context.tr('ছবি পড়া যায়নি', "Couldn't read that photo"));
    }
  }

  Future<void> _recognize(String path) async {
    final result = await _recognizer.processImage(InputImage.fromFilePath(path));
    if (!mounted) return;
    // Pass the block/line tree through, not the flattened string: the line boxes are what tell the
    // parser which words are printed largest, and that is how the name is identified.
    _handleRecognized(packLinesFrom(result));
  }

  void _failScan(String message) {
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _scanError = message;
    });
  }

  void _handleRecognized(List<PackLine> lines) {
    final parsed = parsePackLines(lines);
    if (parsed == null) {
      _failScan(
        context.tr(
          'নাম পড়া যায়নি — আবার চেষ্টা করুন বা নাম লিখুন',
          "Couldn't read a medicine name — try again or type it",
        ),
      );
      return;
    }

    // The parser reports canonical English forms; the draft stores what the patient will read, so
    // scanned medicines don't end up labelled "tablet" while typed ones say "ট্যাবলেট".
    final formWords = {
      'tablet': context.tr('ট্যাবলেট', 'tablet'),
      'capsule': context.tr('ক্যাপসুল', 'capsule'),
      'syrup': context.tr('সিরাপ', 'syrup'),
      'injection': context.tr('ইনজেকশন', 'injection'),
    };

    final (mark, color) = markForName(parsed.name);
    final draft = context.draft;
    draft.update(() {
      draft.displayName = parsed.name;
      draft.packName = parsed.name;
      draft.strength = parsed.strength;
      draft.form = formWords[parsed.form] ?? parsed.form;
      draft.mark = mark;
      draft.markColor = color;
    });
    setState(() => _scanning = false);
    context.nav.addTiming();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: colors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasPermission && ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: GestureDetector(
                  // Tap-to-focus, as on the original: the patient aims at the printed name.
                  onTapUp: (details) {
                    final size = context.size;
                    if (size == null) return;
                    controller.setFocusPoint(Offset(
                      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
                      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
                    ));
                  },
                  child: CameraPreview(controller),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Semantics(
                          button: true,
                          label: context.tr('পিছনে যান', 'Back'),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: context.nav.back,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0x55000000),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_back, color: colors.paper),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _hasPermission
                            ? context.tr(
                                'পাতা বা বাক্সটি সোজা করে ফ্রেমে ধরুন · লেখায় ট্যাপ করে ফোকাস করুন',
                                'Hold the pack flat inside the frame · tap the text to focus',
                              )
                            : context.tr(
                                'ক্যামেরা চালু করতে অনুমতি দিন',
                                'Allow camera access to scan',
                              ),
                        style: context.type.body
                            .copyWith(color: colors.paper.withValues(alpha: 0.9)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        context.tr(
                          'নামটি যেন ফ্রেমের ভেতরে আর সবচেয়ে বড় লেখা হয়',
                          'Keep the name inside the frame and the largest text in view',
                        ),
                        style: context.type.meta
                            .copyWith(color: colors.paper.withValues(alpha: 0.75)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        height: compact ? 130 : 190,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.paper.withValues(alpha: 0.85),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const Spacer(),

                    if (_scanning || _scanError != null)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: Text(
                          _scanning
                              ? context.tr('লেখা পড়া হচ্ছে…', 'Reading the pack…')
                              : _scanError!,
                          style: context.type.meta.copyWith(
                            color: _scanError == null ? colors.paper : colors.warm,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (!_hasPermission) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: PrimaryButton(
                          text: _permissionDenied
                              ? context.tr('সেটিংস খুলুন', 'Open camera settings')
                              : context.tr('অনুমতি দিন', 'Allow camera'),
                          height: 60,
                          onPressed: () async {
                            if (_permissionDenied) {
                              await openAppSettings();
                            } else {
                              await _requestAndStart();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PrimaryButton(
                        text: _scanning
                            ? context.tr('পড়া হচ্ছে…', 'Reading…')
                            : context.tr('এখন স্ক্যান করুন', 'Scan now'),
                        enabled: _hasPermission && ready && !_scanning,
                        onPressed: _focusThenCapture,
                        leading: const Icon(Icons.camera_alt, size: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SecondaryButton(
                        text: context.tr(
                          'গ্যালারি থেকে ছবি নিন',
                          'Choose a photo instead',
                        ),
                        height: 52,
                        enabled: !_scanning,
                        onPressed: _pickFromGallery,
                      ),
                    ),
                    Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: context.nav.addSearch,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard,
                                size: 18,
                                color: colors.paper.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('বরং নাম লিখে দিন', 'Type the name instead'),
                                style: context.type.cardTitleSecondary.copyWith(
                                  color: colors.paper.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 12),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
