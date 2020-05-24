import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasks List',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final taskController = TextEditingController();

  List _taskList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRevemodPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _taskList = json.decode(data);
      });
    });
  }

  // Chama meu arquivo tasks.json armazenado no celular
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tasks.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_taskList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (error) {
      return null;
    }
  }

  void _addTask() {
    setState(() {
      Map<String, dynamic> task = Map();
      task['title'] = taskController.text;
      task['ok'] = false;

      taskController.text = '';

      _taskList.add(task);

      _saveData();
    });
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_taskList[index]['title']),
        value: _taskList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_taskList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (check) {
          setState(() {
            _taskList[index]['ok'] = check;
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_taskList[index]);
          _lastRevemodPosition = index;
          _taskList.removeAt(index);

          _saveData();

          final snackbar = SnackBar(
            content: Text('Task \"${_lastRemoved['title']}\" removed!'),
            action: SnackBarAction(
                label: 'Dissmin',
                onPressed: () {
                  setState(() {
                    _taskList.insert(_lastRevemodPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 4),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackbar);
        });
      },
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _taskList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });
    });

    _saveData();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tasks'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(16.0, 1.0, 16.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                        labelText: 'New Task',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  )),
                  RaisedButton(
                      color: Colors.blueAccent,
                      child: Text('ADD'),
                      textColor: Colors.white,
                      onPressed: _addTask),
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _taskList.length,
                  itemBuilder: buildItem),
              onRefresh: _refresh,
            ))
          ],
        ));
  }
}
