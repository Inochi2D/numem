/**
    Helpers for creating special types.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.types;

/**
    Creates a new unique handle type.

    Handle types are pointers to opaque structs.

    Params:
        name = Unique name of the handle.

    Examples:
        ---
        alias VkInstance = OpaqueHandle!("VkInstance");
        ---
*/
template OpaqueHandle(string name) {
    struct OpaqueHandleT(string name);
    alias OpaqueHandle = OpaqueHandleT!(name)*;
}

@("OpaqueHandle")
unittest {
    alias HandleT1 = OpaqueHandle!("HandleT1");
    alias HandleT2 = OpaqueHandle!("HandleT2");

    assert(!is(HandleT1 == HandleT2));
    assert(!is(HandleT1 : HandleT2));
}

/**
    Creates a new type based on an existing type.

    Params:
        T = Base type of the typedef.
        name = An extra identifier for the type.
        init = Initializer value for this type.

    Examples:
        ---
        alias MyInt = TypeDef!(int, "MyInt");
        assert(!is(MyInt == int));
        ---
*/
template TypeDef(T, string name, T init = T.init) {
    import std.format : format;

    mixin(q{
        struct %s {
        @nogc nothrow:
        private:
            T value = init;

        public:
            alias BaseType = T;
            alias value this;

            static if ((is(T == struct) || is(T == union)) && !is(typeof({T t;}))) {
                @disable this();
            }
            this(T init) { this.value = init; }
            this(typeof(this) init) { this.value = init.value; }
        }
    }.format(name));

    alias TypeDef = mixin(name);
}

/**
    Gets the base type of a typedef.
*/
template TypeDefBase(T) {
    static if (is(typeof({ T.BaseType t; }))) {
        alias TypeDefBase = T.BaseType;
    } else {
        static assert(0, "Not a TypeDef!");
    }
}

@("TypeDef")
unittest {
    alias MyInt = TypeDef!(int, "MyInt");
    
    // They're not the same type, but they *are* implicitly convertible.
    assert(!is(MyInt == int));
    assert(is(MyInt : int));

    int i = 42;
    MyInt va = 42;

    assert(i == va);
    assert(TypeDefBase!MyInt.stringof == int.stringof);
}