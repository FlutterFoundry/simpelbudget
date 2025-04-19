import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:simpelbudget/services/database_helpeer.dart';
import 'package:sqflite/sqflite.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _cutoffDay = 1;
  String _currency = 'USD';
  final List<String> _currencies = [
    'USD', 'IDR', 'EUR', 'GBP', 'JPY', 'CNY', 'AUD', 'CAD', 'INR',
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
    
    // Show confirmation
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Cutoff day set to $day')),
    // );
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
          title: Text('Set Cutoff Day'),
          subtitle: Text('Current cutoff day: $_cutoffDay'),
          onTap: () => _showCutoffDayPicker(context),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.attach_money),
          title: Text('Currency'),
          subtitle: Text('Current currency: $_currency'),
          onTap: () => _showCurrencyPicker(context),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('About'),
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
          title: Text('Clear All Data'),
          subtitle: Text('This action cannot be undone'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Clear All Data'),
                content: Text(
                    'Are you sure you want to delete all transactions? This action cannot be undone.'),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      // Delete database file
                      String path = join(
                          await getDatabasesPath(), DatabaseHelper.databaseName);
                      await deleteDatabase(path);
                      // Reinitialize database
                      await DatabaseHelper.instance.database;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('All data cleared')),
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
          title: Text('Set Cutoff Day'),
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
                  leading: day == _cutoffDay 
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
              child: Text('Cancel'),
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
          title: Text('Select Currency'),
          children: _currencies.map((c) {
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
