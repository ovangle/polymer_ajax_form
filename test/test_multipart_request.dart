library multipart_request_test;

import 'dart:convert' show UTF8;
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:crypto/crypto.dart' show CryptoUtils;

import 'package:polymer_ajax_form/src/multipart_request.dart';

void main() {
  group("multipart request", () {
    var blob1 = new Blob(['hello world'], 'text/plain');
    var blob2 = new Blob(['goodbye'], 'image/jpeg');

    group("file part", () {
      var filePart = new FilePart.fromBlob('test.txt', blob1);

      test("headers", () {
          expect(filePart.headers,
              {
                'content-disposition': 'file; filename="test.txt"',
                'content-type': 'text/plain',
                'content-transfer-encoding': 'base64'
              }
          );
        });

      test("body", () {
        return filePart.getBody().then((body) {
          expect(body, CryptoUtils.bytesToBase64(UTF8.encode('hello world')));
        });
      });
    });

    group("file request part", () {
      var fileRequest = new FileRequestPart.fromBlobs(
          'files',
          {
            'file1.txt': blob1,
            'file2.txt': blob2
          });

      test("headers", () {
        expect(fileRequest.headers,
            {
              'content-disposition': 'form-data; name="files"',
              'content-type': 'multipart/mixed; boundary=${fileRequest.contentBoundary}'
            }
        );
      });

      test("body", () {
        return fileRequest.getBody().then((body) {
          expect(body,
              '--${fileRequest.contentBoundary}\r\n'
              'content-disposition: file; filename="file1.txt"\r\n'
              'content-type: text/plain\r\n'
              'content-transfer-encoding: base64\r\n'
              '\r\n'
              '${CryptoUtils.bytesToBase64(UTF8.encode('hello world'))}\r\n'
              "--${fileRequest.contentBoundary}\r\n"
              'content-disposition: file; filename="file2.txt"\r\n'
              'content-type: image/jpeg\r\n'
              'content-transfer-encoding: base64\r\n'
              '\r\n'
              '${CryptoUtils.bytesToBase64(UTF8.encode('goodbye'))}\r\n'
              '--${fileRequest.contentBoundary}--\r\n'
          );
        });
      });
    });

    group("basic request part", () {
      var basicRequest = new BasicRequestPart('submit-name', "Larry");
      test("request stream", () {
        return basicRequest.getRequestPart().then((request) {
          expect(request,
              'content-disposition: form-data; name="submit-name"\r\n'
              '\r\n'
              'Larry\r\n'
         );
        });
      });
    });
  });

}