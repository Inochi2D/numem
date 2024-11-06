module numem.thread.context;

/**
    Stack context
*/
struct StackContext {
    void* bstack;
    void* tstack;

    void* ehContext;
    StackContext* within;
    StackContext* next;
    StackContext* prev;
}