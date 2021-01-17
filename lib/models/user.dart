import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final Set followers;
  final Set following;

  User({
    this.id,
    this.username,
    this.email,
    this.bio,
    this.displayName,
    this.photoUrl,
    this.followers,
    this.following,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc["id"],
      username: doc["username"],
      email: doc["email"],
      bio: doc["bio"],
      displayName: doc["displayName"],
      photoUrl: doc["photoUrl"],
      followers: doc["followers"].toSet(),
      following: doc["following"].toSet(),
    );
  }
}
