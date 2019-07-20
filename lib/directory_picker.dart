library directory_picker;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'directory_list.dart';

class DirectoryPicker {
  /// Opens a dialog to allow user to pick a directory.
  ///
  /// if [message] is non null then it is rendered when user denies to give
  /// external storage permission. A default message will be used if [message]
  /// is not specified. [rootDirectory] is the initial directory whose
  /// sub directories are shown for picking
  static Future<Directory> pick(
      {@required BuildContext context,
      bool barrierDismissible = true,
      Color backgroundColor,
      @required Directory rootDirectory,
      String message,
      ShapeBorder shape}) async {
    assert(context != null, 'A non null context is required');

    if (Platform.isAndroid) {
      Directory directory = await showDialog<Directory>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (BuildContext context) {
            return DirectoryPickerData(
              child: Dialog(
                  backgroundColor: backgroundColor,
                  child: _DirectoryPickerDialog(),
                  shape: shape),
              message: message,
              rootDirectory: rootDirectory,
            );
          });

      return directory;
    } else {
      throw UnsupportedError('DirectoryPicker is only supported on android!');
    }
  }
}

class DirectoryPickerData extends InheritedWidget {
  final String message;
  final Directory rootDirectory;

  DirectoryPickerData({Widget child, this.message, this.rootDirectory})
      : super(child: child);

  static DirectoryPickerData of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DirectoryPickerData);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

class _DirectoryPickerDialog extends StatefulWidget {
  @override
  _DirectoryPickerDialogState createState() => _DirectoryPickerDialogState();
}

class _DirectoryPickerDialogState extends State<_DirectoryPickerDialog>
    with WidgetsBindingObserver {
  static final double spacing = 8;

  PermissionStatus status;
  bool checkingForPermission = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _getPermissionStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getPermissionStatus(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  /// If silent is true then below function will not try to request permission
  /// if permission is not granter
  Future<void> _getPermissionStatus({bool silent = false}) async {
    final newStatus = await SimplePermissions.getPermissionStatus(
        Permission.ReadExternalStorage);

    print(newStatus);
    setState(() {
      status = newStatus;
    });

    if (!silent && canAskPermission) {
      _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    if (status == PermissionStatus.notDetermined ||
        status == PermissionStatus.denied) {
      final newStatus = await SimplePermissions.requestPermission(
          Permission.ReadExternalStorage);

      setState(() {
        status = newStatus;
      });
    }

    if (status == PermissionStatus.deniedNeverAsk) {
      await SimplePermissions.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (status == null) {
      return Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Column(
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: spacing),
              Text('Checking permission', textAlign: TextAlign.center)
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
          ));
    } else if (status == PermissionStatus.authorized) {
      return DirectoryList();
    } else if (status == PermissionStatus.restricted) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Text(
            'App is restricted from accessing your device storage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Column(
            children: <Widget>[
              Text(message, textAlign: TextAlign.center),
              SizedBox(height: spacing),
              RaisedButton(
                  child: Text('Grant Permission'),
                  color: theme.primaryColor,
                  onPressed: _requestPermission)
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
          ));
    }
  }

  bool get canAskPermission {
    return [PermissionStatus.denied, PermissionStatus.notDetermined]
        .contains(status);
  }

  String get message {
    DirectoryPickerData data = DirectoryPickerData.of(context);
    if (data.message == null) {
      return 'App needs read access to your device storage to load directories';
    } else {
      return data.message;
    }
  }
}
