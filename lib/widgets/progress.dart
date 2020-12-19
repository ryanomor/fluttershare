import 'package:flutter/material.dart';

Container circularProgress(BuildContext context) {
  return Container(
    alignment: Alignment.center,
    // padding: EdgeInsets.only(top: 10.0),
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
    ),
  );
}

Container linearProgress(BuildContext context) {
  return Container(
    // alignment: ,
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
    ),
  );
}
