import Foundation
import EmbraceIO
import EmbraceOTelInternal
import EmbraceSemantics
import OpenTelemetryApi

class EmbraceSpanRepository {

    private var spans: [String : Span] = [:]

    func startSpan(name: String, parentSpanId: String?, startTimeMs: Int?) -> String? {
        if let client = Embrace.client {
            let builder = client
                .buildSpan(name: name)
                .setStartTime(time: createDate(timeMs: startTimeMs) ?? Date())
            if let span = findSpan(id: parentSpanId) {
                builder.setParent(span)
            }
            let span = builder.startSpan()
            let spanId = span.context.spanId.hexString
            spans[spanId] = span
            return spanId
        }
        return nil
    }

    func stopSpan(spanId: String, endTimeMs: Int?, errorCode: String?) -> Bool {
        if let span = findSpan(id: spanId) {
            endSpan(span: span, endTimeMs: endTimeMs, errorCode: errorCode)
            spans.removeValue(forKey: spanId)
            return true
        }
        return false
    }

    func addSpanEvent(spanId: String, name: String, timestampMs: Int?, attributes: Dictionary<String, String>?) -> Bool {
        if let client = Embrace.client,
           let span = findSpan(id: spanId) {
            let startDate = createDate(timeMs: timestampMs) ?? Date()
            let attrs = (attributes ?? [:]).mapValues { val in AttributeValue(val) }
            span.addEvent(name: name, attributes: attrs, timestamp: startDate)
            client.flush(span)
            return true
        }
        return false
    }

    func addSpanAttribute(spanId: String, key: String, value: String) -> Bool {
        if let client = Embrace.client,
           let span = findSpan(id: spanId) {
            span.setAttribute(key: key, value: value)
            client.flush(span)
            return true
        }
        return false
    }

    func recordCompletedSpan(
        name: String,
        startTimeMs: Int,
        endTimeMs: Int,
        errorCode: String?,
        parentSpanId: String?,
        attributes: Dictionary<String, String>?,
        events: Array<Dictionary<String, Any>>) -> Bool {
            if let client = Embrace.client {
                let builder = client
                    .buildSpan(name: name)
                    .setStartTime(time: createDate(timeMs: startTimeMs) ?? Date())

                if let parentSpan = findSpan(id: parentSpanId) {
                    builder.setParent(parentSpan)
                }
                let span = builder.startSpan()

                if let attrs = attributes {
                    attrs.forEach { (key: String, value: String) in
                        span.setAttribute(key: key, value: value)
                    }
                }

                events.forEach { (dict: Dictionary<String, Any>) in
                    if let name = dict["name"] as? String,
                       let timestampDate = createDate(timeMs: dict["timestampMs"] as? Int ?? 0),
                       let eventAttrs = dict["attributes"] as? Dictionary<String, String> {
                        let mappedAttrs = eventAttrs.mapValues { str in
                            AttributeValue(str)
                        }
                        span.addEvent(name: name, attributes: mappedAttrs, timestamp: timestampDate)
                    }
                }

                endSpan(span: span, endTimeMs: endTimeMs, errorCode: errorCode)
                return true
            }
            return false
        }
    
    private func endSpan(span: Span, endTimeMs: Int?, errorCode: String?) {
        let endDate = createDate(timeMs: endTimeMs) ?? Date()
        let code = mapErrorCode(code: errorCode)

        if (code != nil) {
            span.end(errorCode: code, time: endDate)
        } else {
            span.end(time: endDate)
        }
    }

    private func mapErrorCode(code: String?) -> EmbraceSemantics.SpanErrorCode? {
        if (code == "failure") {
            return .failure
        } else if (code == "abandon") {
            return .userAbandon
        } else if (code == "unknown") {
            return .unknown
        } else {
            return nil
        }
    }

    func findSpan(id: String?) -> Span? {
        guard let id = id else {
            return nil
        }
        return spans[id]
    }

    private func createDate(timeMs: Int?) -> Date? {
        if let ms = timeMs {
            return Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        } else {
            return nil
        }
    }
}
