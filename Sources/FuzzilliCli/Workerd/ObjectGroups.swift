import Fuzzilli

// MARK: - Workerd Object Groups
public let htmlRewriterGroup = ObjectGroup(
    name: "HTMLRewriter",
    instanceType: .htmlRewriter,
    properties: [:],
    methods: [
        "on": [.plain(.string), .plain(.elementHandler)] => .htmlRewriter,
        "onDocument": [.plain(.documentHandler)] => .htmlRewriter,
        "transform": [.plain(.workerdResponse)] => .workerdResponse
    ]
)

public let htmlElementGroup = ObjectGroup(
    name: "HTMLElement",
    instanceType: .htmlElement,
    properties: [
        "tagName": .string,
        "attributes": .iterable,
        "namespaceURI": .string
    ],
    methods: [
        "getAttribute": [.plain(.string)] => (.string | .undefined),
        "setAttribute": [.plain(.string), .plain(.string)] => .htmlElement,
        "hasAttribute": [.plain(.string)] => .boolean,
        "removeAttribute": [.plain(.string)] => .htmlElement,
        "before": [.plain(.string)] => .htmlElement,
        "after": [.plain(.string)] => .htmlElement,
        "prepend": [.plain(.string)] => .htmlElement,
        "append": [.plain(.string)] => .htmlElement,
        "replace": [.plain(.string)] => .htmlElement,
        "remove": [] => .htmlElement,
        "removeAndKeepContent": [] => .htmlElement,
        "setInnerContent": [.plain(.string)] => .htmlElement,
        "onEndTag": [.plain(.function())] => .undefined
    ]
)

public let workerdHeadersGroup = ObjectGroup(
    name: "Headers",
    instanceType: .workerdHeaders,
    properties: [:],
    methods: [
        "append": [.string, .string] => .undefined,
        "delete": [.string] => .undefined,
        "entries": [] => .object(),
        "forEach": [.function(), .opt(.object())] => .undefined,
        "get": [.string] => (.string | .undefined),
        "has": [.string] => .boolean,
        "keys": [] => .object(),
        "set": [.string, .string] => .undefined,
        "values": [] => .object()
    ]
)

public let workerdHeadersConstructorGroup = ObjectGroup(
    name: "HeadersConstructor",
    constructorPath: "Headers",
    instanceType: .workerdHeadersConstructor,
    properties: [
        "prototype": workerdHeadersGroup.instanceType
    ],
    methods: [:]
)

public let workerdResponseGroup = ObjectGroup(
    name: "Response",
    instanceType: .workerdResponse,
    properties: [
        "status": .integer,
        "statusText": .string,
        "headers": .workerdHeaders,
        "body": (.object() | .nullish),
        "url": .string,
        "ok": .boolean,
        "redirected": .boolean,
        "type": .string,
        "bodyUsed": .boolean
    ],
    methods: [
        "arrayBuffer": [] => .jsPromise,
        "blob": [] => .jsPromise,
        "formData": [] => .jsPromise,
        "json": [] => .jsPromise,
        "text": [] => .jsPromise,
        "clone": [] => .workerdResponse
    ]
)

public let workerdResponseConstructorGroup = ObjectGroup(
    name: "ResponseConstructor",
    constructorPath: "Response",
    instanceType: .workerdResponseConstructor,
    properties: [
        "prototype": workerdResponseGroup.instanceType
    ],
    methods: [
        "error": [] => .workerdResponse,
        "redirect": [.string, .opt(.integer)] => .workerdResponse,
        "json": [.jsAnything, .opt(.object())] => .workerdResponse
    ]
)
