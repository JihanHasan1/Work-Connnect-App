import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faq_model.dart';

class FAQProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FAQModel> _faqs = [];
  bool _isLoading = false;

  List<FAQModel> get faqs => _faqs;
  bool get isLoading => _isLoading;

  Future<void> loadFAQs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await _firestore.collection('faqs').orderBy('category').get();

      _faqs = snapshot.docs
          .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Load FAQs error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFAQ(FAQModel faq) async {
    try {
      await _firestore.collection('faqs').add(faq.toMap());
      await loadFAQs();
    } catch (e) {
      debugPrint('Add FAQ error: $e');
      rethrow;
    }
  }

  Future<void> updateFAQ(FAQModel faq) async {
    try {
      await _firestore.collection('faqs').doc(faq.id).update(faq.toMap());
      await loadFAQs();
    } catch (e) {
      debugPrint('Update FAQ error: $e');
      rethrow;
    }
  }

  Future<void> deleteFAQ(String id) async {
    try {
      await _firestore.collection('faqs').doc(id).delete();
      await loadFAQs();
    } catch (e) {
      debugPrint('Delete FAQ error: $e');
      rethrow;
    }
  }

  Future<void> incrementViewCount(String id) async {
    try {
      await _firestore.collection('faqs').doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Increment view count error: $e');
    }
  }

  List<String> get categories {
    return _faqs.map((faq) => faq.category).toSet().toList();
  }

  List<FAQModel> getFAQsByCategory(String category) {
    return _faqs.where((faq) => faq.category == category).toList();
  }

  List<FAQModel> searchFAQs(String query) {
    final lowerQuery = query.toLowerCase();
    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(lowerQuery) ||
          faq.answer.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
