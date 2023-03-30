import 'package:embrace_platform_interface/http_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('httpMethodFromString returns correctly', () {
    expect(httpMethodFromString('GET'), HttpMethod.get);
    expect(httpMethodFromString('POST'), HttpMethod.post);
    expect(httpMethodFromString('PUT'), HttpMethod.put);
    expect(httpMethodFromString('PATCH'), HttpMethod.patch);
    expect(httpMethodFromString('DELETE'), HttpMethod.delete);
    expect(httpMethodFromString('OTHER'), HttpMethod.other);
    expect(httpMethodFromString('HEAD'), HttpMethod.other);
    expect(httpMethodFromString('OPTIONS'), HttpMethod.other);
    expect(httpMethodFromString('CONNECT'), HttpMethod.other);
    expect(httpMethodFromString('TRACE'), HttpMethod.other);
    expect(httpMethodFromString('INVALID'), HttpMethod.other);
  });
  test('HttpMethod.toHttpString() returns correctly', () {
    expect(HttpMethod.get.toHttpString(), 'GET');
    expect(HttpMethod.post.toHttpString(), 'POST');
    expect(HttpMethod.put.toHttpString(), 'PUT');
    expect(HttpMethod.patch.toHttpString(), 'PATCH');
    expect(HttpMethod.delete.toHttpString(), 'DELETE');
    expect(HttpMethod.other.toHttpString(), 'OTHER');
  });
}
