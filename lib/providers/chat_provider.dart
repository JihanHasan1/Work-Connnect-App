import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all teams
  Stream<List<TeamModel>> getTeams() {
    return _firestore
        .collection('teams')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get teams for a specific user
  Stream<List<TeamModel>> getUserTeams(String userId, bool isAdmin) {
    if (isAdmin) {
      return getTeams(); // Admin sees all teams
    }

    return _firestore.collection('teams').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
          .where((team) =>
              team.leaderId == userId || team.memberIds.contains(userId))
          .toList();
    });
  }

  // Get a specific team
  Stream<TeamModel?> getTeam(String teamId) {
    return _firestore.collection('teams').doc(teamId).snapshots().map((doc) {
      if (doc.exists) {
        return TeamModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Get team messages with pagination support
  Stream<List<MessageModel>> getTeamMessages(String teamId, {int limit = 100}) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Send a message to a team
  Future<void> sendMessage(String teamId, MessageModel message) async {
    try {
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .add(message.toMap());

      // Update team's last message timestamp
      await _firestore.collection('teams').doc(teamId).update({
        'lastMessageAt': message.timestamp.toIso8601String(),
        'lastMessage': message.content,
        'lastMessageBy': message.senderName,
      });

      // Send notification to team members (placeholder for future implementation)
      await _sendNotificationToTeamMembers(teamId, message);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Create a new team
  Future<void> createTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').doc(team.id).set(team.toMap());

      // Send welcome message
      final welcomeMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        senderName: 'System',
        content:
            'Welcome to ${team.name}! This team was created for: ${team.description}',
        timestamp: DateTime.now(),
        type: 'system',
      );

      await sendSystemMessage(team.id, welcomeMessage);
    } catch (e) {
      debugPrint('Error creating team: $e');
      rethrow;
    }
  }

  // Update team details
  Future<void> updateTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').doc(team.id).update(team.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating team: $e');
      rethrow;
    }
  }

  // Delete a team
  Future<void> deleteTeam(String teamId) async {
    try {
      // Delete all messages first
      final messages = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete the team
      await _firestore.collection('teams').doc(teamId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting team: $e');
      rethrow;
    }
  }

  // Add members to team
  Future<void> addMembersToTeam(String teamId, List<String> userIds) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) throw 'Team not found';

      final currentMembers =
          List<String>.from(teamDoc.data()!['memberIds'] ?? []);
      final newMembers =
          userIds.where((id) => !currentMembers.contains(id)).toList();

      if (newMembers.isEmpty) return;

      currentMembers.addAll(newMembers);

      await _firestore.collection('teams').doc(teamId).update({
        'memberIds': currentMembers,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send notification about new members
      for (String userId in newMembers) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final systemMessage = MessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: 'system',
            senderName: 'System',
            content:
                '${userData['displayName'] ?? userData['username']} has been added to the team',
            timestamp: DateTime.now(),
            type: 'system',
          );
          await sendSystemMessage(teamId, systemMessage);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding members: $e');
      rethrow;
    }
  }

  // Remove member from team
  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) throw 'Team not found';

      final members = List<String>.from(teamDoc.data()!['memberIds'] ?? []);
      members.remove(userId);

      await _firestore.collection('teams').doc(teamId).update({
        'memberIds': members,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send notification about member removal
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final systemMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          content:
              '${userData['displayName'] ?? userData['username']} has left the team',
          timestamp: DateTime.now(),
          type: 'system',
        );
        await sendSystemMessage(teamId, systemMessage);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  // Change team leader
  Future<void> changeTeamLeader(String teamId, String newLeaderId) async {
    try {
      await _firestore.collection('teams').doc(teamId).update({
        'leaderId': newLeaderId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send notification about leadership change
      final userDoc =
          await _firestore.collection('users').doc(newLeaderId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final systemMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          content:
              '${userData['displayName'] ?? userData['username']} is now the team leader',
          timestamp: DateTime.now(),
          type: 'system',
        );
        await sendSystemMessage(teamId, systemMessage);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error changing team leader: $e');
      rethrow;
    }
  }

  // Send system message
  Future<void> sendSystemMessage(String teamId, MessageModel message) async {
    try {
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      debugPrint('Error sending system message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String teamId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a team
  Stream<int> getUnreadMessageCount(String teamId, String userId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Search messages in a team
  Future<List<MessageModel>> searchMessages(String teamId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  // Get team members details
  Future<List<UserModel>> getTeamMembersDetails(TeamModel team) async {
    try {
      final memberIds = [...team.memberIds, team.leaderId];
      final members = <UserModel>[];

      for (String memberId in memberIds) {
        final doc = await _firestore.collection('users').doc(memberId).get();
        if (doc.exists) {
          members.add(UserModel.fromMap(doc.data()!, doc.id));
        }
      }

      return members;
    } catch (e) {
      debugPrint('Error getting team members: $e');
      return [];
    }
  }

  // Send notification to team members (placeholder)
  Future<void> _sendNotificationToTeamMembers(
      String teamId, MessageModel message) async {
    // This is a placeholder for push notification implementation
    // You would integrate with Firebase Cloud Messaging here
    debugPrint('Notification would be sent to team members');
  }

  // Get teams with unread messages for a user
  Stream<Map<String, int>> getTeamsWithUnreadCounts(String userId) {
    return _firestore
        .collection('teams')
        .snapshots()
        .asyncMap((teamsSnapshot) async {
      final unreadCounts = <String, int>{};

      for (var teamDoc in teamsSnapshot.docs) {
        final team = TeamModel.fromMap(teamDoc.data(), teamDoc.id);

        // Check if user is a member
        if (team.leaderId == userId || team.memberIds.contains(userId)) {
          final unreadSnapshot = await _firestore
              .collection('teams')
              .doc(team.id)
              .collection('messages')
              .where('isRead', isEqualTo: false)
              .where('senderId', isNotEqualTo: userId)
              .get();

          if (unreadSnapshot.docs.isNotEmpty) {
            unreadCounts[team.id] = unreadSnapshot.docs.length;
          }
        }
      }

      return unreadCounts;
    });
  }

  // Delete a message
  Future<void> deleteMessage(String teamId, String messageId) async {
    try {
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Edit a message
  Future<void> editMessage(
      String teamId, String messageId, String newContent) async {
    try {
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }
}
