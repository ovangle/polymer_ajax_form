library urlencoded_request_test;

import 'package:unittest/unittest.dart';

import 'package:polymer_ajax_form/src/form_field.dart';
import 'package:polymer_ajax_form/src/urlencoded_request.dart';

void main() {
  print('running test');
   group("urlencoded request", () {

     test("headers", () {
      var request = new UrlencodedRequest([]);
      expect(request.headers, {
        'content-type': 'application/x-www-form-urlencoded; charset=utf-8'
      });
     });

     test("encode basic fields", () {
       var formFields = [
          new MockField('text', 'field1', 'value with whitespace'),
          new MockField('number', 'field2', 12345),
          new MockField('other', '%escaped_name', 'value'),
       ];

       var request = new UrlencodedRequest(formFields);

       return request.getBody().then((body) {
         expect(body,
             'field1=value+with+whitespace&'
             'field2=12345&'
             '%25escaped_name=value'
          );
       });
     });

     test("encode file", () {
       var fields = [
            new MockField('file', 'file_field', [new MockFile('filename.txt')])
        ];

       var request = new UrlencodedRequest(fields);
       return request.getBody().then((body) {
        expect(body, 'file_field=filename.txt');
       });

     });
   });

}

class MockField implements FormField {

  bool get isFile => type == 'file';

  String type;
  String name;
  dynamic value;

  MockField(this.type, this.name, this.value);

  noSuchMethod(Invocation invocation) =>
      throw new UnimplementedError('MockField.${invocation.memberName}');

}

class MockFile {
  String name;

  MockFile(this.name);
}