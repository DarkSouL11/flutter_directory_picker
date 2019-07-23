library directory_picker;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'directory_list.dart';

class DirectoryPicker {
  /// Opens a dialog to allow user to pick a directory.
  ///
  /// If [message] is non null then it is rendered when user denies to give
  /// external storage permission. A default message will be used if [message]
  /// is not specified. [rootDirectory] is the initial directory whose
  /// sub directories are shown for picking
  ///
  /// If [allowFolderCreation] is true then user will be allowed to create
  /// new folders directly from the picker. Make sure that you add write
  /// permission to manifest if you want to support folder creationa
  static Future<Directory> pick(
      {bool allowFolderCreation = false,
      @required BuildContext context,
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
                allowFolderCreation: allowFolderCreation,
                backgroundColor: backgroundColor,
                child: _DirectoryPickerDialog(),
                message: message,
                rootDirectory: rootDirectory,
                shape: shape);
          });

      return directory;
    } else {
      throw UnsupportedError('DirectoryPicker is only supported on android!');
    }
  }
}

class DirectoryPickerData extends InheritedWidget {
  final bool allowFolderCreation;
  final Color backgroundColor;
  final String message;
  final Directory rootDirectory;
  final ShapeBorder shape;

  DirectoryPickerData(
      {Widget child,
      this.allowFolderCreation,
      this.backgroundColor,
      this.message,
      this.rootDirectory,
      this.shape})
      : super(child: child);

  static DirectoryPickerData of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DirectoryPickerData);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

enum _PickerPermissionStatus {
  authorized, // Given all required permissions
  canPrompt, // Can prompt for missing permissions
  grantFromSettings, // One or more permissions should be given from settings
  restricted // one or more permissions cannot be granted in any way
}

class _DirectoryPickerDialog extends StatefulWidget {
  @override
  _DirectoryPickerDialogState createState() => _DirectoryPickerDialogState();
}

class _DirectoryPickerDialogState extends State<_DirectoryPickerDialog>
    with WidgetsBindingObserver {
  static final double spacing = 8;

  List<PermissionStatus> statuses;
  bool checkingForPermission = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero).then((_) => _getPermissionStatus());
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
    Iterable<Future<PermissionStatus>> futures =
        requiredPermissions.map((permission) {
      return SimplePermissions.getPermissionStatus(permission);
    });
    final newStatuses = await Future.wait(futures);

    setState(() {
      statuses = newStatuses;
    });

    if (!silent && status == _PickerPermissionStatus.canPrompt) {
      _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    if (status == _PickerPermissionStatus.canPrompt) {
      Iterable<Future> futures = requiredPermissions.map((permission) {
        return SimplePermissions.requestPermission(permission);
      });
      final newStatuses = await Future.wait(futures);

      setState(() {
        statuses = newStatuses;
      });
    } else if (status == _PickerPermissionStatus.grantFromSettings) {
      await SimplePermissions.openSettings();
    }
  }

  Widget _buildBody(BuildContext context) {
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
    } else if (status == _PickerPermissionStatus.authorized) {
      return DirectoryList();
    } else if (status == _PickerPermissionStatus.restricted) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: data.backgroundColor,
      child: _buildBody(context),
      shape: data.shape,
    );
  }

  List<Permission> get requiredPermissions {
    List<Permission> permissions = [Permission.ReadExternalStorage];
    if (data.allowFolderCreation) {
      permissions.add(Permission.WriteExternalStorage);
    }
    return permissions;
  }

  DirectoryPickerData get data => DirectoryPickerData.of(context);

  String get message {
    if (data.message == null) {
      return 'App needs read access to your device storage to load directories';
    } else {
      return data.message;
    }
  }

  _PickerPermissionStatus get status {
    if (statuses == null) {
      return null;
    } else if (statuses
        .every((status) => status == PermissionStatus.authorized)) {
      return _PickerPermissionStatus.authorized;
    } else if (statuses.contains(PermissionStatus.restricted)) {
      return _PickerPermissionStatus.restricted;
    } else if (statuses.contains(PermissionStatus.deniedNeverAsk)) {
      return _PickerPermissionStatus.grantFromSettings;
    } else {
      return _PickerPermissionStatus.canPrompt;
    }
  }
}
