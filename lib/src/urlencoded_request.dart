library ajax_form.urlencoded_request;

import 'dart:async';

import 'form_field.dart';
import 'base_request.dart';

final Pattern _NEWLINE = new RegExp(r'\r|\n|\r\n');

class UrlencodedRequest extends BaseRequest {
  Iterable<FormField> fields;

  UrlencodedRequest(this.fields);

  String _encodeField(FormField field) {
    var value = field.value;
    if (field.isFile) {
      value = field.value.map((file) => file.name).join(',');
    }

    encodeComp(String str) =>
        Uri.encodeQueryComponent(str);
    return '${encodeComp(field.name)}=${encodeComp(value.toString())}';
  }

  @override
  Future<String> getBody() {
    return new Future.value().then((_) {
      return fields.map(_encodeField).join('&');
    });
  }

  @override
  Map<String, String> get headers {
    var headers = <String,String>{};
    headers['content-type'] = 'application/x-www-form-urlencoded; charset=utf-8';
    return headers;
  }
}