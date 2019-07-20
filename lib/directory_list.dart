import 'dart:io';

import 'package:flutter/material.dart';

import 'directory_picker.dart';

class DirectoryList extends StatefulWidget {
  @override
  _DirectoryListState createState() => _DirectoryListState();
}

class _DirectoryListState extends State<DirectoryList> {
  static final double spacing = 8;

  Directory rootDirectory;
  Directory currentDirectory;
  List<Directory> directoryList;

  @override
  void initState() {
    super.initState();

    // To make context available when init runs
    Future.delayed(Duration.zero).then((_) => _init());
  }

  Widget _buildBackNav(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.folder, color: theme.primaryColor),
      title: Text('..'),
      onTap: () => _setDirectory(currentDirectory.parent),
    );
  }

  List<Widget> _buildDirectories(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (directoryList == null) {
      return [
        Expanded(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        )
      ];
    } else if (directoryList.length == 0) {
      return [
        _buildBackNav(context),
        Expanded(
          child: Center(
            child: Text('Directory is empty!', textAlign: TextAlign.center)
          ),
        )
      ];
    } else {
      return [
        Expanded(
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [_buildBackNav(context)]..addAll(
              directoryList.map((directory) {
                return ListTile(
                  leading: Icon(Icons.folder, color: theme.primaryColor),
                  title: Text(_getDirectoryName(directory)),
                  onTap: () => _setDirectory(directory),
                );
              }
            )),
          ),
        )
      ];
    }
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: [
                Text('Selected directory', style: theme.textTheme.subtitle),
                SizedBox(height: spacing / 2),
                Text(
                  currentDirectory?.path ?? '',
                  style: theme.textTheme.caption
                )
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
          SizedBox(height: 0, width: spacing),
          IconButton(
            color: theme.primaryColor,
            icon: Icon(Icons.check),
            onPressed: () => Navigator.pop(context, currentDirectory)
          )
        ],
        mainAxisSize: MainAxisSize.max,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.primaryColor, width: 2))
      ),
      padding: EdgeInsets.all(spacing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildHeader(context),
        Expanded(
          child: Column(
            children: _buildDirectories(context),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
          ),
        ),
      ],
      mainAxisSize: MainAxisSize.max,
    );
  }

  Future<void> _init() async {
    rootDirectory = DirectoryPickerData.of(context).rootDirectory;
    _setDirectory(rootDirectory);
  }

  Future<void> _setDirectory(Directory directory) async {
    setState(() {
      try {
        directoryList = directory.listSync()
          .map<Directory>((fse) => (fse is Directory ? fse : null))
          .toList()
          ..removeWhere((fse) => fse == null);
        currentDirectory = directory;
      } catch (e) {
        // Ignore when tried navigating to directory that does not exist
        // or to which user does not have permission to read
      }
    });
  }

  String _getDirectoryName(Directory directory) {
    return directory.path.split('/').last;
  }
}