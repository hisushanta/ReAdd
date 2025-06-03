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
      title: 'Advanced Image Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
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
  Uint8List? _originalImageBytes;

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
        _originalImageBytes = bytes;
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

  Future<void> _changeBaseImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final bytes = await pickedFile.readAsBytes();
        await _loadImage(bytes);
        _originalImageBytes = bytes;
        _startPoint = null;
        _endPoint = null;
        _isTyping = false;
        _newText = '';
        _previewMode = false;
        _selectedImageBytes = null;
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _imageBytes != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _image = null;
                    _imageBytes = null;
                    _originalImageBytes = null;
                    _startPoint = null;
                    _endPoint = null;
                  });
                },
              )
            : null,
        title: const Text('Advanced Image Editor'),
        actions: [
          if (_imageBytes != null && !_previewMode)
            _buildAppBarAction(
              icon: Icons.visibility,
              tooltip: 'Preview',
              onPressed: _togglePreviewMode,
              color: Colors.blueAccent,
            ),
          if (_previewMode)
            _buildAppBarAction(
              icon: Icons.edit,
              tooltip: 'Edit',
              onPressed: _togglePreviewMode,
              color: Colors.orange,
            ),
          if (_previewMode)
            _buildAppBarAction(
              icon: Icons.download,
              tooltip: 'Download',
              onPressed: _saveImage,
              color: Colors.green,
            ),
          if (_imageBytes != null)
            _buildAppBarAction(
              icon: Icons.restart_alt,
              tooltip: 'Reset',
              onPressed: _resetImage,
              color: Colors.red,
            ),
          if (_imageBytes != null)
            _buildAppBarAction(
              icon: Icons.image,
              tooltip: 'Change Image',
              onPressed: _changeBaseImage,
              color: Colors.purple,
            ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? _buildLoadingIndicator()
            : _imageBytes == null
                ? _buildEmptyState()
                : _image == null
                    ? _buildLoadingIndicator()
                    : _buildEditorCanvas(),
      ),
      floatingActionButton: _imageBytes == null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _pickImage,
              tooltip: 'Pick Image',
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                'Add Photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.blueAccent,
              elevation: 2,
            )
          : null,
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
        const SizedBox(height: 16),
        Text(
          'Processing...',
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.photo_library,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 20),
        Text(
          'No Image Selected',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap the + button to add an image',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEditorCanvas() {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
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
        ),
        if (!_previewMode && _startPoint != null && _endPoint != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showContentSelectionDialog,
              child: const Icon(Icons.add),
              backgroundColor: Colors.blueAccent,
              elevation: 2,
            ),
          ),
      ],
    );
  }

  void _showContentSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Content',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContentOption(
                    icon: Icons.text_fields,
                    label: 'Text',
                    onTap: () {
                      Navigator.pop(context);
                      _startTextInput();
                    },
                  ),
                  _buildContentOption(
                    icon: Icons.image,
                    label: 'Image',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageForRectangle();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
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
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Text',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type your text here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildFontSelection(setState),
                  const SizedBox(height: 16),
                  _buildTextStyleOptions(setState),
                  const SizedBox(height: 16),
                  _buildColorSelection(setState),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isTyping = false;
                          });
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _newText = _textController.text;
                            _isTyping = false;
                            _textController.clear();
                          });
                          Navigator.pop(context);
                          _applyContent();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Family',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFont,
          items: _availableFonts.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(
                font,
                style: GoogleFonts.poppins(),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFont = value!;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          dropdownColor: Colors.white,
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }

  Widget _buildTextStyleOptions(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Style',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(
                'Bold',
                style: GoogleFonts.poppins(),
              ),
              selected: _isBold,
              onSelected: (selected) {
                setState(() {
                  _isBold = selected;
                });
              },
              selectedColor: Colors.blueAccent.withOpacity(0.2),
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: _isBold ? Colors.blueAccent : Colors.black54,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Color',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildColorOption(
              color: Colors.black,
              isSelected: _selectedColor == Colors.black,
              onTap: () => setState(() => _selectedColor = Colors.black),
            ),
            _buildColorOption(
              color: Colors.red,
              isSelected: _selectedColor == Colors.red,
              onTap: () => setState(() => _selectedColor = Colors.red),
            ),
            _buildColorOption(
              color: Colors.blue,
              isSelected: _selectedColor == Colors.blue,
              onTap: () => setState(() => _selectedColor = Colors.blue),
            ),
            _buildColorOption(
              color: Colors.green,
              isSelected: _selectedColor == Colors.green,
              onTap: () => setState(() => _selectedColor = Colors.green),
            ),
            _buildColorOption(
              color: Colors.purple,
              isSelected: _selectedColor == Colors.purple,
              onTap: () => setState(() => _selectedColor = Colors.purple),
            ),
            _buildColorOption(
              color: const ui.Color.fromARGB(255, 111, 111, 111),
              isSelected: _selectedColor == const ui.Color.fromARGB(255, 111, 111, 111),
              onTap: () => setState(() => _selectedColor = const ui.Color.fromARGB(255, 111, 111, 111)),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildColorOption({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : null,
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
      final x1 = _startPoint!.dx;
      final y1 = _startPoint!.dy;
      final x2 = _endPoint!.dx;
      final y2 = _endPoint!.dy;
      
      final x = x1 < x2 ? x1 : x2;
      final y = y1 < y2 ? y1 : y2;
      final width = (x2 - x1).abs();
      final height = (y2 - y1).abs();
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder, 
        Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()),
      );
      
      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImage(_image!, Offset.zero, paint);
      
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        Paint()..color = Colors.white,
      );
      
      if (_isImageMode) {
        final codec = await ui.instantiateImageCodec(
          _selectedImageBytes!,
          targetWidth: width.toInt(),
          targetHeight: height.toInt(),
        );
        final frame = await codec.getNextFrame();
        final selectedImage = frame.image;
        
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
      
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(
        _image!.width,
        _image!.height,
      );
      final byteData = await newImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final newImageBytes = byteData!.buffer.asUint8List();
      
      setState(() {
        _imageBytes = newImageBytes;
        _startPoint = null;
        _endPoint = null;
        _newText = '';
        _selectedImageBytes = null;
      });
      
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

  Future<void> _resetImage() async {
    if (_originalImageBytes == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadImage(_originalImageBytes!);
      setState(() {
        _startPoint = null;
        _endPoint = null;
        _isTyping = false;
        _newText = '';
        _previewMode = false;
        _selectedImageBytes = null;
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