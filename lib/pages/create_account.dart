import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';
import 'dart:async';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String username;
  final _formkey = GlobalKey<FormState>();
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  submit() {
    final form = _formkey.currentState;
    if (form.validate()) {
      form.save();
      SnackBar snackbar = SnackBar(
        content: Text("Welcome $username"),
      );
      _scaffoldkey.currentState.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldkey,
      appBar:
          header(context, titleText: "Set Up Profile", removeBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Center(
                    child: Text(
                      "Create a Username",
                      style: TextStyle(
                        fontSize: 25.0,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    child: Form(
                      autovalidate: true,
                      key: _formkey,
                      child: TextFormField(
                        validator: (val) {
                          if (val.trim().length < 3 || val.isEmpty) {
                            return "UserName Too Short";
                          } else if (val.trim().length > 20) {
                            return "Username Too Long";
                          } else
                            return null;
                        },
                        onSaved: (val) {
                          username = val;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Username",
                          labelStyle: TextStyle(
                            fontSize: 16.0,
                          ),
                          hintText: "Name must be atleast 3 characters",
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
