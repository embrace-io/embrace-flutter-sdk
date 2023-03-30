/// Used to represent an HTTP method when logging network requests
enum HttpMethod {
  /// Any value that isn't specified below
  other,

  /// GET
  get,

  /// POST
  post,

  /// PUT
  put,

  /// DELETE
  delete,

  /// PATCH
  patch
}

/// Adds the [toHttpString] method to [HttpMethod]
extension HttpMethodToString on HttpMethod {
  /// Returns a [String] representation of this [HttpMethod] in UPPER CASE
  String toHttpString() {
    switch (this) {
      case HttpMethod.other:
        return 'OTHER';
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.delete:
        return 'DELETE';
      case HttpMethod.patch:
        return 'PATCH';
    }
  }
}

/// Parses an [HttpMethod] from an input [String] in UPPER CASE
HttpMethod httpMethodFromString(String input) {
  switch (input) {
    case 'GET':
      return HttpMethod.get;
    case 'POST':
      return HttpMethod.post;
    case 'PUT':
      return HttpMethod.put;
    case 'PATCH':
      return HttpMethod.patch;
    case 'DELETE':
      return HttpMethod.delete;
    case 'OTHER':
    default:
      return HttpMethod.other;
  }
}
