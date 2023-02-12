import 'package:mongo_dart/src/command/command.dart';

import '../../../../../database/database.dart';
import '../../../../../utils/query_union.dart';

class UpdateOneStatementOpen extends UpdateOneStatement {
  UpdateOneStatementOpen(QueryUnion q, UpdateDocument u,
      {super.upsert,
      super.collation,
      super.arrayFilters,
      super.hint,
      super.hintDocument})
      : super.protected(q, u);
}
