module numem;
import std.conv : emplace;
import core.stdc.stdlib : free, exit, malloc;
import std.traits;
import core.stdc.stdio : printf;

nothrow @nogc:

//
//          MANUAL MEMORY MANAGMENT
//
private {
    // Based on code from dplug:core
    // which is released under the Boost license.

    auto assumeNoGC(T) (T t) {
        static if (isFunctionPointer!T || isDelegate!T)
        {
            enum attrs = functionAttributes!T | FunctionAttribute.nogc;
            return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
        }
        else
            static assert(false);
    }

    auto assumeNothrowNoGC(T) (T t) {
        static if (isFunctionPointer!T || isDelegate!T)
        {
            enum attrs = functionAttributes!T | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
            return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
        }
        else
            static assert(false);
    }

    version(minimal_rt) {
        
        struct classDestructorList(T) {
        @nogc nothrow:
            void function(T) destructorFunc;

            void initialize() {
                destructorFunc = (T instance) {
                    import std.traits : BaseTypeTuple;

                    // Scope for base class destructor
                    static foreach(item; BaseClassesTuple!T) {
                        {
                            static if (!is(item == Object) && !is(item == T)) {
                                static if (__traits(hasMember, item, "__xdtor")) {
                                    auto dtorptr = &item.init.__xdtor;
                                    dtorptr.ptr = cast(void*)instance;
                                    dtorptr();
                                } else static if (__traits(hasMember, item, "__dtor")) {
                                    auto dtorptr = &item.init.__dtor;
                                    dtorptr.ptr = cast(void*)instance;
                                    dtorptr();
                                }
                            }
                        }
                    }

                    // Scope for self destructor
                    {
                        static if (__traits(hasMember, T, "__xdtor")) {
                            auto dtorptr = &T.init.__xdtor;
                            dtorptr.ptr = cast(void*)instance;
                            dtorptr();
                        } else static if (__traits(hasMember, T, "__dtor")) {
                            auto dtorptr = &T.init.__dtor;
                            dtorptr.ptr = cast(void*)instance;
                            dtorptr();
                        }
                    }
                };
            }

            /**
                Destruct
            */
            void destruct(T instance) {
                destructorFunc(instance);
            }
        }
    }
}

extern(C):

/**
    Allocates a new struct on the heap.
    Immediately exits the application if out of memory.
*/
T* nogc_new(T, Args...)(Args args) if (is(T == struct)) {
    void* rawMemory = malloc(T.sizeof);
    if (!rawMemory) {
        exit(-1);
    }

    T* obj = cast(T*)rawMemory;
    emplace!T(obj, args);

    return obj;
}

/**
    Allocates a new class on the heap.
    Immediately exits the application if out of memory.
*/
T nogc_new(T, Args...)(Args args) if (is(T == class)) {
    version(minimal_rt) {
        immutable(size_t) destructorObjSize = classDestructorList!T.sizeof;
        immutable(size_t) classObjSize = __traits(classInstanceSize, T);
        immutable size_t allocSize = classObjSize + destructorObjSize;

        void* rawMemory = malloc(allocSize);
        if (!rawMemory) {
            exit(-1);
        }

        // Allocate class destructor list
        auto dlist = emplace!(classDestructorList!(T))(rawMemory[0..destructorObjSize]);
        dlist.initialize();

        // Allocate class
        T obj = emplace!T(rawMemory[destructorObjSize .. allocSize], args);
        return obj;

    } else {
        immutable size_t allocSize = __traits(classInstanceSize, T);
        void* rawMemory = malloc(allocSize);
        if (!rawMemory) {
            exit(-1);
        }

        T obj = emplace!T(rawMemory[0 .. allocSize], args);
        return obj;
    }
}

/**
    Destroys and frees the memory.

    For structs this will call the struct's destructor if it has any.
*/
void nogc_delete(T)(ref T obj_)  {
    
    version(minimal_rt) {
        static if (isPointer!T || is(T == class)) {
            if (obj_) {
            
                static if (is(T == class)) {

                    // Do pointer arithmetic to fetch the class destructor list and call it.
                    void* chunkStart = (cast(void*)obj_)-(classDestructorList!T).sizeof;
                    classDestructorList!(T)* destructorList = (cast(classDestructorList!(T)*)chunkStart);
                    destructorList.destruct(obj_);
                    free(chunkStart);

                } else static if (is(T == struct)) {

                    // Try to call elaborate destructor first before attempting __dtor
                    static if (__traits(hasMember, T, "__xdtor")) {
                        assumeNothrowNoGC(&obj_.__xdtor)();
                    } else static if (__traits(hasMember, T, "__dtor")) {
                        assumeNothrowNoGC(&obj_.__dtor)();
                    }
                    free(cast(void*)obj_);
                }
            }
        } else static if (is(T == struct)) {

            // Try to call elaborate destructor first before attempting __dtor
            static if (__traits(hasMember, T, "__xdtor")) {
                assumeNothrowNoGC(&obj_.__xdtor)();
            } else static if (__traits(hasMember, T, "__dtor")) {
                assumeNothrowNoGC(&obj_.__dtor)();
            }
        }

    } else {

        // With a normal runtime we can use destroy
        static if (isPointer!T || is(T == class)) {
            static if (is(T == class)) {
                auto objptr_ = obj_;
            } else {
                auto objptr_ = &obj_;
            }

            destroy!false(objptr_);
        } else static if (is(T == struct)) {
            auto objptr_ = &obj_;
            destroy!false(objptr_);
        }
    }
}