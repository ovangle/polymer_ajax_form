import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'package:polymer/polymer.dart';
import 'package:polymer_ajax_form/src/form_field.dart';

void main() {
  initPolymer();
  //useHtmlConfiguration();

  group("collect fields", () {
    var fields;
    setUp(() {
      return Polymer.onReady.then((_) {
        var collectionTestsDiv = document.getElementById('collection_tests');

        fields = FormField.collectFields(collectionTestsDiv)
             .map((field) => field.name);
      });
    });

    test("should collect a node at the top level", () {
      expect('collected', isIn(fields));
    });

    test("should not collect a disabled field", () {
      expect('disabled_not_collected', isNot(isIn(fields)));
    });

    test("should not collect an invalid field", () {
      expect('invalid_not_collected', isNot(isIn(fields)));
    });

    test("should collect a nested field", () {
      expect('nested_field', isIn(fields));
    });

    test("should collect a field from an enabled_fieldset", () {
      expect('fieldset_collected1', isIn(fields));
    });

    test("should not collect a field from a disabled fieldset _unless_"
        "the field is in the fieldsets legend", () {
      expect("fieldset_collected2", isIn(fields));
      expect("fieldset_not_collected", isNot(isIn(fields)));
    });

    test("should not collect a field in a datalist", () {
      expect("datalist_not_collected", isNot(isIn(fields)));
    });

    test("should collect a distributed node of a polymer element", () {
      expect("light_dom_distributed_node", isIn(fields));
    });

    test("should collect a shadowed node of a polymer element", () {
      expect("shadowed_input", isIn(fields));
    });

    test("should collect an element from an older shadow root which is included via <shadow>", () {
      expect("shadowed_input_distributed_node", isIn(fields));
    });

    test("should include the fields from a selected content", () {

      expect("light_dom_selected_distributed_node", isIn(fields));
    });

    test("should include fields in tree order", () {
      expect(fields, [
        'collected',
        'nested_field',
        'fieldset_collected1',
        'fieldset_collected2',
        'shadowed_input',
        'shadowed_input_distributed_node',
        'light_dom_distributed_node',
        'light_dom_selected_distributed_node'
      ]);
    });
  });
}