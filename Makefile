# We need to get the absolute path of the makefile (in order to find
# entrypoint.sh) => this is the equivalent of:
# ```
# $(dirname "$(realpath "$source")")
# ```
# in GNUMake
MKFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Placehoder values designed to throw an error unless overwritten by the user
# => simulates mandatory arguments.
SITE ?= INVALID
MODE ?= INVALID
# Valid sites and modes
SITES := nersc psc gcp
MODES := local global
# Check site and mode
ifneq ($(filter $(SITE),$(SITES)),$(SITE))
    $(error SITE must be one of: $(SITES))
endif
ifneq ($(filter $(MODE),$(MODES)),$(MODE))
    $(error MODE must be one of: $(MODES))
endif

ifeq ($(MODE),local)
    LOCAL_PATH ?= $(MKFILE_DIR)/tmp
    EP_ARG := -l $(LOCAL_PATH)
    $(info Running in local install mode with LOCAL_PATH=$(LOCAL_PATH))
    ML_CMD = ml use $(LOCAL_PATH)/modules
else
    EP_ARG :=
endif

# Build steps
.PHONY: julia-env juliaup julia kernels scripts \
	mpitrampoline mpiwrapper extrae

all: julia-env juliaup julia kernels scripts mpitrampoline mpiwrapper extrae

#______________________________________________________________________________
# JULIA-ENV Module
#
ifeq ($(SITE),nersc)
# julia-env not needed by nersc => creating an empty recipe that does nothing
julia-env:
	$(info Skipping "julia-env" at NERSC => not needed)
else
julia-env:
	$(info Building julia-env for $(SITE) using $(MODE) mode)
endif
#------------------------------------------------------------------------------

#______________________________________________________________________________
# JULIAUP Module
#
juliaup:
	$(info Building juliaup for $(SITE) using $(MODE) mode)
	$(MKFILE_DIR)/entrypoint.sh $(EP_ARG) $(SITE)/juliaup/render.sh
#------------------------------------------------------------------------------

#______________________________________________________________________________
# JULIA Module
#
ifeq ($(MODE),local)
julia: $(LOCAL_PATH)/modules/juliaup
	$(info Building julia for $(SITE) using $(MODE) mode)
	$(info Running with MODE=$(MODE) => pointing MODULEPATH to (LOCAL_PATH)/modules)
	bash -c "$(ML_CMD); $(MKFILE_DIR)/entrypoint.sh $(EP_ARG) $(SITE)/julia/render.sh"
else
julia:
	$(info Building julia for $(SITE) using $(MODE) mode)
	$(MKFILE_DIR)/entrypoint.sh $(SITE)/julia/render.sh
endif
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Julia Kernels
#
ifeq ($(MODE),local)
kernels: $(LOCAL_PATH)/modules/julia
	$(info Building julia for $(SITE) using $(MODE) mode)
	$(info Running with MODE=$(MODE) => pointing MODULEPATH to (LOCAL_PATH)/modules)
	bash -c "$(ML_CMD); $(MKFILE_DIR)/entrypoint.sh $(EP_ARG) $(SITE)/kernels/templates/render.sh"
else
kernels:
	$(info Building julia for $(SITE) using $(MODE) mode)
	$(MKFILE_DIR)/entrypoint.sh $(SITE)/kernels/templates/render.sh
endif
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Helper Scripts
#
ifeq ($(MODE),local)
scripts: $(LOCAL_PATH)/modules/julia
	$(info Building julia for $(SITE) using $(MODE) mode)
	$(info Running with MODE=$(MODE) => pointing MODULEPATH to (LOCAL_PATH)/modules)
	bash -c "$(ML_CMD); $(MKFILE_DIR)/entrypoint.sh $(EP_ARG) $(SITE)/scripts/templates/render.sh"
else
scripts:
	$(info Building julia for $(SITE) using $(MODE) mode)
	$(MKFILE_DIR)/entrypoint.sh $(SITE)/scripts/templates/render.sh
endif
#------------------------------------------------------------------------------
