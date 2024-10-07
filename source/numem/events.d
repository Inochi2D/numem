/**
    Numem events
*/
module numem.events;
import numem.collections.vector;
import numem.core.memory;

/**
    An event.
*/
struct Event(T, EventData...) {
@nogc:
private:
    weak_vector!EventHandlerFuncT subscribers;

public:

    /**
        The type of the event handler function
    */
    alias EventHandlerFuncT = void function(ref T, EventData);

    /**
        Calls all of the event handlers
    */
    auto opCall(Y)(auto ref Y caller, EventData data) if (is(T : Y)) {
        foreach(subscriber; subscribers) {
            subscriber(caller, data);
        }
    }

    /**
        Registers a handler with the event
    */
    auto opOpAssign(string op: "~")(EventHandlerFuncT handler) {
        subscribers ~= handler;
        return this;
    }

    /**
        Removes a handler from the event
    */
    auto opOpAssign(string op: "-")(EventHandlerFuncT handler) {
        foreach(i; 0..subscribers.length) {
            if (subscribers[i] == handler) {
                subscribers.remove(i);
                return this;
            }
        }
        return this;
    }
}

version(unittest) {
    class EventTest {
        Event!EventTest onFuncCalled;
        bool localVar = false;

        void func() {
            this.onFuncCalled(this);
        }
    }
}

@("Event call")
unittest {

    EventTest test = nogc_new!EventTest;
    test.onFuncCalled ~= (ref EventTest caller) {
        caller.localVar = true;
        return;
    };

    test.func();

    assert(test.localVar);
}