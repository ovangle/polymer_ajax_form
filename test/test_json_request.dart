import 'package:unittest/unittest.dart';

import 'package:polymer_ajax_form/src/json_request.dart';

Map<String,dynamic> encodeResult(Map<String,String> inputs) {
  var parsedInputs = new Map.fromIterable(
      inputs.keys, key: Step.parseSafe, value: (k) => inputs[k]
  );
  var result = <String,dynamic>{};
  parsedInputs.forEach((step, value) {
    step.setValue(result, value);
  });
  return result;
}

void main() {
  group('steps', () {
    test('simple keys', () {
      var k1 = 'name';
      var step1 = Step.parse(k1);
      var k2 = 'hind';
      var step2 = Step.parse(k2);
      var k3 = 'shiny';
      var step3 = Step.parse(k3);

      var result = <String,dynamic>{};
      step1.setValue(result, 'Bender');
      step2.setValue(result, 'Bitable');
      step3.setValue(result, true);

      expect(result, {
        'name': 'Bender',
        'hind': 'Bitable',
        'shiny': true
      });
    });

    test("if a path is repeated, its value is captured as an array", () {
      var path = 'bottle-on-wall';
      var step = Step.parse(path);
      var result = <String,dynamic>{};
      step.setValue(result, 1);
      step.setValue(result, 2);
      step.setValue(result, 3);
      expect(result, {'bottle-on-wall': [1,2,3]});
    });

    test("structured using strings for keys in objects and integers for values in arrays", () {
      var inputs = {
        'pet[species]': 'Dahut',
        'pet[name]': 'Hypatia',
        'kids[1]': 'Thelma',
        'kids[0]': 'Ashley'
      };
      var parsedInputs = new Map.fromIterable(
          inputs.keys, key: Step.parse, value: (k) => inputs[k]
      );
      var result = <String,dynamic>{};
      parsedInputs.forEach((step, value) {
        step.setValue(result, value);
      });
      expect(
          result,
          {
            'pet': {
              'species': 'Dahut',
              'name': 'Hypatia',
            },
            'kids': ['Ashley', 'Thelma']
          }
      );
    });

    test("if an array is sparse, null values are inserted", () {
      var inputs = {
        'hearbeat[0]': 'thunk',
        'hearbeat[2]': 'thunk'
      };
      var result = encodeResult(inputs);
      expect(
          result,
          {
            'hearbeat': ['thunk', null, 'thunk']
          }
      );
    });

    test("objects can be nested inside array indexes", () {
      var inputs = {
        'pet[0][species]': 'Dahut',
        'pet[0][name]': 'Hypatia',
        'pet[1][species]': 'Felis Stultus',
        'pet[1][name]': 'Billie'
      };
      var result = encodeResult(inputs);
      expect(result,
          {
            'pet':
              [
                {
                  'species': 'Dahut',
                  'name': 'Hypatia'
                },
                {
                  'species': 'Felis Stultus',
                  'name': 'Billie'
                }
              ]
          }
      );
    });

    test("objects can be nested to any depth", () {
      var step = Step.parse('wow[such][deep][3][much][power][!]');
      var result = <String,dynamic>{};
      step.setValue(result, 'Amaze');
      expect(result, {
        'wow': {
          'such': {
            'deep': [
              null,
              null,
              null,
              {
                'much': {
                  'power': {
                    '!': 'Amaze'
                  }
                }
              }
            ]
          }
        }
      });
    });

    test("an object with both string and numeric keys is converted into an object", () {
      var inputs = {
        'mix': 'scalar',
        'mix[0]': 'array 1',
        'mix[2]': 'array 2',
        'mix[key]': 'key key',
        'mix[car]': 'car key'
      };
      var result = encodeResult(inputs);
      expect(result, {
        'mix': {
          '': 'scalar',
          '0': 'array 1',
          '2': 'array 2',
          'key': 'key key',
          'car': 'car key'
        }
      });
    });

    test("append", () {
      var inputs = {'highlander[]': 'one'};
      var result = encodeResult(inputs);
      expect(result, {'highlander': ['one']});
    });

    //TODO: Example 9 test.

    test("invalid path", () {
      var inputs = {
        'error[good]': 'BOOM!',
        'error[bad': 'BOOM BOOM!'
      };
      var result = encodeResult(inputs);
      expect(result,
          {
            'error': {
              'good': 'BOOM!'
            },
            'error[bad': 'BOOM BOOM!'
          }
      );

    });
  });
}