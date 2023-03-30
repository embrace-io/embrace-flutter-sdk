# embrace_dio

A package to enable the `embrace` plugin to capture network requests made with the Dio package.


## Usage

Add an instance of `EmbraceInterceptor` to the Dio instance

```dart
var dio = Dio();
dio.interceptors.add(EmbraceInterceptor());
```
