import Fuzzilli
import Foundation

struct WorkerdFatalErrorCrashProcessor: FuzzingCrashProcessor {
    func process(
        _ program: Program,
        withSignal termsig: Int,
        withStderr stderr: String,
        withStdout stdout: String,
        origin: ProgramOrigin,
        behaviour: CrashBehaviour,
        isUnique: Bool,
        withExecTime exectime: TimeInterval,
        for fuzzer: Fuzzer
    ) -> Bool {
        guard behaviour != .deterministic else { return true }

        if stderr.trimmingCharacters(in: .whitespacesAndNewlines) == "workerd/jsg/setup.c++:38: fatal: V8 fatal error; location = :0; message = Check failed: __asan_address_is_poisoned(reinterpret_cast<const char*>(address) + i)." {
            return false
        }
        return true
    }
}
