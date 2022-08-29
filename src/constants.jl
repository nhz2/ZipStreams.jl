const SIG_L = UInt16(0x4b50) # "PK" in LE ASCII, first 2 bytes in all headers

const SIG_LOCAL_FILE = UInt32(0x04034b50)
const SIG_EXTRA_DATA = UInt32(0x08064b50)
const SIG_CENTRAL_DIRECTORY = UInt32(0x02014b50)
const SIG_DIGITAL_SIGNATURE = UInt32(0x05054b50) # Forbidden by ISO/IEC 21320-1
const SIG_END_OF_CENTRAL_DIRECTORY = UInt32(0x06054b50)
const SIG_ZIP64_CENTRAL_DIRECTORY_LOCATOR = UInt32(0x07064b50)
const SIG_ZIP64_END_OF_CENTRAL_DIRECTORY = UInt32(0x06064b50)
const SIG_DATA_DESCRIPTOR = UInt32(0x08074b50) # Non-standard, see 4.3.9.3

const SIG_LOCAL_FILE_H = UInt16(0x0403)
const SIG_EXTRA_DATA_H = UInt16(0x0806)
const SIG_CENTRAL_DIRECTORY_H = UInt16(0x0201)
const SIG_DIGITAL_SIGNATURE_H = UInt16(0x0505) # Forbidden by ISO/IEC 21320-1
const SIG_END_OF_CENTRAL_DIRECTORY_H = UInt16(0x0605)
const SIG_ZIP64_CENTRAL_DIRECTORY_LOCATOR_H = UInt16(0x0706)
const SIG_ZIP64_END_OF_CENTRAL_DIRECTORY_H = UInt16(0x0606)
const SIG_DATA_DESCRIPTOR_H = UInt16(0x0807) # Non-standard, see 4.3.9.3

const ZIP64_MINIMUM_VERSION = UInt16(45)
const DEFLATE_OR_FOLDER_MINIMUM_VERSION = UInt16(20)
const DEFAULT_VERSION = UInt16(10)

const MASK_COMPRESSION_OPTIONS = UInt16(0x0006)

const FLAG_FILE_SIZE_FOLLOWS = UInt16(0x0008)
const FLAG_PATCHED_DATA = UInt16(0x0020) # Forbidden by ISO/IEC 21320-1
const FLAG_STRONG_ENCRYPTION = UInt16(0x0040) # Forbidden by ISO/IEC 21320-1
const FLAG_LANGUAGE_ENCODING = UInt16(0x0800)
const FLAG_HEADER_MASKED = UInt16(0x2000) # Forbidden by ISO/IEC 21320-1

# Forbidden by ISO/IEC 21320-1
const OPTION_IMPLODE_WINDOW_8K = UInt16(0x0002)
const OPTION_IMPLODE_SF_3TREES = UInt16(0x0004)

const OPTION_DEFLATE_NORMAL = UInt16(0x0000)
const OPTION_DEFLATE_MAXIMUM = UInt16(0x0002)
const OPTION_DEFLATE_FAST = UInt16(0x0004)
const OPTION_DEFLATE_SUPER_FAST = UInt16(0x0006)

# Forbidden by ISO/IEC 21320-1
const OPTION_LZMA_EOS = UInt16(0x0002)

const COMPRESSION_STORE = UInt16(0)
const COMPRESSION_SHRINK = UInt16(1) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_REDUCE1 = UInt16(2) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_REDUCE2 = UInt16(3) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_REDUCE3 = UInt16(4) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_REDUCE4 = UInt16(5) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_IMPLODE = UInt16(6) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_DEFLATE = UInt16(8)
const COMPRESSION_DEFLATE64 = UInt16(9) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_OLD_TERSE = UInt16(10) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_BZIP2 = UInt16(12) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_LZMA = UInt16(14) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_CMPSC = UInt16(16) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_TERSE = UInt16(18) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_LZ77 = UInt16(19) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_ZSTD = UInt16(93) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_MP3 = UInt16(94) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_XZ = UInt16(95) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_JPEG = UInt16(96) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_WAVPACK = UInt16(97) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_PPMD = UInt16(98) # Forbidden by ISO/IEC 21320-1
const COMPRESSION_AEX = UInt16(99) # Forbidden by ISO/IEC 21320-1

const COMPRESSION_LOOKUP = Dict{Symbol,UInt16}(
    :store => COMPRESSION_STORE,
    :deflate => COMPRESSION_DEFLATE,
)

function compression_code(s::Symbol)
    return COMPRESSION_LOOKUP[s]
end
compression_code(x::UInt16) = x

const HEADER_ZIP64 = UInt16(0x0001)
const HEADER_AV_INFO = UInt16(0x0007)
const HEADER_OS2 = UInt16(0x0009)
const HEADER_NTFS = UInt16(0x000a)
const HEADER_OPENVMS = UInt16(0x000c)
const HEADER_UNIX = UInt16(0x000d)
const HEADER_PATCH_DESCRIPTOR = UInt16(0x000f) # Forbidden by ISO/IEC 21320-1
const HEADER_CERTIFICATE_STORE = UInt16(0x0014) # Forbidden by ISO/IEC 21320-1
const HEADER_CENTRAL_DIRECTORY_CERTIFICATE_ID = UInt16(0x0016) # Forbidden by ISO/IEC 21320-1
const HEADER_STRONG_ENCRYPTION = UInt16(0x0017) # Forbidden by ISO/IEC 21320-1
const HEADER_RECORD_MANAGEMENT_CONTROLS = UInt16(0x0018) # Forbidden by ISO/IEC 21320-1
const HEADER_RECIPIENT_CERTIFICATE_LIST = UInt16(0x0019) # Forbidden by ISO/IEC 21320-1
const HEADER_POLICY_DECRYPTION_KEY = UInt16(0x0021) # Forbidden by ISO/IEC 21320-1
const HEADER_SMARTCRYPT_KEY_PROVIDER = UInt16(0x0022) # Forbidden by ISO/IEC 21320-1
const HEADER_SMARTCRYPT_POLICY_KEY_DATA = UInt16(0x0023) # Forbidden by ISO/IEC 21320-1
const HEADER_S390_AS400 = UInt16(0x0065) # Forbidden by ISO/IEC 21320-1

const ZIP_PATH_DELIMITER = "/"