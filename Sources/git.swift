#if os(Linux)
import Glibc
#else
import Darwin.C
#endif


enum GitError: ErrorProtocol {
    case ExitedWithError(Int32)
    case Utf8DecodingException
}

/// The SHA1 of the empty tree
let emptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

/// Returns whether the repository has a HEAD or not
func headExists() throws -> Bool {
#if os(OSX)
    var fileActions: posix_spawn_file_actions_t? = nil
#else
    var fileActions = posix_spawn_file_actions_t()
#endif
    posix_spawn_file_actions_init(&fileActions)
    defer { posix_spawn_file_actions_destroy(&fileActions) }
    posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0)
    posix_spawn_file_actions_adddup2(&fileActions, STDOUT_FILENO, STDERR_FILENO)
    let pid = try posix_spawnp("git", args: ["git", "rev-parse", "--verify", "HEAD"],
                               fileActions: fileActions)
    let exitStatus = try waitpid(pid)
    return exitStatus == 0
}

func getDiff(_ against: String) throws -> String {
    // Create a pipe for reading the output
    var pipeFds: [Int32] = [0, 0]
    var rv = pipe(&pipeFds)
    guard rv == 0 else {
        throw SystemError.pipe(rv)
    }
#if os(OSX)
    var fileActions: posix_spawn_file_actions_t? = nil
#else
    var fileActions = posix_spawn_file_actions_t()
#endif
    posix_spawn_file_actions_init(&fileActions)
    defer { posix_spawn_file_actions_destroy(&fileActions) }

    // Use the write end of the pipe as stderr
    posix_spawn_file_actions_adddup2(&fileActions, pipeFds[1], STDOUT_FILENO)
    // Close pipe FDs in child
    posix_spawn_file_actions_addclose(&fileActions, pipeFds[0])
    posix_spawn_file_actions_addclose(&fileActions, pipeFds[1])

    // Launch actual Git command
    let pid = try posix_spawnp("git", args: ["git", "diff", "--cached", against, "--"],
                               fileActions: fileActions)
    // Close write end of pipe
    rv = close(pipeFds[1])
    guard rv == 0 else {
        throw SystemError.close(rv)
    }
    var diff = ""
    try _readOutputAsUtf8(fd: pipeFds[0]) { chunk in diff += chunk }
    // Close read end of pipe
    rv = close(pipeFds[0])
    guard rv == 0 else {
        throw SystemError.close(rv)
    }

    // Check that Git exited without error exit code
    let exitStatus = try waitpid(pid)
    guard exitStatus == 0 else {
        throw GitError.ExitedWithError(exitStatus)
    }
    return diff
 }

func _readOutputAsUtf8(fd: Int32, consumer: (String) -> Void) throws {
    let bufSize = 16 * 1024
    var buf = [Int8](repeating: 0, count: bufSize + 1)

    loop: while true {
        let bytesRead = read(fd, &buf, bufSize)
        switch bytesRead {
        case -1:
            if errno == EINTR {
                continue
            } else {
                throw SystemError.read(errno)
            }
        case 0:
            // EOF
            break loop
        default:
            buf[bufSize] = 0
            if let str = String(validatingUTF8: buf) {
                consumer(str)
            } else {
                throw GitError.Utf8DecodingException
            }
        }
    }
}
