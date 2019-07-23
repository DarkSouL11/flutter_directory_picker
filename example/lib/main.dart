import 'dart:io';

import 'package:directory_picker/directory_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Directory Picker Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Directory Picker Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Directory selectedDirectory;

  Future<void> _pickDirectory(BuildContext context) async {
    Directory directory = selectedDirectory;
    if (directory == null) {
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await DirectoryPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    setState(() {
      selectedDirectory = newDirectory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Selected Directory:',
                style: theme.textTheme.title,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.0),
              Text(selectedDirectory != null ? selectedDirectory.path : 'none',
                  textAlign: TextAlign.center)
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickDirectory(context),
        tooltip: 'Pick Directory',
        child: Icon(Icons.create_new_folder),
      ),
    );
  }
}
