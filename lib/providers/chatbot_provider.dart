import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../models/faq_model.dart';

class ChatbotProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Structure: { questionId: { question, answer, keywords: [keyword1, keyword2, ...] } }
  Map<String, Map<String, dynamic>> _botKnowledge = {};
  List<FAQModel> _faqs = [];
  bool _isLoading = false;

  Map<String, Map<String, dynamic>> get botKnowledge => _botKnowledge;
  bool get isLoading => _isLoading;

  // Load both chatbot knowledge and FAQs
  Future<void> loadBotKnowledge() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load chatbot knowledge with keywords
      final doc = await _firestore.collection('chatbot').doc('knowledge').get();
      if (doc.exists) {
        final data = doc.data()?['responses'] ?? {};
        _botKnowledge = Map<String, Map<String, dynamic>>.from(
          data.map((key, value) => MapEntry(
                key,
                Map<String, dynamic>.from(value),
              )),
        );
        debugPrint('✅ Loaded ${_botKnowledge.length} chatbot responses');
      }

      // Load FAQs for chatbot use
      final faqSnapshot = await _firestore.collection('faqs').get();
      _faqs = faqSnapshot.docs
          .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
          .toList();
      debugPrint('✅ Loaded ${_faqs.length} FAQs');
    } catch (e) {
      debugPrint('❌ Load bot knowledge error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add bot response with keywords
  Future<void> addBotResponse(
    String question,
    String answer,
    List<String> keywords,
  ) async {
    try {
      final questionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Clean and prepare keywords
      final cleanKeywords = keywords
          .map((k) => k.toLowerCase().trim())
          .where((k) => k.isNotEmpty)
          .toSet()
          .toList();

      debugPrint('➕ Adding response with ${cleanKeywords.length} keywords');

      _botKnowledge[questionId] = {
        'question': question.trim(),
        'answer': answer.trim(),
        'keywords': cleanKeywords,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Response added successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Add bot response error: $e');
      rethrow;
    }
  }

  // Update bot response
  Future<void> updateBotResponse(
    String questionId,
    String question,
    String answer,
    List<String> keywords,
  ) async {
    try {
      final cleanKeywords = keywords
          .map((k) => k.toLowerCase().trim())
          .where((k) => k.isNotEmpty)
          .toSet()
          .toList();

      _botKnowledge[questionId] = {
        'question': question.trim(),
        'answer': answer.trim(),
        'keywords': cleanKeywords,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Response updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Update bot response error: $e');
      rethrow;
    }
  }

  // Remove bot response
  Future<void> removeBotResponse(String questionId) async {
    try {
      _botKnowledge.remove(questionId);
      await _firestore.collection('chatbot').doc('knowledge').set({
        'responses': _botKnowledge,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Response removed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Remove bot response error: $e');
      rethrow;
    }
  }

  // Enhanced bot response with keyword matching
  String? getBotResponse(String question) {
    final lowerQuestion = question.toLowerCase().trim();
    debugPrint('\n🤖 Processing question: "$question"');

    // Extract words from the question (minimum 3 characters)
    final questionWords = lowerQuestion
        .split(RegExp(r'[^\w]+'))
        .where((w) => w.length >= 3)
        .map((w) => w.toLowerCase())
        .toSet();

    debugPrint('📝 Question words: $questionWords');

    if (questionWords.isEmpty) {
      debugPrint('❌ No valid words in question');
      return null;
    }

    String? bestMatch;
    double bestScore = 0.0;
    String? bestQuestionText;

    // Search in chatbot knowledge using keywords
    for (var entry in _botKnowledge.entries) {
      final data = entry.value;
      final keywords = List<String>.from(data['keywords'] ?? []);
      final storedQuestion = data['question']?.toString().toLowerCase() ?? '';

      // Calculate keyword match score
      int keywordMatches = 0;
      for (var word in questionWords) {
        if (keywords.contains(word)) {
          keywordMatches++;
        }
      }

      // Calculate question similarity score
      final questionWordsInStored = storedQuestion
          .split(RegExp(r'[^\w]+'))
          .where((w) => w.length >= 3)
          .toSet();

      final wordMatches =
          questionWords.intersection(questionWordsInStored).length;

      // Combined score: keyword matches are weighted more heavily
      final score = (keywordMatches * 2.0) + (wordMatches * 1.0);

      debugPrint('  Checking: "${data['question']}"');
      debugPrint('    Keywords: $keywords');
      debugPrint('    Keyword matches: $keywordMatches');
      debugPrint('    Word matches: $wordMatches');
      debugPrint('    Score: $score');

      // Require at least 1 keyword match OR 2 word matches
      if (score > bestScore && (keywordMatches >= 1 || wordMatches >= 2)) {
        bestScore = score;
        bestMatch = data['answer'];
        bestQuestionText = data['question'];
      }
    }

    if (bestMatch != null) {
      debugPrint('✅ Found match with score $bestScore: "$bestQuestionText"');
      return bestMatch;
    }

    // Search in FAQs with keywords
    for (var faq in _faqs) {
      final faqQuestion = faq.question.toLowerCase();
      final faqWords = faqQuestion
          .split(RegExp(r'[^\w]+'))
          .where((w) => w.length >= 3)
          .toSet();

      final wordMatches = questionWords.intersection(faqWords).length;
      final score = wordMatches.toDouble();

      debugPrint('  Checking FAQ: "${faq.question}"');
      debugPrint('    Word matches: $wordMatches');
      debugPrint('    Score: $score');

      if (score > bestScore && wordMatches >= 2) {
        bestScore = score;
        bestMatch = faq.answer;
        bestQuestionText = faq.question;
      }
    }

    if (bestMatch != null) {
      debugPrint(
          '✅ Found FAQ match with score $bestScore: "$bestQuestionText"');
      return bestMatch;
    }

    debugPrint('❌ No match found');
    return null;
  }

  // Auto-extract keywords from question (helper method)
  List<String> extractKeywords(String question) {
    // Common words to ignore
    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'was',
      'are',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'can',
      'may',
      'might',
      'what',
      'when',
      'where',
      'who',
      'how',
      'why',
      'which',
      'this',
      'that',
      'these',
      'those',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'my',
      'your',
      'his',
      'her',
      'our',
      'their',
      'me',
      'him',
      'us',
      'them'
    };

    final words = question
        .toLowerCase()
        .split(RegExp(r'[^\w]+'))
        .where((w) => w.length >= 3 && !stopWords.contains(w))
        .toSet()
        .toList();

    return words;
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

  // Resolve issue with a response and keywords
  Future<void> resolveIssue(
    String issueId,
    String response,
    String teamLeaderId,
    bool saveToKnowledge,
    String? question,
    List<String>? keywords,
  ) async {
    try {
      // Update issue status
      await _firestore.collection('issues').doc(issueId).update({
        'status': 'resolved',
        'teamLeaderResponse': response,
        'teamLeaderId': teamLeaderId,
        'resolvedAt': DateTime.now().toIso8601String(),
      });

      // Optionally add to chatbot knowledge with keywords
      if (saveToKnowledge && question != null) {
        final finalKeywords = keywords ?? extractKeywords(question);
        await addBotResponse(question, response, finalKeywords);
        debugPrint('✅ Added to knowledge with keywords: $finalKeywords');
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
