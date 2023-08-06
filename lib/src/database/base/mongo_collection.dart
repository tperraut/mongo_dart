import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart'
    hide
        QueryFilter,
        ProjectionDocument,
        MongoDocument,
        ArrayFilter,
        UpdateDocument;
import 'package:mongo_dart/src/command/base/operation_base.dart';
import 'package:mongo_dart/src/unions/hint_union.dart';
import 'package:mongo_dart/src/unions/query_union.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart';
import 'package:mongo_dart/src/unions/projection_union.dart';
import 'package:mongo_dart_query/mongo_query.dart';
import '../../command/query_and_write_operation_commands/wrapper/find_one_and_delete/base/find_one_and_delete_operation.dart';
import '../../command/query_and_write_operation_commands/wrapper/find_one_and_delete/base/find_one_and_delete_options.dart';
import '../../command/query_and_write_operation_commands/wrapper/find_one_and_replace/base/find_one_and_replace_operation.dart';
import '../../command/query_and_write_operation_commands/wrapper/find_one_and_replace/base/find_one_and_replace_options.dart';
import '../../command/query_and_write_operation_commands/wrapper/find_one_and_update/base/find_one_and_update_operation.dart';
import '../../command/query_and_write_operation_commands/wrapper/find_one_and_update/base/find_one_and_update_options.dart';
import '../../session/client_session.dart';
import '../../unions/sort_union.dart';
import '../../utils/parms_utils.dart';
import '../modern_cursor.dart';

abstract class MongoCollection {
  @protected
  MongoCollection.protected(this.db, this.collectionName);

  factory MongoCollection(MongoDatabase db, String collectionName) {
    // Todo if the serverApi will be available also by collection
    //      receive tha appropriate parameter ad use it instead of
    //      the one from the db class
    if (db.serverApi != null) {
      switch (db.serverApi!.version) {
        case ServerApiVersion.v1:

          /// Release 6.0 has a slight change
          if (db.server.serverCapabilities.maxWireVersion >= 17) {
            return MongoCollectionV117(db, collectionName);
          }
          return MongoCollectionV1(db, collectionName);
        default:
          throw MongoDartError(
              'Stable Api ${db.serverApi!.version} not managed');
      }
    }
    return MongoCollectionOpen(db, collectionName);
  }

  MongoDatabase db;
  String collectionName;
  ReadPreference? readPreference;

  String fullName() => '${db.databaseName}.$collectionName';

  /// Sets the readPreference at Collection level
  void setReadPref(ReadPreference? readPreference) =>
      this.readPreference = readPreference;

  /// At present it can be defined only at client level
  ServerApi? get serverApi => db.serverApi;

  /// returns true if a Strict Stable Api is required
  bool get isStrict => serverApi?.strict ?? false;

  /// Insert one document into this collection
  /// Returns a WriteResult object
  Future<InsertOneDocumentRec> insertOne(MongoDocument document,
      {ClientSession? session, InsertOneOptions? insertOneOptions});

  /// Insert many document into this collection
  /// Returns a BulkWriteResult object
  Future<InsertManyDocumentRec> insertMany(List<MongoDocument> documents,
      {ClientSession? session, InsertManyOptions? insertManyOptions});

  // TODO to be completed (document, let)
  // Update one document into this collection
  Future<UpdateOneDocumentRec> updateOne(filter, update,
      {bool? upsert,
      WriteConcern? writeConcern,
      CollationOptions? collation,
      List<dynamic>? arrayFilters,
      HintUnion? hint});

  // TODO to be completed (document, let)
  // Replace one document into this collection
  Future<ReplaceOneDocumentRec> replaceOne(filter, update,
      {bool? upsert,
      WriteConcern? writeConcern,
      CollationOptions? collation,
      HintUnion? hint});

  // TODO to be completed (document, let)?
  // Updates many documents into this collection
  Future<UpdateManyDocumentRec> updateMany(selector, update,
      {bool? upsert,
      WriteConcern? writeConcern,
      CollationOptions? collation,
      List<dynamic>? arrayFilters,
      HintUnion? hint});

  // Deletes one document into this collection
  Future<DeleteOneDocumentRec> deleteOne(selector,
      {WriteConcern? writeConcern,
      CollationOptions? collation,
      HintUnion? hint});

  // Deletes many documents into this collection
  Future<DeleteManyDocumentRec> deleteMany(selector,
      {WriteConcern? writeConcern,
      CollationOptions? collation,
      HintUnion? hint});

  Future<FindOneAndDeleteDocumentRec> findOneAndDelete(query,
      {ProjectionDocument? fields,
      sort,
      ClientSession? session,
      HintUnion? hint,
      FindOneAndDeleteOptions? findOneAndDeleteOptions,
      Options? rawOptions});

  Future<FindOneAndReplaceDocumentRec> findOneAndReplace(
      query, MongoDocument replacement,
      {ProjectionDocument? fields,
      sort,
      bool? upsert,
      bool? returnNew,
      ClientSession? session,
      HintUnion? hint,
      FindOneAndReplaceOptions? findOneAndReplaceOptions,
      Options? rawOptions});

  Future<FindOneAndUpdateDocumentRec> findOneAndUpdate(query, update,
      {ProjectionDocument? fields,
      sort,
      bool? upsert,
      bool? returnNew,
      List<ArrayFilter>? arrayFilters,
      ClientSession? session,
      HintUnion? hint,
      FindOneAndUpdateOptions? findOneAndUpdateOptions,
      Options? rawOptions});

  /// Returns one document that satisfies the specified query criteria on
  /// the collection or view. If multiple documents satisfy the query,
  /// this method returns the first document according to the sort order
  /// or the natural order of sort parameter is not specified.
  /// In capped collections, natural order is the same as insertion order.
  /// If no document satisfies the query, the method returns null.
  ///
  /// In MongoDb this method only allows the filter and the projection
  /// parameters.
  /// This version has more parameters, and it is essentially a wrapper
  /// araound the find method with a fixed limit set to 1 that returns
  /// a document instead of a stream.
  Future<Map<String, dynamic>?> findOne(dynamic filter,
      {dynamic projection,
      dynamic sort,
      int? skip,
      dynamic hint,
      FindOptions? findOptions,
      MongoDocument? rawOptions});

  /// Behaves like the find method, but allows to define a global
  /// query object containing all the specifications for the query
  Stream<Map<String, dynamic>> findQuery([QueryExpression? query]) {
    return find(query?.filter,
        projection: query?.fields,
        sort: query?.sortExp,
        skip: query?.getSkip(),
        limit: query?.getLimit());
  }

  /// Selects documents in a collection or view and returns a stream
  /// of the selected documents.
  Stream<Map<String, dynamic>> find(dynamic filter,
      {dynamic projection,
      dynamic sort,
      int? skip,
      int? limit,
      dynamic hint,
      FindOptions? findOptions,
      MongoDocument? rawOptions});

  // ****************************************************
  // ***********        OLD       ***********************
  // ****************************************************
/* 
  @Deprecated('Since version 4.2. Use insertOne() or replaceOne() instead.')
  Future<Map<String, dynamic>> save(Map<String, dynamic> document,
      {WriteConcern? writeConcern}) {
    dynamic id;
    var createId = false;
    if (document.containsKey('_id')) {
      id = document['_id'];
      if (id == null) {
        createId = true;
      }
    }
    if (id != null) {
      return legacyUpdate({'_id': id}, document,
          upsert: true, writeConcern: writeConcern);
    } else {
      if (createId) {
        document['_id'] = ObjectId();
      }
      return insert(document, writeConcern: writeConcern);
    }
  } */
/* 
  @Deprecated('No More Used')
  Future<Map<String, dynamic>> insertAll(List<Map<String, dynamic>> documents,
      {WriteConcern? writeConcern}) async {
    throw MongoDartError('To be deleted');
  } */
/* 
  /// Allows to insert many documents at a time.
  /// This is the legacy version of the insertMany() method
  @Deprecated('No More Used')
  Future<Map<String, dynamic>> legacyInsertAll(
      List<Map<String, dynamic>> documents,
      {WriteConcern? writeConcern}) {
    throw MongoDartError('No More Used');
  } */

  /// Modifies an existing document or documents in a collection.
  /// The method can modify specific fields of an existing document or
  /// documents or replace an existing document entirely,
  /// depending on the `document` parameter.
  ///
  /// By default, the `update()` method updates a single document.
  /// Include the option multiUpdate: true to update all documents that match
  /// the query criteria.
  /* Future<Map<String, dynamic>> update(selector, document,
      {bool upsert = false,
      bool multiUpdate = false,
      WriteConcern? writeConcern}) async {
    await modernUpdate(selector, document,
        upsert: upsert, multi: multiUpdate, writeConcern: writeConcern);
    // Todo change return type
    return {keyOk: 1.0};
  } */

  // Old version to be used on MongoDb versions prior to 3.6
  /*  @Deprecated('No More Used')
  Future<Map<String, dynamic>> legacyUpdate(selector, document,
      {bool upsert = false,
      bool multiUpdate = false,
      WriteConcern? writeConcern}) {
    throw MongoDartError('No More Used');
  } */

  /// Creates a cursor for a query that can be used to iterate over results
  /// from MongoDB
  /// ##[selector]
  /// parameter represents query to locate objects. If omitted as in `find()`
  /// then query matches all documents in colleciton.
  /// Here's a more selective example:
  ///     find({'last_name': 'Smith'})
  /// Here our selector will match every document where the last_name attribute
  /// is 'Smith.'
  @Deprecated('Use find() instead')
  Stream<MongoDocument> findOriginal([selector]) {
    if (selector is SelectorBuilder) {
      return modernFind(selector: selector);
    } else if (selector is MongoDocument) {
      return modernFind(filter: selector);
    } else if (selector == null) {
      return modernFind();
    }
    throw MongoDartError('The selector parameter should be either a '
        'SelectorBuilder or a Map<String, dynamic>');
  }

  /*  @Deprecated('No More Used')
  // Old version to be used on MongoDb versions prior to 3.6
  Stream<Map<String, dynamic>> legacyFind([selector]) =>
      throw MongoDartError('No More Used'); */

  // Old version to be used on MongoDb versions prior to 3.6
  /* @Deprecated('No More Used')
  ModernCursor createCursor([selector]) => throw MongoDartError('No More Used'); */

  /// Returns one document that satisfies the specified query criteria on the
  /// collection or view. If multiple documents satisfy the query,
  /// this method returns the first document.
  /*  Future<Map<String, dynamic>?> findOne([selector]) {
    if (selector is SelectorBuilder) {
      return modernFindOne(selector: selector);
    } else if (selector is Map<String, dynamic>) {
      return modernFindOne(filter: selector);
    } else if (selector == null) {
      return modernFindOne();
    }
    throw MongoDartError('The selector parameter should be either a '
        'SelectorBuilder or a Map<String, dynamic>');
  } */

  // Old version to be used on MongoDb versions prior to 3.6
  /*  @Deprecated('No More Used')
  Future<Map<String, dynamic>?> legacyFindOne([selector]) {
    throw MongoDartError('No More Used');
  } */

  // **************************************************
  //              Find and Modify
  // **************************************************

  /// Modifies and returns a single document.
  /// By default, the returned document does not include the modifications
  /// made on the update.
  /// To return the document with the modifications made on the update,
  /// use the returnNew option.
  /*  Future<MongoDocument?> findAndModify(
      {query,
      sort,
      bool? remove,
      update,
      bool? returnNew,
      fields,
      bool? upsert}) async {
    var (result,_) = await modernFindAndModify(
        query: query,
        sort: sort,
        remove: remove,
        update: update,
        returnNew: returnNew,
        fields: fields,
        upsert: upsert);
    return result.value;
  } */

  // Old version to be used on MongoDb versions prior to 3.6
  /*  @Deprecated('No More Used')
  Future<Map<String, dynamic>> legacyFindAndModify(
      {query,
      sort,
      bool? remove,
      update,
      bool? returnNew,
      fields,
      bool? upsert}) {
    throw MongoDartError('No More Used');
  } */

  // **************************************************
  //              Drop Collection
  // **************************************************

  Future<bool> drop() => db.dropCollection(collectionName);

  // **************************************************
  //            Delete Many (Remove)
  // **************************************************

  /// Removes documents from a collection.
  /* Future<Map<String, dynamic>> remove(selector,
      {WriteConcern? writeConcern}) async {
    var result = await deleteMany(
      selector,
      writeConcern: writeConcern,
    );
    return result.serverResponses.first;
  } */

  // Old version to be used on MongoDb versions prior to 3.6
/*   @Deprecated('No More Used')
  Future<Map<String, dynamic>> legacyRemove(selector,
          {WriteConcern? writeConcern}) =>
      db.removeFromCollection(
          collectionName, selectorBuilder2Map(selector), writeConcern); */

  // **************************************************
  //                   Count
  // **************************************************

  Future<int> count([selector]) async {
    var result = await modernCount(
        selector: selector is SelectorBuilder ? selector : null,
        filter: selector is Map<String, dynamic> ? selector : null);
    return result.count;
  }

  // Todo - missing modern version
  @Deprecated('No More Used')
  Future<int> legacyCount([selector]) {
    throw MongoDartError('No More Used');
  }

  // **************************************************
  //                   Distinct
  // **************************************************

  Future<Map<String, dynamic>> distinct(String field, [selector]) async {
    return modernDistinctMap(field, query: selector);
  }

  /// Old version to be used on MongoDb versions prior to 3.6
  @Deprecated('No More Used')
  Future<Map<String, dynamic>> legacyDistinct(String field, [selector]) async =>
      throw MongoDartError('No More Used');

  /// Old version to be used on MongoDb versions prior to 3.6
  @Deprecated('No More Used')
  Future<Map<String, dynamic>> aggregate(List pipeline,
      {bool allowDiskUse = false, Map<String, Object>? cursor}) {
    throw MongoDartError('No More Used');
  }

  /// Executes an aggregation pipeline
  Stream<Map<String, dynamic>> aggregateToStream(
      List<Map<String, Object>> pipeline,
      {Map<String, Object> cursorOptions = const <String, Object>{},
      bool allowDiskUse = false}) {
    return modernAggregate(pipeline,
        cursor: cursorOptions,
        aggregateOptions: AggregateOptions(allowDiskUse: allowDiskUse));
  }

  /// Old version to be used on MongoDb versions prior to 3.6
  @Deprecated('No More Used')
  Stream<Map<String, dynamic>> legacyAggregateToStream(List pipeline,
      {Map<String, dynamic> cursorOptions = const {},
      bool allowDiskUse = false}) {
    throw MongoDartError('No More Used');
  }

/*   /// Inserts a document into a collection
  Future<Map<String, dynamic>> insert(Map<String, dynamic> document,
      {WriteConcern? writeConcern}) async {
    await insertOne(document,
        insertOneOptions: InsertOneOptions(writeConcern: writeConcern));
    // Todo change return type
    return {keyOk: 1.0};
  } */
/* 
  /// Old version to be used on MongoDb versions prior to 3.6
  @Deprecated('No More Used')
  Future<Map<String, dynamic>> legacyInsert(Map<String, dynamic> document,
          {WriteConcern? writeConcern}) =>
      insertAll([document], writeConcern: writeConcern);
*/
  /// Analogue of mongodb shell method `db.collection.getIndexes()`
  /// Returns an array that holds a list of documents that identify and describe
  /// the existing indexes on the collection. You must call `getIndexes()`
  ///  on a collection
  Future<List<Map<String, dynamic>>> getIndexes() {
    return listIndexes().toList();
  }

  Map<String, dynamic> _setKeys(String? key, Map<String, dynamic>? keys) {
    if (key != null && keys != null) {
      throw ArgumentError('Only one parameter must be set: key or keys');
    }

    if (key != null) {
      keys = {};
      keys[key] = 1;
    }

    if (keys == null) {
      throw ArgumentError('key or keys parameter must be set');
    }

    return keys;
  }

  @Deprecated('Use QueryUnionInstead')
  Map<String, dynamic> selectorBuilder2Map(selector) {
    if (selector == null) {
      return <String, dynamic>{};
    }
    if (selector is SelectorBuilder) {
      return selector.map[key$Query] as Map<String, dynamic>? ??
          <String, dynamic>{};
    }
    return <String, dynamic>{...?(selector as Map?)};
  }

  @Deprecated('Use QueryUnionInstead')
  Map<String, dynamic> queryBuilder2Map(Object query) {
    if (query is SelectorBuilder) {
      query = query.map['\$query'];
    }
    return query as Map<String, dynamic>;
  }

/* 
  Map<String, Object> _sortBuilder2Map(query) {
    if (query is SelectorBuilder) {
      query = query.map['orderby'];
    }
    return query as Map<String, Object>;
  }
 */
  Map<String, dynamic>? fieldsBuilder2Map(fields) {
    if (fields is SelectorBuilder) {
      return fields.paramFields;
    }
    return fields as Map<String, dynamic>?;
  }

  UpdateDocument updateBuilder2Map(update) {
    if (update is ModifierBuilder) {
      update = update.map;
    }
    return update as UpdateDocument;
  }

  // ****************************************************************+
  // ******************** OP_MSG_COMMANDS ****************************
  // *****************************************************************
  // All the following methods are available starting from release 3.6
  // *****************************************************************

  /// This function is provided for all servers starting from version 3.6
  /// For previous releases use the same method on Db class.
  ///
  /// The modernReply flag allows the caller to receive the result of
  /// the command without a call to getLastError().
  /// As the format is different from the getLastError() one, for compatibility
  /// reasons, if you specify false, the old format is returned
  /// (but one more getLastError() is performed).
  /// Example of the new format:
  /// {createdCollectionAutomatically: false,
  /// numIndexesBefore: 2,
  /// numIndexesAfter: 3,
  /// ok: 1.0}
  ///
  /// Example of the old format:
  /// {"connectionId" -> 11,
  /// "n" -> 0,
  /// "syncMillis" -> 0,
  /// "writtenTo" -> null,
  /// "err" -> null,
  /// "ok" -> 1.0}
  Future<Map<String, dynamic>> createIndex(
      {ClientSession? session,
      String? key,
      Map<String, dynamic>? keys,
      bool? unique,
      bool? sparse,
      bool? background,
      bool? dropDups,
      Map<String, dynamic>? partialFilterExpression,
      String? name}) async {
    var indexOptions = CreateIndexOptions(this,
        uniqueIndex: unique == true,
        sparseIndex: sparse == true,
        background: background == true,
        dropDuplicatedEntries: dropDups == true,
        partialFilterExpression: partialFilterExpression,
        indexName: name);

    var indexOperation = CreateIndexOperation(
        db, this, _setKeys(key, keys), indexOptions,
        session: session);

    var res = await indexOperation.process();
    if (res[keyOk] == 0.0) {
      // It should be better to create a MongoDartError,
      // but, for compatibility reasons, we throw the received map.
      throw res;
    }

    return res;
  }

  Stream<Map<String, dynamic>> listIndexes(
      {int? batchSize, String? comment, Map<String, Object>? rawOptions}) {
    var indexOptions =
        ListIndexesOptions(batchSize: batchSize, comment: comment);

    var command = ListIndexesCommand(db, this,
        listIndexesOptions: indexOptions, rawOptions: rawOptions);

    return ModernCursor(command, db.server).stream;
  }

  Future<Map<String, dynamic>> dropIndexes(Object index,
      {ClientSession? session,
      WriteConcern? writeConcern,
      String? comment,
      Map<String, Object>? rawOptions}) {
    var indexOptions =
        DropIndexesOptions(writeConcern: writeConcern, comment: comment);

    var command = DropIndexesCommand(db, this, index,
        dropIndexesOptions: indexOptions,
        rawOptions: rawOptions,
        session: session);

    return command.process();
  }

/* 
  Future<Map<String, dynamic>> modernUpdate(selector, update,
      {ClientSession? session,
      bool? upsert,
      bool? multi,
      WriteConcern? writeConcern,
      CollationOptions? collation,
      List<dynamic>? arrayFilters,
      HintUnion? hint}) async {
    var updateOperation = UpdateOperation(
        this,
        [
          UpdateStatement(QueryUnion(selector), UpdateUnion(update),
              upsert: upsert,
              multi: multi,
              collation: collation,
              arrayFilters: arrayFilters,
              hint: hint)
        ],
        updateOptions: UpdateOptions(writeConcern: writeConcern));
    return updateOperation.process();
  } */

  // Find operation with the new OP_MSG (starting from release 3.6)
  @Deprecated('Use find instead')
  Stream<Map<String, dynamic>> modernFind(
      {SelectorBuilder? selector,
      QueryFilter? filter,
      Map<String, Object>? sort,
      ProjectionDocument? projection,
      HintUnion? hint,
      int? skip,
      int? limit,
      FindOptions? findOptions,
      Map<String, Object>? rawOptions}) {
    var sortMap = sort;
    if (sortMap == null && selector?.map[keyOrderby] != null) {
      sortMap = <String, Object>{...selector!.map[keyOrderby]};
    }

    var operation = FindOperation(this, QueryUnion(filter),
        sort: SortUnion(sortMap),
        projection: ProjectionUnion(projection ?? selector?.paramFields),
        hint: hint,
        limit: limit ?? selector?.paramLimit,
        skip: skip ??
            (selector != null && selector.paramSkip > 0
                ? selector.paramSkip
                : null),
        findOptions: findOptions,
        rawOptions: rawOptions);

    return ModernCursor(operation, db.server).stream;
  }

  /// Returns one document that satisfies the specified query criteria on
  /// the collection or view. If multiple documents satisfy the query,
  /// this method returns the first document according to the sort order
  /// or the natural order of sort parameter is not specified.
  /// In capped collections, natural order is the same as insertion order.
  /// If no document satisfies the query, the method returns null.
  ///
  /// In MongoDb this method only allows the filter and the projection
  /// parameters.
  /// This version has more parameters, and it is essentially a wrapper
  /// araound the find method with a fixed limit set to 1 that returns
  /// a document instead of a stream.
  /*  Future<Map<String, dynamic>?> modernFindOne(
      {SelectorBuilder? selector,
      Map<String, dynamic>? filter,
      Map<String, Object>? sort,
      Map<String, Object>? projection,
      HintUnion? hint,
      int? skip,
      FindOptions? findOptions,
      Map<String, Object>? rawOptions}) async {
    var sortMap = sort;
    if (sortMap == null && selector?.map[keyOrderby] != null) {
      sortMap = <String, Object>{...selector!.map[keyOrderby]};
    }
    var operation = FindOperation(this, QueryUnion(filter),
        sort: sortMap,
        projection: projection ?? selector?.paramFields,
        hint: hint,
        limit: 1,
        skip: skip ??
            (selector != null && selector.paramSkip > 0
                ? selector.paramSkip
                : null),
        findOptions: findOptions,
        rawOptions: rawOptions);

    return ModernCursor(operation, db.server).nextObject();
  } */

  /// Utility method for preparing a DistinctOperation
  DistinctOperation _prepareDistinct(String field,
          {query,
          DistinctOptions? distinctOptions,
          Map<String, Object>? rawOptions}) =>
      DistinctOperation(this, field,
          query: extractfilterMap(query),
          distinctOptions: distinctOptions,
          rawOptions: rawOptions);

  /// Executes a Distinct command on this collection.
  /// Retuns a DistinctResult class.
  Future<DistinctResult> modernDistinct(String field,
          {ClientSession? session,
          query,
          DistinctOptions? distinctOptions,
          Map<String, Object>? rawOptions}) async =>
      _prepareDistinct(field, query: query, distinctOptions: distinctOptions)
          .executeDocument(session: session);

  /// Executes a Distinct command on this collection.
  /// Retuns a Map like received from the server.
  /// Used for compatibility with the legacy method
  Future<Map<String, dynamic>> modernDistinctMap(String field,
          {ClientSession? session,
          query,
          DistinctOptions? distinctOptions,
          Map<String, Object>? rawOptions}) async =>
      _prepareDistinct(field, query: query, distinctOptions: distinctOptions)
          .process();

  /// This method returns a stream that can be read or transformed into
  /// a list with `.toList()`
  ///
  /// It corresponds to the legacy method `aggregateToStream()`.
  ///
  /// The pipeline can be either an `AggregationPipelineBuilder` or a
  /// List of Maps (`List<Map<String, Object>>`)
  Stream<Map<String, dynamic>> modernAggregate(dynamic pipeline,
          {bool? explain,
          Map<String, Object>? cursor,
          HintUnion? hint,
          AggregateOptions? aggregateOptions,
          Map<String, Object>? rawOptions}) =>
      modernAggregateCursor(pipeline,
              explain: explain,
              cursor: cursor,
              hint: hint,
              aggregateOptions: aggregateOptions,
              rawOptions: rawOptions)
          .stream;

  /// This method returns a curosr that can be read or transformed into
  /// a stream with `stream` (for a stream you can directly call
  /// `modernAggregate`)
  ///
  /// It corresponds to the legacy method `aggregate()`
  ///
  /// The pipeline can be either an `AggregationPipelineBuilder` or a
  /// List of Maps (`List<Map<String, Object>>`)
  ModernCursor modernAggregateCursor(dynamic pipeline,
      {bool? explain,
      Map<String, Object>? cursor,
      HintUnion? hint,
      AggregateOptions? aggregateOptions,
      Map<String, Object>? rawOptions}) {
    return ModernCursor(
        AggregateOperation(pipeline,
            collection: this,
            explain: explain,
            cursor: cursor,
            hint: hint,
            aggregateOptions: aggregateOptions,
            rawOptions: rawOptions),
        db.server);
  }

  Stream watch(Object pipeline,
          {int? batchSize,
          HintUnion? hint,
          ChangeStreamOptions? changeStreamOptions,
          Map<String, Object>? rawOptions}) =>
      watchCursor(pipeline,
              batchSize: batchSize,
              hint: hint,
              changeStreamOptions: changeStreamOptions,
              rawOptions: rawOptions)
          .changeStream;

  ModernCursor watchCursor(Object pipeline,
          {int? batchSize,
          HintUnion? hint,
          ChangeStreamOptions? changeStreamOptions,
          Map<String, Object>? rawOptions}) =>
      ModernCursor(
          ChangeStreamOperation(pipeline,
              collection: this,
              hint: hint,
              changeStreamOptions: changeStreamOptions,
              rawOptions: rawOptions),
          db.server);

  Future<BulkWriteResult> bulkWrite(List<Map<String, Object>> documents,
      {bool ordered = true, WriteConcern? writeConcern}) async {
    Bulk bulk;
    if (ordered) {
      bulk = OrderedBulk(this, writeConcern: writeConcern);
    } else {
      bulk = UnorderedBulk(this, writeConcern: writeConcern);
    }
    var index = -1;
    for (var document in documents) {
      index++;
      if (document.isEmpty) {
        continue;
      }
      var key = document.keys.first;
      var testMap = document[key];
      if (testMap is! Map<String, Object>) {
        throw MongoDartError('The "$key" element at index '
            '$index must contain a Map');
      }
      var docMap = testMap;

      switch (key) {
        case bulkInsertOne:
          if (docMap[bulkDocument] is! Map<String, dynamic>) {
            throw MongoDartError('The "$bulkDocument" key of the '
                '"$bulkInsertOne" element at index $index must '
                'contain a Map');
          }
          bulk.insertOne(docMap[bulkDocument] as Map<String, dynamic>);

          break;
        case bulkInsertMany:
          if (docMap[bulkDocuments] is! List<Map<String, dynamic>>) {
            throw MongoDartError('The "$bulkDocuments" key of the '
                '"$bulkInsertMany" element at index $index must '
                'contain a List of Maps');
          }
          bulk.insertMany(docMap[bulkDocuments] as List<Map<String, dynamic>>);
          break;
        case bulkUpdateOne:
          bulk.updateOneFromMap(docMap, index: index);
          break;
        case bulkUpdateMany:
          bulk.updateManyFromMap(docMap, index: index);
          break;
        case bulkReplaceOne:
          bulk.replaceOneFromMap(docMap, index: index);
          break;
        case bulkDeleteOne:
          bulk.deleteOneFromMap(docMap, index: index);
          break;
        case bulkDeleteMany:
          bulk.deleteManyFromMap(docMap, index: index);
          break;
        default:
          throw StateError('The operation "$key" is not allowed in bulkWrite');
      }
    }

    return bulk.executeDocument(db.server);
  }

  Future<CountResult> modernCount(
      {SelectorBuilder? selector,
      Map<String, dynamic>? filter,
      int? limit,
      int? skip,
      CollationOptions? collation,
      HintUnion? hint,
      CountOptions? countOptions,
      Map<String, Object>? rawOptions}) async {
    var countOperation = CountOperation(this,
        query:
            filter ?? (selector?.map == null ? null : selector!.map[key$Query]),
        skip: skip,
        limit: limit,
        hint: hint,
        countOptions: countOptions,
        rawOptions: rawOptions);
    return countOperation.executeDocument(db.server);
  }
}