module atomic;

/*
    This more or less decides which method to use
    for atomics.
*/
version(LDC) enum ATOMIC_USE_DUMMY = false;
else enum ATOMIC_USE_DUMMY = true;