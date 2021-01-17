import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/post_state.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;
  final bool removeBackButton;

  Profile({this.profileId, this.removeBackButton = true});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currUserId = currUser?.id;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  bool isLoading = false;
  bool isFollowing = false;
  String postView = "grid";

  @override
  void initState() {
    super.initState();

    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIsFollowing();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection("usersPosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  getFollowers() async {
    User viewedUser = await usersRef
        .document(widget.profileId)
        .get()
        .then((doc) => User.fromDocument(doc));

    setState(() {
      followerCount = viewedUser.followers.length;
    });
  }

  getFollowing() async {
    User viewedUser = await usersRef
        .document(widget.profileId)
        .get()
        .then((doc) => User.fromDocument(doc));

    setState(() {
      followingCount = viewedUser.following.length;
    });
  }

  checkIsFollowing() async {
    User viewedUser = await usersRef
        .document(widget.profileId)
        .get()
        .then((doc) => User.fromDocument(doc));

    setState(() {
      isFollowing = viewedUser.followers.contains(currUserId);
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(
          currentUserId: currUserId,
        ),
      ),
    );
  }

  FlatButton buildButton({String text, Function function}) {
    return FlatButton(
      padding: EdgeInsets.only(top: 2.0),
      onPressed: function,
      child: Container(
        width: 250.0,
        height: 27.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Theme.of(context).accentColor,
            border: Border.all(
              color: isFollowing ? Colors.grey : Theme.of(context).accentColor,
            ),
            borderRadius: BorderRadius.circular(5.0)),
        child: Text(
          text,
          style: TextStyle(
            color: isFollowing ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  handleFollow() {
    setState(() {
      isFollowing = true;
      followerCount += 1;
    });

    // Make auth user follower of THAT user (update THEIR followers List)
    usersRef.document(widget.profileId).updateData({
      "followers": FieldValue.arrayUnion([currUserId])
    });

    // Put THAT user on YOUR following List (update your following List)
    currUser.following.add(widget.profileId);
    usersRef
        .document(currUserId)
        .updateData({"following": currUser.following.toList()});

    // Add activity feed item for that user to notify about new follower (currUser)
    activityFeedRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "userId": currUserId, // currUser.id,
      "username": currUser.username,
      "avatarUrl": currUser.photoUrl,
      "timestamp": DateTime.now(),
    });
  }

  handleUnfollow() {
    setState(() {
      isFollowing = false;
      followerCount -= 1;
    });

    // remove follower
    usersRef.document(widget.profileId).updateData({
      "followers": FieldValue.arrayRemove([currUserId])
    });

    // remove from curr user's following List
    currUser.following.remove(widget.profileId);
    usersRef
        .document(currUserId)
        .updateData({"following": currUser.following.toList()});

    // Delete activity feed item for that user
    activityFeedRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildProfileButton() {
    bool isProfileOwner = widget.profileId == currUserId;

    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if (isFollowing) {
      return buildButton(text: "Unfollow", function: handleUnfollow);
    } else if (!isFollowing) {
      return buildButton(text: "Follow", function: handleFollow);
    }
    return Text("Profile Button");
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }

        User user = User.fromDocument(snapshot.data);

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 40.0,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          user.username,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          user.displayName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Text(user.bio),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton(),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress(context);
    } else if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  fontSize: 40.0,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postView == 'grid') {
      List<GridTile> gridTiles = [];

      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postView == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  togglePostView(String postView) {
    if (this.postView == postView) return;

    setState(() {
      this.postView = postView;
    });
  }

  buildTogglePostsView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.grid_on),
          color:
              postView == 'grid' ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => togglePostView('grid'),
        ),
        IconButton(
          icon: Icon(Icons.list),
          color:
              postView == 'list' ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => togglePostView('list'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(
        context,
        titleText: "Profile",
        removeBackButton: widget.removeBackButton,
      ),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePostsView(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}

navigateToProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
        removeBackButton: false,
      ),
    ),
  );
}
