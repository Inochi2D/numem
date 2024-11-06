/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    General-purpose semaphore for synchronisation.
*/
module numem.sync.semaphore;
import core.atomic;
import numem.platform;
import numem.core.memory;
import core.sync.exception;
import core.time : convert;

version(Windows) {
    
    import core.sys.windows.basetsd;
    import core.sys.windows.winbase;
    import core.sys.windows.windef;
    import core.sys.windows.winerror;

    alias SemaphoreHandle = HANDLE;
} else version(AppleOS) {

    import core.sync.config;
    import core.stdc.errno;
    import core.sys.posix.time;
    import core.sys.darwin.mach.semaphore;

    alias SemaphoreHandle = semaphore_t;
} else version(Posix) {

    import core.sync.config;
    import core.stdc.errno;
    import core.sys.posix.pthread;
    import core.sys.posix.semaphore;

    alias SemaphoreHandle = sem_t;
} else {
    static assert(0, "Platform not supported.");
}

/**
    A semaphore for synchronisation
*/
class Semaphore {
@nogc:
private:

    // Semaphore handle.
    SemaphoreHandle handle;
    long signalCount;

    void addCount() {
        signalCount = atomicFetchSub(signalCount, 1);
    }

    void subCount() {
        signalCount = atomicFetchAdd(signalCount, 1);
    }

public:

    ~this() {
        bool rc = true;

        version(Windows) rc = cast(bool)CloseHandle(handle);
        else version(AppleOS) rc = !semaphore_destroy(mach_task_self(), handle);
        else version(Posix) rc = !sem_destroy(&handle);
        assert(rc, "Unable to destroy semahpore");
    }

    /**
        Constructor
    */
    this(size_t count = 0) {
        version(Windows) {

            handle = CreateSemaphoreA(null, cast(LONG)count, int.max, null);
            if (handle == handle.init)
                throw nogc_new!SyncError("Unable to create semaphore");
        } else version(AppleOS) {

            auto rc = semaphore_create(mach_task_self(), &handle, SYNC_POLICY_FIFO, cast(int)count);
            if (rc)
                throw nogc_new!SyncError("Unable to create semaphore");
        } else version(Posix) {

            auto rc = sem_init(&handle, 0, cast(int)count);
            if (rc)
                throw nogc_new!SyncError("Unable to create semaphore");
        }

        signalCount = count;
    }

    /**
        Waits for the semaphore to be signaled.

        Params:
            timeoutMs = How long to wait for the semaphore.

        Returns:
            `true` if the semaphore was signaled before
            the timeout was reached.
    */
    bool wait(size_t timeoutMs = 0) {
        if (timeoutMs > 0) {
            version(Windows) {

                auto rc = WaitForSingleObject(handle, cast(uint)timeoutMs);
                if ( rc != WAIT_OBJECT_0 )
                    throw nogc_new!SyncError("Unable to wait for semaphore");

                this.subCount();
            } else version(AppleOS) {
                mach_timespec_t timeout = mach_timespec_t(
                    tv_sec:     convert!("msecs", "seconds")(timeoutMs),
                    tv_nsec:    convert!("msecs", "nsecs")(timeoutMs)
                );
                
                while(true) {

                    auto rc = semaphore_timedwait(handle, timeout);
                    if (!rc) {
                        this.subCount();
                        return true;
                    }
                    if (rc == KERN_OPERATION_TIMED_OUT)
                        return false;
                    if (rc != KERN_ABORTED || errno != EINTR)
                        throw nogc_new!SyncError("Unable to wait for semaphore");
                }

            } else version(Posix) {
                timespec timeout = timespec(
                    tv_sec:     convert!("msecs", "seconds")(timeoutMs),
                    tv_nsec:    convert!("msecs", "nsecs")(timeoutMs)
                );

                while(true) {

                    if (!sem_timedwait(handle, &timeout)) {
                        this.subCount();
                        return true;
                    }

                    if (errno == ETIMEDOUT)
                        return false;
                    
                    if (errno != EINTR)
                        throw nogc_new!SyncError("Unable to wait for semaphore");
                }
            }
        } else {
            version(Windows) {

                auto rc = WaitForSingleObject(handle, INFINITE);
                if ( rc != WAIT_OBJECT_0 )
                    throw nogc_new!SyncError("Unable to wait for semaphore");
                
                this.subCount();

            } else version(AppleOS) {

                while(true) {
                    auto rc = semaphore_wait(handle);
                    if (!rc) {
                        this.subCount();
                        return true;
                    }
                    
                    if (rc == KERN_ABORTED && errno == EINTR)
                        continue;
                    
                    throw nogc_new!SyncError("Unable to wait for semaphore");
                }
            } else version(Posix) {

                while(true) {
                    if (!sem_wait(&handle)) {
                        this.subCount();
                        return true;
                    }

                    if (errno != EINTR)
                        throw nogc_new!SyncError("Unable to wait for semaphore");
                }
            }
        }

        return false;
    }

    /**
        Signals the semaphore, this operation does not transfer control to
        the waiter.

    */
    void signal() {
        version(Windows) {
            if (!ReleaseSemaphore(handle, 1, null))
                throw nogc_new!SyncError("Unable to signal semaphore");
        } else version (AppleOS) {
            auto rc = semaphore_signal(handle);
            if (rc)
                throw nogc_new!SyncError("Unable to signal semaphore");
        } else version(Posix) {
            auto rc = sem_post(handle);
            if (rc)
                throw nogc_new!SyncError("Unable to signal semaphore");
        }

        this.addCount();
    }

    /**
        Gets the signal value.
    */
    long getSignalCount() {
        return atomicLoad(signalCount);
    }
}