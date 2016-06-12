// This code is taken (with minimal modifications) from https://github.com/apple/swift-package-manager/blob/c8f754b60d7888c1fb1dc3c356f7ec3dd99629c1/Sources/POSIX/system.swift
// Copyright 2015 - 2016 Apple Inc. and the Swift project authors.
// Licensed under Apache License v2.0 with Runtime Library Exception.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif


public enum SystemError: ErrorProtocol {
    case close(Int32)
    case pipe(Int32)
    case posix_spawn(Int32, [String])
    case read(Int32)
    case waitpid(Int32)
}


#if os(OSX)
typealias swiffer_posix_spawn_file_actions_t = posix_spawn_file_actions_t?
#else
typealias swiffer_posix_spawn_file_actions_t = posix_spawn_file_actions_t
#endif

/// Convenience wrapper for posix_spawn.
func posix_spawnp(_ path: String, args: [String],
                  fileActions: swiffer_posix_spawn_file_actions_t? = nil) throws -> pid_t {
    let argv: [UnsafeMutablePointer<CChar>?] = args.map{ $0.withCString(strdup) }
    defer { for case let arg? in argv { free(arg) } }

    var pid = pid_t()
    let rv: Int32
    if var fileActions = fileActions {
        rv = posix_spawnp(&pid, argv[0], &fileActions, nil, argv + [nil], nil)
    } else {
        rv = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], nil)
    }
    guard rv == 0 else {
        throw SystemError.posix_spawn(rv, args)
    }

    return pid
}

private func _WSTATUS(_ status: CInt) -> CInt {
    return status & 0x7f
}

private func WIFEXITED(_ status: CInt) -> Bool {
    return _WSTATUS(status) == 0
}

private func WEXITSTATUS(_ status: CInt) -> CInt {
    return (status >> 8) & 0xff
}

/// convenience wrapper for waitpid
func waitpid(_ pid: pid_t) throws -> Int32 {
    while true {
        var exitStatus: Int32 = 0
        let rv = waitpid(pid, &exitStatus, 0)

        if rv != -1 {
            if WIFEXITED(exitStatus) {
                return WEXITSTATUS(exitStatus)
            }
        } else if errno == EINTR {
            continue
        } else {
            throw SystemError.waitpid(errno)
        }
    }
}
