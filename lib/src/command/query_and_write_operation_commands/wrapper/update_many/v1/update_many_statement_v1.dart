import 'package:mongo_dart/src/command/command.dart';

import '../../../../../unions/query_union.dart';
import '../../../update_operation/base/update_union.dart';

class UpdateManyStatementV1 extends UpdateManyStatement {
  UpdateManyStatementV1(QueryUnion q, UpdateUnion u,
      {super.upsert, super.collation, super.arrayFilters, super.hint})
      : super.protected(q, u);
}