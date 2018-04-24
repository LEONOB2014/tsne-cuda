# defines:
#   MKL_INCLUDE_DIRS
#   MKL_LIBRARIES
#   MKL_COMPILER_LIBRARIES - a list of compiler libraries (file names) required for MKL

#unset(MKL_LIB_DIR CACHE)
#unset(MKL_COMPILER_LIB_DIR CACHE)
#unset(MKL_COMPILER_REDIST_PATH CACHE)

SET(MKL_INCLUDE_SEARCH_PATHS
  /usr/include
  /usr/include/mkl
  /usr/include/intel/mkl
  /usr/local/include
  /usr/local/include/intel/mkl
  /opt/intel/mkl/include
  /opt/local/include
  $ENV{MKL_ROOT}
  $ENV{MKL_HOME}
  ${MKL_INCLUDE_DIR}
)

if(NOT HAVE_MKL)
  find_path(MKL_INCLUDE_DIRS "mkl.h" PATHS ${MKL_INCLUDE_SEARCH_PATHS} DOC "The path to MKL headers")

  if(MKL_INCLUDE_DIRS)

		get_filename_component(_MKL_LIB_PATH "${MKL_INCLUDE_DIRS}/../lib" ABSOLUTE)
		
		if(APPLE)
			# MKL 2017 for mac has only 64 bit libraries without directory prefix 
			set(_MKL_COMPILER_LIB_PATH ${MKL_INCLUDE_DIRS}/../../compiler/lib)
		else()
			if(CMAKE_SIZEOF_VOID_P EQUAL 8)
				set(_MKL_LIB_PATH "${_MKL_LIB_PATH}/intel64")
				set(_MKL_COMPILER_LIB_PATH ${MKL_INCLUDE_DIRS}/../../compiler/lib/intel64)
				if(WIN32)
					set(_MKL_COMPILER_REDIST_PATH ${MKL_INCLUDE_DIRS}/../../redist/intel64/compiler)
				endif()
			else()
				set(_MKL_LIB_PATH "${_MKL_LIB_PATH}/ia32")
				set(_MKL_COMPILER_LIB_PATH ${MKL_INCLUDE_DIRS}/../../compiler/lib/ia32)
				if(WIN32)
					set(_MKL_COMPILER_REDIST_PATH ${MKL_INCLUDE_DIRS}/../../redist/ia32/compiler)
				endif()
			endif()
		endif()

		# On Linux and Apple take libraries for redistribution from the same location that is used for linking
		if(UNIX)
			set(_MKL_COMPILER_REDIST_PATH ${_MKL_COMPILER_LIB_PATH})
		endif()

		if(WIN32)
			set(MKL_COMPILER_LIBRARIES libiomp5md.dll)
			set(MKL_LIBRARIES ${MKL_LIBRARIES} mkl_intel_lp64 mkl_core mkl_intel_thread libiomp5md)
		elseif(APPLE)
			set(MKL_COMPILER_LIBRARIES libiomp5.dylib)
			# generated by https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor
			# with the following options: OSX; Clang; Intel64; static; 32 bit integer; OpenMP; Intel OpenMP
			set(MKL_LIBRARIES ${MKL_LIBRARIES} libmkl_intel_lp64.a libmkl_intel_thread.a libmkl_core.a iomp5 pthread m dl)
		else()
			set(MKL_COMPILER_LIBRARIES libiomp5.so)
			# a --start-group / --end-group pair is required when linking with static MKL on GNU.
			# see https://software.intel.com/en-us/forums/topic/280974#comment-1478780
			# and https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor
			set(MKL_LIBRARIES ${MKL_LIBRARIES}
			"-Wl,--start-group"
			libmkl_intel_lp64.a libmkl_core.a libmkl_intel_thread.a
			"-Wl,--end-group"
			"-Wl,--exclude-libs,libmkl_intel_lp64.a,--exclude-libs,libmkl_core.a,--exclude-libs,libmkl_intel_thread.a,--exclude-libs,iomp5"
			iomp5 dl pthread m)
		endif()

		set(MKL_LIB_DIR "${_MKL_LIB_PATH}"
			CACHE PATH "Full path of MKL library directory")
		set(MKL_COMPILER_LIB_DIR "${_MKL_COMPILER_LIB_PATH}"
			CACHE PATH "Full path of MKL compiler library directory")
		set(MKL_COMPILER_REDIST_PATH "${_MKL_COMPILER_REDIST_PATH}"
			CACHE PATH "Full path of MKL compiler redistributable library directory")

	link_directories(${MKL_LIB_DIR} ${MKL_COMPILER_LIB_DIR})

    set(HAVE_MKL 1)

  endif(MKL_INCLUDE_DIRS)
endif(NOT HAVE_MKL)