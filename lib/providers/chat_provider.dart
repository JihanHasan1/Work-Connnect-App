import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TeamModel>> getTeams() {
    return _firestore.collection('teams').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<MessageModel>> getTeamMessages(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> sendMessage(String teamId, MessageModel message) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .add(message.toMap());
  }

  Future<void> createTeam(TeamModel team) async {
    await _firestore.collection('teams').doc(team.id).set(team.toMap());
  }

  Future<void> updateTeam(TeamModel team) async {
    await _firestore.collection('teams').doc(team.id).update(team.toMap());
  }

  Future<void> deleteTeam(String teamId) async {
    await _firestore.collection('teams').doc(teamId).delete();
  }
}
