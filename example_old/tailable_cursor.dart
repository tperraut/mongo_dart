import 'dart:async';

import 'package:mongo_dart/src/mongo_client.dart';

//////// I guess tailable cursor does not work in that example
/// NJ: it works for me provide the collection is not empty...
void main() async {
  var client = MongoClient('mongodb://127.0.0.1/test');
  await client.connect();
  var db = client.db();
  var i = 0;
  await db.collection('log').insertOne({'index': i});
  Timer.periodic(Duration(seconds: 10), (Timer t) async {
    i++;
    print('Insert $i');
    await db.collection('log').insertOne({'index': i});
    if (i == 10) {
      print('Stop inserting');
      t.cancel();
    }
  });
  // Todo to be checked
  /* var oplog = DbCollection(db, 'log');
  var cursor = oplog.createCursor()
    ..tailable = true
    ..timeout = false
    ..awaitData = false;
  while (true) {
    var doc = await cursor.nextObject();
    if (doc == null) {
      print('.');
      await Future.delayed(Duration(seconds: 1), () => null);
    } else {
      print('Fetched: $doc');
    }
  } */
}
