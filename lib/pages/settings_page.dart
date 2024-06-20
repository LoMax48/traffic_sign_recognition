import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_traffic_signs/constants.dart';
import 'package:flutter_traffic_signs/models/settings_model.dart';
import 'package:flutter_traffic_signs/services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future? _loadPage;
  final StorageService _storageService = StorageService();
  SettingsModel? _settings;

  @override
  void initState() {
    super.initState();
    _loadPage = _getData();
  }

  @override
  void dispose() {
    if (_settings != null) {
      _storageService.setString(
        Constants.dataKey,
        jsonEncode(_settings!.toJson()),
      );
    }
    super.dispose();
  }

  Future<void> _getData() async {
    var data = await _storageService.getString(Constants.dataKey);
    if (data == null) {
      setState(() {
        _settings = SettingsModel(signs: Constants.signs);
      });
    } else {
      var jsonData = jsonDecode(data);
      setState(() {
        _settings = SettingsModel.fromJson(jsonData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: _loadPage,
        builder: (context, snapshot) {
          return _settings != null
              ? ReorderableListView(
                  children: <Widget>[
                    for (int index = 0;
                        index < _settings!.signs.length;
                        index += 1)
                      ListTile(
                        key: Key(_settings!.signs[index].fileName),
                        tileColor: index % 2 == 0
                            ? colorScheme.primary.withOpacity(0.05)
                            : colorScheme.primary.withOpacity(0.15),
                        title: Text(_settings!.signs[index].name),
                      ),
                  ],
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      var item = _settings!.signs.removeAt(oldIndex);
                      _settings!.signs.insert(newIndex, item);
                    });
                  },
                )
              : const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
