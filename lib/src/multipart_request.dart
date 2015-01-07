library ajax_form.multipart_request;

import 'dart:async';
import 'dart:convert' show UTF8;
import 'dart:math' show Random;
import 'dart:html';

import 'package:quiver/async.dart' show forEachAsync;
import 'package:crypto/crypto.dart' show CryptoUtils;

import 'form_field.dart';
import 'base_request.dart';
import 'utils.dart';

final _NEWLINE = new RegExp(r'\r|\n|\r\n');

String _encodeName(String name) {
  return name.replaceAll(_NEWLINE, '%0D%0A').replaceAll('"', '%22');
}

/**
 * A request with content type multipart/form-data
 */
class MultipartRequest implements BaseRequest {
  static final List<int> _VALID_BOUNDARY_CHARCODES =
      UTF8.encode("abcdefghijklmnopqrstuvwyz0123456789");
  static final Random _random = new Random();

  static String _genBoundaryIdentifier() {
    List charCodes = new List(6);
    for (var i=0;i<6;i++) {
      var charIndex = _random.nextInt(_VALID_BOUNDARY_CHARCODES.length);
      charCodes[i] = _VALID_BOUNDARY_CHARCODES[charIndex];
    }
    return new String.fromCharCodes(charCodes);
  }

  final Iterable<RequestPart> parts;
  final String contentBoundary;

  MultipartRequest(Iterable<FormField> fields):
    parts = fields.map((field) => new RequestPart.fromFormField(field)),
    this.contentBoundary = _genBoundaryIdentifier();

  Map<String,String> get headers {
    var headers = <String,String>{};
    headers['content-type'] = 'multipart/form-data; boundary=$contentBoundary';
    return headers;
  }

  Future<String> getBody() {
    var sbuf = new StringBuffer();
    return forEachAsync(parts, (RequestPart part) {
      sbuf.write('--$contentBoundary');
      return part.getRequestPart().then(sbuf.write);
    }).then((_) {
      sbuf.write('--$contentBoundary');
    });
  }
}

abstract class RequestPart {

  RequestPart();

  factory RequestPart.fromFormField(FormField formField) {
    if (formField.isFile) {
      return new FileRequestPart(formField.name, formField.value);
    } else {
      return new BasicRequestPart(formField.name, formField.value);
    }
  }

  Map<String,String> get headers;

  Future<String> getBody();

  Future<String> getRequestPart() {
    var sbuf = new StringBuffer();
    return new Future.value().then((_) {
      headers.forEach((k, v) => sbuf.write('$k: $v\r\n'));
      sbuf.write('\r\n');
      return getBody();
    }).then((body) {
      sbuf.write(body);
      return sbuf.toString();
    });
  }
}

/**
 * A part of the request for a normal form field.
 */
class BasicRequestPart extends RequestPart {

  final String fieldName;
  final dynamic fieldValue;

  BasicRequestPart(this.fieldName, this.fieldValue);

  @override
  Map<String, String> get headers {
    var headers = <String,String>{};
    headers['content-disposition'] = 'form-data; name="${_encodeName(fieldName)}"';

    return headers;
  }

  @override
  Future<String> getBody() => new Future.value('$fieldValue\r\n');
}

class FileRequestPart extends RequestPart {
  final String fieldName;
  final Iterable<FilePart> parts;
  final String contentBoundary;

  FileRequestPart(String this.fieldName, Iterable<Blob> files):
    this.parts = files.map((f) => new FilePart(f)),
    this.contentBoundary = 'ajax-form-${MultipartRequest._genBoundaryIdentifier()}';

  FileRequestPart.fromBlobs(
      String this.fieldName,
      Map<String,Blob> fileBlobs):
        this.parts =
            fileBlobs.keys
                .map((fileName) => new FilePart.fromBlob(fileName, fileBlobs[fileName])),
        this.contentBoundary = 'ajax-form-${MultipartRequest._genBoundaryIdentifier()}';

  @override
  Map<String,String> get headers {
    var headers = <String,String>{};
    headers['content-disposition'] = 'form-data; name="${_encodeName(fieldName)}"';
    headers['content-type'] = 'multipart/mixed; boundary=$contentBoundary';
    return headers;
  }

  @override
  Future<String> getBody() {
    StringBuffer sbuf = new StringBuffer();
    return forEachAsync(parts, (part) {
      sbuf.write('--$contentBoundary\r\n');
      return part.getRequestPart().then((part) {
        sbuf.write(part);
        sbuf.write('\r\n');
      });
    }).then((_) {
      sbuf.write('--$contentBoundary--\r\n');
      return sbuf.toString();
    });
  }
}

class FilePart extends RequestPart {
  String fileName;
  final Blob file;

  FilePart(File file):
    this.file = file,
    this.fileName = file.name;

  FilePart.fromBlob(String this.fileName, Blob this.file);

  Map<String,String> get headers {
    var headers = <String,String>{};
    headers['content-disposition'] = 'file; filename="${_encodeName(fileName)}"';
    headers['content-type'] = file.type;
    headers['content-transfer-encoding'] = 'base64';
    return headers;
  }

  @override
  Future<String> getBody() {
    // If you're loading a large file via ajax, you're doing something wrong.
    // Assume the file is small and load it entirely into memory
    return readFile(file).then((fileContent) {
      return CryptoUtils.bytesToBase64(fileContent);
    });
  }
}