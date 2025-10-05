import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';

class ChatbotProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, String> _botKnowledge = {};
  bool _isLoading = false;

  Map<String, String> get botKnowledge => _botKnowledge;
  bool get isLoading => _isLoading;

  Future<void> loadBotKnowledge() async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('chatbot').doc('knowledge').get();
      if (doc.exists) {
        _botKnowledge =
            Map<String, String>.from(doc.data()?['responses'] ?? {});
      }
    } catch (e) {
      debugPrint('Load bot knowledge error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBotResponse(String question, String answer) async {
    try {
      _botKnowledge[question.toLowerCase()] = answer;
      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Add bot response error: $e');
      rethrow;
    }
  }

  Future<void> removeBotResponse(String question) async {
    try {
      _botKnowledge.remove(question.toLowerCase());
      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Remove bot response error: $e');
      rethrow;
    }
  }

  String? getBotResponse(String question) {
    final lowerQuestion = question.toLowerCase().trim();

    // Exact match
    if (_botKnowledge.containsKey(lowerQuestion)) {
      return _botKnowledge[lowerQuestion];
    }

    // Partial match
    for (var key in _botKnowledge.keys) {
      if (lowerQuestion.contains(key) || key.contains(lowerQuestion)) {
        return _botKnowledge[key];
      }
    }

    return null;
  }

  Future<void> createIssue(IssueModel issue) async {
    try {
      await _firestore.collection('issues').add(issue.toMap());
    } catch (e) {
      debugPrint('Create issue error: $e');
      rethrow;
    }
  }

  Stream<List<IssueModel>> getPendingIssues() {
    return _firestore
        .collection('issues')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> resolveIssue(
      String issueId, String response, String teamLeaderId) async {
    try {
      await _firestore.collection('issues').doc(issueId).update({
        'status': 'resolved',
        'teamLeaderResponse': response,
        'teamLeaderId': teamLeaderId,
        'resolvedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Resolve issue error: $e');
      rethrow;
    }
  }
}
