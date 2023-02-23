import 'package:mongo_dart/mongo_dart_old.dart';
import 'package:mongo_dart/src/mongo_client.dart';

const dbName = 'mongo-dart-example';
const dbAddress = '127.0.0.1';

const defaultUri = 'mongodb://$dbAddress:27017/$dbName';

void main() async {
  var client = MongoClient(defaultUri);
  await client.connect();
  var db = client.db();
  Future cleanupDatabase() async {
    await client.close();
  }

  var collectionName = 'find-modify-return-new';
  await db.dropCollection(collectionName);
  var collection = db.collection(collectionName);

  var (ret,_,_,_) = await collection.insertMany(<Map<String, dynamic>>[
    {'_id': 1, 'name': 'Tom', 'state': 'active', 'rating': 100, 'score': 5},
    {'_id': 2, 'name': 'William', 'state': 'busy', 'rating': 80, 'score': 4},
    {'_id': 3, 'name': 'Liz', 'state': 'on hold', 'rating': 70, 'score': 8},
    {'_id': 4, 'name': 'George', 'state': 'active', 'rating': 95, 'score': 8},
    {'_id': 5, 'name': 'Jim', 'state': 'idle', 'rating': 40, 'score': 3},
    {'_id': 6, 'name': 'Laureen', 'state': 'busy', 'rating': 87, 'score': 8},
    {'_id': 7, 'name': 'John', 'state': 'idle', 'rating': 72, 'score': 7}
  ]);

  if (!ret.isSuccess) {
    print('Error detected in record insertion');
  }

  var (res, _) = await collection.findAndModify(
      query: where
          .eq('name', 'Tom')
          .eq('state', 'active')
          .eq('rating', {r'$gt': 10}),
      sort: <String, dynamic>{'rating': 1},
      update: ModifierBuilder().inc('score', 1),
      returnNew: true);

  print('Updated document: ${res.lastErrorObject?.updatedExisting}'); // true

  print('Modified element new score: ${res.value?['score']}'); // 6;

  await cleanupDatabase();
}
