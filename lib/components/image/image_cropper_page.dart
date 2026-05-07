import 'package:nchat_mobile/common/settings.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/base/stateful.dart';
import 'package:nchat_mobile/utils/logger.dart';

const String TAG = "ImageCropperPage";

class ImageCropperPage extends BaseStateFulWidget {
  final File imageFile;
  final String? savePath;
  final bool isRectangle;
  final int quality;

  ImageCropperPage({
    required this.imageFile,
    this.savePath,
    this.isRectangle = false,
    this.quality = 80,
  });

  @override
  _ImageCropperPageState createState() => _ImageCropperPageState();
}

class _ImageCropperPageState extends BaseStateFulWidgetState<ImageCropperPage> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Size _imageSize = Size.zero;
  Size _containerSize = Size.zero;
  bool _isLoading = true;
  bool _isProcessing = false;
  ui.Image? _loadedImage;

  static const double _maxScale = 8.0;

  @override
  void onRefreshArguments() {}

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  double _getMinScale() {
    if (_imageSize.isEmpty || _containerSize.isEmpty) return 1.0;
    final cropSize = _getCropSize();
    if (cropSize.isEmpty) return 1.0;

    // Base image display: fit inside container
    final baseScale =
        (_containerSize.width / _imageSize.width).clamp(0.0, double.infinity);
    final baseScaleH =
        (_containerSize.height / _imageSize.height).clamp(0.0, double.infinity);
    final fitInside = baseScale < baseScaleH ? baseScale : baseScaleH;

    // Ensure displayed image covers crop area
    final neededW = cropSize.width / (_imageSize.width * fitInside);
    final neededH = cropSize.height / (_imageSize.height * fitInside);
    final needed = neededW > neededH ? neededW : neededH;

    final minScale = needed.isFinite ? needed : 1.0;
    return minScale < 0.01 ? 0.01 : minScale;
  }

  void _clampOffset() {
    if (_imageSize.isEmpty || _containerSize.isEmpty) return;
    final cropSize = _getCropSize();
    if (cropSize.isEmpty) return;

    final baseScaleW = _containerSize.width / _imageSize.width;
    final baseScaleH = _containerSize.height / _imageSize.height;
    final fitInside = baseScaleW < baseScaleH ? baseScaleW : baseScaleH;

    final displayedW = _imageSize.width * fitInside * _scale;
    final displayedH = _imageSize.height * fitInside * _scale;

    // How much the image can be moved while still covering crop area
    final maxDx = (displayedW - cropSize.width) / 2;
    final maxDy = (displayedH - cropSize.height) / 2;

    final clampedDx = _offset.dx.clamp(-maxDx, maxDx).toDouble();
    final clampedDy = _offset.dy.clamp(-maxDy, maxDy).toDouble();
    _offset = Offset(clampedDx, clampedDy);
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _loadedImage = frame.image;
        _imageSize = Size(
            _loadedImage!.width.toDouble(), _loadedImage!.height.toDouble());
        _isLoading = false;
      });
    } catch (e) {
      logger.e("$TAG - Error loading image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle scaling
      final minScale = _getMinScale();
      _scale = (_scale * details.scale).clamp(minScale, _maxScale);
      // Handle panning (translation)
      _offset += details.focalPointDelta;
      _clampOffset();
    });
  }

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cropSize = _getCropSize();
      final cropOffset = _getCropOffset();

      final pixelCropSize = Size(
        cropSize.width / _scale,
        cropSize.height / _scale,
      );

      final centerOffset = Offset(
        _imageSize.width / 2 - cropOffset.dx - _offset.dx / _scale,
        _imageSize.height / 2 - cropOffset.dy - _offset.dy / _scale,
      );

      final sourceRect = Rect.fromCenter(
        center: centerOffset,
        width: pixelCropSize.width,
        height: pixelCropSize.height,
      );

      final clampedSourceRect = Rect.fromLTWH(
        sourceRect.left.clamp(0.0, _imageSize.width).toDouble(),
        sourceRect.top.clamp(0.0, _imageSize.height).toDouble(),
        sourceRect.width
            .clamp(0.0, _imageSize.width - sourceRect.left)
            .toDouble(),
        sourceRect.height
            .clamp(0.0, _imageSize.height - sourceRect.top)
            .toDouble(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        _loadedImage!,
        clampedSourceRect,
        Rect.fromLTWH(0, 0, cropSize.width, cropSize.height),
        Paint(),
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        cropSize.width.toInt(),
        cropSize.height.toInt(),
      );

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();

        String savePath = widget.savePath ?? widget.imageFile.path;
        File croppedFile = File(savePath);
        await croppedFile.create(recursive: true);
        await croppedFile.writeAsBytes(pngBytes, flush: true);

        if (mounted) {
          Navigator.of(context).pop(croppedFile);
        }
      }
    } catch (e) {
      logger.e("$TAG - Error cropping image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Size _getCropSize() {
    if (_containerSize.isEmpty) return Size.zero;
    // Make crop area fit screen width with some padding
    double cropWidth = _containerSize.width * 0.9;
    double cropHeight = widget.isRectangle
        ? cropWidth * 0.75 // 4:3 ratio for rectangle
        : cropWidth; // Square for circle crop
    return Size(cropWidth, cropHeight);
  }

  Offset _getCropOffset() {
    return Offset(
      (_containerSize.width - _getCropSize().width) / 2,
      (_containerSize.height - _getCropSize().height) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _cropAndSave,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    Settings.locale((s) => s.save, ctx: context),
                    style: TextStyle(
                      color: application.theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  application.theme.primaryColor,
                ),
              ),
            )
          : Stack(
              children: [
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _containerSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        onScaleUpdate: _onScaleUpdate,
                        child: Container(
                          width: _containerSize.width,
                          height: _containerSize.height,
                          child: CustomPaint(
                            painter: _ImageCropperPainter(
                              loadedImage: _loadedImage,
                              imageSize: _imageSize,
                              scale: _scale,
                              offset: _offset,
                              containerSize: _containerSize,
                              cropSize: _getCropSize(),
                            ),
                            size: _containerSize,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: CustomPaint(
                    size: _getCropSize(),
                    painter: _CropOverlayPainter(
                      cropSize: _getCropSize(),
                      isRectangle: widget.isRectangle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InstructionChip(
                        icon: Icons.pan_tool,
                        label: 'Drag to move',
                      ),
                      const SizedBox(width: 16),
                      _InstructionChip(
                        icon: Icons.zoom_in,
                        label: 'Pinch to zoom',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InstructionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InstructionChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ImageCropperPainter extends CustomPainter {
  final ui.Image? loadedImage;
  final Size imageSize;
  final double scale;
  final Offset offset;
  final Size containerSize;
  final Size cropSize;

  _ImageCropperPainter({
    this.loadedImage,
    required this.imageSize,
    required this.scale,
    required this.offset,
    required this.containerSize,
    required this.cropSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (loadedImage == null) return;

    final imageWidth = imageSize.width * scale;
    final imageHeight = imageSize.height * scale;

    // Center the image initially, then apply pan offset
    final imageOffset = Offset(
      (containerSize.width - imageWidth) / 2 + offset.dx,
      (containerSize.height - imageHeight) / 2 + offset.dy,
    );

    // Draw the image
    canvas.drawImage(loadedImage!, imageOffset, Paint());

    // Calculate crop area center
    final cropCenter = Offset(
      containerSize.width / 2,
      containerSize.height / 2,
    );

    // Draw dark overlay outside crop area
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Create path for the entire screen minus the crop area
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, containerSize.width, containerSize.height));

    final cropRect = Rect.fromCenter(
      center: cropCenter,
      width: cropSize.width,
      height: cropSize.height,
    );

    // Use path difference to create overlay
    if (cropSize.width > 0 && cropSize.height > 0) {
      final overlayPath = Path.combine(
        PathOperation.difference,
        fullScreenPath,
        Path()..addRect(cropRect),
      );
      canvas.drawPath(overlayPath, overlayPaint);

      // Draw crop border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(cropRect, borderPaint);

      // Draw corner handles
      final handleSize = 20.0;
      final handlePaint = Paint()
        ..color = application.theme.primaryColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      // Top-left corner
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + handleSize),
        Offset(cropRect.left, cropRect.top),
        handlePaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top),
        Offset(cropRect.left + handleSize, cropRect.top),
        handlePaint,
      );

      // Top-right corner
      canvas.drawLine(
        Offset(cropRect.right - handleSize, cropRect.top),
        Offset(cropRect.right, cropRect.top),
        handlePaint,
      );
      canvas.drawLine(
        Offset(cropRect.right, cropRect.top),
        Offset(cropRect.right, cropRect.top + handleSize),
        handlePaint,
      );

      // Bottom-left corner
      canvas.drawLine(
        Offset(cropRect.left, cropRect.bottom - handleSize),
        Offset(cropRect.left, cropRect.bottom),
        handlePaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.bottom),
        Offset(cropRect.left + handleSize, cropRect.bottom),
        handlePaint,
      );

      // Bottom-right corner
      canvas.drawLine(
        Offset(cropRect.right - handleSize, cropRect.bottom),
        Offset(cropRect.right, cropRect.bottom),
        handlePaint,
      );
      canvas.drawLine(
        Offset(cropRect.right, cropRect.bottom),
        Offset(cropRect.right, cropRect.bottom - handleSize),
        handlePaint,
      );

      // Draw rule of thirds grid
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Vertical lines
      canvas.drawLine(
        Offset(cropRect.left + cropRect.width / 3, cropRect.top),
        Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left + 2 * cropRect.width / 3, cropRect.top),
        Offset(cropRect.left + 2 * cropRect.width / 3, cropRect.bottom),
        gridPaint,
      );

      // Horizontal lines
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + cropRect.height / 3),
        Offset(cropRect.right, cropRect.top + cropRect.height / 3),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + 2 * cropRect.height / 3),
        Offset(cropRect.right, cropRect.top + 2 * cropRect.height / 3),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ImageCropperPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.loadedImage != loadedImage ||
        oldDelegate.containerSize != containerSize ||
        oldDelegate.cropSize != cropSize;
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Size cropSize;
  final bool isRectangle;

  _CropOverlayPainter({
    required this.cropSize,
    required this.isRectangle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isRectangle) {
      final gridPaint = Paint()
        ..color = Colors.white.withAlpha(153)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(cropSize.width / 3, 0),
        Offset(cropSize.width / 3, cropSize.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(2 * cropSize.width / 3, 0),
        Offset(2 * cropSize.width / 3, cropSize.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, cropSize.height / 3),
        Offset(cropSize.width, cropSize.height / 3),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, 2 * cropSize.height / 3),
        Offset(cropSize.width, 2 * cropSize.height / 3),
        gridPaint,
      );

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, cropSize.width, cropSize.height),
        borderPaint,
      );
    } else {
      final center = Offset(cropSize.width / 2, cropSize.height / 2);
      final radius = cropSize.width / 2;

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return oldDelegate.cropSize != cropSize ||
        oldDelegate.isRectangle != isRectangle;
  }
}
