# ZipStreams
A Julia package to burn through ZIP archives as fast as possible by ignoring
standards just a little bit.

## Overview
> "There are three ways to do things: the right way, the wrong way, and the Max Power way."
>
> -Homer from The Simpsons, season 10, episode 13: "Homer to the Max"

ZIP archives are optimized for _appending_ and _deleting_ operations. This is
because the canonical source of information for what is stored in a ZIP archive,
the "Central Directory", is written at the very end of the archive. Users
who want to append a file to the archive can overwrite the Central Directory with
new file data, then append an updated Central Directory afterward, and nothing
else in the file has to be touched. Likewise, users who want to delete files in
the archive only have to change the entries in the Central Directory: readers
that conform to the _de facto_ standard described in the [PKWARE APPNOTE file](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)
will ignore the files that are no longer listed.

This design choice means that standards-conformant readers like [`ZipFile.jl`](https://github.com/fhs/ZipFile.jl)
cannot know what files are stored in a ZIP archive until they read to the very end of
the file. While this is not typically a problem on modern SSD-based storage, where
random file access is fast, it is a major limitation on stream-based file transfer
systems like networks, where readers typically have no choice but to read an
entire file from beginning to end in order. This is not a problem for archives
with sizes on the order of megabytes, but standard ZIP archives can be as large as
4GB, which can easily overwhelm systems with limited memory or storage like
embedded systems or cloud-based micro-instances. To make matters worse, ZIP64
archives can be up to 16 EB (2^64 bytes) in size, which can easily overwhelm even
the largest of modern supercomputers.

However, the ZIP archive specification also requires a "Local File Header" that
preceeding the (possibly compressed) file data of every file in the archive. The
Local File Header contains enough information to allow a reader to extract the
file and perform simple error checking as long as three conditions are met:
1. The information in the Local File Header is correctly specified. The Central
Directory is the canonical source of information, so the Local File Header could
be lying.
2. The Central Directory is not encrypted. File sizes and checksum values are
masked from the Local File Header if the Central Directory is encrypted, so it is
impossible to know where the file ends and the next one begins.
3. The file is not stored with a "Data Descriptor" (general purpose flag 3). As
with encryption, files that are stored with a Data Descriptor have masked file
sizes and checksums in the Local File Header. This format is typically used only
when the archive is _written_ in a streaming fashion.

All this being said, most users will never see ZIP files that cannot be extracted
exclusively using Local File Header information.

## DO NOT BLINDLY TRUST ZIP ARCHIVES

By ignoring standards, this module makes no guarantees that what you get out of
the ZIP archive matches what you or anyone else put into it. The code is tested
against ZIP archives generated by various writers, but there are corner cases,
ambiguities in the standard, and even pathological ZIP files in the wild that may
silently break this package.

> _Bart:_ "Isn't that the wrong way?"
>
> _Homer:_ "Yeah, but faster!"
>
> -The Simpsons, season 10, episode 13: "Homer to the Max"

You have been warned!

## Installation and use

~~Install via the Julia package manager, `Pkg.add("ZipStreams")`.~~

Until the package is published, install via the Julia package manager with
`Pkg.add(; url="https://github.com/reallyasi9/ZipStreams.jl")`.

### Reading archives with `zipsource`

You can wrap any Julia readable `IO` object with the `zipsource` function. The returned
struct can be iterated to read archived files in archive order. Information about
each file is stored in the `.info` property of the struct returned from the
iterator. The struct returned from the iterator is readable like any standard
Julia `IO` object.

Here are some examples:

#### Iterating through file from an archive on disk

This is perhaps the most common way to work with ZIP archives: reading them from disk and
doing things with the contained files. Because `zipsource` reads from the beginning of the
file to the end, you can only iterate through files in archive order and cannot randomly
access files. Here is an example of how to work with this kind of file iteration:

```julia
using ZipStreams

# open an archive from an IO object
open("archive.zip") do io
    zs = zipsource(io)

    # iterate through files
    for f in zs
        
        # get information about each file from the .info property
        println(f.info.name)

        # read from the file just like any other IO object
        println(readline(f))
        
        println(read(f, String))
    end
end
```

You can use the `next_file` method to access the next file in the archive without iterating
in a loop. The method returns `nothing` if it reaches the end of the archive.

```julia
using ZipStreams

open("archive.zip") do io
    zs = zipsource(io)
    f = next_file(zs) # the first file in the archive, or nothing if there are no files archived
    # ...
    f = next_file(zs) # the next file in the archive, or nothing if there was only one file
    # ...
end
```

Because reading ZIP files from a file on disk is a common use case, a convenience
method taking a file name argument is provided:

```julia
using ZipStreams

zs = zipsource("archive.zip") # Note: the caller is responsible for closing this to free the file handle
# ... 
close(zs)
```

In addition, a method that mimics Julia's `open() do x ... end` behavior is
included for managing the lifetime of any file handles opened by `zipsource`:

```julia
using ZipStreams

zipsource("archive.zip") do zs
    # ...
end # file handle is automatically closed at the end of the block
```

The same method is defined for `IO` arguments, but it works slightly differently:
the object passed is _not_ closed when the block ends. It assumes that the
caller is responsible for the `IO` object's lifetime. However, manually calling `close`
on the source will always close the wrapped `IO` object. Here is an example:

```julia
using ZipStreams

io = open("archive.zip")
zipsource(io) do zs
    # ...
end
@assert isopen(io) == true

seekstart(io)
zipsource(io) do zs
    # ...
    close(zs) # called manually
end
@assert isopen(io) == false
```

#### Verifying the content of ZIP archives

A ZIP archive stores file sizes and checksums in two of three locations: one of 
either immediately before the archived file data (in the "Local File Header")
or immediately after the archived file data (in the "Data Descriptor"), and always
at the end of the file (in the "Central Directory"). Because the Central Directory
is considered the ground truth, the Local File Header and Data Descriptor may report
inaccurate values. To verify that the content of the file matches the values in the
Local File Header, use the `validate` method on the archived file. To verify that
all file content in the archive matches the values in the Central Directory, use
the `validate` method on the archive itself. These methods will throw an error if
they detect any inconsitencies.

For example, to validate the data in a single file stored in the archive:

```julia
using ZipStreams

zipsource("archive.zip") do zs
    f = next_file(zs)
    validate(f) # throws if there is an inconsistency
end
```

To validate the data in all of the _remaining_ files in the archive:

```julia
using ZipStreams

io = open("archive.zip")
zipsource(io) do zs
    validate(zs) # validate all files and the archive itself
end

seekstart(io)
zipsource(io) do zs
    f = next_file(zs) # read the first file
    validate(zs) # validate all files except the first!
end

close(io)
```

The `validate` methods consume the data in the source and return vectors of
raw bytes. When called on an archived file, it returns a single `Vector{UInt8}`.
When called on the archive itself, it returns a `Vector{Vector{UInt8}}` with
the remaining unread file data in archive order, _excluding any files that have already
been read by iterating or with `next_file`_.

```julia
using ZipStreams

zs = zipsource("archive.zip")
f1 = next_file(zs)
data1 = validate(f1) # contains all the file data as raw bytes
@assert typeof(data1) == Vector{UInt8}
close(zs)

zs = zipsource("archive.zip")
f2 = next_file(zs)
println(readline(f2)) # read a line off the file first
data2 = validate(f2) # contains the remaining file data excluding the first line!
@assert typeof(data2) == Vector{UInt8}
@assert sizeof(data2) < sizeof(data1)
close(zs)

zs = zipsource("archive.zip")
all_data = validate(zs) # returns a Vector{Vector{UInt8}} of all remaining files
@assert all_data[1] == data1
close(zs)
```

Note that these methods consume the data in the file or archive, as demonstrated in this
example:

```julia
using ZipStreams

zs = zipsource("archive.zip")
validate(zs)
@assert eof(zs) == true
```

### Creating archives and writing files with `zipsink`

You can wrap any `IO` object that supports writing bytes (any type that implements
`unsafe_write(::T, ::Ptr{UInt8}, ::UInt)`) in a special ZIP archive writer with the
`zipsink` function. The function will return an object that allows creating and writing
files within the archive. You can then call `open(sink, filename)` using the returned
object to create a new file in the archive and begin writting to it with standard `IO`
functions.

This example creates a new ZIP archive file on disk, creates a new file within the archive,
writes data to the file, then closes the file and archive:

```julia
using ZipStreams

io = open("new-archive.zip", "w")
sink = zipsink(io)
f = open(sink, "hello.txt")
write(f, "Hello, Julia!")
close(f)
close(sink)
```

Convenience methods are included that create a new file on disk by passing a file name to
`zipsink` instead of an `IO` object and that run a unary function so that `zipsink` can be
used like `Base.open() do io ... end`. In addition, the `open(sink, filename)` method can
also be used like `Base.open() do io ... end`, as this example shows:

```julia
using ZipStreams

zipsink("new-archive.zip") do sink  # create a new archive on disk and truncate it
    open(sink, "hello.txt") do f  # create a new file in the archive
        write(f, "Hello, Julia!")
    end  # automatically write a Data Descriptor to the archive and close the file
end  # automatically write the Central Directory and close the archive
```

Because the data are streamed to the archive, you can only have one file open for writing
at a time in a given archive. If you try to open a new file before closing the previous
file, a warning will be printed to the console and the previous file will automatically be
closed. In addition, any file still open for writing when the archive is closed will
automatically be closed before the archive is finalized, as this example demonstrates:

```julia
using ZipStreams

zipsink("new-archive.zip") do sink
    f1 = open(sink, "hello.txt")
    write(f1, "Hello, Julia!")
    f2 = open(sink, "goodbye.txt")  # issues a warning and closes f1 before opening f2
    write(f2, "Good bye, Julia!")
end  # automatically closes f2 before closing the archive
```

#### Writing files to an archive all at once with `write_file`

When you open a file for writing in a ZIP archive using `open(sink, filename)`, writing to
the file is done in a streaming fashion with a Data Descriptor written at the end of the
file data when it is closed. If you want to write an entire file to the archive at once,
you can use the `write_file(sink, filename, data)` method. This method will write file size
and checksum information to the archive using the Local File Header rather than a Data
Descriptor. The advantage to this method is that you can turn around and open the archive
using `zipsource`: when streamed for reading, the Local File Header will report the correct
file size, allowing proper streaming of the file data. The disadvantages to using this method
for writing data are that you need to have all of the data you want to write available at
one time and that both the raw data and the compressed data need to fit in memory at the
same time. Here are some examples using this method for writing files:

```julia
using ZipStreams

zipsink("new-archive.zip") do sink
    open(sink, "hello.txt") do f1
        write(f1, "Hello, Julia!")  # writes using a Data Descriptor
    end
end

try
    zipsource("new-archive.zip") do source
        f = next_file(source)  # fails because the size of the file cannot be read from the Local File Header
    end
catch e
    @error "exception caught" e
end

zipsink("new-archive.zip") do sink
    text = "Hello, Julia!"
    write_file(sink, "hello.txt", text)  # writes without a Data Descriptor
end

zipsource("new-archive.zip") do source
    f = next_file(source)  # can be streamed with zipsource
    @assert read(f, String) == "Hello, Julia!"
end
```

### Unstreamable reading and writing with `zipfile`


```julia
# open an enormous file from a network stream
using BufferedStreams
using HTTP
HTTP.open(:GET, "https://download.cms.gov/nppes/NPPES_Data_Dissemination_August_2022.zip") do http
    zipsource(BufferedInputStream(http)) do zs
        for f in zs
            println(f.info.name)
            break
        end
    end
end

# convenience method for opening an archive as a zipstream
zs = zipsource("archive.zip")
close(zs)

# convenience method for automatically closing the archive when done
zipsource("archive.zip") do zs
    ...
end

# local header information is stored while iterating through the archive,
# which allows validation against the central directory
zipsource("archive.zip") do zs

    # validate individual files
    for f in zs
        validate(f) # throws if there is a problem, returns file data
    end

    # validate the entire archive at once (including the remaining files)
    validate(zs) # throws if there is a problem, returns a vector of file data
end
```

# Notes and aspirations

This package was inspired by frustrations at using more standard ZIP archive
reader/writers like [`ZipFile.jl`](https://github.com/fhs/ZipFile.jl). That's
not to say ZipFile.jl is bad--on the contrary, it is _way_ more
standards-compliant than this package ever intends to be! As you can see from
the history of this repository, much of the work here started as a fork of
that package.

## To do

* Document `zipsink` and `open` writing functionality
* Add Documenter.jl hooks
* Add benchmarks
* Mock read-only and write-only streams for testing
* Add all-at-once file writing
* Add filesystem-like `open` function for reading.
* Make the user responsible for closing files if `open() do x ... end` syntax is not used.
