# Copyright 2018-2019 Google LLC
#
# This is part of the Google Cloud IoT Device SDK for Embedded C,
# it is licensed under the BSD 3-Clause license; you may not use this file
# except in compliance with the License.
#
# You may obtain a copy of the License at:
#  https://opensource.org/licenses/BSD-3-Clause
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LIBIOTC := $(CURDIR)

export LIBIOTC

# Reserve 'all' as the default build target
all:

IOTC_SRCDIRS ?=
IOTC_CONFIG_FLAGS ?=
IOTC_ARFLAGS ?=
BSP_FLAGS ?=
IOTC_INCLUDE_FLAGS ?= -I.
IOTC_PROTO_COMPILER ?=
IOTC_BSP_DIR ?= $(LIBIOTC)/src/bsp
MD ?= @

# TLS related configuration
IOTC_BSP_TLS ?= mbedtls

# Cryptographic BSP implementation
IOTC_BSP_CRYPTO ?= $(IOTC_BSP_TLS)

#detect if the build happen on Travis
ifdef TRAVIS_OS_NAME
IOTC_TRAVIS_BUILD=1
endif

include make/mt-config/mt-presets.mk

include make/mt-config/mt-config.mk
include make/mt-os/mt-os.mk
include make/mt-os/mt-$(IOTC_CONST_PLATFORM_CURRENT).mk
include make/mt-config/mt-examples.mk
include make/mt-config/tests/mt-gtest.mk
include make/mt-config/tests/mt-tests-tools.mk
include make/mt-config/tests/mt-tests-unit.mk
include make/mt-config/tests/mt-tests-integration.mk
include make/mt-config/tests/mt-tests-fuzz.mk


ifdef MAKEFILE_DEBUG
$(info ----- )
$(info -TOOLCHAIN- $$CC is [${CC}])
$(info -TOOLCHAIN- $$AR is [${AR}])
$(info ----- )
$(info -TESTS- $$IOTC_UTESTS is [${IOTC_UTESTS}])
$(info -TESTS- $$IOTC_TEST_BINDIR is [${IOTC_TEST_BINDIR}])
$(info -TESTS- $$IOTC_TEST_DIR is [${IOTC_TEST_DIR}])
$(info ----- )
$(info -EXAMPLES- $$IOTC_EXAMPLES is [${IOTC_EXAMPLES}])
$(info ----- )
endif

#gather all binary directories
IOTC_BIN_DIRS := $(IOTC_EXAMPLE_BINDIR) $(IOTC_EXAMPLE_BINDIR)/internal $(IOTC_TEST_BINDIR) $(IOTC_TEST_TOOLS_BINDIR)

#default test target always present cause tiny test cross-compiles
IOTC_TESTS_TARGETS := $(IOTC_UTESTS) $(IOTC_TEST_TOOLS_OBJS) $(IOTC_TEST_TOOLS)

# default output file declaration
IOTC_COMPILER_OUTPUT ?= -o $@

.PHONY: header
header:
	$(info )
	$(info # )
	$(info # Google IoT Core Embedded C Client Makefile )
	$(info #  Please see ./README.md for more information.)
	$(info # )
	$(info )

.PHONY: build_output
build_output: header preset_output
	$(info .    CONFIG:          [${CONFIG}])
	$(info .    TARGET:          [${TARGET}])
	$(info .    COMPILER:        [$(CC)] )
	$(info )

all: build_output $(XI)

.PHONY: tests
tests: build_output utests gtests itests

.PHONY: utests
utests: $(IOTC_UTESTS) $(IOTC_TEST_TOOLS_OBJS) $(IOTC_TEST_TOOLS)
	$(IOTC_RUN_UTESTS)

.PHONY: itests
itests: $(IOTC_ITESTS) $(IOTC_TEST_TOOLS_OBJS) $(IOTC_TEST_TOOLS)
	$(IOTC_RUN_ITESTS)

.PHONY: gtests
gtests: $(IOTC_GTESTS)
	$(IOTC_RUN_GTESTS)

.PHONY: test_coverage
test_coverage:
	./tools/test_coverage.sh

internal_examples: $(XI) $(IOTC_INTERNAL_EXAMPLES)

linux:
	make CONFIG=$(CONFIG) TARGET=$(subst osx,linux,$(TARGET))

buildtime:
	time bash -c make

clean:
	$(RM) -rf \
		$(IOTC_BINDIR) \
		$(IOTC_OBJDIR)
	$(MAKE) -C $(IOTC_TLS_LIB_SRC_DIR) clean

clean_all: clean
	$(RM) -rf \
		$(IOTC_BINDIR_BASE) \
		$(IOTC_OBJDIR_BASE)
	$(RM) -rf $(IOTC_TEST_TOOLS_EXT_PROTOBUF_OBJS)
	$(RM) -rf $(CMOCKA_BUILD_DIR)
	$(RM) -rf $(IOTC_TEST_OBJDIR)
	$(RM) -rf $(IOTC_TLS_LIB_SRC_DIR)

libiotc: $(XI)

$(XI): $(IOTC_TLS_LIB_DEP) $(IOTC_CRYPTO_LIB_DEP) $(IOTC_PROTOFILES_C) $(IOTC_OBJS) $(IOTC_BUILD_PRECONDITIONS) | $(IOTC_BIN_DIRS)
	$(info [$(AR)] $@ )
	$(MD) $(AR) $(IOTC_ARFLAGS) $(IOTC_OBJS) $(IOTC_EXTRA_ARFLAGS)

# protobuf compilation
$(IOTC_PROTOBUF_GENERATED)/%.pb-c.c : $(IOTC_PROTO_DIR)/%.proto
	@-mkdir -p $(dir $@)
	$(IOTC_PROTO_COMPILER) --c_out=$(IOTC_PROTOBUF_GENERATED) --proto_path=$(IOTC_PROTO_DIR) $<

# defining dependencies for object files generated by gcc -MM
# Autodependencies with GNU make: http://scottmcpeak.com/autodepend/autodepend.html
-include $(IOTC_TEST_TOOLS_OBJS:.o=.d)

# specific compiler flags for utest objects
$(IOTC_UTEST_OBJDIR)/%.o : $(IOTC_UTEST_SOURCE_DIR)/%.c $(IOTC_BUILD_PRECONDITIONS)
	@-mkdir -p $(dir $@)
	$(info [$(CC)] $@)
	$(MD) $(CC) $(IOTC_UTEST_CONFIG_FLAGS) $(IOTC_UTEST_INCLUDE_FLAGS) -c $< $(IOTC_COMPILER_OUTPUT)
	$(MD) $(CC) $(IOTC_UTEST_CONFIG_FLAGS) $(IOTC_UTEST_INCLUDE_FLAGS) -MM $< -MT $@ -MF $(@:.o=.d)

# specific compiler flags for gtest objects
$(IOTC_GTEST_OBJDIR)/%.o : $(LIBIOTC_SRC)/%.cc $(IOTC_BUILD_PRECONDITIONS)
	@-mkdir -p $(dir $@)
	$(info [$(CXX)] $@)
	$(MD) $(CXX) $(IOTC_GTEST_CONFIG_FLAGS) $(IOTC_GTEST_CXX_FLAGS) -c $< $(IOTC_COMPILER_OUTPUT)
	$(MD) $(CXX) $(IOTC_GTEST_CONFIG_FLAGS) $(IOTC_GTEST_CXX_FLAGS) -MM $< -MT $@ -MF $(@:.o=.d)

# specific compiler flags for libiotc_driver
$(IOTC_OBJDIR)/tests/tools/iotc_libiotc_driver/%.o : $(LIBIOTC)/src/tests/tools/iotc_libiotc_driver/%.c $(IOTC_BUILD_PRECONDITIONS)
	@-mkdir -p $(dir $@)
	$(info [$(CC)] $@)
	$(MD) $(CC) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) $(IOTC_TEST_TOOLS_INCLUDE_FLAGS) -c $< $(IOTC_COMPILER_OUTPUT)
	$(MD) $(CC) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) $(IOTC_TEST_TOOLS_INCLUDE_FLAGS) -MM $< -MT $@ -MF $(@:.o=.d)

-include $(IOTC_OBJS:.o=.d)

# C source files
$(IOTC_OBJDIR)/%.o : $(LIBIOTC)/src/%.c $(IOTC_BUILD_PRECONDITIONS)
	@-mkdir -p $(dir $@)
	$(info [$(CC)] $@)
	$(MD) $(CC) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) -c $< $(IOTC_COMPILER_OUTPUT)
	$(IOTC_POST_COMPILE_ACTION_CC)

$(IOTC_OBJDIR)/third_party/%.o : $(LIBIOTC)/third_party/%.c $(IOTC_BUILD_PRECONDITIONS)
	@-mkdir -p $(dir $@)
	$(info [$(CC)] $@)
	$(MD) $(CC) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) -c $< $(IOTC_COMPILER_OUTPUT)
	$(IOTC_POST_COMPILE_ACTION_CC)

# C++ source files
$(IOTC_OBJDIR)/%.o : $(LIBIOTC)/src/%.cc $(IOTC_BUILD_PRECONDITIONS)
	@-mkdir -p $(dir $@)
	$(info [$(CXX)] $@)
	$(MD) $(CXX) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_CXX_FLAGS) $(IOTC_INCLUDE_FLAGS) -c $< $(IOTC_COMPILER_OUTPUT)
	$(IOTC_POST_COMPILE_ACTION_CXX)

###
#### Builtin root CA certificates
###
IOTC_BUILTIN_ROOTCA_CERTS := $(LIBIOTC)/res/trusted_RootCA_certs/roots.pem

$(IOTC_BUILTIN_ROOTCA_CERTS):
	curl -s "https://pki.goog/gtsltsr/gtsltsr.crt" \
		| openssl x509 -inform der -outform pem \
		> $@

	curl -s "https://pki.goog/gsr4/GSR4.crt" \
		| openssl x509 -inform der -outform pem \
		>> $@

.PHONY: update_builtin_cert_buffer
update_builtin_cert_buffer: $(IOTC_BUILTIN_ROOTCA_CERTS)
	./tools/create_buffer.py \
		--file_name $< \
		--array_name iotc_RootCA_list \
		--out_path ./src/libiotc/tls/certs \
		--no-pretend

# gather all of the binary directories
IOTC_RESOURCE_FILES := $(IOTC_BUILTIN_ROOTCA_CERTS)

ifneq (,$(findstring posix_fs,$(CONFIG)))
IOTC_PROVIDE_RESOURCE_FILES = ON
endif

###
#### EXAMPLES
###
-include $(IOTC_EXAMPLE_OBJDIR)/*.d

$(IOTC_EXAMPLE_BINDIR)/internal/%: $(XI)
	$(info [$(CC)] $@)
	@-mkdir -p $(IOTC_EXAMPLE_OBJDIR)/$(subst $(IOTC_EXAMPLE_BINDIR)/,,$(dir $@))
	$(MD) $(CC) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS)$(IOTC_INCLUDE_FLAGS) -L$(IOTC_BINDIR) $(XI) $(LIBIOTC)/examples/common/src/commandline.c $(IOTC_EXAMPLE_DIR)/$(subst $(IOTC_EXAMPLE_BINDIR),,$@).c $(IOTC_LIB_FLAGS) $(IOTC_COMPILER_OUTPUT)
	$(MD) $(CC) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) -MM $(IOTC_EXAMPLE_DIR)/$(subst $(IOTC_EXAMPLE_BINDIR),,$@).c -MT $@ -MF $(IOTC_EXAMPLE_OBJDIR)/$(subst $(IOTC_EXAMPLE_BINDIR)/,,$@).d

###
#### TEST TOOLS
###
-include $(IOTC_TEST_TOOLS_OBJDIR)/*.d

$(IOTC_TEST_TOOLS_BINDIR)/%: $(XI) $(IOTC_TEST_TOOLS_OBJS)
	$(info [$(CC)] $@)
	$(MD) $(CC) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) -L$(IOTC_BINDIR) $(IOTC_TEST_TOOLS_OBJS) $(IOTC_TEST_TOOLS_SRCDIR)/$(notdir $@)/$(notdir $@).c $(IOTC_LIB_FLAGS) $(IOTC_COMPILER_OUTPUT)
	@-mkdir -p $(IOTC_TEST_TOOLS_OBJDIR)
	$(MD) $(CC) $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS) -MM $(IOTC_TEST_TOOLS_SRCDIR)/$(notdir $@)/$(notdir $@).c -MT $@ -MF $(IOTC_TEST_TOOLS_OBJDIR)/$(notdir $@).d
	@#$@

###
#### TESTS
###
# dependencies for unit test binary
IOTC_UTESTS_DEPENDENCIES_FILE = $(IOTC_UTEST_OBJDIR)/$(notdir $(IOTC_UTESTS)).d
-include $(IOTC_UTESTS_DEPENDENCIES_FILE)

IOTC_GTESTS_DEPENDENCIES_FILE = $(IOTC_GTEST_OBJDIR)/$(notdir $(IOTC_GTESTS)).d
-include $(IOTC_GTESTS_DEPENDENCIES_FILE)

$(IOTC_UTESTS): $(XI) $(IOTC_UTEST_OBJS) $(TINY_TEST_OBJ)
	$(info [$(CC)] $@)
	@-mkdir -p $(IOTC_UTEST_OBJDIR)
	$(MD) $(CC) $(IOTC_UTEST_CONFIG_FLAGS) $(IOTC_UTEST_INCLUDE_FLAGS) -L$(IOTC_BINDIR) $(IOTC_UTEST_SUITE_SOURCE) $(IOTC_UTEST_OBJS) $(TINY_TEST_OBJ) $(IOTC_LIB_FLAGS) $(IOTC_COMPILER_OUTPUT)
	$(MD) $(CC) $(IOTC_UTEST_CONFIG_FLAGS) $(IOTC_UTEST_INCLUDE_FLAGS) -MM $(IOTC_UTEST_SUITE_SOURCE) -MT $@ -MF $(IOTC_UTESTS_DEPENDENCIES_FILE)

$(IOTC_GTESTS): $(XI) $(IOTC_GTEST_OBJS) $(IOTC_UTEST_UTIL_OBJS) $(GTEST_OBJS) $(GMOCK_OBJS)
	$(info [$(CXX)] $@)
	@-mkdir -p $(IOTC_GTEST_OBJDIR)
	$(MD) $(CXX) $(IOTC_GTEST_CONFIG_FLAGS) $(IOTC_GTEST_CXX_FLAGS) -L$(IOTC_BINDIR) $(IOTC_GTEST_OBJS) $(GTEST_OBJS) $(GMOCK_OBJS) $(IOTC_UTEST_UTIL_OBJS) $(IOTC_LIB_FLAGS) $(IOTC_COMPILER_OUTPUT)

# dependencies for integration test binary
ifneq ($(IOTC_CONST_PLATFORM_CURRENT),$(IOTC_CONST_PLATFORM_ARM))

-include $(IOTC_ITEST_OBJS:.o=.d)

$(IOTC_ITESTS): $(XI) $(CMOCKA_LIBRARY_DEPS) $(IOTC_ITEST_OBJS)
	$(info [$(CC)] $@)
	$(MD) $(CC) $(IOTC_ITEST_OBJS) $(IOTC_ITESTS_CFLAGS) -L$(IOTC_BINDIR) $(IOTC_LIB_FLAGS) $(CMOCKA_LIBRARY) $(IOTC_COMPILER_OUTPUT)
endif

$(IOTC_FUZZ_TESTS_BINDIR)/%: $(IOTC_FUZZ_TESTS_SOURCE_DIR)/%.cpp
	@-mkdir -p $(dir $@)
	$(info [$(CXX)] $@)
	$(MD) $(CXX) $< $(IOTC_CONFIG_FLAGS) $(IOTC_INCLUDE_FLAGS) -L$(IOTC_BINDIR) -L$(IOTC_LIBFUZZER_DOWNLOAD_DIR) $(IOTC_LIB_FLAGS) $(IOTC_FUZZ_TEST_LIBRARY) $(IOTC_COMPILER_OUTPUT)

$(IOTC_FUZZ_TESTS): $(XI)

.PHONY: fuzz_tests
fuzz_tests: build_output $(IOTC_LIBFUZZER) $(IOTC_FUZZ_TESTS) $(IOTC_FUZZ_TESTS_CORPUS_DIRS)
	$(foreach fuzztest, $(IOTC_FUZZ_TESTS), $(call IOTC_RUN_FUZZ_TEST,$(fuzztest)))

.PHONY: static_analysis
static_analysis:  $(IOTC_SOURCES:.c=.sa)

NOW:=$(shell date +"%F-%T")

$(LIBIOTC)/src/%.sa:
	$(info [clang-tidy] $(@:.sa=.c))
	@clang-tidy --checks='clang-analyzer-*,-clang-analyzer-cplusplus*,-clang-analyzer-osx*' $(@:.sa=.c) >> static_analysis_$(NOW).log -- $(IOTC_CONFIG_FLAGS) $(IOTC_COMMON_COMPILER_FLAGS) $(IOTC_C_FLAGS) $(IOTC_INCLUDE_FLAGS)

$(IOTC_BIN_DIRS):
	@mkdir -p $@
ifdef IOTC_PROVIDE_RESOURCE_FILES
	@cp $(IOTC_RESOURCE_FILES) $@
endif

libiotc: $(XI)

update_docs_branch:
	-rm -rf doc/html
	doxygen && cd doc/html \
		&& git init \
		&& git remote add github git@github.com:googlecloudplatform/iotcore-sdk-embedded-c \
		&& git add . \
		&& git commit -m "[docs] Regenerated documentation for $(REV)" \
		&& git push github master:gh-pages -f
