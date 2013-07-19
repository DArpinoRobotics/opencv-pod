REPO := git://code.opencv.org/opencv.git #http://code.opencv.org/svn/opencv/tags/2.3.1/opencv/
CHECKOUT_DIR := opencv

default_target: all

# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)

# Default to a release build.  If you want to enable debugging flags, run
# "make BUILD_TYPE=Debug"
ifeq "$(BUILD_TYPE)" ""
BUILD_TYPE="Release"
endif

all: pod-build/Makefile
	$(MAKE) -C pod-build all install

pod-build/Makefile:
	$(MAKE) configure

.PHONY: configure
configure: $(CHECKOUT_DIR)/CMakeLists.txt
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

	# create the temporary build directory if needed
	@mkdir -p pod-build

	# Apply patches to work with libtool
	echo "Applying patches to opencv cmake files"
	- patch -p0 -N -s -i opencv.lib_components.patch
	- patch -p0 -N -s -i opencv.pkgconfig_libdir.patch

	# Patch the INSTALL_NAME_DIR for OSX, which ensures that the install name
	# for shared libraries includes the full path
ifeq ($(shell uname),Darwin)
	- patch -p0 -N -s -i opencv.osx.install_name_dir.patch
endif

	# run CMake to generate and configure the build scripts
	@cd pod-build && cmake -DCMAKE_INSTALL_PREFIX=$(BUILD_PREFIX) \
		-DWITH_FFMPEG=FALSE -DWITH_GSTREAMER=FALSE \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ../$(CHECKOUT_DIR)
		   
$(CHECKOUT_DIR)/CMakeLists.txt:
	#@svn checkout $(REPO) $(CHECKOUT_DIR)
	@git clone $(REPO) #git://code.opencv.org/opencv.git
		   

clean:
	-if [ -e pod-build/install_manifest.txt ]; then rm -f `cat pod-build/install_manifest.txt`; fi
	-if [ -d pod-build ]; then $(MAKE) -C pod-build clean; rm -rf pod-build; fi

# other (custom) targets are passed through to the cmake-generated Makefile 
%::
	$(MAKE) -C pod-build $@
