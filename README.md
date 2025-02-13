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

## Using slices

Numem allows creating slice buffers, however these buffers are less safe than higher level
alternatives available in nucore.