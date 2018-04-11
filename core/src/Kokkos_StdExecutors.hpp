/*
//@HEADER
// ************************************************************************
//
//                        Kokkos v. 2.0
//              Copyright (2014) Sandia Corporation
//
// Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
// the U.S. Government retains certain rights in this software.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// 1. Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the Corporation nor the names of the
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY SANDIA CORPORATION "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SANDIA CORPORATION OR THE
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Questions? Contact Christian R. Trott (crtrott@sandia.gov)
//
// ************************************************************************
//@HEADER
*/

#ifndef KOKKOS_STDEXECUTORS_HPP
#define KOKKOS_STDEXECUTORS_HPP

#include <Kokkos_Macros.hpp>
#include <Kokkos_Core_fwd.hpp>


#ifdef KOKKOS_ENABLE_STDEXECUTORS

#include <cstddef>
#include <iosfwd>
#include <optional>
#include <memory>

#include <Kokkos_HostSpace.hpp>
#include <Kokkos_ScratchSpace.hpp>
#include <Kokkos_Parallel.hpp>
#include <Kokkos_TaskScheduler.hpp>
#include <Kokkos_Layout.hpp>
#include <impl/Kokkos_Tags.hpp>

namespace Kokkos {
namespace Experimental {

namespace Impl {

// Pimpl forward declaration
template <typename ExecutionContext>
struct StdExecutorsImpl;

} // end namespace impl

/// \class StdExecutors
/// \brief Kokkos backend build on the standard library executors proposal, P0443r7
template <typename Executor>
class StdExecutors {
public:
  //! Tag this class as a kokkos execution space
  using execution_space = StdExecutors<Executor>;

  // Use HostSpace for now;
  // TODO wrap the allocator property of the executor to generate something like a memory_space
  using memory_space = HostSpace;

  //! This execution space preferred device_type
  using device_type          = Kokkos::Device< execution_space, memory_space >;

  // TODO query this from the executor???
  using array_layout         = LayoutRight;

  using size_type            = memory_space::size_type;
  using scratch_memory_space = ScratchMemorySpace< OpenMP >;

  /// \brief Get a handle to the default execution space instance
  inline
  StdExecutors() noexcept;

  /// \brief Initialize the default execution space
  ///
  /// if ( thread_count == -1 )
  ///   then use the number of threads that openmp defaults to
  /// if ( thread_count == 0 && Kokkos::hwlow_available() )
  ///   then use hwloc to choose the number of threads and change
  ///   the default number of threads
  /// if ( thread_count > 0 )
  ///   then force openmp to use the given number of threads and change
  ///   the default number of threads
  static void initialize( int thread_count = -1 );

  /// \brief Free any resources being consumed by the default execution space
  static void finalize();

  /// \brief is the default execution space initialized for current 'master' thread
  static bool is_initialized() noexcept;

  /// \brief Print configuration information to the given output stream.
  static void print_configuration( std::ostream & , const bool verbose = false );

  /// \brief is the instance running a parallel algorithm
  inline static bool in_parallel() noexcept;
  inline static bool in_parallel( StdExecutors const& ) noexcept;

  /// \brief Wait until all dispatched functors complete on the given instance
  inline static void fence();
  inline static void fence( StdExecutors const& );

  /// \brief Does the given instance return immediately after launching
  /// a parallel algorithm
  ///
  /// This always returns false on OpenMP
  inline static bool is_asynchronous() noexcept;
  inline static bool is_asynchronous( StdExecutors const& ) noexcept;

  /// \brief Partition the default instance into new instances without creating
  ///  new masters
  ///
  static std::vector<StdExecutors> partition(...);

  /// Non-default instances should be ref-counted so that when the last
  /// is destroyed the instance resources are released
  ///
  static StdExecutors instance(...);

  /// \brief Partition the default instance and call 'f' on each new 'master' thread
  ///
  /// Func is a functor with the following signiture
  ///   void( int partition_id, int num_partitions )
  template <typename F>
  static void partition_master( F const& f
    , int requested_num_partitions = 0
    , int requested_partition_size = 0
  );

  inline
  static int thread_pool_size() noexcept;

  /** \brief  The rank of the executing thread in this thread pool */
  KOKKOS_INLINE_FUNCTION
  static int thread_pool_rank() noexcept;

  static constexpr const char* name() noexcept { return ""; }

private:
  static std::unique_ptr<Impl::StdExecutorsImpl<Executor>> s_default_impl;
  Impl::StdExecutorsImpl<Executor> m_impl;
  template <typename>
  friend struct Impl::StdExecutorsImpl;
};

} // end namespace Experimental
} // namespace Kokkos

#include <StdExecutors/Kokkos_StdExecutors_Exec.hpp>

#endif // KOKKOS_ENABLE_STDEXECUTORS

#endif //KOKKOS_STDEXECUTORS_HPP