import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openJournalDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  await directory.create(recursive: true);
  return databaseFactoryIo.openDatabase(
    path.join(directory.path, 'adventure_journal.db'),
    version: 1,
  );
}
