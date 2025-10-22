// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Fuzzilli

let workderdProfile = Profile(
    processArgs: { randomize in
        var args = [
            "reprl",
        ]

        guard randomize else { return args }

        return args
    },

    processBinaries: { randomize in
        let bins = [
            "./bin/workerd-fuzzilli-asan",
            "./bin/workerd-fuzzilli-asan-lsan",
            "./bin/workerd-fuzzilli-cfi-ubsan",
            "./bin/workerd-fuzzilli-lsan",
            "./bin/workerd-fuzzilli-tsan",
            "./bin/workerd-fuzzilli-ubsan",
            "./bin/workerd-fuzzilli-ubsan-minimal",
        ]

        guard randomize else { return bins[0] }

        return bins.randomElement() ?? bins[0]
    },

    // ASan options.
    // - abort_on_error=true: We need asan to exit in a way that's detectable for Fuzzilli as a crash
    // - symbolize=false: Symbolization can tak a _very_ long time (> 1s), which may cause crashing samples to time out before the stack trace has been captured (in which case Fuzzilli will discard the sample)
    // - redzone=128: This value is used by Clusterfuzz for reproducing testcases so we should use the same value
    processEnv: [
        // "FUZZILLI_MODE": "REUSE_CONTEXT",
        // "FUZZILLI_MODE": "REUSE_ISOLATE",
        "FUZZILLI_MODE": "FULL_ISOLATION",
        "ASAN_OPTIONS": "abort_on_error=1:symbolize=0:print_stats=0:print_module_map=0:print_legend=0:print_scariness=0:print_summary=0:print_suppressions=0:print_stack_trace=0:halt_on_error=1:fast_unwind_on_fatal=1:allocator_may_return_null=0:handle_abort=1:handle_segv=1:handle_sigill=1:check_initialization_order=0:strict_init_order=0:print_full_thread_history=0:verbosity=0:redzone=128:max_redzone=256:quarantine_size_mb=0:malloc_context_size=0:check_printf=0:intercept_tls_get_addr=0:allow_addr2line=0:print_tids=0",
        "UBSAN_OPTIONS": "abort_on_error=1:symbolize=0:print_stacktrace=0:print_module_map=0:halt_on_error=1:verbosity=0:print_summary=0:silence_unsigned_overflow=1",
        "MSAN_OPTIONS": "abort_on_error=1:symbolize=0:print_stats=0:halt_on_error=1:verbosity=0:print_summary=0:print_tids=0",
        "TSAN_OPTIONS": "abort_on_error=1:symbolize=0:print_module_map=0:print_suppressions=0:print_stack_trace=0:halt_on_error=1:verbosity=0:print_summary=0:print_tids=0"
        // TODO: Other sanitizers
    ],


    maxExecsBeforeRespawn: 5_000,

    timeout: 250,

    codePrefix: """
                """,

    codeSuffix: """
                """,

    ecmaVersion: ECMAScriptVersion.es6,

    startupTests: [
        // Check that the fuzzilli integration is available.
        ("fuzzilli('FUZZILLI_PRINT', 'test')", .shouldSucceed),

        // Check that common crash types are detected.
        // IMMEDIATE_CRASH()
        ("fuzzilli('FUZZILLI_CRASH', 0)", .shouldCrash),
        // CHECK failure
        ("fuzzilli('FUZZILLI_CRASH', 1)", .shouldCrash),
        // DCHECK failure
        ("fuzzilli('FUZZILLI_CRASH', 2)", .shouldCrash),
        // Wild-write
        ("fuzzilli('FUZZILLI_CRASH', 3)", .shouldCrash),
        // use-after-free (ASan should catch)
        ("fuzzilli('FUZZILLI_CRASH', 4)", .shouldCrash),
        // out-of-bounds (libc++ hardening)
        ("fuzzilli('FUZZILLI_CRASH', 5)", .shouldCrash),
        // OOB that ASan catches; fallback to wild-write if not ASan
        ("fuzzilli('FUZZILLI_CRASH', 6)", .shouldCrash),
        // Attempt a large-stride write to trigger segfault only under certain builds.
        ("fuzzilli('FUZZILLI_CRASH', 7)", .shouldCrash),
        // Check that DEBUG is defined.
        ("fuzzilli('FUZZILLI_CRASH', 8)", .shouldCrash),
        // TODO: How to test all sanitizers

        // Check that gc is availlable - crash if not
        ("typeof gc === 'undefined' && fuzzilli('FUZZILLI_CRASH', 0)", .shouldSucceed),

        // Check that HTMLRewriter API is available - crash if not
        ("typeof HTMLRewriter === 'undefined' && fuzzilli('FUZZILLI_CRASH', 0)", .shouldSucceed),
        ("typeof Response === 'undefined' && fuzzilli('FUZZILLI_CRASH', 0)", .shouldSucceed),

        // Basic HTMLRewriter API tests - crash if not working
        ("const r = new HTMLRewriter(); !(r instanceof HTMLRewriter) && fuzzilli('FUZZILLI_CRASH', 0)", .shouldSucceed),
    ],

    additionalCodeGenerators: [
        // HTMLRewriter specific generators
        (HTMLRewriterConstructorGenerator,        10),
        (ElementHandlerGenerator,                 15),
        (HTMLRewriterTransformGenerator,          10),
        (SelectorMatchingGenerator,               10),

        // V8HoleFuzzing generators
        (ForceJITCompilationThroughLoopGenerator,  5),
        (ForceTurboFanCompilationGenerator,        5),
        (ForceMaglevCompilationGenerator,          5),
        (V8GcGenerator,                           10),
    ],

    additionalProgramTemplates: WeightedList<ProgramTemplate>([
        (MapTransitionFuzzer,    2),
        (V8RegExpFuzzer,         3),
        (WasmFastCallFuzzer,     1),
        (LazyDeoptFuzzer,        1),
        (WasmDeoptFuzzer,        1),
        (WasmTurbofanFuzzer,     1),
        // TODO: Make it work
        // (HTMLRewriterFuzzer,     25),
    ]),

    disabledCodeGenerators: [],

    disabledMutators: [],

    additionalBuiltins: [
        "gc": .function([.opt(gcOptions.instanceType)] => (.undefined | .jsPromise)),

        // HTMLRewriter API
        "HTMLRewriter": .htmlRewriterConstructor,
        "Headers": .workerdHeadersConstructor,
        "Response": .workerdResponseConstructor,
    ],

    additionalObjectGroups: [
        gcOptions,
        htmlRewriterGroup,
        htmlElementGroup,
        workerdHeadersGroup,
        workerdHeadersConstructorGroup,
        workerdResponseGroup,
        workerdResponseConstructorGroup
    ],

    additionalEnumerations: [.gcTypeEnum, .gcExecutionEnum],

    optionalPostProcessor: nil,

    optionalCrashProcessor: WorkerdFatalErrorCrashProcessor()
)
