import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

AppBar header(context,
    {bool isAppTitle = false,
    String titleText,
    bool removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? "MemeFy" : titleText,
      style: TextStyle(
        fontFamily: "Signatra",
        color: Colors.white,
        fontSize: isAppTitle ? 50.0 : 30.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).primaryColor,
  );
}
