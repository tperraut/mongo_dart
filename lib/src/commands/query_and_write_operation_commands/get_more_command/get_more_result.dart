import 'package:mongo_dart/src/commands/base/cursor_result.dart';
import 'package:mongo_dart/src/commands/mixin/basic_result.dart';
import 'package:mongo_dart/src/commands/mixin/timing_result.dart';
import 'package:mongo_dart/src/utils/map_keys.dart';

class GetMoreResult with BasicResult, TimingResult {
  GetMoreResult(Map<String, Object?> document)
      : cursor =
            CursorResult(<String, Object>{...?(document[keyCursor] as Map?)}) {
    extractBasic(document);
    extractTiming(document);
  }

  CursorResult cursor;
}