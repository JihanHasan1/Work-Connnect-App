import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../models/faq_model.dart';

class ChatbotProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, String> _botKnowledge = {};
  List<FAQModel> _faqs = [];
  bool _isLoading = false;

  Map<String, String> get botKnowledge => _botKnowledge;
  bool get isLoading => _isLoading;

  // Load both chatbot knowledge and FAQs
  Future<void> loadBotKnowledge() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load chatbot responses
      final doc = await _firestore.collection('chatbot').doc('knowledge').get();
      if (doc.exists) {
        _botKnowledge =
            Map<String, String>.from(doc.data()?['responses'] ?? {});
      }

      // Load FAQs for chatbot use
      final faqSnapshot = await _firestore.collection('faqs').get();
      _faqs = faqSnapshot.docs
          .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Load bot knowledge error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBotResponse(String question, String answer) async {
    try {
      _botKnowledge[question.toLowerCase().trim()] = answer;
      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Add bot response error: $e');
      rethrow;
    }
  }

  Future<void> removeBotResponse(String question) async {
    try {
      _botKnowledge.remove(question.toLowerCase().trim());
      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Remove bot response error: $e');
      rethrow;
    }
  }

  // Enhanced bot response with FAQ integration and improved fuzzy matching
  String? getBotResponse(String question) {
    final lowerQuestion = question.toLowerCase().trim();

    // 1. Exact match in chatbot knowledge
    if (_botKnowledge.containsKey(lowerQuestion)) {
      debugPrint('✅ Exact match found in chatbot knowledge');
      return _botKnowledge[lowerQuestion];
    }

    // 2. Check FAQs for exact match
    for (var faq in _faqs) {
      if (faq.question.toLowerCase().trim() == lowerQuestion) {
        debugPrint('✅ Exact match found in FAQs');
        return faq.answer;
      }
    }

    // 3. Improved fuzzy matching - check for significant keyword overlap
    // Extract meaningful keywords (words longer than 3 characters)
    final questionWords = lowerQuestion
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .map((w) => w.toLowerCase())
        .toSet();

    if (questionWords.isEmpty) {
      debugPrint('❌ No meaningful keywords found in question');
      return null;
    }

    // Search in chatbot knowledge with stricter matching
    String? bestMatch;
    double bestScore = 0.0;

    for (var entry in _botKnowledge.entries) {
      final knowledgeWords = entry.key
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .map((w) => w.toLowerCase())
          .toSet();

      if (knowledgeWords.isEmpty) continue;

      // Calculate Jaccard similarity (intersection / union)
      final intersection = questionWords.intersection(knowledgeWords).length;
      final union = questionWords.union(knowledgeWords).length;
      final similarity = intersection / union;

      // Require at least 60% similarity AND at least 2 matching words
      if (similarity > bestScore && similarity >= 0.6 && intersection >= 2) {
        bestScore = similarity;
        bestMatch = entry.value;
      }
    }

    if (bestMatch != null) {
      debugPrint(
          '✅ Fuzzy match found in chatbot (score: ${(bestScore * 100).toStringAsFixed(1)}%)');
      return bestMatch;
    }

    // Search in FAQs with same stricter matching
    bestMatch = null;
    bestScore = 0.0;

    for (var faq in _faqs) {
      final faqWords = faq.question
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .map((w) => w.toLowerCase())
          .toSet();

      if (faqWords.isEmpty) continue;

      final intersection = questionWords.intersection(faqWords).length;
      final union = questionWords.union(faqWords).length;
      final similarity = intersection / union;

      // Slightly lower threshold for FAQs (50%) but still require 2 matching words
      if (similarity > bestScore && similarity >= 0.5 && intersection >= 2) {
        bestScore = similarity;
        bestMatch = faq.answer;
      }
    }

    if (bestMatch != null) {
      debugPrint(
          '✅ Fuzzy match found in FAQs (score: ${(bestScore * 100).toStringAsFixed(1)}%)');
      return bestMatch;
    }

    // 4. Check for common single keywords only as last resort
    final commonKeywords = {
      'leave':
          'For leave-related queries, please check the Leave Policy in FAQs or contact HR.',
      'salary':
          'For salary-related queries, please contact the HR department directly.',
      'pay':
          'For payment-related queries, please contact the HR department directly.',
      'password':
          'For password reset, please contact IT support or use the password reset link.',
      'login':
          'For login issues, please contact IT support or check your credentials.',
      'benefits':
          'For information about benefits, please check the Employee Benefits section in FAQs.',
      'holiday':
          'For holiday schedules, please check the Company Calendar in FAQs.',
      'vacation':
          'For vacation policies, please check the Leave Policy in FAQs.',
      'sick':
          'For sick leave information, please check the Leave Policy in FAQs or contact HR.',
    };

    // Only check single keywords if the question is very short (4 words or less)
    if (lowerQuestion.split(RegExp(r'\s+')).length <= 4) {
      for (var keyword in commonKeywords.keys) {
        if (lowerQuestion.contains(keyword)) {
          debugPrint('✅ Single keyword match found: $keyword');
          return commonKeywords[keyword];
        }
      }
    }

    debugPrint('❌ No match found for: $question');
    return null;
  }

  // Create an issue when chatbot can't answer
  Future<void> createIssue(IssueModel issue) async {
    try {
      await _firestore.collection('issues').add(issue.toMap());
      debugPrint('✅ Issue created: ${issue.question}');
    } catch (e) {
      debugPrint('❌ Create issue error: $e');
      rethrow;
    }
  }

  // Get pending issues (for team leaders)
  Stream<List<IssueModel>> getPendingIssues() {
    return _firestore
        .collection('issues')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 Pending issues count: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all issues (for team leaders)
  Stream<List<IssueModel>> getAllIssues() {
    return _firestore
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Resolve issue with a response
  Future<void> resolveIssue(
    String issueId,
    String response,
    String teamLeaderId,
    bool saveToKnowledge,
    String? question,
  ) async {
    try {
      // Update issue status
      await _firestore.collection('issues').doc(issueId).update({
        'status': 'resolved',
        'teamLeaderResponse': response,
        'teamLeaderId': teamLeaderId,
        'resolvedAt': DateTime.now().toIso8601String(),
      });

      // Optionally add to chatbot knowledge
      if (saveToKnowledge && question != null) {
        await addBotResponse(question, response);
      }

      debugPrint('✅ Issue resolved: $issueId');
    } catch (e) {
      debugPrint('❌ Resolve issue error: $e');
      rethrow;
    }
  }

  // Delete issue
  Future<void> deleteIssue(String issueId) async {
    try {
      await _firestore.collection('issues').doc(issueId).delete();
      debugPrint('✅ Issue deleted: $issueId');
    } catch (e) {
      debugPrint('❌ Delete issue error: $e');
      rethrow;
    }
  }

  // Get issue count for badges
  Stream<int> getPendingIssuesCount() {
    return _firestore
        .collection('issues')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 Badge count: ${snapshot.docs.length}');
      return snapshot.docs.length;
    });
  }
}
