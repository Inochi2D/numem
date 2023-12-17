# Nu:Mem
Nu:Mem is a package for D which implements various nogc memory managment tools, allowing classes, strings, and more to be handled safely in nogc mode.
This library is still a work in progress, but is intended to be used within Inochi2D's nogc rewrite to allow the library to have good ergonomics, 
while allowing more seamless integration with other programming languages.

# Roadmap
This is a incomplete and unordered roadmap of features I want to add and have added

 - [x] Utilities for managing D classes with no gc
   - [x] nogc_new (nogc new alternative)
   - [x] nogc_delete (nogc destroy alternative)
   - More to be added?
 - [x] Smart (ref-counted) pointers.
   - [x] shared_ptr (strong reference)
   - [x] weak_ptr (weak, borrowed reference)
   - [x] unique_ptr (strong, single-owner reference)
 - [x] C++ style vector struct
 - [ ] String and slice memory managment
 - [ ] Safe nogc streams (memory and file)
 - [ ] Safe(r) nogc array and buffer types.
 - [ ] Special reference counted class type?


# Note
Some parts of the library will pretend GC'ed types are no-gc, as such you should be careful about mixing GCed code in.