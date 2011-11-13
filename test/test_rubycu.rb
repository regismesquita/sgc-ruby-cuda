#-----------------------------------------------------------------------
# Copyright (c) 2010 Chung Shin Yee
#
#       shinyee@speedgocomputing.com
#       http://www.speedgocomputing.com
#       http://github.com/xman/sgc-ruby-cuda
#       http://rubyforge.org/projects/rubycuda
#
# This file is part of SGC-Ruby-CUDA.
#
# SGC-Ruby-CUDA is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SGC-Ruby-CUDA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SGC-Ruby-CUDA.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------

require 'test/unit'
require 'rubycu'

include SGC::CU

DEVID = ENV['DEVID'].to_i


class TestRubyCU < Test::Unit::TestCase

    def setup
        @dev = CUDevice.get(DEVID)
        @ctx = CUContext.new.create(0, @dev)
        @mod = prepare_loaded_module
        @func = @mod.get_function("vadd")
    end

    def teardown
        @func = nil
        @mod.unload
        @mod = nil
        @ctx.destroy
        @ctx = nil
        @dev = nil
    end

    def test_device_count
        assert_nothing_raised do
            count = CUDevice.get_count
            assert(count > 0, "Device count failed.")
        end
    end

    def test_device_query
        assert_nothing_raised do
            d = CUDevice.get(DEVID)
            assert_not_nil(d)
            assert_device_name(d)
            assert_device_memory_size(d)
            assert_device_capability(d)
            assert_device_properties(d)
            CUDeviceAttribute.constants.each do |symbol|
                k = CUDeviceAttribute.const_get(symbol)
                v = d.get_attribute(k)
                assert_instance_of(Fixnum, v)
            end
        end
    end

    def test_context_create_destroy
        assert_nothing_raised do
            c = CUContext.new.create(0, @dev)
            assert_not_nil(c)
            c = c.destroy
            assert_nil(c)
            CUContextFlags.constants.each do |symbol|
                k = CUContextFlags.const_get(symbol)
                c = CUContext.new.create(k, @dev)
                assert_not_nil(c)
                c = c.destroy
                assert_nil(c)
            end
        end
    end

    def test_context_attach_detach
        assert_nothing_raised do
            c1 = @ctx.attach(0)
            assert_not_nil(c1)
            c2 = @ctx.detach
            assert_nil(c2)
        end
    end

    def test_context_attach_nonzero_flags_detach
        assert_raise(CUInvalidValueError) do
            c1 = @ctx.attach(999)
            assert_not_nil(c1)
            c2 = @ctx.detach
            assert_nil(c2)
        end
    end

    def test_context_push_pop_current
        assert_nothing_raised do
            c1 = CUContext.pop_current
            assert_not_nil(c1)
            c2 = @ctx.push_current
            assert_not_nil(c2)
        end
    end

    def test_context_get_device
        assert_nothing_raised do
            d = CUContext.get_device
            assert_device(d)
        end
    end

    def test_context_get_set_limit
        if @dev.compute_capability[:major] >= 2
            assert_limit = Proc.new { |&b| assert_nothing_raised(&b) }
        else
            assert_limit = Proc.new { |&b| assert_raise(CUUnsupportedLimitError, &b) }
        end
        assert_limit.call do
            stack_size = CUContext.get_limit(CULimit::STACK_SIZE)
            assert_kind_of(Numeric, stack_size)
            fifo_size = CUContext.get_limit(CULimit::PRINTF_FIFO_SIZE)
            assert_kind_of(Numeric, fifo_size)
            heap_size = CUContext.get_limit(CULimit::MALLOC_HEAP_SIZE)
            assert_kind_of(Numeric, heap_size)
            s1 = CUContext.set_limit(CULimit::STACK_SIZE, stack_size)
            assert_nil(s1)
            s2 = CUContext.set_limit(CULimit::PRINTF_FIFO_SIZE, fifo_size)
            assert_nil(s2)
            s3 = CUContext.set_limit(CULimit::MALLOC_HEAP_SIZE, heap_size)
            assert_nil(s3)
        end
    end

    def test_context_get_set_cache_config
        assert_nothing_raised do
            if @dev.compute_capability[:major] >= 2
                config = CUContext.get_cache_config
                assert_const_in_class(CUFunctionCache, config)
                s = CUContext.set_cache_config(config)
                assert_nil(s)
            else
                config = CUContext.get_cache_config
                assert_equal(CUFunctionCache::PREFER_NONE, config)
                s = CUContext.set_cache_config(config)
                assert_nil(s)
            end
        end
    end

    def test_context_get_api_version
        assert_nothing_raised do
            v1 = @ctx.get_api_version
            v2 = CUContext.get_api_version
            assert_kind_of(Numeric, v1)
            assert_kind_of(Numeric, v2)
            assert(v1 == v2)
        end
    end

    def test_context_synchronize
        assert_nothing_raised do
            s = CUContext.synchronize
            assert_nil(s)
        end
    end

    def test_module_load_unload
        assert_nothing_raised do
            path = prepare_ptx
            m = CUModule.new
            m = m.load(path)
            assert_not_nil(m)
            m = m.unload
            assert_not_nil(m)
        end
    end

    def test_module_load_with_invalid_ptx
        assert_raise(CUInvalidImageError) do
            m = CUModule.new
            m = m.load('test/bad.ptx')
        end

        assert_raise(CUFileNotFoundError) do
            m = CUModule.new
            m = m.load('test/notexists.ptx')
        end
    end

    def test_module_load_data
        path = prepare_ptx
        assert_nothing_raised do
            m = CUModule.new
            File.open(path) do |f|
                str = f.read
                m.load_data(str)
                m.unload
            end
        end
    end

    def test_module_load_data_with_invalid_ptx
        assert_raise(CUInvalidImageError) do
            m = CUModule.new
            str = "invalid ptx"
            m.load_data(str)
        end
    end

    def test_module_get_function
        assert_nothing_raised do
            f = @mod.get_function('vadd')
            assert_not_nil(f)
        end
    end

    def test_module_get_function_with_invalid_name
        assert_raise(CUInvalidValueError) do
            f = @mod.get_function('')
        end

        assert_raise(CUReferenceNotFoundError) do
            f = @mod.get_function('badname')
        end
    end

    def test_module_get_global
        assert_nothing_raised do
            devptr, nbytes = @mod.get_global('gvar')
            assert_equal(4, nbytes)
            u = Int32Buffer.new(1)
            memcpy_dtoh(u, devptr, nbytes)
            assert_equal(1997, u[0])
        end
    end

    def test_module_get_global_with_invalid_name
        assert_raise(CUInvalidValueError) do
            devptr, nbytes = @mod.get_global('')
        end

        assert_raise(CUReferenceNotFoundError) do
            devptr, nbytes = @mod.get_global('badname')
        end
    end

    def test_module_get_texref
        assert_nothing_raised do
            tex = @mod.get_texref('tex')
            assert_not_nil(tex)
        end
    end

    def test_module_get_texref_with_invalid_name
        assert_raise(CUInvalidValueError) do
            tex = @mod.get_texref('')
        end

        assert_raise(CUReferenceNotFoundError) do
            tex = @mod.get_texref('badname')
        end
    end

    def test_device_ptr_mem_alloc_free
        assert_nothing_raised do
            devptr = CUDevicePtr.new
            devptr.mem_free
            devptr.mem_alloc(1024)
            devptr.mem_free
        end
    end

    def test_device_ptr_mem_alloc_with_huge_mem
        assert_raise(CUOutOfMemoryError) do
            devptr = CUDevicePtr.new
            size = @dev.total_mem + 1
            devptr.mem_alloc(size)
        end
    end

    def test_device_ptr_offset
        assert_nothing_raised do
            devptr = CUDevicePtr.new
            p = devptr.offset(1024)
            assert_instance_of(CUDevicePtr, p)
            p = devptr.offset(-1024)
            assert_instance_of(CUDevicePtr, p)
        end
    end

    def test_function_set_param
        assert_nothing_raised do
            da = CUDevicePtr.new
            db = CUDevicePtr.new
            dc = CUDevicePtr.new
            f = @func.set_param(da, db, dc, 10)
            assert_instance_of(CUFunction, f)
        end
    end

    def test_function_set_block_shape
        assert_nothing_raised do
            f = @func.set_block_shape(2)
            assert_instance_of(CUFunction, f)
            f = @func.set_block_shape(2, 3)
            assert_instance_of(CUFunction, f)
            f = @func.set_block_shape(2, 3, 4)
            assert_instance_of(CUFunction, f)
        end
    end

    def test_function_set_shared_size
        assert_nothing_raised do
            f = @func.set_shared_size(0)
            assert_instance_of(CUFunction, f)
            f = @func.set_shared_size(1024)
            assert_instance_of(CUFunction, f)
        end
    end

    def test_function_launch
        assert_nothing_raised do
            assert_function_launch(10) do |f|
                f.set_block_shape(10)
                f.launch
            end
        end
    end

    def test_function_launch_grid
        assert_nothing_raised do
            assert_function_launch(10) do |f|
                f.set_block_shape(10)
                f.launch_grid(1)
            end

            assert_function_launch(20) do |f|
                f.set_block_shape(5)
                f.launch_grid(4)
            end
        end
    end

    def test_function_launch_async
        assert_nothing_raised do
            assert_function_launch(10) do |f|
                f.set_block_shape(10)
                f.launch_grid_async(1, 0)
            end

            assert_function_launch(20) do |f|
                f.set_block_shape(5)
                f.launch_grid_async(4, 0)
            end
        end
    end

    def test_function_get_attribute
        CUFunctionAttribute.constants.each do |symbol|
            k = CUFunctionAttribute.const_get(symbol)
            v = @func.get_attribute(k)
            assert_instance_of(Fixnum, v)
        end
    end

    def test_function_set_cache_config
        CUFunctionCache.constants.each do |symbol|
            k = CUFunctionCache.const_get(symbol)
            f = @func.set_cache_config(k)
            assert_instance_of(CUFunction, f)
        end
    end

    def test_stream_create_destroy
        assert_nothing_raised do
            s = CUStream.new
            s = s.create(0)
            assert_instance_of(CUStream, s)
            s = s.destroy
            assert_nil(s)
        end
    end

    def test_stream_query
        assert_nothing_raised do
            s = CUStream.new.create(0)
            b = s.query
            assert(b)
            s.destroy
        end
    end

    def test_stream_synchronize
        assert_nothing_raised do
            s = CUStream.new.create(0)
            s = s.synchronize
            assert_instance_of(CUStream, s)
            s.destroy
        end
    end

    def test_event_create_destroy
        assert_nothing_raised do
            e = CUEvent.new.create(CUEventFlags::DEFAULT)
            assert_instance_of(CUEvent, e)
            e = e.destroy
            assert_nil(e)
        end
    end

    def test_event_record_synchronize_query
        assert_nothing_raised do
            e = CUEvent.new.create(CUEventFlags::DEFAULT)
            e = e.record(0)
            assert_instance_of(CUEvent, e)
            e = e.synchronize
            assert_instance_of(CUEvent, e)
            b = e.query
            assert(b)
            e.destroy
        end
    end

    def test_event_elapsed_time
        assert_nothing_raised do
            e1 = CUEvent.new.create(CUEventFlags::DEFAULT)
            e2 = CUEvent.new.create(CUEventFlags::DEFAULT)
            e1.record(0)
            e2.record(0)
            e2.synchronize
            elapsed = CUEvent.elapsed_time(e1, e2)
            assert_instance_of(Float, elapsed)
            e1.destroy
            e2.destroy
        end
    end

    def test_texref_get_set_address
        assert_nothing_raised do
            t = @mod.get_texref("tex")
            p = CUDevicePtr.new.mem_alloc(16)
            t.set_address(p, 16)
            r = t.get_address
            assert_instance_of(CUDevicePtr, r)
            p.mem_free
        end
    end

    def test_texref_get_set_address_mode
        assert_nothing_raised do
            t = @mod.get_texref("tex")
            r = t.get_address_mode(0)
            assert_const_in_class(CUAddressMode, r)
            t = t.set_address_mode(0, r)
            assert_instance_of(CUTexRef, t)
        end
    end

    def test_texref_get_set_filter_mode
        assert_nothing_raised do
            t = @mod.get_texref("tex")
            r = t.get_filter_mode
            assert_const_in_class(CUFilterMode, r)
            t = t.set_filter_mode(r)
            assert_instance_of(CUTexRef, t)
        end
    end

    def test_texref_get_set_flags
        assert_nothing_raised do
            t = @mod.get_texref("tex")
            f = t.get_flags
            assert_kind_of(Numeric, f)
            t = t.set_flags(f)
            assert_instance_of(CUTexRef, t)
        end
    end

    def test_buffer_initialize
        assert_nothing_raised do
            b = MemoryBuffer.new(16)
            assert_instance_of(MemoryBuffer, b)
            assert_equal(false, b.page_locked?)
            assert_equal(16, b.size)

            b = Int32Buffer.new(10)
            assert_instance_of(Int32Buffer, b)
            assert_equal(false, b.page_locked?)
            assert_equal(10, b.size)

            b = Int64Buffer.new(20)
            assert_instance_of(Int64Buffer, b)
            assert_equal(false, b.page_locked?)
            assert_equal(20, b.size)

            b = Float32Buffer.new(30)
            assert_instance_of(Float32Buffer, b)
            assert_equal(false, b.page_locked?)
            assert_equal(30, b.size)

            b = Float64Buffer.new(40)
            assert_instance_of(Float64Buffer, b)
            assert_equal(false, b.page_locked?)
            assert_equal(40, b.size)
        end
    end

    def test_buffer_initialize_page_locked
        assert_nothing_raised do
            b = MemoryBuffer.new(16, page_locked: true)
            assert_instance_of(MemoryBuffer, b)
            assert_equal(true, b.page_locked?)
            assert_equal(16, b.size)

            b = Int32Buffer.new(10, page_locked: true)
            assert_instance_of(Int32Buffer, b)
            assert_equal(true, b.page_locked?)
            assert_equal(10, b.size)

            b = Int64Buffer.new(20, page_locked: true)
            assert_instance_of(Int64Buffer, b)
            assert_equal(true, b.page_locked?)
            assert_equal(20, b.size)

            b = Float32Buffer.new(30, page_locked: true)
            assert_instance_of(Float32Buffer, b)
            assert_equal(true, b.page_locked?)
            assert_equal(30, b.size)

            b = Float64Buffer.new(40, page_locked: true)
            assert_instance_of(Float64Buffer, b)
            assert_equal(true, b.page_locked?)
            assert_equal(40, b.size)
        end
    end

    def test_buffer_element_size
        assert_nothing_raised do
            assert_equal(1, MemoryBuffer.element_size)
            assert_equal(4, Int32Buffer.element_size)
            assert_equal(8, Int64Buffer.element_size)
            assert_equal(4, Float32Buffer.element_size)
            assert_equal(8, Float64Buffer.element_size)
        end
    end

    def test_buffer_offset
        assert_nothing_raised do
            b = MemoryBuffer.new(16)
            c = b.offset(4)
            assert_kind_of(MemoryPointer, c)

            b = Int32Buffer.new(10)
            c = b.offset(2)
            assert_kind_of(MemoryPointer, c)

            b = Int64Buffer.new(10)
            c = b.offset(3)
            assert_kind_of(MemoryPointer, c)

            b = Float32Buffer.new(10)
            c = b.offset(4)
            assert_kind_of(MemoryPointer, c)

            b = Float64Buffer.new(10)
            c = b.offset(5)
            assert_kind_of(MemoryPointer, c)
        end
    end

    def test_buffer_access
        assert_nothing_raised do
            b = MemoryBuffer.new(16)
            b[0] = 127
            assert_equal(127, b[0])
            b[15] = 128
            assert_not_equal(128, b[15])

            b = Int32Buffer.new(10)
            b[0] = 10
            assert_equal(10, b[0])
            b[9] = 20
            assert_equal(20, b[9])

            b = Int64Buffer.new(10)
            b[3] = 2**40
            assert_equal(2**40, b[3])
            b[7] = 2**50
            assert_equal(2**50, b[7])

            b = Float32Buffer.new(10)
            b[2] = 3.14
            assert_in_delta(3.14, b[2])
            b[8] = 9.33
            assert_in_delta(9.33, b[8])

            b = Float64Buffer.new(10)
            b[1] = 3.14
            assert_in_delta(3.14, b[1])
            b[6] = 9.33
            assert_in_delta(9.33, b[6])
        end
    end

    def test_memory_copy
        assert_nothing_raised do
            cBuffer = Int32Buffer
            size = 16
            b = cBuffer.new(size, page_locked: true)
            c = cBuffer.new(size, page_locked: true)
            d = cBuffer.new(size)
            e = cBuffer.new(size)
            p = CUDevicePtr.new.mem_alloc(size*cBuffer.element_size)
            q = CUDevicePtr.new.mem_alloc(size*cBuffer.element_size)
            r = CUDevicePtr.new.mem_alloc(size*cBuffer.element_size)

            (0...size).each do |i|
                b[i] = i
                c[i] = 0
                d[i] = 0
                e[i] = 0
            end
            memcpy_htod(p, b, size*cBuffer.element_size)
            memcpy_dtoh(c, p, size*cBuffer.element_size)
            (0...size).each do |i|
                assert_equal(b[i], c[i])
            end

            (0...size).each do |i|
                b[i] = 2*i
                c[i] = 0
            end
            memcpy_htod_async(p, b, size*cBuffer.element_size, 0)
            memcpy_dtoh_async(c, p, size*cBuffer.element_size, 0)
            CUContext.synchronize
            (0...size).each do |i|
                assert_equal(b[i], c[i])
            end

            memcpy_dtod(q, p, size*cBuffer.element_size)
            CUContext.synchronize
            memcpy_dtoh(d, q, size*cBuffer.element_size)
            (0...size).each do |i|
                assert_equal(b[i], d[i])
            end

            memcpy_dtod_async(r, p, size*cBuffer.element_size, 0)
            CUContext.synchronize
            memcpy_dtoh(e, r, size*cBuffer.element_size)
            (0...size).each do |i|
                assert_equal(b[i], e[i])
            end

            p.mem_free
            q.mem_free
            r.mem_free
        end
    end

    def test_memory_get_info
        info = mem_get_info
        assert(info[:free] >= 0)
        assert(info[:total] >= 0)
    end

private

    def assert_device(dev)
        assert_device_name(dev)
        assert_device_memory_size(dev)
        assert_device_capability(dev)
        assert_device_properties(dev)
    end

    def assert_device_name(dev)
        assert(dev.get_name.size > 0, "Device name failed.")
    end

    def assert_device_memory_size(dev)
        assert(dev.total_mem > 0, "Device total memory size failed.")
    end

    def assert_device_capability(dev)
        cap = dev.compute_capability
        assert(cap[:major] > 0 && cap[:minor] >= 0, "Device compute capability failed.")
    end

    def assert_device_properties(dev)
        p = dev.get_properties
        assert(p[:clock_rate] > 0)
        assert(p[:max_threads_per_block] > 0)
        assert(p[:mem_pitch] > 0)
        assert(p[:regs_per_block] > 0)
        assert(p[:shared_mem_per_block] > 0)
        assert(p[:simd_width] > 0)
        assert(p[:texture_align] > 0)
        assert(p[:total_constant_memory] > 0)
        assert_instance_of(Array, p[:max_grid_size])
        assert_equal(3, p[:max_grid_size].size)
        assert_instance_of(Array, p[:max_threads_dim])
        assert_equal(3, p[:max_threads_dim].size)
    end

    def assert_function_launch(size)
        assert_nothing_raised do
            cBuffer = Int32Buffer
            da = CUDevicePtr.new.mem_alloc(size*cBuffer.element_size)
            db = CUDevicePtr.new.mem_alloc(size*cBuffer.element_size)
            dc = CUDevicePtr.new.mem_alloc(size*cBuffer.element_size)
            ha = cBuffer.new(size)
            hb = cBuffer.new(size)
            hc = Array.new(size)
            hd = cBuffer.new(size)
            (0...size).each { |i|
                ha[i] = i
                hb[i] = 1
                hc[i] = ha[i] + hb[i]
                hd[i] = 0
            }
            memcpy_htod(da, ha, size*cBuffer.element_size)
            memcpy_htod(db, hb, size*cBuffer.element_size)
            @func.set_param(da, db, dc, size)

            yield @func

            memcpy_dtoh(hd, dc, size*cBuffer.element_size)
            (0...size).each { |i|
                assert_equal(hc[i], hd[i])
            }
            da.mem_free
            db.mem_free
            dc.mem_free
        end
    end

    def assert_const_in_class(klass, v)
        assert_not_nil(klass.constants.find { |k| klass.const_get(k) == v })
    end

    def prepare_ptx
        if File.exists?('test/vadd.ptx') == false || File.mtime('test/vadd.cu') > File.mtime('test/vadd.ptx')
            system %{cd test; nvcc --ptx vadd.cu}
        end
        'test/vadd.ptx'
    end

    def prepare_loaded_module
        path = prepare_ptx
        m = CUModule.new
        m.load(path)
    end

end
