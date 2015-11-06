cdef class UVIdle(UVHandle):
    def __cinit__(self, Loop loop, object callback):
        cdef int err

        self.handle = <uv.uv_handle_t*> \
                            PyMem_Malloc(sizeof(uv.uv_idle_t))
        if self.handle is NULL:
            raise MemoryError()

        self.handle.data = <void*> self

        err = uv.uv_idle_init(loop.loop, <uv.uv_idle_t*>self.handle)
        if err < 0:
            raise UVError.from_error(err)

        self.callback = callback
        self.running = 0

    cdef stop(self):
        cdef int err

        self.ensure_alive()

        if self.running == 1:
            err = uv.uv_idle_stop(<uv.uv_idle_t*>self.handle)
            self.running = 0
            if err < 0:
                raise UVError.from_error(err)

    cdef start(self):
        cdef int err

        self.ensure_alive()

        if self.running == 0:
            err = uv.uv_idle_start(<uv.uv_idle_t*>self.handle,
                                   cb_idle_callback)
            if err < 0:
                raise UVError.from_error(err)
            self.running = 1


cdef void cb_idle_callback(uv.uv_idle_t* handle) with gil:
    cdef UVIdle idle = <UVIdle> handle.data
    try:
        idle.callback()
    except BaseException as ex:
        idle.loop._handle_uvcb_exception(ex)
