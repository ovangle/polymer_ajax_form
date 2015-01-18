library ajax_form;

import 'dart:async';
import 'dart:convert' show JSON, UTF8;
import 'dart:html';
import 'dart:typed_data';

import 'package:polymer/polymer.dart';
import 'package:core_elements/core_ajax_dart.dart';

import 'src/form_field.dart';
import 'src/base_request.dart';
import 'src/urlencoded_request.dart';
import 'src/multipart_request.dart';
import 'src/json_request.dart';

typedef BaseRequest _REQUEST_FACTORY(Iterable<FormField> fields);


@CustomTag('ajax-form')
class AjaxFormElement extends FormElement with Polymer, Observable {
  // TODO:
  // - bind to <input type=submit> elements

  static final _VALID_ENCTYPES = <String, _REQUEST_FACTORY>{
      'application/x-www-form-urlencoded': (fields) => new UrlencodedRequest(fields),
      'multipart/form-data': (fields) => new MultipartRequest(fields),
      'application/json': (fields) => new JsonRequest(fields)
  };


  static const _ajaxFormResponse = const EventStreamProvider('ajax-form-response');

  /// An event emitted when the form has received a response.
  /// The [:detail:] of the response event is always a [:FormResponse:] object.
  Stream<CustomEvent> get onFormResponse => _ajaxFormResponse.forElement(this);

  /// The URI of a program that processes the form information.
  @published
  String get action => readValue(#action, () => window.location.href);
  set action(String value) => writeValue(#action, value);

  /// The method that the form should use to submit data to the server
  /// Unlike normal html forms, this accepts any valid http method.
  @published
  String get method => readValue(#method, () => 'GET');
  set method(String value) => writeValue(#method, value);

  /// How to encode the value when sending to the server.
  /// Accepted values are:
  /// - application/x-www-form-urlencoded
  /// - multipart/form-data
  /// - application/json.
  ///
  /// NOTE: The enctype is ignored if the method is 'GET' and can only
  /// be set if the value is one of the accepted values.
  @published
  String get enctype =>readValue(#enctype, () => 'application/x-www-form-urlencoded');
  set enctype(String value) {
    if (_VALID_ENCTYPES.keys.contains(value)) {
      writeValue(#enctype, value);
    }
  }

  /// Headers to be passed to the ajax request.
  /// headers associated with the content type of the request are added
  /// automatically.
  @published
  Map<String,String> get headers => readValue(#headers, () => <String,String>{});
  set headers(Map<String,String> value) => writeValue(#headers, value);

  ///
  /// The [FormResponse] which was returned the last time the
  /// request was submitted
  ///
  @published
  FormResponse get response => readValue(#response);
  set response(FormResponse value) => writeValue(#response, value);



  ContentElement get _content => shadowRoot.querySelector('content');
  CoreAjax get _ajax => shadowRoot.querySelector('core-ajax-dart');

  PathObserver _inputObserver;

  AjaxFormElement.created(): super.created() {
    polymerCreated();
  }

  Future<FormResponse> submit() {
    return new Future.value().then((_) {
      var request = _VALID_ENCTYPES[enctype](_formInputs);
      return request.getBody().then((body) {
        var headers = new Map.from(this.headers);
        headers.addAll(request.headers);

        _ajax.headers = headers;
        _ajax.body = body;
        return _ajax.go().onLoad.first.then((evt) {
          var response = new FormResponse(evt.target);
          this.fire('ajax-form-response', detail: response);
          return response;
        });
      });
    });
  }

  Iterable<FormField> get _formInputs =>
      shadowRoot.children.expand(FormField.collectFields);

}

class FormResponse {
  /// The underlying [HttpRequest].
  final HttpRequest xhr;

  int get status => xhr.status;

  /// The body of the response as a list of bytes.
  List<int> get content => (xhr.response as ByteBuffer).asUint8List();

  /// The response text. Assumes that the content is encoded as a UTF8 array
  String get responseText => UTF8.decode(content);

  /// The json body of the response (if the body was encoded as json).
  /// Otherswise raises an exception
  Map<String,dynamic> get responseJson => JSON.decode(responseText);

  Map<String,String> _headers;
  Map<String,String> get headers {
    // HttpRequest parses the headers each time.
    // parse once and cache the result.
    if (_headers == null) {
      _headers = new Map.from(xhr.responseHeaders);
    }
    return _headers;

  }

  FormResponse(this.xhr);
}

