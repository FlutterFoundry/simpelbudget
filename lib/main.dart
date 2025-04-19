import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:simpelbudget/pages/dashboard.dart';
import 'package:simpelbudget/pages/settings.dart';
import 'package:simpelbudget/pages/transaction_add.dart';
import 'package:simpelbudget/pages/transaction_list.dart';
import 'package:simpelbudget/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await DatabaseHelper.instance.database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

// Home page with tabs
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        bottom: TabBar(
          controller: _tabController,
        tabs: [
            Tab(icon: Icon(Icons.dashboard), text: AppLocalizations.of(context)!.dashboard),
            Tab(icon: Icon(Icons.list), text: AppLocalizations.of(context)!.transactions),
            Tab(icon: Icon(Icons.settings), text: AppLocalizations.of(context)!.settings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [DashboardPage(), TransactionsPage(), SettingsPage()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionPage()),
          ).then((_) {
            setState(() {});
          });
        },
        tooltip: AppLocalizations.of(context)!.addTransaction,
        child: Icon(Icons.add),
      ),
    );
  }
}
