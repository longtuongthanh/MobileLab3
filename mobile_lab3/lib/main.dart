import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CollectionReference query = FirebaseFirestore.instance.collection("comment");
  StreamSubscription querySub;
  List<Tuple3<String, String, DateTime>> list = [];

  final TextEditingController inputController = TextEditingController();
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();

    query.get().then((value) => updateData(value));

    querySub = query.snapshots().listen((event) {
      updateData(event);
    });
  }

  @override
  void dispose() {
    querySub?.cancel();
    super.dispose();
  }

  void updateData(QuerySnapshot snapshot) {
    List<Tuple3<String, String, DateTime>> temp = snapshot.docs
        .map((e) {
          try {
            return new Tuple3<String, String, DateTime>(
                e.data()["username"],
                e.data()["content"],
                (e.data()["postTime"] as Timestamp).toDate());
          } catch (e) {
            return null;
          }
        })
        .where((element) => element != null)
        .toList();
    temp.sort((a, b) {
      return a.item3.compareTo(b.item3);
    });

    setState(() {
      list = temp;
    });
  }

  void post() {
    String username = name;
    String content = inputController.text;
    DateTime timeStamp = DateTime.now();
    query.add(<String, dynamic>{
      "username": username,
      "content": content,
      "postTime": timeStamp,
    });
    FocusScope.of(context).unfocus();
  }

  int itemCount() {
    if (list == null || list.length <= 0) return 0;
    return list.length * 2 - 1;
  }

  String _getDuration(DateTime dateTime) {
    Duration ageDuration = DateTime.now().difference(dateTime);

    if (ageDuration.inDays >= 365) {
      return "${ageDuration.inDays / 365}y";
    } else if (ageDuration.inDays >= 30) {
      return "${ageDuration.inDays / 30}m";
    } else if (ageDuration.inDays > 0) {
      return "${ageDuration.inDays}d";
    } else if (ageDuration.inHours > 0) {
      return "${ageDuration.inHours}h";
    } else {
      return "${ageDuration.inMinutes} minutes";
    }
  }

  Widget comment(Tuple3<String, String, DateTime> data) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Text(
                      data.item1,
                      style: Theme.of(context).textTheme.subtitle2.copyWith(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        _getDuration(data.item3),
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(fontSize: 10, color: Colors.black),
                      ),
                    ),
                  ]),
                  // Content
                  Text(
                    data.item2,
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget mainScreen() {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 15, 15, 15),
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Text("Post")]),
        ),
        body: Stack(children: [
          // ListView.builder(
          //   itemBuilder: (context, index) {
          //     if (index < _mainScreenComponent.length) {
          //       return _mainScreenComponent[index];
          //     }
          //   },
          // ),
          ScrollablePositionedList.builder(
              itemScrollController: itemScrollController,
              itemCount: itemCount(),
              itemBuilder: (context, index) {
                if (index >= itemCount()) return null;

                if (index % 2 == 0) {
                  return comment(list[index ~/ 2]);
                } else {
                  return Container(
                    height: 8,
                    color: Colors.white,
                  );
                }
              }),
          //Bottom comment input field
          buildBottomCommentInput(context),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (name == null || name == "")
      content = loginScreen();
    else
      content = mainScreen();

    return content;
  }

  String name;
  String nameTemp;
  bool _processing = false;

  Widget loginScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: Text("")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewInsets.bottom,
          color: Colors.white,
          child: Stack(children: [
            AbsorbPointer(
              absorbing: _processing ? true : false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What should we call you",
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          .copyWith(color: Colors.black),
                    ),
                    SizedBox(height: 16),
                    // Name
                    TextField(
                      onChanged: (value) {
                        nameTemp = value;
                      },
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
            ),
            if (_processing)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(),
                ),
              ),
          ]),
        ),
      ),
      floatingActionButton: AbsorbPointer(
        absorbing: _processing ? true : false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.blue,
            borderRadius: BorderRadius.all(Radius.circular(32)),
            child: InkWell(
              borderRadius: BorderRadius.all(Radius.circular(32)),
              onTap: () {
                setState(() {
                  name = nameTemp;
                });
              },
              splashColor: Colors.blue[200],
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(32))),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    "Continue",
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(color: Colors.white),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Align buildBottomCommentInput(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.only(bottom: 8),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 2,
              thickness: 2,
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: inputController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(color: Colors.black, fontSize: 12),
                      decoration: InputDecoration(
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(color: Colors.black, fontSize: 10),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        hintText: "Write comment...",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    child: InkWell(
                      onTap: post,
                      child: Container(
                        decoration: BoxDecoration(
                            color: inputController.text.length > 0
                                ? Colors.blue
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(5)),
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Text(
                              "Post",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
