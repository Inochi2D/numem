module ut.core.exception;
import numem.core.exception;

@("catch & free NuException")
@nogc
unittest {
    try {
        enforce(false, "Ooops!");
    } catch(NuException ex) {
        assert(ex.message() == "Ooops!");
        ex.free();
    }
}

@("assuming pure")
unittest {
    static int notPure(int a) {
        __gshared int illegal;
        illegal = 4;
        return a;
    }

    pure int identity(int a) {
        return assumePure(&notPure, a);
    }
}