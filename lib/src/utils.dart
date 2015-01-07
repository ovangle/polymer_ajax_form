library ajax_form.utils;

import 'dart:async';
import 'dart:html';

Future<List<int>> readFile(Blob file) {
  var reader = new FileReader();
  var completer = new Completer();
  reader.onLoad.listen((_) {
    completer.complete(reader.result);
  });
  reader.onError.listen((ErrorEvent evt) {
    completer.completeError(evt.error);
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}