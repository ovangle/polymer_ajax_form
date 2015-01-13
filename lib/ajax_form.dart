library ajax_form;

import 'dart:async';
import 'dart:html';

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
  static const _ajaxFormError = const EventStreamProvider('ajax-form-error');
  static const _ajaxFormComplete = const EventStreamProvider('ajax-form-complete');

  Stream<CustomEvent> get onFormResponse => _ajaxFormResponse.forElement(this);
  Stream<CustomEvent> get onFormError => _ajaxFormError.forElement(this);
  /// An error handler
  Stream<CustomEvent> get onFormComplete => _ajaxFormComplete.forElement(this);

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

  /// Specifies what data to store in the response properties.
  /// Accepted values are the same as for the [:core-ajax:] element
  /// from the [:core_elements:] package
  @published
  String get handleAs => readValue(#handleAs, () => 'text');
  set handleAs(String value) => writeValue(#handleAs, value);

  ContentElement get _content => shadowRoot.querySelector('content');
  CoreAjax get _ajax => shadowRoot.querySelector('core-ajax-dart');

  PathObserver _inputObserver;

  AjaxFormElement.created(): super.created() {
    polymerCreated();
  }

  void attached() {
    _ajax.onCoreResponse.listen((evt) {
      this.fire('ajax-form-response', detail: evt.detail);
    });
    _ajax.onCoreError.listen((evt) {
      this.fire('ajax-form-error', detail: evt.detail);
    });
    _ajax.onCoreComplete.listen((evt) {
      this.fire('ajax-form-complete', detail: evt.detail);
    });
  }

  Future<HttpRequest> submit() {
    return new Future.value().then((_) {
      var request = _VALID_ENCTYPES[enctype](_formInputs);
      return request.getBody().then((body) {
        var headers = new Map.from(this.headers);
        headers.addAll(request.headers);

        _ajax.headers = headers;
        _ajax.body = body;
        return _ajax.go();
      });
    });
  }

  Iterable<FormField> get _formInputs =>
      shadowRoot.children.expand(FormField.collectFields);

}

