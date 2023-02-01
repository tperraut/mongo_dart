import '../../command/command.dart';
import '../../session/client_session.dart';
import '../database.dart';

class MongoCollectionOpen extends MongoCollection {
  MongoCollectionOpen(super.db, super.collectionName) : super.protected();

  // Insert one document into this collection
  // Returns a WriteResult object
  @override
  Future<InsertOneDocumentRec> insertOne(MongoDocument document,
          {ClientSession? session, InsertOneOptions? insertOneOptions}) async =>
      InsertOneOperationOpen(this, document,
              insertOneOptions: insertOneOptions?.toOneOpen)
          .executeDocument(session: session);

  /// Insert many document into this collection
  /// Returns a BulkWriteResult object
  @override
  Future<InsertManyDocumentRec> insertMany(List<MongoDocument> documents,
          {ClientSession? session,
          InsertManyOptions? insertManyOptions}) async =>
      InsertManyOperationOpen(this, documents,
              insertManyOptions: insertManyOptions?.toManyOpen)
          .executeDocument(session: session);
}
