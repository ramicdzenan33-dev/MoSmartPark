import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mosmartpark_mobile/model/car.dart';
import 'package:mosmartpark_mobile/model/brand.dart';
import 'package:mosmartpark_mobile/model/color.dart' as model;
import 'package:mosmartpark_mobile/providers/car_provider.dart';
import 'package:mosmartpark_mobile/providers/brand_provider.dart';
import 'package:mosmartpark_mobile/providers/color_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:provider/provider.dart';

class CarsEditScreen extends StatefulWidget {
  final Car? car;

  const CarsEditScreen({super.key, this.car});

  @override
  State<CarsEditScreen> createState() => _CarsEditScreenState();
}

class _CarsEditScreenState extends State<CarsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _yearController = TextEditingController();

  late CarProvider carProvider;
  late BrandProvider brandProvider;
  late ColorProvider colorProvider;

  bool isLoading = true;
  bool isSaving = false;
  bool isLoadingBrands = true;
  bool isLoadingColors = true;

  List<Brand> brands = [];
  List<model.CarColor> colors = [];

  Brand? selectedBrand;
  model.CarColor? selectedColor;
  String? pictureBase64;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      carProvider = context.read<CarProvider>();
      brandProvider = context.read<BrandProvider>();
      colorProvider = context.read<ColorProvider>();

      if (widget.car != null) {
        _modelController.text = widget.car!.model;
        _licensePlateController.text = widget.car!.licensePlate;
        _yearController.text = widget.car!.yearOfManufacture.toString();
        pictureBase64 = widget.car!.picture;
        isActive = widget.car!.isActive;
      }

      await _loadBrands();
      await _loadColors();
      _setInitialSelections();

      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _loadBrands() async {
    try {
      final result = await brandProvider.get();
      setState(() {
        brands = result.items ?? [];
        isLoadingBrands = false;
      });
    } catch (e) {
      setState(() {
        brands = [];
        isLoadingBrands = false;
      });
    }
  }

  Future<void> _loadColors() async {
    try {
      final result = await colorProvider.get();
      setState(() {
        colors = result.items ?? [];
        isLoadingColors = false;
      });
    } catch (e) {
      setState(() {
        colors = [];
        isLoadingColors = false;
      });
    }
  }

  void _setInitialSelections() {
    if (widget.car != null) {
      selectedBrand = brands.firstWhere(
        (b) => b.id == widget.car!.brandId,
        orElse: () => brands.isNotEmpty ? brands.first : Brand(id: 0, name: ''),
      );
      selectedColor = colors.firstWhere(
        (c) => c.id == widget.car!.colorId,
        orElse: () => colors.isNotEmpty ? colors.first : model.CarColor(id: 0, name: '', hexCode: '#000000'),
      );
    } else if (brands.isNotEmpty && colors.isNotEmpty) {
      selectedBrand = brands.first;
      selectedColor = colors.first;
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          pictureBase64 = base64String;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedBrand == null || selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select brand and color'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = UserProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final request = {
        'brandId': selectedBrand!.id,
        'colorId': selectedColor!.id,
        'userId': user.id,
        'model': _modelController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'yearOfManufacture': int.tryParse(_yearController.text.trim()) ?? 2020,
        'isActive': isActive,
        'picture': pictureBase64,
      };

      if (widget.car != null) {
        await carProvider.update(widget.car!.id, request);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        await carProvider.insert(request);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: pictureBase64 != null && pictureBase64!.isNotEmpty
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      base64Decode(pictureBase64!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  // Remove button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          pictureBase64 = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Edit hint
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Color(0xFF8B6F47),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tap to change photo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B6F47),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B6F47).withOpacity(0.1),
                      const Color(0xFF8B6F47).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 50,
                      color: Color(0xFF8B6F47),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap to Add Car Photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B6F47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.car != null ? 'Edit Car' : 'Add Car',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6B5B3D),
                const Color(0xFF8B6F47),
                const Color(0xFFA0826D),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Image Picker
                    Center(
                      child: _buildImagePicker(),
                    ),
                    const SizedBox(height: 32),
                    // Model
                    TextFormField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: 'Model',
                        prefixIcon: const Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter model';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // License Plate
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: InputDecoration(
                        labelText: 'License Plate',
                        prefixIcon: const Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter license plate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Year of Manufacture
                    TextFormField(
                      controller: _yearController,
                      decoration: InputDecoration(
                        labelText: 'Year of Manufacture',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter year';
                        }
                        final year = int.tryParse(value.trim());
                        if (year == null || year < 1900 || year > 2100) {
                          return 'Please enter a valid year (1900-2100)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Brand Dropdown
                    isLoadingBrands
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<Brand>(
                            value: selectedBrand,
                            decoration: InputDecoration(
                              labelText: 'Brand',
                              prefixIcon: const Icon(Icons.branding_watermark),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: brands.map((brand) {
                              return DropdownMenuItem<Brand>(
                                value: brand,
                                child: Text(brand.name),
                              );
                            }).toList(),
                            onChanged: (Brand? value) {
                              setState(() {
                                selectedBrand = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a brand';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),
                    // Color Dropdown
                    isLoadingColors
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<model.CarColor>(
                            value: selectedColor,
                            decoration: InputDecoration(
                              labelText: 'Color',
                              prefixIcon: const Icon(Icons.palette),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: colors.map((color) {
                              return DropdownMenuItem<model.CarColor>(
                                value: color,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _parseColor(color.hexCode),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(color.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (model.CarColor? value) {
                              setState(() {
                                selectedColor = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a color';
                              }
                              return null;
                            },
                          ),
                    // Active/Inactive Switch (only show when editing)
                    if (widget.car != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  color: isActive ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? Colors.green[700] : Colors.red[700],
                                      ),
                                    ),
                                    Text(
                                      isActive
                                          ? 'Car is currently active'
                                          : 'Car is currently inactive',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (value) {
                                setState(() {
                                  isActive = value;
                                });
                              },
                              activeColor: const Color(0xFF8B6F47),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Save Button
                    ElevatedButton(
                      onPressed: isSaving ? null : _saveCar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF8B6F47).withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.car != null ? 'Update Car' : 'Add Car',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

