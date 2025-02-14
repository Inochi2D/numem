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

# Configuration

Numem provides a couple of version flags for configuring some base features of numem.
Packages which intend to extend numem should appropriately implement these flags to handle
parts of numem being non-functional.

| Flag               | Description                                                                          |
| :----------------- | ------------------------------------------------------------------------------------ |
| `NUMEM_NO_ATOMICS` | Disables atomic operations, all atomic operations are replaced with dummy functions. |

&nbsp;
&nbsp;
&nbsp;

# Using numem
Numem allows you to instantiate classes without the GC, it's highly recommended that you mark all functions in classes as @nogc to avoid GC conflicts.  

Using `nogc_new` you can instantiate types on the heap, and `nogc_delete` can destruct and free types.

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
alternatives available in nucore.

```d
float[] myFloatSlice;
myFloatSlice.nu_resize(42);
foreach(i; 0..myFloatSlice.length)
    myFloatSlice[i] = 0.0;

// Slices MUST be freed by resizing the slice to 0,
// other functions will either fail or cause memory corruption.
// as slices are using the aligned allocation functions.
myFloatSlice.nu_resize(0);
```