import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/product_service.dart';
import 'dart:convert';
import '../utils/category_constants.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';

class ProductPostModal extends StatefulWidget {
  final Map<String, dynamic>? initialProduct;

  const ProductPostModal({super.key, this.initialProduct});

  @override
  State<ProductPostModal> createState() => _ProductPostModalState();
}

class _ProductPostModalState extends State<ProductPostModal> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController(); // Add this line
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedCategory; // Add this line

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _locationController.dispose(); // Add this line
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _productNameController.text = widget.initialProduct!['name'] ?? '';
      _descriptionController.text = widget.initialProduct!['description'] ?? '';
      _priceController.text = widget.initialProduct!['price']?.toString() ?? '';
      _selectedCategory = widget.initialProduct!['category'];
      _locationController.text = widget.initialProduct!['location'] ?? '';

      // Handle image if it exists
      if (widget.initialProduct!['image'] != null) {
        if (widget.initialProduct!['isLocalImage'] == true) {
          // Handle base64 image
          // You might want to convert it back to File if needed
        }
      }
    }
  }

  Future<void> _getImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageBase64;
        if (_imageFile != null) {
          final bytes = await _imageFile!.readAsBytes();
          imageBase64 = base64Encode(bytes);
        }

        final product = {
          'name': _productNameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'category': _selectedCategory,
          'location': _locationController.text,
          'image': imageBase64,
          'isLocalImage': imageBase64 != null ? 1 : 0,
          'status': 'Active',
          'views': 0,
          'inCart': 0,
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Save or update product
        if (widget.initialProduct != null) {
          await ProductService.updateProduct(product);
          // Send update notification
          await NotificationService.showNotification(
            title: 'Product Updated',
            body: '${product['name']} has been updated',
            payload: json.encode(product),
          );
          await NotificationService.addNotification(
              'Product "${product['name']}" has been updated successfully');
        } else {
          await ProductService.saveProduct(product);

          // Send new product notifications
          await NotificationService.showNotification(
            title: 'New Product Added! 🎉',
            body:
                'Check out ${product['name']} in ${product['category']} category!',
            payload: json.encode(product),
          );
          await NotificationService.addNotification(
              'New product "${product['name']}" added successfully in ${product['category']} category');

          // Send push notification to other users
          await PushNotificationService.sendProductNotification(
            productName: product['name'].toString(),
            category: product['category'].toString(),
            sellerId: 'current_user_id',
          );

          // Show local notification
          await PushNotificationService.showLocalNotification(
            title: 'Product Posted Successfully! 🎉',
            body: '${product['name']} is now live and visible to buyers',
            data: {
              'type': 'product_posted',
              'product_name': product['name'],
              'category': product['category'],
            },
          );

          // Show visual push notification overlay
          if (mounted) {
            PushNotificationService.showPushNotificationOverlay(
              context,
              title: 'New Product Posted! 🎉',
              body:
                  '${product['name']} is now available in ${product['category']}',
            );
          }

          // Show immediate success notification to user
          _showProductAddedDialog(product['name'].toString());
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.initialProduct != null
                  ? 'Product updated successfully!'
                  : 'Product posted successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showProductAddedDialog(String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: Text(
              '$productName has been added successfully!\n\nOther users will now be able to see and purchase your product.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Great!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post New Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product Image Upload
              GestureDetector(
                onTap: _getImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add product image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Name
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter product name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter product description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter product price";
                  }
                  if (double.tryParse(value) == null) {
                    return "Please enter a valid price";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: CategoryConstants.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select a category";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: "Enter product location",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter product location";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                          const SizedBox(width: 12),
                          Text(
                            widget.initialProduct != null
                                ? "Updating..."
                                : "Posting...",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        widget.initialProduct != null
                            ? "Update Product"
                            : "Post Product",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
