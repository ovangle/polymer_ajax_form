library utils_test;

import 'dart:convert' show UTF8;
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:polymer_ajax_form/src/utils.dart';

void main() {
  group("utils", () {
    test("read file", () {
      var blob = new Blob(['hello world']);
      readFile(blob).then((body) {
        expect(UTF8.decode(body), 'hello world');
      });
    });
  });
}