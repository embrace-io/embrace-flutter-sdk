/// Shared test constants for OTel adapter tests in embrace_platform_interface.

/// Valid 16-character hex string (8 bytes) for use as a span ID.
const String kTestSpanId = 'a1b2c3d4e5f6a7b8';

/// Valid 32-character hex string (16 bytes) for use as a trace ID.
const String kTestTraceId = '00112233445566778899aabbccddeeff';

/// All-zeros trace ID — the OTel sentinel for an invalid trace ID.
const String kInvalidTraceId = '00000000000000000000000000000000';

/// Span name used across OTel adapter tests.
const String kTestSpanName = 'test-span';

/// Start timestamp in milliseconds since epoch (2024-01-01 00:00:00 UTC).
const int kTestStartTimeMs = 1704067200000;

/// End timestamp in milliseconds since epoch (2024-01-01 00:01:00 UTC).
const int kTestEndTimeMs = 1704067260000;

/// A sample attribute map for use in tests.
const Map<String, String> kTestAttributes = {'key': 'value', 'env': 'test'};

/// A raw event list matching the shape used by `recordCompletedSpan`.
///
/// Each entry may have:
/// - `'name'` ([String]) — required
/// - `'timestampMs'` ([int]?) — optional
/// - `'attributes'` ([Map<String, String>]?) — optional
const List<Map<String, dynamic>> kTestRawEvents = [
  {
    'name': 'event-one',
    'timestampMs': 1704067210000,
    'attributes': {'ek': 'ev'},
  },
  {
    'name': 'event-two',
    'timestampMs': null,
    'attributes': null,
  },
];
