import 'package:sembast_web/sembast_web.dart';

Future<Database> openJournalDatabase() =>
    databaseFactoryWeb.openDatabase('adventure_journal', version: 1);
