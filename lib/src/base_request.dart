library ajax_form.request;

import 'dart:async';

abstract class BaseRequest {
  Map<String,String> get headers;
  Future<String> getBody();
}