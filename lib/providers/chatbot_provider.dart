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

  // Enhanced bot response with FAQ integration and fuzzy matching
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

    // 3. Partial match in chatbot knowledge (contains any keyword)
    final questionWords =
        lowerQuestion.split(' ').where((w) => w.length > 3).toList();

    for (var entry in _botKnowledge.entries) {
      final keyWords = entry.key.split(' ');
      int matchCount = 0;

      for (var qWord in questionWords) {
        for (var kWord in keyWords) {
          if (kWord.contains(qWord) || qWord.contains(kWord)) {
            matchCount++;
          }
        }
      }

      // If at least 50% of words match
      if (matchCount >= (questionWords.length * 0.5)) {
        debugPrint(
            '✅ Partial match found in chatbot: $matchCount/${questionWords.length} words');
        return entry.value;
      }
    }

    // 4. Partial match in FAQs
    for (var faq in _faqs) {
      final faqWords = faq.question
          .toLowerCase()
          .split(' ')
          .where((w) => w.length > 3)
          .toList();
      int matchCount = 0;

      for (var qWord in questionWords) {
        for (var fWord in faqWords) {
          if (fWord.contains(qWord) || qWord.contains(fWord)) {
            matchCount++;
          }
        }
      }

      // If at least 40% of words match (FAQs are more general)
      if (matchCount >= (questionWords.length * 0.4)) {
        debugPrint(
            '✅ Partial match found in FAQs: $matchCount/${questionWords.length} words');
        return faq.answer;
      }
    }

    // 5. Check for common keywords
    final commonKeywords = {
      'leave':
          'For leave-related queries, please check the Leave Policy in FAQs or contact HR.',
      'salary':
          'For salary-related queries, please contact the HR department directly.',
      'password':
          'For password reset, please contact IT support or use the password reset link.',
      'benefits':
          'For information about benefits, please check the Employee Benefits section in FAQs.',
      'holiday':
          'For holiday schedules, please check the Company Calendar in FAQs.',
    };

    for (var keyword in commonKeywords.keys) {
      if (lowerQuestion.contains(keyword)) {
        debugPrint('✅ Keyword match found: $keyword');
        return commonKeywords[keyword];
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
        .map((snapshot) => snapshot.docs.length);
  }
}
