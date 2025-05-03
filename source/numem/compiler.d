/**
    Numem Compiler Traits and Information.

    New definitions are added to this file over time to have a central place
    to query about compiler differences which may cause compilation to fail.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
*/
module numem.compiler;

version(D_Ddoc) {

    /**
        Whether the compiler being used for this compilation is strict
        about types and function definitions matching exactly.

        This flag allows libraries to detect this case and revert to
        using libdruntime or libphobos definitions for things like
        C symbols.
    */
    enum NU_COMPILER_STRICT_TYPES;

} else version(LDC) { 
    import ldc.intrinsics;

    // NOTE:    Before LLVM 17 typed pointers were provided by the IR.
    //          These typed pointers can cause conflicts if symbols are redeclared,
    //          as nulib and other libraries may end up redefining symbols
    //          workarounds may need to be employed. This enum helps dependents
    //          detect this case.
    enum NU_COMPILER_STRICT_TYPES = LLVM_version < 1700;
} else version(GNU) {

    // NOTE:    GDC is *always* strict about type matches, so this should always
    //          be enabled there.
    enum NU_COMPILER_STRICT_TYPES = true; 
} else version(DMD) {
    
    // NOTE:    DMD, to my understanding hasn't been too strict about types.
    enum NU_COMPILER_STRICT_TYPES = __VERSION__ < 2100; 
} else {
    
    // NOTE:    For any other compiler it's better to be on the safe side.
    enum NU_COMPILER_STRICT_TYPES = true; 
}

