import 'package:mongo_dart/src/command/command.dart';

import '../../../../../unions/query_union.dart';
import '../../../update_operation/base/update_union.dart';

class ReplaceOneStatementOpen extends ReplaceOneStatement {
  ReplaceOneStatementOpen(QueryUnion q, UpdateUnion u,
      {super.upsert, super.collation, super.hint})
      : super.protected(q, u);
}