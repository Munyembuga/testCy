// ignore_for_file: unused_element, avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'database_service.dart';
import 'firebase_service.dart';

class ProductService {
  static const String _productsKey = 'products';
  static const String _nextIdKey = 'nextProductId';

  // Save a new product
  static Future<void> saveProduct(Map<String, dynamic> product) async {
    try {
      final db = await DatabaseService.database;
      
      // Ensure image is properly handled
      if (product['image'] != null) {
        if (product['image'] is File) {
          final bytes = await (product['image'] as File).readAsBytes();
          product['image'] = base64Encode(bytes);
          product['isLocalImage'] = 1; // SQLite uses integers for boolean
        } else if (product['image'] is String) {
          product['isLocalImage'] = product['image'].startsWith('data:image') ? 1 : 0;
        }
      }

      // Ensure location is included
      if (!product.containsKey('location') || product['location'] == null) {
        product['location'] = 'No location specified';
      }

      await db.insert('products', product);
      // ignore: avoid_print
      print('Product saved successfully: ${product['name']}');
      
      // Debug: verify the save
      await DatabaseService.debugPrintTableInfo();
    } catch (e) {
      print('Error saving product: $e');
      rethrow;
    }
  }

  static Future<void> _saveLocalProduct(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing products
    final productsJson = prefs.getString(_productsKey);
    List<Map<String, dynamic>> products = [];

    if (productsJson != null) {
      products = (json.decode(productsJson) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Get next ID
    int nextId = prefs.getInt(_nextIdKey) ?? 1;
    product['id'] = nextId.toString();

    // Add seller information
    product['sellerId'] =
        prefs.getString('current_user_id') ?? 'default_seller';

    // Handle image
    if (product['image'] is File) {
      // Convert File to base64
      final bytes = await (product['image'] as File).readAsBytes();
      product['image'] = base64Encode(bytes);
      product['isLocalImage'] = true;
    } else if (product['image'].toString().startsWith('http')) {
      product['isLocalImage'] = false;
    }

    // Add new product
    products.add(product);

    // Save updated products list
    await prefs.setString(_productsKey, json.encode(products));
    await prefs.setInt(_nextIdKey, nextId + 1);
  }

  // Get all products
  static Future<List<Map<String, dynamic>>> getProducts() async {
    // Get from SQLite
    final db = await DatabaseService.database;
    return await db.query('products');
  }

  // Update a product
  static Future<void> updateProduct(Map<String, dynamic> updatedProduct) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      return;
    }

    List<Map<String, dynamic>> products = (json.decode(productsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // Find and update the product
    final index = products.indexWhere((p) => p['id'] == updatedProduct['id']);
    if (index != -1) {
      products[index] = updatedProduct;
      await prefs.setString(_productsKey, json.encode(products));
    }
  }

  // Delete a product
  static Future<void> deleteProduct(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      return;
    }

    List<Map<String, dynamic>> products = (json.decode(productsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // Remove the product
    products.removeWhere((p) => p['id'] == productId);
    await prefs.setString(_productsKey, json.encode(products));
  }

  // Add payment functionality
  static Future<void> savePayment(Map<String, dynamic> payment) async {
    final db = await DatabaseService.database;
    await db.insert('payments', payment);
    await FirebaseService.savePayment(payment);
  }
}
