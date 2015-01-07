library test_form_field;
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer_ajax_form/src/form_field.dart';
import 'package:polymer_ajax_form/form_input.dart';

void main() {
  print('running main');
  useHtmlConfiguration();
  group("form field", () {
    group("input element tests", () {
      testInput(elementId, runTest(formField)) {
        test("input field ($elementId)", () {
          var elem = document.getElementById(elementId);
          var field = new FormField.fromInputElement(elem);
          runTest(field);
        });
      }

      testInput("disabled_field", (field) {
        expect(field.disabled, isTrue);
        expect(field.isSuccessful, isFalse);
      });

      testInput("invalid_field", (field) {
        expect(field.valid, isFalse);
        expect(field.isSuccessful, isFalse);
      });

      testInput("unnamed_input", (field) {
        expect(field.isSuccessful, isFalse);
      });

      testInput("submit_field", (field) {
        expect(field.isSuccessful, isFalse);
      });

      testInput("reset_field", (field) {
        expect(field.isSuccessful, isFalse);
      });

      testInput("button_field", (field) {
        expect(field.isSuccessful, isFalse);
      });

      testInput("text_field", (field) {
        expect(field.name, "text_field");
        expect(field.type, "text");
        expect(field.value, "hello world");
        expect(field.isSuccessful, isTrue);
      });

      testInput("color_field", (field) {
        expect(field.type, "color");
        expect(field.value, '#000000');
        expect(field.isSuccessful, isTrue);
      });

      testInput("date_field", (field) {
        expect(field.type, 'date');
        expect(field.value, '2014-05-01');
        expect(field.isSuccessful, isTrue);
      });
      /*
       * TODO: Not working
      testInput("datetime_field", (field) {
        expect(field.type, 'datetime');
        expect(field.value, '');
      });
      *
       */

      testInput("datetime_local_field", (field) {
        expect(field.type, 'datetime-local');
        expect(field.value, '');
        expect(field.isSuccessful, isTrue);
      });

      testInput("email_field", (field) {
        expect(field.type, 'email');
        expect(field.value, 'test@user.com');
        expect(field.isSuccessful, isTrue);
      });

      testInput("password_field", (field) {
        expect(field.type, 'password');
        expect(field.value, 'password');
        expect(field.isSuccessful, isTrue);
      });

      testInput("month_field", (field) {
        expect(field.type, 'month');
        expect(field.value, '2014-01');
        expect(field.isSuccessful, isTrue);
      });

      testInput("week_field", (field) {
        expect(field.type, 'week');
        expect(field.value, '2014-W01');
        expect(field.isSuccessful, isTrue);
      });

      testInput("number_field", (field) {
        expect(field.type, 'number');
        expect(field.value, 14.01);
        expect(field.isSuccessful, isTrue);
      });

      testInput("checkbox_field", (field) {
        expect(field.type, 'checkbox');
        expect(field.value, 'on');
        expect(field.isSuccessful, isTrue);
      });

      testInput('checkbox_unchecked', (field) {
        expect(field.type, 'checkbox');
        expect(field.value, null);
        expect(field.isSuccessful, isFalse);
      });

      testInput('radio1', (field) {
        expect(field.type, 'radio');
        expect(field.value, 'on');
        expect(field.isSuccessful, isTrue);
      });

      testInput('radio2', (field) {
        expect(field.type, 'radio');
        expect(field.value, null);
        expect(field.isSuccessful, isFalse);
      });

      testInput("file_field", (field) {
        expect(field.type, 'file');
        expect(field.value, []);
        expect(field.isSuccessful, isTrue);
      });
    });

    group("form input", () {
      test("valid + enabled implies successful", () {
        var input = new MockInput()
            ..name = 'form_input'
            ..value = 40;
        var field = new FormField.fromFormInput(input);
        expect(field.name, 'form_input');
        expect(field.value, 40);
        expect(field.isSuccessful, isTrue);
      });

      test("invalid implies not successful", () {
        var input = new MockInput()
            ..name = 'form_input'
            ..value = 'hello world'
            ..valid = false;
        expect(new FormField.fromFormInput(input).isSuccessful, isFalse);
      });

      test("disabled implies not successful", () {
        var input = new MockInput()
            ..name = 'form_input'
            ..disabled = true;
        expect(new FormField.fromFormInput(input).isSuccessful, isFalse);
      });

      test("no name implies not successful", () {
        var input = new MockInput();
        expect(new FormField.fromFormInput(input).isSuccessful, isFalse);
      });
    });

    group("select element", () {
      testSelectElement(elementId, runTest(formField)) {
        test("$elementId", () {
          var elem = document.getElementById(elementId);
          var field = new FormField.fromSelectElement(elem);
          runTest(field);
        });
      }

      testSelectElement("select_with_value", (field) {
        expect(field.value, 'value');
        expect(field.isSuccessful, isTrue);
      });

      testSelectElement('select_no_value', (field) {
        expect(field.value, 'Option 1');
        expect(field.isSuccessful, isTrue);
      });



      testSelectElement('select_multiple', (field) {
        expect(field.value, ['value1', 'value2']);
        expect(field.isSuccessful, isTrue);
      });

      testSelectElement('select_no_selection', (field) {
        expect(field.value, []);
        expect(field.isSuccessful, isTrue);
      });

      testSelectElement('disabled_select', (field) {
        expect(field.isSuccessful, isFalse);
      });
    });

    group("textarea element", () {
      test("valid", () {
        var field = new FormField.fromTextAreaElement(
            document.getElementById('textarea_field'));
        expect(field.name, 'textarea_field');
        expect(field.value, 'Lorem ipsum dolor amet');
        expect(field.isSuccessful, isTrue);
      });
    });
  });
}

class MockInput extends FormInput {

  MockInput();
  @override
  bool disabled = false;

  @override
  String name;

  @override
  bool valid = true;

  @override
  String validationMessage = null;

  @override
  var value = null;

  dynamic noSuchMethod(Invocation invocation) =>
      throw 'MockInput.${invocation.memberName}';
}