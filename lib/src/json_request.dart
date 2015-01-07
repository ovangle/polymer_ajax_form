library ajax_form.json_request;

import 'dart:async';
import 'dart:html';

import 'package:crypto/crypto.dart' show CryptoUtils;
import 'package:quiver/async.dart' show forEachAsync;

import 'form_field.dart';
import 'base_request.dart';

import 'utils.dart';

class JsonRequest extends BaseRequest {
  Iterable<FormField> fields;
  JsonRequest(Iterable<FormField> this.fields);

  Future<dynamic> getFieldValue(FormField field) {
    if (field.isFile) {
      var json = <dynamic>[];
      return forEachAsync(field.value, (File file) {
        return readFile(file).then((body) {
          json.add({
            'name': file.name,
            'type': file.type,
            'body': CryptoUtils.bytesToBase64(body)
          });
        });
      }).then((_) => json);
    } else {
      return new Future.value().then((_) => field.value);
    }
  }
  @override
  Future<String> getBody() {
    var result = <String,dynamic>{};
    return forEachAsync(fields, (field) {
      var step = Step.parseSafe(field.name);
      return getFieldValue(field).then((value) {
        step.setValue(result, value);
      });
    }).then((_) => result);
  }

  @override
  Map<String, String> get headers {
    var headers = <String,String>{};
    headers['content-type'] = 'application/json';
    return headers;
  }
}


abstract class Step {
  static final _INIT_STEP = new RegExp(r'([^[]+)');
  static final _APPEND_STEP = new RegExp(r'\[\]');
  static final _INDEX_STEP = new RegExp(r'\[(\d+)\]');
  static final _OBJECT_STEP = new RegExp(r'\[(.*?)\]');

  static Step parseSafe(String path) {
    try {
      return parse(path);
    } on FormatException {
      //TODO: Log exception
      return new ObjectStep(path);
    }
  }

  static Step parse(String path) {
    var initStep = null;
    var match = _INIT_STEP.matchAsPrefix(path);
    if (match == null) {
      print(path);
      throw new FormatException("Path cannot start with '['");
    }
    initStep = new ObjectStep(match.group(1));

    var index = match.end;
    var currStep = initStep;

    while (index < path.length) {
      match = _APPEND_STEP.matchAsPrefix(path, index);
      if (_APPEND_STEP.matchAsPrefix(path, index) != null) {
        currStep = currStep.next = new ArrayStep(-1);
        index = match.end;
        if (index < path.length)
          throw new FormatException('Append step can only appear at end of path');
        continue;
      }
      match = _INDEX_STEP.matchAsPrefix(path, index);
      if (match != null) {
        var stepIndex = int.parse(match.group(1));
        currStep = currStep.next = new ArrayStep(stepIndex);
        index = match.end;
        continue;
      }
      match = _OBJECT_STEP.matchAsPrefix(path, index);
      if (match != null) {
        currStep = currStep.next = new ObjectStep(match.group(1));
        index = match.end;
        continue;
      }
      throw new FormatException('Unexpected step in path');
    }
    return initStep;
  }

  Step get next;
  bool get isLast => next == null;

  dynamic setValue(context, entryValue);

}

Map<String,dynamic> _arrayToMap(List arr) {
  var obj = <String,dynamic>{};
  for (var i=0;i<arr.length;i++) {
    if (arr[i] == null) continue;
    obj['$i'] = arr[i];
  }
  return obj;
}

class ObjectStep extends Step {
  final String key;
  Step next;

  ObjectStep(this.key);


  Map<String,dynamic> setValue(context, entryValue) {
    if (context is! Map) {
      var obj = <String,dynamic>{};
      if (context is List) {
        for (var i=0;i<context.length;i++) {
          if (context[i] == null)
            continue;
          obj['$i'] = context[i];
        }
      } else {
        obj[key] = context;
      }
      context = obj;
    }

    var currentValue = context[key];
    if (isLast) {
      if (currentValue == null) {
        context[key] = entryValue;
      } else if (currentValue is List) {
        context[key].add(entryValue);
      } else if (currentValue is Map) {
        // If we're trying to insert the value into an already existing map
        // but there is no next step it's probably an error. Preserve the
        // data by inserting it into the current value with an empty key
        var pseudoStep = new ObjectStep('');
        context[key] = pseudoStep.setValue(currentValue, entryValue);
      } else {
        context[key] = [currentValue, entryValue];
      }
    } else {
      context[key] = next.setValue(context[key], entryValue);
    }
    return context;
  }

  @override
  int get hashCode {
    var h = 0;
    h += 43 * key.hashCode;
    h += 43 * next.hashCode;
    return h;
  }

  bool operator ==(Object other) =>
      other is ObjectStep &&
      other.key == key &&
      other.next == next;
}

class ArrayStep extends Step {
  final int index;
  bool get isAppend => index == -1;
  Step next;
  ArrayStep(this.index);

  @override
  dynamic setValue(context, entryValue) {
    if (context == null)
      context = <dynamic>[];

    var index = isAppend ? context.length : this.index;

    if (context is! List) {
      if (context is! Map) {
        context = <String,dynamic>{'': context};
      }

      // Attempting to insert into a map.
      // Should be inserted as a key with the string value of the index.
      var step = new ObjectStep('$index')
        ..next = this.next;
      return step.setValue(context, entryValue);
    }

    if (isAppend && !isLast) {
      throw new StateError('An append step must be the last step in path');
    }

    if (index >= context.length)
      context.length = index + 1;

    var currentValue = context[index];

    if (isLast) {
      if (currentValue == null) {
        context[index] = entryValue;
      } else if (currentValue is List) {
        currentValue.add(entryValue);
      } else if (currentValue is Map) {
        // See note in ObjectStep.
        var pseudoStep = new ObjectStep('');
        pseudoStep.setValue(currentValue, entryValue);
      } else {
        context[index] = [currentValue, entryValue];
      }
    } else {
      context[index] = next.setValue(context[index], entryValue);
    }
    return context;
  }

  @override
   int get hashCode {
     var h = 0;
     h += 43 * index.hashCode;
     h += 43 * next.hashCode;
     return h;
   }

   bool operator ==(Object other) =>
       other is ArrayStep &&
       other.index == index &&
       other.next == next;
}
