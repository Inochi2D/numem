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