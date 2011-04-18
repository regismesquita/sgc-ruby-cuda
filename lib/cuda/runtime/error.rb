#
# Copyright (c) 2010-2011 Chung Shin Yee
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
#

require 'cuda/runtime/ffi-cuda'


module SGC
module Cuda

    # @param [Integer, CudaError] e A CUDA error value or label.
    # @return [String] The error string of _e_.
    def get_error_string(e)
        API::cudaGetErrorString(e)
    end
    module_function :get_error_string


    # @return [Integer] The error value of the last CUDA error.
    def get_last_error
        API::cudaGetLastError
    end
    module_function :get_last_error


    # Return the last CUDA error, but do not reset the error.
    # @return [Integer] The error value of the last CUDA error.
    def peek_at_last_error
        API::cudaPeekAtLastError
    end
    module_function :peek_at_last_error

module Pvt

    CUDA_SUCCESS = API::CudaError[:SUCCESS]
    CUDA_ERROR_NOT_READY = API::CudaError[:ERROR_NOT_READY]

    def self.handle_error(status, msg = nil)
        status == CUDA_SUCCESS or raise API::cudaGetErrorString(status) + (msg.nil? ? "" : " : #{msg}")
        nil
    end

end

end # module
end # module
