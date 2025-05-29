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

  void _startTextInput() {
    if (_startPoint == null || _endPoint == null || _previewMode || _image == null) return;
    
    setState(() {
      _isTyping = true;
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
                      }).toList(),
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
                  _applyText();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
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

  Future<void> _applyText() async {
    if (_startPoint == null || _endPoint == null || _newText.isEmpty || _image == null) return;

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
      
      // Create a canvas to draw on
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()));
      
      // Draw original image
      canvas.drawImage(_image!, Offset.zero, Paint());
      
      // Draw white rectangle
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        Paint()..color = Colors.white,
      );
      
      // Prepare text with selected font and style
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
      
      // Calculate centered position
      final textX = x + (width - textPainter.width) / 2;
      final textY = y + (height - textPainter.height) / 2;
      
      // Draw text
      textPainter.paint(canvas, Offset(textX, textY));
      
      // Convert to image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(_image!.width, _image!.height);
      final byteData = await newImage.toByteData(format: ui.ImageByteFormat.png);
      final newImageBytes = byteData!.buffer.asUint8List();
      
      // Update state
      setState(() {
        _imageBytes = newImageBytes;
        _startPoint = null;
        _endPoint = null;
        _newText = '';
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
      appBar: AppBar(
        title: const Text('Image Text Editor'),
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
                                onPressed: _startTextInput,
                                child: const Icon(Icons.text_fields),
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