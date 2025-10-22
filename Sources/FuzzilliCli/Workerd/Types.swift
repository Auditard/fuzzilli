import Fuzzilli

// MARK: - Workerd Type Extensions
public extension ILType {
    // HTMLRewriter API types
    static let htmlRewriter = ILType.object(ofGroup: "HTMLRewriter", withProperties: [], withMethods: ["on", "onDocument", "transform"])
    static let htmlRewriterConstructor = ILType.constructor([] => .htmlRewriter)

    // Element types
    static let htmlElement = ILType.object(ofGroup: "HTMLElement",
                                          withProperties: ["tagName", "attributes", "namespaceURI"],
                                          withMethods: ["getAttribute", "setAttribute", "hasAttribute", "removeAttribute",
                                                       "before", "after", "prepend", "append", "replace", "remove",
                                                       "removeAndKeepContent", "setInnerContent", "onEndTag"])

    // Comment type
    static let htmlComment = ILType.object(ofGroup: "HTMLComment",
                                          withProperties: ["text", "removed"],
                                          withMethods: ["before", "after", "replace", "remove"])

    // Text chunk type
    static let htmlTextChunk = ILType.object(ofGroup: "HTMLTextChunk",
                                            withProperties: ["text", "lastInTextNode", "removed"],
                                            withMethods: ["before", "after", "replace", "remove"])

    // Document end type
    static let htmlDocumentEnd = ILType.object(ofGroup: "HTMLDocumentEnd",
                                              withProperties: [],
                                              withMethods: ["append"])

    // Handler types
    static let elementHandler = ILType.object(ofGroup: "ElementHandler",
                                             withProperties: [],
                                             withMethods: [])

    static let documentHandler = ILType.object(ofGroup: "DocumentHandler",
                                              withProperties: [],
                                              withMethods: [])

    // Fetch API types
    static let workerdHeaders = ILType.object(ofGroup: "Headers",
                                             withProperties: [],
                                             withMethods: ["append", "delete", "entries", "forEach", "get", "has", "keys", "set", "values"])
    static let workerdHeadersConstructor = ILType.constructor([.opt(.jsAnything)] => .workerdHeaders) +
                                           .object(ofGroup: "HeadersConstructor", withProperties: ["prototype"], withMethods: [])
    static let workerdResponse = ILType.object(ofGroup: "Response",
                                              withProperties: ["status", "statusText", "headers", "body", "url", "ok", "redirected", "type", "bodyUsed"],
                                              withMethods: ["arrayBuffer", "blob", "formData", "json", "text", "clone"])
    static let workerdResponseConstructor = ILType.constructor([.opt(.jsAnything), .opt(.object())] => .workerdResponse) +
                                            .object(ofGroup: "ResponseConstructor", withProperties: ["prototype"], withMethods: ["error", "redirect", "json"])
}
