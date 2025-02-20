module tests.object;
import numem.object;
import numem.lifetime;

class MyRCClass : NuRefCounted {
@nogc:
private:
    int secret;

public:
    ~this() { }

    this(int secret) {
        super();
        this.secret = secret;
    }

    int getSecret() {
        return secret;
    }
}

class TrackedClass : NuRefCounted {
@nogc:
private:
    __gshared uint rcClassCount;

public:
    ~this() { rcClassCount--; }
    this() { rcClassCount++; }
}

@("refcounted create-destroy.")
unittest {
    MyRCClass rcclass = nogc_new!MyRCClass(42);
    assert(rcclass.getSecret() == 42);
    assert(rcclass.release() is null);
}

@("refcounted pool")
unittest {
    autoreleasepool(() {
        foreach(i; 0..100) {
            nogc_new!TrackedClass().autoreleased();
        }

        assert(TrackedClass.rcClassCount == 100);
    });
    assert(TrackedClass.rcClassCount == 0);
}

@("numem nogc overloads")
@nogc
unittest {
    MyRCClass rcclass = nogc_new!MyRCClass(42);

    assert(rcclass.toString() == typeid(MyRCClass).name);
    assert(rcclass.toHash() == rcclass.toHash()); // Just to ensure they are properly nogc.
    assert(rcclass.opCmp(rcclass) == 0);
    assert(rcclass.opEquals(rcclass)); // Just to ensure they are properly nogc.
    rcclass.release();
}