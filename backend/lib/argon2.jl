module Argon2

using Random # For generating salt
using Base64 # For base64 encoding/decoding if needed, but Argon2 encoded string handles it
using Printf # For sprintf-like string formatting in errors

# --- Configuration for Argon2 Parameters (Adjust these values as needed) ---
# These are global constants within the module, user can override them by re-defining
# them in their application or by passing them to the functions if exposed as arguments.
const T_COST = 3       # Time cost (number of iterations). Higher is slower, more secure.
const M_COST_KIB = 65536 # Memory cost in KiB (e.g., 64MB = 65536 KiB). Higher is slower, more secure.
const P_COST = 1       # Parallelism (number of threads). Higher is slower, more secure.
const SALT_LEN_BYTES = 16 # Length of the random salt in bytes (16 bytes is standard)
const HASH_LEN_BYTES = 32 # Desired length of the final hash in bytes (32 bytes is standard for Argon2)

# Maximum length for the encoded hash string (PHC string format).
# This depends on your parameters. A safe upper bound for common parameters is around 128 bytes.
# Example: $argon2id$v=19$m=65536,t=3,p=1$SALTBASE64$HASHBASE64
# You might need to adjust this if you use very different parameters or longer salts/hashes.
const ENCODED_LEN_MAX = 128

# --- Argon2 C Library Path Determination ---
# This function helps locate the shared library based on the operating system.
# Users might need to adjust this if libargon2 is installed in a non-standard location.
function get_argon2_lib_path()::String
    if Sys.islinux()
        return "libargon2.so.1"
    elseif Sys.isapple()
        return "libargon2.dylib"
    elseif Sys.iswindows()
        # On Windows, you might need the full path if argon2.dll is not in a system PATH directory.
        # For example: return "C:\\path\\to\\your\\argon2.dll"
        return "argon2.dll"
    else
        error("Unsupported operating system for Argon2 library discovery.")
    end
end

const ARGON2_LIB_PATH = get_argon2_lib_path()

# --- C Type Definitions and Error Codes ---
# Define C-compatible types for clarity in ccall.
const C_UINT32 = Cuint
const C_SIZE_T = Csize_t
const C_PCHAR = Ptr{Cchar}
const C_PVOID = Ptr{Cvoid}
const C_INT = Cint

# Argon2 error codes (from argon2.h)
# typedef enum {
#     ARGON2_OK = 0,
#     ARGON2_OUTPUT_PTR_NULL,
#     ARGON2_OUTPUT_TOO_SHORT,
#     ARGON2_OUTPUT_TOO_LONG,
#     ARGON2_PWD_TOO_SHORT,
#     ARGON2_PWD_TOO_LONG,
#     ARGON2_SALT_TOO_SHORT,
#     ARGON2_SALT_TOO_LONG,
#     ARGON2_AD_TOO_SHORT,
#     ARGON2_AD_TOO_LONG,
#     ARGON2_SECRET_TOO_SHORT,
#     ARGON2_SECRET_TOO_LONG,
#     ARGON2_TIME_TOO_SMALL,
#     ARGON2_TIME_TOO_LARGE,
#     ARGON2_MEMORY_TOO_LITTLE,
#     ARGON2_MEMORY_TOO_MUCH,
#     ARGON2_LANES_TOO_SMALL,
#     ARGON2_LANES_TOO_LARGE,
#     ARGON2_PWD_PTR_MISMATCH,
#     ARGON2_SALT_PTR_MISMATCH,
#     ARGON2_AD_PTR_MISMATCH,
#     ARGON2_SECRET_PTR_MISMATCH,
#     ARGON2_PWD_REF_FAILED,
#     ARGON2_AD_REF_FAILED,
#     ARGON2_SECRET_REF_FAILED,
#     ARGON2_ENCODED_LEN_TOO_SHORT,
#     ARGON2_CUSTOM_PALETTE_TOO_LIGHT,
#     ARGON2_VERIFY_MISMATCH,
#     ARGON2_DECODING_FAIL,
#     ARGON2_THREAD_FAIL,
#     ARGON2_ALLOCFAIL,
#     ARGON2_FREEFAIL,
#     ARGON2_MISMATCH = -1
# } argon2_error_t;
const ARGON2_OK = 0
#const ARGON2_VERIFY_MISMATCH = -28 # From argon2.h, for verification failures
const ARGON2_VERIFY_MISMATCH = -35 

# Argon2 type (ARGON2_I, ARGON2_D, ARGON2_ID)
# typedef enum { ARGON2_D = 0, ARGON2_I = 1, ARGON2_ID = 2 } argon2_type;
const ARGON2_TYPE_ID = C_UINT32(2) # Argon2id is the recommended hybrid variant

# Function to get human-readable error messages from the C library
# C signature: const char* argon2_error_message(int error_code);
function argon2_get_error_message(error_code::C_INT)::String
    msg_ptr = ccall(
        (:argon2_error_message, ARGON2_LIB_PATH),
        C_PCHAR,
        (C_INT,),
        error_code
    )
    return unsafe_string(msg_ptr)
end

# --- Module Entry Points ---

"""
    hash_password(password::String)

Hashes a plain text password using Argon2id with default parameters.
Returns the Argon2 hash string in PHC string format.
Throws an error if hashing fails.
"""
function hash_password(password::String)::String
    pwd_bytes = Vector{UInt8}(password)
    pwd_len = C_SIZE_T(length(pwd_bytes))

    salt_bytes = rand(UInt8, SALT_LEN_BYTES) # Generate random salt
    salt_len = C_SIZE_T(SALT_LEN_BYTES)

    encoded_buffer = Vector{UInt8}(undef, ENCODED_LEN_MAX) # Buffer for output string
    encoded_len = C_SIZE_T(ENCODED_LEN_MAX)

    ret = ccall(
        (:argon2id_hash_encoded, ARGON2_LIB_PATH), # C function name and library
        C_INT,                                    # Return type: int
        (C_UINT32, C_UINT32, C_UINT32,            # time_cost, memory_cost, parallelism
         C_PVOID, C_SIZE_T,                       # password, password_len
         C_PVOID, C_SIZE_T,                       # salt, salt_len
         C_UINT32,                                # hash_len
         C_PCHAR, C_SIZE_T),                      # encoded_output_buffer, encoded_output_len
        C_UINT32(T_COST), C_UINT32(M_COST_KIB), C_UINT32(P_COST),
        pwd_bytes, pwd_len,
        salt_bytes, salt_len,
        C_UINT32(HASH_LEN_BYTES),
        encoded_buffer, encoded_len
    )

    if ret == ARGON2_OK
        # Find the null terminator if present, otherwise use the full buffer
        null_idx = findfirst(iszero, encoded_buffer)
        if isnothing(null_idx)
            return String(encoded_buffer)
        else
            return String(encoded_buffer[1:null_idx-1])
        end
    else
        error_msg = argon2_get_error_message(ret)
        error(@sprintf("Argon2 hashing failed with error code %d: %s", ret, error_msg))
    end
end

"""
    verify_password(password::String, hashed_password_encoded::String)

Verifies a plain text password against an Argon2 hash in PHC string format.
Returns `true` if the password matches, `false` otherwise.
Throws an error if verification encounters a non-mismatch issue.
"""
function verify_password(password::String, hashed_password_encoded::String)::Bool
    pwd_bytes = Vector{UInt8}(password)
    pwd_len = C_SIZE_T(length(pwd_bytes))

    ret = ccall(
        (:argon2_verify, ARGON2_LIB_PATH),
        C_INT,
        (C_PCHAR,
         C_PVOID, C_SIZE_T,
         C_UINT32),
        hashed_password_encoded,
        pwd_bytes, pwd_len,
        ARGON2_TYPE_ID
    )

    if ret == ARGON2_OK
        return true
    elseif ret == ARGON2_VERIFY_MISMATCH # Now correctly checks for -35
        return false # Password does not match
    else
        error_msg = argon2_get_error_message(ret)
        error(@sprintf("Argon2 verification failed with unexpected error code %d: %s", ret, error_msg))
    end
end

end # module Argon2Wrapper

# --- Simple Example Usage (outside the module for demonstration) ---
if abspath(PROGRAM_FILE) == @__FILE__
    using .Argon2

    println("--- Argon2 Hashing and Verification Example ---")

    test_password = "MySuperSecretPassword123!"

    println("\nHashing password: \"$test_password\"...")
    try
        hashed_pwd = Argon2.hash_password(test_password)
        println("Hashed password (PHC string format): $hashed_pwd")

        # Verify with the correct password
        println("\nVerifying with CORRECT password...")
        if Argon2.verify_password(test_password, hashed_pwd)
            println("Verification successful! Password matches.")
        else
            println("Verification FAILED! Password does NOT match. (This should not happen)")
        end

        # Verify with an incorrect password
        println("\nVerifying with INCORRECT password...")
        incorrect_password = "WrongPassword"
        if Argon2.verify_password(incorrect_password, hashed_pwd)
            println("Verification successful. (This should NOT happen for incorrect password)")
        else
            println("Verification FAILED! Password does NOT match. (As expected for incorrect password)")
        end

        # Verify with a different valid password (should fail)
        println("\nVerifying with a DIFFERENT valid password (should fail due to different salt)...")
        different_password = "AnotherSecretPassword456!"
        if Argon2.verify_password(different_password, hashed_pwd)
            println("Verification successful. (This should NOT happen)")
        else
            println("Verification FAILED! Password does NOT match. (As expected, different salt/hash)")
        end

    catch e
        @error "An error occurred during Argon2 operations: $(e)"
    end
end