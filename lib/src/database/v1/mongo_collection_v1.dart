import 'package:mongo_dart/src/utils/query_union.dart';

import '../../command/command.dart';
import '../../session/client_session.dart';
import '../database.dart';

class MongoCollectionV1 extends MongoCollection {
  MongoCollectionV1(super.db, super.collectionName) : super.protected();

  // Insert one document into this collection
  // Returns a WriteResult object
  @override
  Future<InsertOneDocumentRec> insertOne(MongoDocument document,
          {ClientSession? session, InsertOneOptions? insertOneOptions}) async =>
      InsertOneOperationV1(this, document,
              session: session, insertOneOptions: insertOneOptions?.toOneV1)
          .executeDocument();

  /// Insert many document into this collection
  /// Returns a BulkWriteResult object
  @override
  Future<InsertManyDocumentRec> insertMany(List<MongoDocument> documents,
          {ClientSession? session,
          InsertManyOptions? insertManyOptions}) async =>
      InsertManyOperationV1(this, documents,
              session: session, insertManyOptions: insertManyOptions?.toManyV1)
          .executeDocument();

  // Update one document into this collection
  @override
  Future<WriteResult> updateOne(q, update,
      {bool? upsert,
      WriteConcern? writeConcern,
      CollationOptions? collation,
      List<dynamic>? arrayFilters,
      String? hint,
      Map<String, Object>? hintDocument}) async {
    var updateOneOperation = UpdateOneOperation(
        this,
        UpdateOneStatement(QueryUnion(q), updateBuilder2Map(update),
            upsert: upsert,
            collation: collation,
            arrayFilters: arrayFilters,
            hint: hint,
            hintDocument: hintDocument),
        updateOneOptions: UpdateOneOptions(writeConcern: writeConcern));
    return updateOneOperation.executeDocument();
  }
}
