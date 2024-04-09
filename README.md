<p align="center">
  <img src="numem.png" alt="NuMem" style="width: 50%; max-width: 512px; height: auto;">
</p>

[![Unit Test Status](https://github.com/Inochi2D/numem/actions/workflows/d.yml/badge.svg)](https://github.com/Inochi2D/numem/actions/workflows/d.yml)

Nu:Mem is a package for D which implements various nogc memory managment tools, allowing classes, strings, and more to be handled safely in nogc mode.
This library is still a work in progress, but is intended to be used within Inochi2D's nogc rewrite to allow the library to have good ergonomics, 
while allowing more seamless integration with other programming languages.

&nbsp;
&nbsp;
&nbsp;

# Roadmap
This is a incomplete and unordered roadmap of features I want to add and have added

 - [x] Utilities for managing D classes with no gc
   - [x] nogc_new (nogc new alternative)
   - [x] nogc_delete (nogc destroy alternative)
 - [x] Smart (ref-counted) pointers.
   - [x] shared_ptr (strong reference)
   - [x] weak_ptr (weak, borrowed reference)
   - [x] unique_ptr (strong, single-owner reference)
 - [x] C++ style vector struct
 - [x] C++ style string struct
 - [x] C++ style map
 - [x] C++ style set
 - [ ] Safe nogc streams\*\*
   - [x] FileStream\*
   - [x] MemoryStream\*
   - [ ] NetworkStream
 - [x] Endianness utilities
 - [x] Support for minimal D runtime
   - [x] tinyd-rt\*\*
 - [x] File handling\*\*
   - [x] Check if file exists
   - [ ] Iterate directories
   - [ ] Cross platform path handling
 - [ ] Networking
   - [ ] Sockets
   - [ ] IP utilities
 - [ ] Character encoding handling
   - [ ] Unicode
   - [ ] Allow plugging more handlers in?
 - [ ] String formatting (compatible with phobos syntax?)

\*: Implemented but untested.  
\*\*: Partially implemented.

# Note
Some parts of the library will pretend GC'ed types are no-gc, as such you should be careful about mixing GCed code in.