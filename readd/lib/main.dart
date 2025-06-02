import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Text Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageEditorScreen(),
    );
  }
}

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  _ImageEditorScreenState createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  ui.Image? _image;
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isTyping = false;
  String _newText = '';
  bool _previewMode = false;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  final TextEditingController _textController = TextEditingController();
  String _selectedFont = 'PT Sans';
  Color _selectedColor = Colors.black;
  bool _isBold = false;
  Uint8List? _selectedImageBytes;
  bool _isImageMode = false;

  // List of available Google Fonts
  final List<String> _availableFonts = [
    'PT Sans',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Oswald',
    'Raleway',
    'Poppins',
    'Nunito',
    'Ubuntu'
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await _loadImage(bytes);
      }
    } finally {
      setState(() {
        _isLoading = false;
        _startPoint = null;
        _endPoint = null;
        _isTyping = false;
        _newText = '';
        _previewMode = false;
      });
    }
  }

  Future<void> _loadImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    setState(() {
      _image = frame.image;
      _imageBytes = bytes;
    });
  }

  void _startSelection(Offset position) {
    if (_previewMode || _image == null) return;
    
    setState(() {
      _startPoint = position;
      _endPoint = position;
      _isTyping = false;
    });
  }

  void _updateSelection(Offset position) {
    if (_previewMode || _startPoint == null || _image == null) return;
    
    setState(() {
      _endPoint = position;
    });
  }

  void _endSelection(Offset position) {
    if (_previewMode || _startPoint == null || _image == null) return;
    
    setState(() {
      _endPoint = position;
    });
  }

  void _showContentSelectionDialog() {
    if (_startPoint == null || _endPoint == null || _previewMode || _image == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Content Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Add Text'),
              onTap: () {
                Navigator.pop(context);
                _startTextInput();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Add Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForRectangle();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startTextInput() {
    setState(() {
      _isTyping = true;
      _isImageMode = false;
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Enter Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Type your text here'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedFont,
                    items: _availableFonts.map((font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(font),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFont = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Font'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Text Style: '),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Bold'),
                        selected: _isBold,
                        onSelected: (selected) {
                          setState(() {
                            _isBold = selected;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Text Color: '),
                      const SizedBox(width: 10),
                      ...['Black', 'Red', 'Blue', 'Green'].map((colorName) {
                        Color color;
                        switch (colorName) {
                          case 'Red':
                            color = Colors.red;
                            break;
                          case 'Blue':
                            color = Colors.blue;
                            break;
                          case 'Green':
                            color = Colors.green;
                            break;
                          default:
                            color = Colors.black;
                        }
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(
                                color: _selectedColor == color 
                                    ? Colors.white 
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isTyping = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _newText = _textController.text;
                    _isTyping = false;
                    _textController.clear();
                  });
                  Navigator.pop(context);
                  _applyContent();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImageForRectangle() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _isImageMode = true;
      });
      _applyContent();
    }
  }

  TextStyle _getSelectedFontStyle(double fontSize) {
    TextStyle style;
    switch (_selectedFont) {
      case 'Roboto':
        style = GoogleFonts.roboto(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Open Sans':
        style = GoogleFonts.openSans(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Lato':
        style = GoogleFonts.lato(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Montserrat':
        style = GoogleFonts.montserrat(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Oswald':
        style = GoogleFonts.oswald(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Raleway':
        style = GoogleFonts.raleway(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Poppins':
        style = GoogleFonts.poppins(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Nunito':
        style = GoogleFonts.nunito(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      case 'Ubuntu':
        style = GoogleFonts.ubuntu(
          fontSize: fontSize,
          color: _selectedColor,
        );
        break;
      default: // 'PT Sans'
        style = GoogleFonts.ptSans(
          fontSize: fontSize,
          color: _selectedColor,
        );
    }

    if (_isBold) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }

    return style;
  }

Future<void> _applyContent() async {
  if (_startPoint == null || _endPoint == null || _image == null) return;
  if (!_isImageMode && _newText.isEmpty) return;
  if (_isImageMode && _selectedImageBytes == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    // Calculate rectangle coordinates
    final x1 = _startPoint!.dx;
    final y1 = _startPoint!.dy;
    final x2 = _endPoint!.dx;
    final y2 = _endPoint!.dy;
    
    final x = x1 < x2 ? x1 : x2;
    final y = y1 < y2 ? y1 : y2;
    final width = (x2 - x1).abs();
    final height = (y2 - y1).abs();
    
    // Create a canvas to draw on with higher quality settings
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder, 
      Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()),
    );
    
    // Draw original image with high quality
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImage(_image!, Offset.zero, paint);
    
    // Draw white rectangle
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()..color = Colors.white,
    );
    
    if (_isImageMode) {
      // Load the selected image with original quality
      final codec = await ui.instantiateImageCodec(
        _selectedImageBytes!,
        targetWidth: width.toInt(),
        targetHeight: height.toInt(),
      );
      final frame = await codec.getNextFrame();
      final selectedImage = frame.image;
      
      // Calculate aspect ratio and scaling while maintaining quality
      final imageRatio = selectedImage.width / selectedImage.height;
      final rectRatio = width / height;
      
      double drawWidth, drawHeight;
      if (imageRatio > rectRatio) {
        drawWidth = width;
        drawHeight = width / imageRatio;
      } else {
        drawHeight = height;
        drawWidth = height * imageRatio;
      }
      
      // Center the image in the rectangle with high quality
      final offsetX = x + (width - drawWidth) / 2;
      final offsetY = y + (height - drawHeight) / 2;
      
      canvas.drawImageRect(
        selectedImage,
        Rect.fromLTWH(0, 0, 
          selectedImage.width.toDouble(), 
          selectedImage.height.toDouble()
        ),
        Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      // Text handling remains the same
      final fontSize = _calculateOptimalFontSize(width, height, _newText);
      final textSpan = TextSpan(
        text: _newText,
        style: _getSelectedFontStyle(fontSize),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final textX = x + (width - textPainter.width) / 2;
      final textY = y + (height - textPainter.height) / 2;
      
      textPainter.paint(canvas, Offset(textX, textY));
    }
    
    // Convert to image with high quality
    final picture = recorder.endRecording();
    final newImage = await picture.toImage(
      _image!.width,
      _image!.height,
    );
    final byteData = await newImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final newImageBytes = byteData!.buffer.asUint8List();
    
    // Update state
    setState(() {
      _imageBytes = newImageBytes;
      _startPoint = null;
      _endPoint = null;
      _newText = '';
      _selectedImageBytes = null;
    });
    
    // Reload the new image
    await _loadImage(newImageBytes);
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  double _calculateOptimalFontSize(double width, double height, String text) {
    double fontSize = 50.0;
    final textSpan = TextSpan(
      text: text,
      style: _getSelectedFontStyle(fontSize),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    while ((textPainter.width > width || textPainter.height > height) && fontSize > 5) {
      fontSize -= 1;
      final newSpan = TextSpan(
        text: text,
        style: _getSelectedFontStyle(fontSize),
      );
      textPainter.text = newSpan;
      textPainter.layout();
    }
    
    return fontSize;
  }

  Future<void> _saveImage() async {
    if (_imageBytes == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // For web, we'll download the image
      final blob = html.Blob([_imageBytes!]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'edited_image.png')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image downloaded')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetImage() {
    if (_imageBytes == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      _loadImage(_imageBytes!).then((_) {
        setState(() {
          _startPoint = null;
          _endPoint = null;
          _isTyping = false;
          _newText = '';
          _previewMode = false;
          _selectedImageBytes = null;
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePreviewMode() {
    setState(() {
      _previewMode = !_previewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const ui.Color.fromARGB(255, 240, 237, 237),
        title: const Text('Image Editor'),
        actions: [
          if (_imageBytes != null && !_previewMode)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _togglePreviewMode,
              tooltip: 'Preview and Save',
            ),
          if (_previewMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _togglePreviewMode,
              tooltip: 'Back to Editing',
            ),
          if (_previewMode)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _saveImage,
              tooltip: 'Save Image',
            ),
          if (_imageBytes != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetImage,
              tooltip: 'Reset Image',
            ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _imageBytes == null
                ? const Text('No image selected')
                : _image == null
                    ? const CircularProgressIndicator()
                    : Stack(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: GestureDetector(
                                onPanStart: (details) => _startSelection(details.localPosition),
                                onPanUpdate: (details) => _updateSelection(details.localPosition),
                                onPanEnd: (details) => _endSelection(details.localPosition),
                                child: CustomPaint(
                                  size: Size(
                                    _image!.width.toDouble(),
                                    _image!.height.toDouble(),
                                  ),
                                  painter: ImageEditorPainter(
                                    image: _image,
                                    startPoint: _startPoint,
                                    endPoint: _endPoint,
                                    previewMode: _previewMode,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!_previewMode && _startPoint != null && _endPoint != null)
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: FloatingActionButton(
                                onPressed: _showContentSelectionDialog,
                                child: const Icon(Icons.add),
                              ),
                            ),
                        ],
                      ),
      ),
      floatingActionButton: _imageBytes == null && !_isLoading
          ? FloatingActionButton(
              onPressed: _pickImage,
              tooltip: 'Pick Image',
              child: const Icon(Icons.add_photo_alternate),
            )
          : null,
    );
  }
}

class ImageEditorPainter extends CustomPainter {
  final ui.Image? image;
  final Offset? startPoint;
  final Offset? endPoint;
  final bool previewMode;

  ImageEditorPainter({
    required this.image,
    required this.startPoint,
    required this.endPoint,
    required this.previewMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      canvas.drawImage(image!, Offset.zero, Paint());
    }

    if (!previewMode && startPoint != null && endPoint != null) {
      final rect = Rect.fromPoints(startPoint!, endPoint!);
      final paint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(rect, paint);
      
      final borderPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}