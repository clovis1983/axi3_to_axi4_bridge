# Makefile for AXI3->AXI4 Bridge

TOP        ?= axi3_to_axi4_tb
SIMV       ?= simv_axi3_to_axi4
FSDB_FILE  ?= axi3_to_axi4.fsdb
NOVAS_HOME ?=
NOVAS_ARCH ?= LINUX64
VERILATOR  ?= verilator
SDKROOT    ?= $(shell xcrun --show-sdk-path 2>/dev/null)
CXX        ?= clang++
LIBCXX_INC ?= $(SDKROOT)/usr/include/c++/v1

RTL_FILES  := axi3_to_axi4_bridge.v
TB_FILES   := axi3_to_axi4_tb.v
SRC_FILES  := $(RTL_FILES) $(TB_FILES)

VCS        ?= vcs
VCS_FLAGS  ?= -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca
VERILATOR_FLAGS ?= --binary --timing -Wno-fatal
SIM_FLAGS  ?=

COMPILE_LOG ?= vcs_compile.log
RUN_LOG     ?= sim.log
RUN_FSDB_LOG?= sim_fsdb.log

# Optional explicit Novas PLI linkage
FSDB_PLI :=
ifneq ($(NOVAS_HOME),)
FSDB_PLI += -P $(NOVAS_HOME)/share/PLI/VCS/$(NOVAS_ARCH)/novas.tab
FSDB_PLI += $(NOVAS_HOME)/share/PLI/VCS/$(NOVAS_ARCH)/pli.a
endif

ifneq ($(shell command -v $(VCS) 2>/dev/null),)
SIM_BACKEND := vcs
else ifneq ($(shell command -v $(VERILATOR) 2>/dev/null),)
SIM_BACKEND := verilator
else
SIM_BACKEND := none
endif

all: run

check_vcs:
	@command -v $(VCS) >/dev/null 2>&1 || (echo "ERROR: '$(VCS)' not found in PATH" && exit 127)

check_verilator:
	@command -v $(VERILATOR) >/dev/null 2>&1 || (echo "ERROR: '$(VERILATOR)' not found in PATH" && exit 127)

compile_vcs: check_vcs
	@echo "[VCS] Compile $(TOP)"
	$(VCS) $(VCS_FLAGS) $(FSDB_PLI) -top $(TOP) $(SRC_FILES) -o $(SIMV) -l $(COMPILE_LOG)

compile_verilator: check_verilator
	@echo "[Verilator] Compile $(TOP)"
	SDKROOT="$(SDKROOT)" CXX="$(CXX)" CPPFLAGS="-isysroot $(SDKROOT) -isystem $(LIBCXX_INC)" CXXFLAGS="-isysroot $(SDKROOT) -isystem $(LIBCXX_INC)" $(VERILATOR) $(VERILATOR_FLAGS) -top $(TOP) $(SRC_FILES)

compile:
ifeq ($(SIM_BACKEND),vcs)
	@$(MAKE) compile_vcs
else ifeq ($(SIM_BACKEND),verilator)
	@$(MAKE) compile_verilator
else
	@echo "ERROR: neither '$(VCS)' nor '$(VERILATOR)' is available in PATH"
	@exit 127
endif

run_vcs: compile_vcs
	@echo "[VCS] Run (no waveform)"
	./$(SIMV) $(SIM_FLAGS) -l $(RUN_LOG)

run_verilator: compile_verilator
	@echo "[Verilator] Run"
	./obj_dir/V$(TOP) $(SIM_FLAGS)

run: 
ifeq ($(SIM_BACKEND),vcs)
	@$(MAKE) run_vcs
else ifeq ($(SIM_BACKEND),verilator)
	@$(MAKE) run_verilator
else
	@echo "ERROR: neither '$(VCS)' nor '$(VERILATOR)' is available in PATH"
	@exit 127
endif

run_fsdb: compile
ifeq ($(SIM_BACKEND),vcs)
	@echo "[VCS] Run + FSDB ($(FSDB_FILE))"
	./$(SIMV) $(SIM_FLAGS) +DUMP_FSDB +FSDB_FILE=$(FSDB_FILE) -l $(RUN_FSDB_LOG)
	@echo "[INFO] FSDB expected: $(FSDB_FILE)"
else ifeq ($(SIM_BACKEND),verilator)
	@echo "[Verilator] Run + VCD ($(FSDB_FILE))"
	./obj_dir/V$(TOP) $(SIM_FLAGS) +DUMP_FSDB +FSDB_FILE=$(FSDB_FILE)
	@echo "[INFO] VCD generated with requested filename: $(FSDB_FILE)"
else
	@echo "ERROR: neither '$(VCS)' nor '$(VERILATOR)' is available in PATH"
	@exit 127
endif

run_gui: run_fsdb
	@echo "[GUI] Open FSDB with verdi"
	verdi -ssf $(FSDB_FILE) &

clean:
	rm -rf csrc ucli.key *.daidir DVEfiles novas* verdiLog *.vpd *.vcd *.fsdb
	rm -f $(SIMV) $(COMPILE_LOG) $(RUN_LOG) $(RUN_FSDB_LOG)

help:
	@echo "Targets:"
	@echo "  make run                 # compile + run"
	@echo "  make run_fsdb            # compile + run + generate FSDB"
	@echo "  make run_gui             # run_fsdb and open verdi"
	@echo "  make clean               # cleanup"
	@echo ""
	@echo "Variables:"
	@echo "  SIM_BACKEND=$(SIM_BACKEND)"
	@echo "  SDKROOT=$(SDKROOT)"
	@echo "  LIBCXX_INC=$(LIBCXX_INC)"
	@echo "  TOP=$(TOP)"
	@echo "  SIMV=$(SIMV)"
	@echo "  FSDB_FILE=$(FSDB_FILE)"
	@echo "  NOVAS_HOME=$(NOVAS_HOME)"
	@echo "  NOVAS_ARCH=$(NOVAS_ARCH)"

.PHONY: all check_vcs check_verilator compile compile_vcs compile_verilator run run_vcs run_verilator run_fsdb run_gui clean help
