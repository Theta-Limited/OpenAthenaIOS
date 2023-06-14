import Foundation
#if canImport(NSExceptionSwift_ObjC)
import NSExceptionSwift_ObjC
#endif

/// Executes the `block` and whether returns its result or,
/// if an exception has been thrown in an Objective-C invocation,
/// rethrows `NSException` as a Swift error.
///
/// - Important: NSException is fundamentally incompatible with
///   ARC, so it leads to memory leaks when thrown.
///
/// - Parameters:
///   - block: A closure that contains an invocation of an
///     Objective-C method that can throw an `NSException`
/// - Returns: The return value, if any, of the `block` closure.
public func handlingNSException<O>(
    _ block: () throws -> O
) throws -> O {
    #if canImport(Darwin)
    var exception: NSException?
    var rethrowError: Error?
    var result: O!
    __handlingNSException({
        do {
            result = try block()
        } catch {
            rethrowError = error
        }
    }, &exception)
    if let error = exception ?? rethrowError {
        throw error
    }
    return result
    #else
    return try block()
    #endif
}

#if canImport(Darwin)
extension NSException: Error {}
#endif
