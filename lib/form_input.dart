import 'dart:html';

import 'package:polymer/polymer.dart';

///
/// A [FormInput] is an interface which represents a
/// polymer element which acts like a user input.
///
/// An ajax form does not descend into the shadow root
/// of an element, instead it assumes that any element
/// which acts as an input in a form implements this
/// interface.
///
abstract class FormInput implements Polymer, Observable {
  @published
  String get name => readValue(#name);
  set name(String value) => writeValue(#name, value);

  /// The current [:value:] of the input.
  /// Should be a primitive value (num, string, bool etc) or have a `toString`
  /// implementation which encodes all information about the object.
  @published
  dynamic get value => readValue(#name);
  set value(String value) => writeValue(#value, value);

  /// Whether the form is currently disabled
  @published
  bool get disabled => readValue(#disabled, () => false);
  set disabled(bool value) => writeValue(#disabled, value);

  /// The message associated with an invalid input. Should be `null`.
  /// iff [:!formInput.valid:]
  @observable
  String validationMessage = null;

  /// `true` if the [FormInput] is valid.
  @observable
  bool valid = true;
}