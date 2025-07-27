<p align="center">
  <img src="numem.png" alt="NuMem" style="width: 50%; max-width: 512px; height: auto;">
</p>

[![Unit Test Status](https://github.com/Inochi2D/numem/actions/workflows/pushes.yml/badge.svg)](https://github.com/Inochi2D/numem/actions/workflows/pushes.yml)

Nu:Mem is a package for D which implements various nogc memory managment tools, allowing classes, strings, and more to be handled safely in nogc mode.
This library is still a work in progress, but is intended to be used within Inochi2D's nogc rewrite to allow the library to have good ergonomics, 
while allowing more seamless integration with other programming languages.

&nbsp;
&nbsp;
&nbsp;

&nbsp;
&nbsp;
&nbsp;

# Using numem
Numem allows you to instantiate classes without the GC, it's highly recommended that you mark all functions in classes as @nogc to avoid GC conflicts.  

Using `nogc_new` you can instantiate types on the heap, and `nogc_delete` can destruct and free types.

### Note

As of numem 1.3.0, a D Compiler with frontend version 2.106 or newer is required.  
For macOS builds, LDC 1.41.0 or newer is required.

## Hooksets

Numem works on a concept of hooksets, all core functionality of numem is built on a small series of internal hook functions.  
By default, numem provides an internal hookset that uses the system's C library and compiler intrinsics to provide the given
functionality. If you have special requirements you can implement your own, overwriting the function calls as needed.

The following hooksets are provided as subpackages that you can include.

| Name           |                                                                                 Comments |
| :------------- | ---------------------------------------------------------------------------------------: |
| `hookset-libc` |                                                                Deprecated, does nothing. |
| `hookset-dgc`  |           Forwards all allocation and deallocation to the D Runtime's garbage collector. |
| `hookset-wasm` | Implements a very simple allocator called "walloc", not recommended for production, yet. |

## Using Classes

```d
import numem;

class MyClass {
@nogc:
    void doSomething() {
        import core.stdc.stdio : printf;
        printf("Hello, world!\n");
    }
}

void main() {
    MyClass klass = nogc_new!MyClass();
    klass.doSomething();

    nogc_delete(klass);
}
```

All features of classes are available without the GC, such as subclassing and interfaces.

It is recommended that nogc classes extend `NuObject`.
```d
import numem;

class MyClass : NuObject {
@nogc:
    // NuObject ensures all the derived functions
    // are nogc; as such you can easily override functions
    // like opEquals.
}
```

## Reference Counted Classes

Numem features an extra base class, derived from `NuObject`, called `NuRefCounted`.
This class implements manual reference counting using the `retain` and `release` functions.

```d
import numem;
import std.stdio;

class MyRCClass : NuRefCounted {
@nogc:
private:
    int secret;

public:
    ~this() {
        import core.stdc.stdio : printf;
        printf("Deleted!\n");
    }

    int getSecret() {
        return secret;
    }
}

void main() {
    MyRCClass rcclass = nogc_new!MyRCClass();

    // Add one refcount.
    rcclass.retain();
    writeln(rcclass.retain().getSecret());

    // Repeatedly release a refcount until rcclass is freed.
    while(rcclass)
        rcclass = rcclass.release();

    assert(rcclass is null);
}
```

## Using slices

Numem allows creating slice buffers, however these buffers are less safe than higher level
alternatives available in [nulib](https://github.com/Inochi2D/nulib).

```d
// Allocate a new float slice, then set all values to 0.
float[] myFloatSlice = nu_malloca!float(42);
myFloatSlice[0..$] = 0.0;

// Resize slice, and add -1 to the end of it.
myFloatSlice = myFloatSlice.nu_resize(43);
myFloatSlice[$-1] = -1; 

// Slices must be freed by you, you can either resize the slice to a length
// of 0, or use nu_freea
nu_freea(myFloatSlice);

// Is equivalent to nu_freea(myFloatSlice);
myFloatSlice = myFloatSlice.nu_resize(0);
```

These slice handling functions are marked `@system` due to their memory unsafe nature.  
As such you may not use them in `@safe` code.