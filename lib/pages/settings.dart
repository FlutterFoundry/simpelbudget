import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:simpelbudget/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _cutoffDay = 1;
  String _currency = 'USD';
  final List<String> _currencies = [
    'USD',
    'IDR',
    'EUR',
    'GBP',
    'JPY',
    'CNY',
    'AUD',
    'CAD',
    'INR',
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getSettings();
    setState(() {
      _cutoffDay = int.tryParse(settings['cutoff_day'] ?? '1') ?? 1;
      _currency = settings['currency'] ?? 'USD';
      _isLoading = false;
    });
  }

  Future<void> _saveCutoffDay(int day) async {
    await DatabaseHelper.instance.saveSettings({'cutoff_day': day.toString()});
    setState(() {
      _cutoffDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text(AppLocalizations.of(context)!.setCutoffDay),
          subtitle: Text(AppLocalizations.of(context)!.cutoffDay(_cutoffDay)),
          onTap: () => _showCutoffDayPicker(context),
        ),
        Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.currency),
          subtitle: Text(
            AppLocalizations.of(context)!.currentCurrency(_currency),
          ),
          onTap: () => _showCurrencyPicker(context),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info),
          title: Text(AppLocalizations.of(context)!.about),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Budget Tracker',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2025',
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_forever),
          title: Text(AppLocalizations.of(context)!.clearAllData),
          subtitle: Text(AppLocalizations.of(context)!.confirmClearAllData),
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.clearAllData),
                    content: Text(
                      AppLocalizations.of(context)!.confirmClearAllData,
                    ),
                    actions: [
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.cancel),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          String path = join(
                            await getDatabasesPath(),
                            DatabaseHelper.databaseName,
                          );
                          await deleteDatabase(path);
                          await DatabaseHelper.instance.database;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.allDataCleared,
                              ),
                            ),
                          );
                        },
                        child: Text('Delete All'),
                      ),
                    ],
                  ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showCutoffDayPicker(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.setCutoffDay),
          content: SizedBox(
            height: 300,
            width: 300,
            child: ListView.builder(
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                return ListTile(
                  title: Text('$day'),
                  selected: day == _cutoffDay,
                  leading:
                      day == _cutoffDay
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.calendar_today),
                  onTap: () {
                    _saveCutoffDay(day);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context)!.selectCurrency),
          children:
              _currencies.map((c) {
                return SimpleDialogOption(
                  child: Text(c),
                  onPressed: () => Navigator.pop(context, c),
                );
              }).toList(),
        );
      },
    );
    if (selected != null && selected != _currency) {
      await DatabaseHelper.instance.saveSettings({'currency': selected});
      setState(() {
        _currency = selected;
      });
    }
  }
}
