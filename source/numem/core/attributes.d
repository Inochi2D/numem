/**
    Numem attribute hooks for various compilers.

    We implement them here to avoid relying on druntime,
    or phobos.

    Some of this code references druntime in dmd, ldc and gcc.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.attributes;

// TODO: Ask GCC maintainers whether this is OK licensing wise.
// Internal Helpers.
version(GDC) {
    private struct Attribute(A...) {
        A arguments;
    }
}

/**
    When applied to a global symbol, specifies that the symbol should be emitted
    with weak linkage. An example use case is a library function that should be
    overridable by user code.

    Quote from the LLVM manual: "Note that weak linkage does not actually allow
    the optimizer to inline the body of this function into callers because it
    doesn’t know if this definition of the function is the definitive definition
    within the program or whether it will be overridden by a stronger
    definition."

    Examples:
        $(D_CODE
            import numem.core.attributes;

            @weak int user_hook() { return 1; }
        )
*/
version(LDC) {
    immutable weak = _weak();
    private struct _weak { }
} else version(GDC) {
    enum weak = Attribute!string("weak");
} else {
    // NOTE: Not used by other compilers.
    struct weak;
}

/**
    When applied to a global variable or function, causes it to be emitted to a
    non-standard object file/executable section.

    The target platform might impose certain restrictions on the format for
    section names.

    Examples:
        $(D_CODE
            import numem.core.attributes;

            @section(".mySection") int myGlobal;
        )
*/
version(LDC) {
    struct section { string name; }
} else version(GDC) {
    auto section(string sectionName) {
        return Attribute!(string, string)("section", sectionName);
    }
} else {

    // DMD doesn't support this, but whatever.
    struct section { string name; }
}

/**
    Use this attribute to attach an Objective-C selector to a method.

    Examples:
        $(D_CODE
            extern (Objective-C)
            class NSObject
            {
                this() @selector("init");
                static NSObject alloc() @selector("alloc");
                NSObject initWithUTF8String(in char* str) @selector("initWithUTF8String:");
                ObjcObject copyScriptingValue(ObjcObject value, NSString key, NSDictionary properties)
                    @selector("copyScriptingValue:forKey:withProperties:");
            }
        )
*/
version(D_ObjectiveC)
struct selector {
    string selector;
}

/**
    Use this attribute to make an Objective-C interface method optional.

    An optional method is a method that does **not** have to be implemented in
    the class that implements the interface. To safely call an optional method,
    a runtime check should be performed to make sure the receiver implements the
    method.
*/
version(D_ObjectiveC)
enum optional;