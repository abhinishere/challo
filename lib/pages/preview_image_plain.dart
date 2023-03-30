import 'package:flutter/material.dart';

class PreviewImagePlain extends StatefulWidget {
  final String imageUrl;

  const PreviewImagePlain({
    required this.imageUrl,
  });

  @override
  State<PreviewImagePlain> createState() => _PreviewImagePlainState();
}

class _PreviewImagePlainState extends State<PreviewImagePlain> {
  bool dataisthere = false;

  Widget arrowbackWidget() {
    return ButtonTheme(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0, horizontal: 8.0), //adds padding inside the button
      materialTapTargetSize: MaterialTapTargetSize
          .shrinkWrap, //limits the touch area to the button area
      minWidth: 0, //wraps child's width
      height: 0, //wraps child's height

      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(
          Icons.arrow_back,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }

  final _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      // For a 3x zoom
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
      // Fox a 2x zoom
      // ..translate(-position.dx, -position.dy)
      // ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onDoubleTapDown: _handleDoubleTapDown,
                  onDoubleTap: _handleDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(0),
                    minScale: 0.5,
                    maxScale: 2,
                    child: Image.network(widget.imageUrl),
                  ),
                ),
              ),

              /* Positioned.fill(
                      child: InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(100),
                          minScale: 0.5,
                          maxScale: 2,
                          child: Image.network(imgUrl)),
                    ),*/

              Positioned(
                left: 0.0,
                top: 0.0,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: arrowbackWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
