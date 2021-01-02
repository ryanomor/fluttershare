import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  User user;
  bool isLoading = false;
  bool _bioInvalid = false;
  bool _displayNameInvalid = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController bioController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);

    displayNameController.text = user.displayName;
    bioController.text = user.bio;

    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Display name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update display name",
            errorText: !_displayNameInvalid
                ? null
                : "Display name should be more than 3 characters",
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update bio",
            errorText:
                !_bioInvalid ? null : "Bio is longer than 100 characters",
          ),
        )
      ],
    );
  }

  updateProfileData() {
    setState(() {
      _bioInvalid = bioController.text.trim().length > 100;
      _displayNameInvalid = displayNameController.text.trim().length < 3 ||
          displayNameController.text.isEmpty;
    });

    if (!_displayNameInvalid && !_bioInvalid) {
      usersRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text
      });
    }

    SnackBar snackbar = SnackBar(content: Text("Profile Updated"));
    _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  goToPreviousScreen() {
    displayNameController.clear();
    bioController.clear();

    return Navigator.pop(context);
  }

  logout() async {
    await googleSignIn.signOut();

    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: goToPreviousScreen,
            icon: Icon(Icons.done, size: 30.0, color: Colors.green),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress(context)
          : ListView(
              children: [
                Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [buildDisplayNameField(), buildBioField()],
                        ),
                      ),
                      RaisedButton(
                        textColor: Colors.white,
                        color: Theme.of(context).primaryColor,
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text(
                            "Logout",
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
