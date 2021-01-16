import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  Future notifications;

  @override
  void initState() {
    super.initState();
    notifications = getActivityFeed();
  }

  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(25)
        .getDocuments();

    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });

    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          header(context, titleText: 'Activity Feed', removeBackButton: true),
      backgroundColor: Colors.grey[300],
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress(context);
            }
            return ListView(children: snapshot.data);
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String avatarUrl;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.avatarUrl,
    this.commentData,
    this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      avatarUrl: doc['avatarUrl'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
    );
  }

  configureMediaPreview() {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => print('show post'),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(mediaUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    switch (type) {
      case 'like':
        activityItemText = 'liked your post!';
        break;
      case 'follow':
        activityItemText = 'followed you!';
        break;
      case 'comment':
        activityItemText = 'commented: $commentData';
        break;
      default:
        activityItemText = 'Error: Unknown type "$type"';
    }

    // if (type == 'like') {
    //   activityItemText = 'liked your post!';
    // } else if (type == 'follow') {
    //   activityItemText = 'followed you!';
    // } else if (type == 'comment') {
    //   activityItemText = 'commented: $commentData';
    // } else {
    //   activityItemText = 'Error: Unknown type "$type"';
    // }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview();

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => print('go to activity context'),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14.0, color: Colors.black),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' $activityItemText',
                  ),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}
