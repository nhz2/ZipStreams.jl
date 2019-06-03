using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libz"], :libz),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, libc=:glibc) => ("$bin_prefix/Zlib.v1.2.11.aarch64-linux-gnu.tar.gz", "3431c1a7d937cbad379ae5fe78c11dd0d425a6bce02b12c9d7c89e0a3173af97"),
    Linux(:aarch64, libc=:musl) => ("$bin_prefix/Zlib.v1.2.11.aarch64-linux-musl.tar.gz", "7f89328d100f16ab75d37759cdb4df98d8f5b192146eacbe23fa859c6d7bca09"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf) => ("$bin_prefix/Zlib.v1.2.11.arm-linux-gnueabihf.tar.gz", "04abd9100d2d24a56e50d536679c2df317d6c344b3ae06feb77681533377652f"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf) => ("$bin_prefix/Zlib.v1.2.11.arm-linux-musleabihf.tar.gz", "fd4fd26462039de7135b5ad09f0c86ec441afd9bb7feb2689f705bc9b087931f"),
    Linux(:i686, libc=:glibc) => ("$bin_prefix/Zlib.v1.2.11.i686-linux-gnu.tar.gz", "41495344e20619158a05561db8a7ccb9c57192dc5038744419bb9bd58eba7b7a"),
    Linux(:i686, libc=:musl) => ("$bin_prefix/Zlib.v1.2.11.i686-linux-musl.tar.gz", "c5d101f21c440156fdc8616bbe9f13f437dfed634cb17dbc65ed83c6b180533c"),
    Windows(:i686) => ("$bin_prefix/Zlib.v1.2.11.i686-w64-mingw32.tar.gz", "84d4d5037459ec706029c78a94c98b07760943662a4adbe21cd3d353ac3a0484"),
    Linux(:powerpc64le, libc=:glibc) => ("$bin_prefix/Zlib.v1.2.11.powerpc64le-linux-gnu.tar.gz", "c485627191c75411eaa66088427813a182c7ca0549f0dc21971c9452c45d8167"),
    MacOS(:x86_64) => ("$bin_prefix/Zlib.v1.2.11.x86_64-apple-darwin14.tar.gz", "a28fb652f94f1b1548197a3b3c9a71ec56fa50bb7d39454c5e12320335d30934"),
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/Zlib.v1.2.11.x86_64-linux-gnu.tar.gz", "1c3b1c8520713f98d3f605ee1ca5e2e3656d92ddb6441abeeeff0ae12a11a620"),
    Linux(:x86_64, libc=:musl) => ("$bin_prefix/Zlib.v1.2.11.x86_64-linux-musl.tar.gz", "17da1e44f7a815f5dc6eb66e3c7df8c80846c67d5212148a33fb68ea677e38dc"),
    FreeBSD(:x86_64) => ("$bin_prefix/Zlib.v1.2.11.x86_64-unknown-freebsd11.1.tar.gz", "87522b29c8dfb7681209fea541dcc09bd5863f55df9cb1de1645ec8484aad7b8"),
    Windows(:x86_64) => ("$bin_prefix/Zlib.v1.2.11.x86_64-w64-mingw32.tar.gz", "13934d974c5b1fd99897897b9af4ef7cce1025a1cdf1a57f14a9dd8e0258508a"),
    )

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
