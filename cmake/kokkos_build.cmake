# Sources come from makefile-generated gen_kokkos.cmake file
#TODO: Need to separate sources out into container sources later

set(KOKKOS_CORE_SRCS ${KOKKOS_SRC})
#string(REPLACE "${KOKKOS_PATH}" "${CMAKE_SOURCE_DIR}" KOKKOS_CORE_SRCS "${KOKKOS_SRC}")
set(KOKKOS_CONTAINERS_SRCS)

# gen_kokkos.cmake includes the kokkos library itself in KOKKOS_LIBS
# which we do not want to use for the cmake builds so clean this up
string(REGEX REPLACE "-lkokkos" "" KOKKOS_LIBS ${KOKKOS_LIBS})

############################ Detect if submodule ###############################
#
# With thanks to StackOverflow:  
#      http://stackoverflow.com/questions/25199677/how-to-detect-if-current-scope-has-a-parent-in-cmake
#
get_directory_property(HAS_PARENT PARENT_DIRECTORY)
if(HAS_PARENT)
  message(STATUS "Submodule build")
  SET(KOKKOS_HEADER_DIR "include/kokkos")
else()
  message(STATUS "Standalone build")
  SET(KOKKOS_HEADER_DIR "include")
endif()

################################ Handle the actual build #######################

SET(INSTALL_LIB_DIR lib CACHE PATH "Installation directory for libraries")
SET(INSTALL_BIN_DIR bin CACHE PATH "Installation directory for executables")
SET(INSTALL_INCLUDE_DIR ${KOKKOS_HEADER_DIR} CACHE PATH
  "Installation directory for header files")
IF(WIN32 AND NOT CYGWIN)
  SET(DEF_INSTALL_CMAKE_DIR CMake)
ELSE()
  SET(DEF_INSTALL_CMAKE_DIR lib/CMake/Kokkos)
ENDIF()

SET(INSTALL_CMAKE_DIR ${DEF_INSTALL_CMAKE_DIR} CACHE PATH
    "Installation directory for CMake files")

# Make relative paths absolute (needed later on)
FOREACH(p LIB BIN INCLUDE CMAKE)
  SET(var INSTALL_${p}_DIR)
  IF(NOT IS_ABSOLUTE "${${var}}")
    SET(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
  ENDIF()
ENDFOREACH()

# set up include-directories
SET (Kokkos_INCLUDE_DIRS
    ${Kokkos_SOURCE_DIR}/core/src
    ${Kokkos_SOURCE_DIR}/containers/src
    ${Kokkos_SOURCE_DIR}/algorithms/src
    ${Kokkos_BINARY_DIR}  # to find KokkosCore_config.h
    ${KOKKOS_INCLUDE_DIRS}
)

# pass include dirs back to parent scope
if(HAS_PARENT)
SET(Kokkos_INCLUDE_DIRS_RET ${Kokkos_INCLUDE_DIRS} PARENT_SCOPE)
else()
SET(Kokkos_INCLUDE_DIRS_RET ${Kokkos_INCLUDE_DIRS})
endif()

INCLUDE_DIRECTORIES(${Kokkos_INCLUDE_DIRS})

IF(KOKKOS_SEPARATE_LIBS)
  # kokkoscore
  ADD_LIBRARY(
    kokkoscore
    ${KOKKOS_CORE_SRCS}
  )

  target_compile_options(
    kokkoscore
    PUBLIC ${KOKKOS_CXX_FLAGS}
  )

  target_compile_features(
    kokkoscore
    PUBLIC ${KOKKOS_CXX11_FEATURES}
  )

  # Install the kokkoscore library
  INSTALL (TARGETS kokkoscore
           ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
  )

  # Install the kokkoscore headers
  INSTALL (DIRECTORY
           ${Kokkos_SOURCE_DIR}/core/src/
           DESTINATION ${KOKKOS_HEADER_DIR} 
           FILES_MATCHING PATTERN "*.hpp"
  )

  # Install KokkosCore_config.h header
  INSTALL (FILES
           ${Kokkos_BINARY_DIR}/KokkosCore_config.h
           DESTINATION ${KOKKOS_HEADER_DIR}
  )

  TARGET_LINK_LIBRARIES(
    kokkoscore
    ${KOKKOS_LD_FLAGS}
    ${KOKKOS_LIBS}
  )

  # kokkoscontainers
  if (DEFINED KOKKOS_CONTAINERS_SRCS)
    ADD_LIBRARY(
      kokkoscontainers
      ${KOKKOS_CONTAINERS_SRCS}
    )
  endif()

  TARGET_LINK_LIBRARIES(
    kokkoscontainers
    kokkoscore
  )

  # Install the kokkocontainers library
  INSTALL (TARGETS kokkoscontainers
           ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

  # Install the kokkoscontainers headers
  INSTALL (DIRECTORY
           ${Kokkos_SOURCE_DIR}/containers/src/
           DESTINATION ${KOKKOS_HEADER_DIR} 
           FILES_MATCHING PATTERN "*.hpp"
  )

  # kokkosalgorithms - Build as interface library since no source files.
  ADD_LIBRARY(
    kokkosalgorithms
    INTERFACE
  )

  target_include_directories(
    kokkosalgorithms
    INTERFACE ${Kokkos_SOURCE_DIR}/algorithms/src
  )

  TARGET_LINK_LIBRARIES(
    kokkosalgorithms
    INTERFACE kokkoscore
  )

  # Install the kokkoalgorithms library
  INSTALL (TARGETS kokkosalgorithms
           ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

  # Install the kokkosalgorithms headers
  INSTALL (DIRECTORY
           ${Kokkos_SOURCE_DIR}/algorithms/src/
           DESTINATION ${KOKKOS_INSTALL_INDLUDE_DIR}
           FILES_MATCHING PATTERN "*.hpp"
  )

  SET (Kokkos_LIBRARIES_NAMES kokkoscore kokkoscontainers kokkosalgorithms)

ELSE()
  # kokkos
  ADD_LIBRARY(
    kokkos
    ${KOKKOS_CORE_SRCS}
    ${KOKKOS_CONTAINERS_SRCS}
  )

  target_compile_options(
    kokkos
    PUBLIC ${KOKKOS_CXX_FLAGS}
  )

  target_compile_features(
    kokkos
    PUBLIC ${KOKKOS_CXX11_FEATURES}
  )

  TARGET_LINK_LIBRARIES(
    kokkos
    ${KOKKOS_LD_FLAGS}
    ${KOKKOS_LIBS}
  )

  # Install the kokkos library
  INSTALL (TARGETS kokkos
           EXPORT KokkosTargets
           ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
           RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)


  # Install the kokkos headers
  INSTALL (DIRECTORY
           EXPORT KokkosTargets
           ${Kokkos_SOURCE_DIR}/core/src/
           DESTINATION ${KOKKOS_HEADER_DIR}
           FILES_MATCHING PATTERN "*.hpp"
  )
  INSTALL (DIRECTORY
           EXPORT KokkosTargets
           ${Kokkos_SOURCE_DIR}/containers/src/
           DESTINATION ${KOKKOS_HEADER_DIR}
           FILES_MATCHING PATTERN "*.hpp"
  )
  INSTALL (DIRECTORY
           EXPORT KokkosTargets
           ${Kokkos_SOURCE_DIR}/algorithms/src/
           DESTINATION ${KOKKOS_HEADER_DIR}
           FILES_MATCHING PATTERN "*.hpp"
  )

  INSTALL (FILES
           ${Kokkos_BINARY_DIR}/KokkosCore_config.h
           DESTINATION ${KOKKOS_HEADER_DIR}
  )

  include_directories(${Kokkos_BINARY_DIR})
  include_directories(${Kokkos_SOURCE_DIR}/core/src)
  include_directories(${Kokkos_SOURCE_DIR}/containers/src)
  include_directories(${Kokkos_SOURCE_DIR}/algorithms/src)

  SET (Kokkos_LIBRARIES_NAMES kokkos)

endif()

# Add all targets to the build-tree export set
export(TARGETS ${Kokkos_LIBRARIES_NAMES}
  FILE "${Kokkos_BINARY_DIR}/KokkosTargets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE Kokkos)

# Create the KokkosConfig.cmake and KokkosConfigVersion files
file(RELATIVE_PATH REL_INCLUDE_DIR "${INSTALL_CMAKE_DIR}"
   "${INSTALL_INCLUDE_DIR}")
# ... for the build tree
set(CONF_INCLUDE_DIRS "${Kokkos_SOURCE_DIR}" "${Kokkos_BINARY_DIR}")
configure_file(${Kokkos_SOURCE_DIR}/cmake/KokkosConfig.cmake.in
  "${Kokkos_BINARY_DIR}/KokkosConfig.cmake" @ONLY)
# ... for the install tree
set(CONF_INCLUDE_DIRS "\${Kokkos_CMAKE_DIR}/${REL_INCLUDE_DIR}")
configure_file(${Kokkos_SOURCE_DIR}/cmake/KokkosConfig.cmake.in
  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfig.cmake" @ONLY)

# Install the KokkosConfig.cmake and KokkosConfigVersion.cmake
install(FILES
  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfig.cmake"
  DESTINATION "${INSTALL_CMAKE_DIR}")

# Install the export set for use with the install-tree
INSTALL(EXPORT KokkosTargets DESTINATION
       "${INSTALL_CMAKE_DIR}")
