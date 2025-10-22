import Fuzzilli

// MARK: - Workerd Code Generators

public let HTMLRewriterConstructorGenerator = CodeGenerator("HTMLRewriterConstructorGenerator") { b in
    // Create a new HTMLRewriter instance
    let HTMLRewriter = b.createNamedVariable(forBuiltin: "HTMLRewriter")
    let rewriter = b.construct(HTMLRewriter)

    // Add a simple handler
    let selector = b.loadString(chooseUniform(from: ["div", "p", "a", "*"]))
    let handler = b.createObject(with: [:])

    let elementCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
        let element = args[0]
        b.callMethod("setAttribute", on: element, withArgs: [
            b.loadString("data-rewritten"),
            b.loadString("true")
        ])
    }
    b.setProperty("element", of: handler, to: elementCallback)

    b.callMethod("on", on: rewriter, withArgs: [selector, handler])
}

public let ElementHandlerGenerator = CodeGenerator("ElementHandlerGenerator", produces: [.elementHandler]) { b in
    let handler = b.createObject(with: [:])

    // Randomly add element callback
    if probability(0.7) {
        let elementCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let element = args[0]

            // Perform random operations on the element
            let _ = withEqualProbability({
                // Get/set attributes
                let attrName = b.loadString(chooseUniform(from: ["class", "id", "href", "src"]))
                let hasAttr = b.callMethod("hasAttribute", on: element, withArgs: [attrName])

                b.buildIf(hasAttr) {
                    let attrValue = b.callMethod("getAttribute", on: element, withArgs: [attrName])
                    b.callMethod("setAttribute", on: element, withArgs: [attrName, b.loadString(b.randomString())])
                }
                return element
            }, {
                // Content manipulation
                let content = b.loadString("<span>" + b.randomString() + "</span>")
                return withEqualProbability({
                    b.callMethod("before", on: element, withArgs: [content])
                }, {
                    b.callMethod("after", on: element, withArgs: [content])
                }, {
                    b.callMethod("append", on: element, withArgs: [content])
                })
            }, {
                // Remove element
                b.callMethod("remove", on: element)
            })
        }
        b.setProperty("element", of: handler, to: elementCallback)
    }

    // Randomly add comments callback
    if probability(0.5) {
        let commentsCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let comment = args[0]
            b.callMethod("remove", on: comment)
        }
        b.setProperty("comments", of: handler, to: commentsCallback)
    }

    // Randomly add text callback
    if probability(0.5) {
        let textCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let textChunk = args[0]
            let text = b.getProperty("text", of: textChunk)
            b.callMethod("replace", on: textChunk, withArgs: [b.loadString(b.randomString())])
        }
        b.setProperty("text", of: handler, to: textCallback)
    }
}

public let HTMLRewriterTransformGenerator = CodeGenerator("HTMLRewriterTransformGenerator") { b in
    // Create a mock response
    let Response = b.createNamedVariable(forBuiltin: "Response")
    let htmlContent = b.loadString("<html><body><div>Test</div></body></html>")
    let response = b.construct(Response, withArgs: [htmlContent])

    // Create HTMLRewriter
    let HTMLRewriter = b.createNamedVariable(forBuiltin: "HTMLRewriter")
    let rewriter = b.construct(HTMLRewriter)

    // Add multiple handlers
    for _ in 0..<Int.random(in: 1...3) {
        let selector = b.loadString(chooseUniform(from: ["div", "p", "a", "*", "[class]"]))
        let handler = b.createObject(with: [:])

        let callback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let element = args[0]
            b.callMethod("setAttribute", on: element, withArgs: [
                b.loadString("data-processed"),
                b.loadString("true")
            ])
        }
        b.setProperty("element", of: handler, to: callback)

        b.callMethod("on", on: rewriter, withArgs: [selector, handler])
    }

    // Transform the response
    _ = b.callMethod("transform", on: rewriter, withArgs: [response])
}

public let SelectorMatchingGenerator = CodeGenerator("SelectorMatchingGenerator") { b in
    let HTMLRewriter = b.createNamedVariable(forBuiltin: "HTMLRewriter")
    let rewriter = b.construct(HTMLRewriter)

    let selectors = [
        "div", "p", ".class", "#id", "[attr]",
        "div > p", "div p", "div + p",
        "[href^='http']", "[class~='test']",
        "p:first-child", "*"
    ]

    // Add handlers for random selectors
    for _ in 0..<Int.random(in: 2...4) {
        let selector = b.loadString(chooseUniform(from: selectors))
        let handler = b.createObject(with: [:])

        let callback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let element = args[0]
            b.callMethod("setAttribute", on: element, withArgs: [
                b.loadString("data-selector"),
                selector
            ])
        }
        b.setProperty("element", of: handler, to: callback)

        b.callMethod("on", on: rewriter, withArgs: [selector, handler])
    }
}

private func htmlRewriterElementHandler(in b: ProgramBuilder) -> Variable {
    let handler = b.createObject(with: [:])

    if probability(0.7) {
        let elementCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let element = args[0]
            withEqualProbability({
                let attrName = b.loadString(
                    chooseUniform(from: ["class", "id", "href", "src", "data-tag"])
                )
                let hasAttr = b.callMethod("hasAttribute", on: element, withArgs: [attrName])
                b.buildIf(hasAttr) {
                    let attrValue = b.callMethod("getAttribute", on: element, withArgs: [attrName])
                    b.callMethod("setAttribute", on: element, withArgs: [attrName, attrValue])
                }
                if probability(0.5) {
                    b.callMethod(
                        "setAttribute",
                        on: element,
                        withArgs: [attrName, b.loadString(b.randomString())]
                    )
                }
                return ()
            }, {
                let chunk = b.loadString("<span>\(b.randomString())</span>")
                withEqualProbability({
                    b.callMethod("append", on: element, withArgs: [chunk])
                }, {
                    b.callMethod("prepend", on: element, withArgs: [chunk])
                }, {
                    b.callMethod("before", on: element, withArgs: [chunk])
                }, {
                    b.callMethod("after", on: element, withArgs: [chunk])
                })
                return ()
            }, {
                let inner = b.loadString("<em>\(b.randomString())</em>")
                b.callMethod("setInnerContent", on: element, withArgs: [inner])
                return ()
            }, {
                b.callMethod("remove", on: element)
                return ()
            })
        }
        b.setProperty("element", of: handler, to: elementCallback)
    }

    if probability(0.5) {
        let commentsCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let comment = args[0]
            withEqualProbability({
                b.callMethod("remove", on: comment)
            }, {
                b.callMethod("replace", on: comment, withArgs: [b.loadString(b.randomString())])
            })
        }
        b.setProperty("comments", of: handler, to: commentsCallback)
    }

    if probability(0.5) {
        let textCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let textChunk = args[0]
            let currentText = b.getProperty("text", of: textChunk)
            let slice = b.callMethod(
                "slice",
                on: currentText,
                withArgs: [b.loadInt(0), b.loadInt(Int64.random(in: 0...8))]
            )
            b.callMethod("replace", on: textChunk, withArgs: [slice])
        }
        b.setProperty("text", of: handler, to: textCallback)
    }

    return handler
}

private func htmlRewriterDocumentHandler(in b: ProgramBuilder) -> Variable {
    let handler = b.createObject(with: [:])

    let endCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
        let docEnd = args[0]
        withEqualProbability({
            b.callMethod("append", on: docEnd, withArgs: [b.loadString("<!-- Processed -->")])
        }, {
            b.callMethod("prepend", on: docEnd, withArgs: [b.loadString("<!-- Preface -->")])
        }, {
            b.callMethod("after", on: docEnd, withArgs: [b.loadString("<!-- Tail -->")])
        })
    }
    b.setProperty("end", of: handler, to: endCallback)

    if probability(0.4) {
        let elementCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
            let element = args[0]
            b.callMethod(
                "setAttribute",
                on: element,
                withArgs: [b.loadString("data-document"), b.loadString("true")]
            )
        }
        b.setProperty("element", of: handler, to: elementCallback)
    }

    return handler
}

private func randomHTMLFixture() -> String {
    return chooseUniform(
        from: [
            """
            <!DOCTYPE html>
            <html lang="en">
                <head>
                    <title>Example</title>
                </head>
                <body>
                    <section data-block="one">
                        <h1>Heading</h1>
                        <p>Sample paragraph.</p>
                        <a href="https://example.com">Link</a>
                    </section>
                    <!-- Marker -->
                </body>
            </html>
            """,
            """
            <article>
                <header>
                    <h2>Article Title</h2>
                </header>
                <div class="content">
                    <p>First paragraph.</p>
                    <p>Second paragraph with <strong>emphasis</strong>.</p>
                </div>
                <footer>Footer content</footer>
            </article>
            """,
            """
            <div id="wrapper">
                <ul class="items">
                    <li data-index="1">One</li>
                    <li data-index="2">Two</li>
                    <li data-index="3">Three</li>
                </ul>
                <template id="template">
                    <span data-template="yes"></span>
                </template>
            </div>
            """
        ]
    )
}

public let HTMLRewriterFuzzer = ProgramTemplate("HTMLRewriterFuzzer") { b in
    b.buildPrefix()

    // Check that the Workerd-specific builtins we rely on are actually available before using them.
    let htmlRewriterType = b.eval("typeof HTMLRewriter", hasOutput: true)!
    let responseType = b.eval("typeof Response", hasOutput: true)!
    let undefinedString = b.loadString("undefined")
    let hasHTMLRewriter = b.compare(htmlRewriterType, with: undefinedString, using: .strictNotEqual)
    let hasResponse = b.compare(responseType, with: undefinedString, using: .strictNotEqual)
    let canUseHTMLRewriter = b.binary(hasHTMLRewriter, hasResponse, with: .LogicAnd)

    b.buildIfElse(canUseHTMLRewriter, ifBody: {
        // Build the HTML payload and response init options.
        let Response = b.createNamedVariable(forBuiltin: "Response")
        let html = b.loadString(randomHTMLFixture())
        let Headers = b.createNamedVariable(forBuiltin: "Headers")
        let headers = b.construct(Headers)
        b.callMethod("set", on: headers, withArgs: [b.loadString("content-type"), b.loadString("text/html")])
        if probability(0.4) {
            b.callMethod("append", on: headers, withArgs: [b.loadString("x-meta"), b.loadString(b.randomString())])
        }
        var responseInitProperties: [String: Variable] = ["headers": headers]
        if probability(0.4) {
            responseInitProperties["status"] = b.loadInt(Int64(Int.random(in: 200...599)))
        }
        if probability(0.3) {
            responseInitProperties["statusText"] = b.loadString(b.randomString())
        }
        let responseInit = b.createObject(with: responseInitProperties)
        let response = b.construct(Response, withArgs: [html, responseInit])

        // Create HTMLRewriter and register handlers.
        let HTMLRewriter = b.createNamedVariable(forBuiltin: "HTMLRewriter")
        let rewriter = b.construct(HTMLRewriter)
        let selectorPool = [
            "*", "div", "p", ".content", ".items > li",
            "#wrapper", "[data-block]", "article > *", "section:first-child"
        ]
        let handlerCount = Int.random(in: 1...4)
        for _ in 0..<handlerCount {
            let handler = htmlRewriterElementHandler(in: b)
            let selector = b.loadString(chooseUniform(from: selectorPool))
            b.callMethod("on", on: rewriter, withArgs: [selector, handler])
        }
        if probability(0.7) {
            let docHandler = htmlRewriterDocumentHandler(in: b)
            b.callMethod("onDocument", on: rewriter, withArgs: [docHandler])
        }

        b.buildTryCatchFinally(tryBody: {
            let transformed = b.callMethod("transform", on: rewriter, withArgs: [response])
            if probability(0.5) {
                let cloned = b.callMethod("clone", on: transformed, withArgs: [])
                _ = b.callMethod("transform", on: rewriter, withArgs: [cloned])
            }
            if probability(0.6) {
                let textPromise = b.callMethod("text", on: transformed, withArgs: [])
                if probability(0.5) {
                    let thenCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
                        let text = args[0]
                        let preview = b.callMethod(
                            "slice",
                            on: text,
                            withArgs: [b.loadInt(0), b.loadInt(Int64.random(in: 0...12))]
                        )
                        b.callMethod("toString", on: preview, withArgs: [])
                    }
                    b.callMethod("then", on: textPromise, withArgs: [thenCallback])
                }
            }
            if probability(0.4) {
                let bufferPromise = b.callMethod("arrayBuffer", on: transformed, withArgs: [])
                if probability(0.5) {
                    let catchCallback = b.buildPlainFunction(with: .parameters(n: 1)) { args in
                        b.callMethod("toString", on: args[0], withArgs: [])
                    }
                    b.callMethod("catch", on: bufferPromise, withArgs: [catchCallback])
                }
            }
        }, catchBody: { err in
            b.callMethod("toString", on: err, withArgs: [])
        })

        b.build(n: Int.random(in: 2...5))
    }, elseBody: {
        // Fall back to generic code generation when the environment lacks Workerd APIs.
        b.build(n: 10)
    })

    b.build(n: 5)
}
