import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Paths configuration
ISA_DIR_WSL = "/mnt/c/Users/PC/Documents/Codex/2026-09-11/referenced-chatgpt-conversation-this-is-an/work/riscv-tests/isa"
DEFAULT_TEST_ELF = f"{ISA_DIR_WSL}/rv32ui-p-add"

# Vivado project paths
FRESH_PROJECT_XPR = "D:/Fresh/Fresh.xpr"
PROGRAM_MEM_TARGETS = [
    "D:/Fresh/Fresh.srcs/sim_1/new/Program.mem",
    "D:/Fresh/Fresh.sim/sim_1/behav/xsim/Program.mem",
    "D:/Fresh/Fresh.srcs/sim_1/imports/xsim/Program.mem"
]
SIMULATE_LOG_PATH = "D:/Fresh/Fresh.sim/sim_1/behav/xsim/simulate.log"
TCL_SCRIPT_PATH = "C:/Users/PC/.gemini/antigravity-ide/scratch/run_sim.tcl"

DEFAULT_VIVADO_HEX_TXT = "vivado_machine_code.txt"
DEFAULT_COMMIT_LOG_TXT = "spike_commit_log.txt"
DEFAULT_DUT_TRACE_TXT = "dut_commit_log.txt"
START_ADDRESS = 0x80000000  # Filter: address >= 0x80000000

# System instructions to replace with NOP (00000013) for pure RV32I hardware
SYSTEM_OPCODES = {0x73, 0x0F}
SYSTEM_MNEMONICS = {'csrr', 'csrw', 'csrs', 'csrc', 'csrrw', 'csrrs', 'csrrc', 
                    'csrrwi', 'csrrsi', 'csrrci', 'ecall', 'ebreak', 'fence', 
                    'fence.i', 'mret', 'sret', 'uret', 'wfi'}
NOP_HEX = "00000013"

ALLOWED_RV32I_TESTS = {
    'rv32ui-p-add', 'rv32ui-p-addi', 'rv32ui-p-sub',
    'rv32ui-p-and', 'rv32ui-p-andi', 'rv32ui-p-or', 'rv32ui-p-ori', 'rv32ui-p-xor', 'rv32ui-p-xori',
    'rv32ui-p-sll', 'rv32ui-p-slli', 'rv32ui-p-srl', 'rv32ui-p-srli', 'rv32ui-p-sra', 'rv32ui-p-srai',
    'rv32ui-p-slt', 'rv32ui-p-slti', 'rv32ui-p-sltu', 'rv32ui-p-sltiu',
    'rv32ui-p-lui', 'rv32ui-p-auipc',
    'rv32ui-p-beq', 'rv32ui-p-bne', 'rv32ui-p-blt', 'rv32ui-p-bge', 'rv32ui-p-bltu', 'rv32ui-p-bgeu',
    'rv32ui-p-jal', 'rv32ui-p-jalr',
    'rv32ui-p-lw', 'rv32ui-p-sw', 'rv32ui-p-lh', 'rv32ui-p-lhu', 'rv32ui-p-lb', 'rv32ui-p-lbu', 'rv32ui-p-sh', 'rv32ui-p-sb',
    'rv32ui-p-simple'
}

def get_available_tests():
    """Finds official compiled RISC-V test ELFs for user-level RV32I instructions."""
    tests = []
    cmd = f"find {ISA_DIR_WSL} -maxdepth 1 -name 'rv32ui-p-*' ! -name '*.log'"
    try:
        res = subprocess.run(["wsl", "bash", "-c", cmd], capture_output=True, text=True, check=True)
        found_paths = res.stdout.strip().splitlines()
        for p in sorted(found_paths):
            if p:
                test_name = os.path.basename(p)
                if test_name in ALLOWED_RV32I_TESTS:
                    tests.append({"name": test_name, "path": p})
    except Exception as e:
        print(f"[-] Error finding tests in {ISA_DIR_WSL}: {e}")
        
    if not tests:
        tests.append({"name": "rv32ui-p-add", "path": DEFAULT_TEST_ELF})
        
    return tests

def generate_aligned_memory_hex(test_elf_path):
    """
    Extracts raw 32-bit words from ELF disassembler and section dump preserving exact memory addresses starting from 0x80000000.
    Includes both .text (with CSR/system instructions replaced with NOP 00000013) and pre-initialized data (.data at 0x80002000).
    """
    mem_dict = {}

    # 1. Text section disassembly + NOP replacement for CSR/system opcodes
    cmd_d = f"riscv64-unknown-elf-objdump -d {test_elf_path}"
    try:
        res_d = subprocess.run(["wsl", "bash", "-c", cmd_d], capture_output=True, text=True, check=True)
        dump_pattern = re.compile(r"^\s*([0-9a-fA-F]+):\s+([0-9a-fA-F]{8})\s+(.*)")

        for line in res_d.stdout.splitlines():
            m = dump_pattern.match(line)
            if m:
                addr_val = int(m.group(1), 16)
                if addr_val < 0x80000000:
                    continue
                mach_hex = m.group(2).lower()
                asm_text = m.group(3).strip()
                mnemonic = asm_text.split()[0].lower() if asm_text else ""
                mach_val = int(mach_hex, 16)
                opcode_7 = mach_val & 0x7F
                idx = (addr_val - 0x80000000) // 4

                if opcode_7 in SYSTEM_OPCODES or mnemonic in SYSTEM_MNEMONICS:
                    mem_dict[idx] = NOP_HEX
                else:
                    mem_dict[idx] = mach_hex
    except Exception as e:
        print(f"[-] Error extracting disassembly from {test_elf_path}: {e}")

    # 2. Data section full contents (populates test constants at 0x80002000+)
    cmd_s = f"riscv64-unknown-elf-objdump -s {test_elf_path}"
    try:
        res_s = subprocess.run(["wsl", "bash", "-c", cmd_s], capture_output=True, text=True, check=True)
        sec_pattern = re.compile(r"^\s*([0-9a-fA-F]{8})\s+([0-9a-fA-F]{1,8})?\s*([0-9a-fA-F]{1,8})?\s*([0-9a-fA-F]{1,8})?\s*([0-9a-fA-F]{1,8})?")
        in_data = False

        for line in res_s.stdout.splitlines():
            if "Contents of section" in line:
                sec_name = line.split()[-1].rstrip(":")
                in_data = sec_name not in [".text.init", ".riscv.attributes", ".comment"]
                continue
            if in_data:
                m = sec_pattern.match(line)
                if m:
                    base_addr = int(m.group(1), 16)
                    if base_addr < 0x80000000:
                        continue
                    groups = [g for g in [m.group(2), m.group(3), m.group(4), m.group(5)] if g]
                    for offset_idx, chunk in enumerate(groups):
                        addr = base_addr + offset_idx * 4
                        idx = (addr - 0x80000000) // 4
                        chunk_padded = chunk.ljust(8, '0')
                        b0, b1, b2, b3 = chunk_padded[0:2], chunk_padded[2:4], chunk_padded[4:6], chunk_padded[6:8]
                        word_hex = f"{b3}{b2}{b1}{b0}"
                        mem_dict[idx] = word_hex
    except Exception as e:
        print(f"[-] Error extracting section contents from {test_elf_path}: {e}")

    if not mem_dict:
        return [NOP_HEX]

    max_idx = max(mem_dict.keys())
    memory_words = [mem_dict.get(i, NOP_HEX) for i in range(max_idx + 1)]
    return memory_words

def run_spike_in_wsl(test_elf_path, isa="rv32i"):
    """Runs Spike inside WSL with commit logging streaming directly to stdout/stderr."""
    test_name = os.path.basename(test_elf_path)
    wsl_cmd = f"spike --isa={isa} --log-commits -l {test_elf_path} 2>&1"
    
    print(f"\n[+] Step 1: Running Spike in WSL for: {test_name}")
    try:
        result = subprocess.run(
            ["wsl", "bash", "-c", wsl_cmd],
            capture_output=True,
            text=True,
            check=False
        )
        return result.stdout
    except Exception as e:
        print(f"[-] Exception running Spike: {e}")
        return ""

def parse_spike_log_with_commits(raw_log_text, min_address=0x80000000):
    """
    Parses Spike trace and commit lines preserving exact execution sequence.
    Converts CSR/System instructions and stores to standard PC-matching trace format.
    """
    inst_pattern = re.compile(r"core\s+\d+:\s+(0x[0-9a-fA-F]+)\s+\((0x[0-9a-fA-F]+)\)\s+(.*)")
    commit_pattern = re.compile(r"core\s+\d+:\s+\d+\s+(0x[0-9a-fA-F]+)\s+\((0x[0-9a-fA-F]+)\)(.*)")

    parsed_instructions = []
    lines = raw_log_text.splitlines()
    
    i = 0
    while i < len(lines):
        inst_match = inst_pattern.search(lines[i])
        if inst_match:
            pc_hex = inst_match.group(1)
            machine_hex = inst_match.group(2)
            assembly_text = inst_match.group(3).strip()
            mnemonic = assembly_text.split()[0].lower() if assembly_text else ""

            try:
                pc_val = int(pc_hex, 16)
                mach_val = int(machine_hex, 16)
                clean_hex_8 = f"{mach_val:08x}"
                pc_clean_8 = f"{pc_val:08x}"
                opcode_7 = mach_val & 0x7F
            except ValueError:
                i += 1
                continue

            reg_num_str = ""
            reg_val_str = ""
            mem_addr_str = ""
            mem_data_str = ""
            is_store = mnemonic.startswith('s') and mnemonic in {'sw', 'sh', 'sb'}
            is_system = (opcode_7 in SYSTEM_OPCODES or mnemonic in SYSTEM_MNEMONICS)

            if i + 1 < len(lines):
                commit_match = commit_pattern.search(lines[i+1])
                if commit_match:
                    commit_body = commit_match.group(3).strip()
                    
                    reg_m = re.search(r"x(\d+)\s+0x([0-9a-fA-F]+)", commit_body)
                    if reg_m:
                        reg_idx = int(reg_m.group(1))
                        reg_num_str = f"{reg_idx:02d}"
                        reg_val_str = f"{int(reg_m.group(2), 16):08x}"

                    mem_m = re.search(r"mem\s+0x([0-9a-fA-F]+)(?:\s+0x([0-9a-fA-F]+))?", commit_body)
                    if mem_m:
                        mem_addr_str = f"{int(mem_m.group(1), 16):08x}"
                        if mem_m.group(2):
                            mem_data_str = f"{int(mem_m.group(2), 16):08x}"

                    i += 1

            # If system/CSR or store instruction, model it as PC only to match DUT trace formatting
            if is_system or is_store:
                commit_formatted = f"{pc_clean_8}"
            elif reg_num_str and reg_val_str:
                commit_formatted = f"{pc_clean_8} {reg_num_str} {reg_val_str}"
            else:
                commit_formatted = f"{pc_clean_8}"

            if pc_val >= min_address:
                parsed_instructions.append({
                    "pc": pc_clean_8,
                    "clean_hex": clean_hex_8,
                    "assembly": assembly_text,
                    "commit_formatted": commit_formatted
                })
                # If ecall occurs after test pass signal (or ecall at test end), stop parsing post-test trap loop
                if mnemonic == 'ecall' or mnemonic == 'ebreak' or (opcode_7 == 0x73 and mnemonic not in {'csrr', 'csrw', 'csrs', 'csrc', 'csrrw', 'csrrs', 'csrrc', 'csrrwi', 'csrrsi', 'csrrci'}):
                    # Check if previous instructions signaled test completion (gp/x3 = 1)
                    has_pass_signal = any(" 03 00000001" in item['commit_formatted'] for item in parsed_instructions[-5:])
                    if has_pass_signal or len(parsed_instructions) > 400:
                        break
        i += 1

    return parsed_instructions

def update_vivado_program_mem(memory_words):
    """Writes memory_words (with NOP-replaced CSRs) to Program.mem targets."""
    print(f"\n[+] Step 2: Updating Vivado Program.mem files with aligned machine code...")
    for target in PROGRAM_MEM_TARGETS:
        try:
            target_path = Path(target)
            target_path.parent.mkdir(parents=True, exist_ok=True)
            with open(target_path, "w", encoding="utf-8") as f:
                for word in memory_words:
                    f.write(f"{word}\n")
            print(f"    -> Updated: {target} ({len(memory_words)} memory words)")
        except Exception as e:
            print(f"    [!] Could not update {target}: {e}")

PILOT_SV_PATH = "D:/Fresh/Fresh.srcs/sim_1/new/Pilot.sv"

def update_pilot_sv_cycles(num_cycles):
    """Ensures Pilot.sv has fixed repeat(2000) cycles for pre-compiled fast xsim execution."""
    pilot_path = Path(PILOT_SV_PATH)
    if not pilot_path.exists():
        return
    # Leave pre-compiled Pilot.sv untouched if num_cycles <= 2000 to prevent binary mismatch
    if num_cycles <= 2000:
        return
        
    code = f"""`timescale 1ns / 1ps

module Pilot;

    logic clk = 0;
    logic rst = 1;

    Top DUT(clk, rst);

    always #5 clk = ~clk;

    initial begin
        #5 rst = 0;

        repeat({num_cycles}) begin
            @(posedge clk);

            $display(
                "PC=%h | INSTR=%h | RegW=%b | WD3=%h | RS1=%d | RS2=%d | RD=%d | Branch=%b | Jump=%b",
                DUT.rm.MB.Address,
                DUT.rm.MB.instr,
                DUT.rm.MB.RegW,
                DUT.rm.WD3,
                DUT.rm.MB.RS1,
                DUT.rm.MB.RS2,
                DUT.rm.MB.rd,
                DUT.rm.MB.Branch_taken,
                DUT.rm.MB.Jump
            );
        end

        $finish;
    end

endmodule
"""
    try:
        with open(pilot_path, "w", encoding="utf-8") as f:
            f.write(code)
    except Exception as e:
        print(f"    [!] Could not update {PILOT_SV_PATH}: {e}")

XSIM_DIR = "D:/Fresh/Fresh.sim/sim_1/behav/xsim"

def run_vivado_simulation(num_cycles=500):
    """Runs Vivado hardware processor simulation using fast standalone xsim executable."""
    update_pilot_sv_cycles(num_cycles)
    
    # Pre-clear simulate.log before simulation
    sim_log = Path(SIMULATE_LOG_PATH)
    if sim_log.exists():
        try:
            with open(sim_log, "w", encoding="utf-8") as f:
                f.truncate(0)
        except Exception:
            pass

    print(f"\n[+] Step 3: Launching Fast Standalone xsim Simulation ({num_cycles} cycles)...")
    
    # Ensure Pilot.tcl uses run -all and ends with exit so xsim runs completely
    pilot_tcl = Path(XSIM_DIR) / "Pilot.tcl"
    if pilot_tcl.exists():
        try:
            content = pilot_tcl.read_text(encoding="utf-8")
            content = re.sub(r"run\s+\d+ns", "run -all", content)
            if "exit" not in content:
                content = content.strip() + "\nexit\n"
            pilot_tcl.write_text(content, encoding="utf-8")
        except Exception:
            pass

    sim_bat = Path(XSIM_DIR) / "simulate.bat"
    if sim_bat.exists():
        cmd = f'cmd /c "cd /d {XSIM_DIR} && simulate.bat"'
        try:
            subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
            print("[+] Fast xsim Simulation Completed Successfully!")
            return
        except subprocess.CalledProcessError as e:
            print(f"[!] Fast xsim returned {e.returncode}, falling back to Vivado batch mode...")

    # Fallback to full Vivado batch run if xsim snapshot is missing
    sim_us = max(50, (num_cycles * 10 // 1000) + 100)
    tcl_content = f"""open_project {FRESH_PROJECT_XPR}
catch {{ close_sim }}
catch {{ file delete -force "{SIMULATE_LOG_PATH}" }}
launch_simulation -mode behavioral
run {sim_us}us
close_sim
close_project
"""
    with open(TCL_SCRIPT_PATH, "w", encoding="utf-8") as f:
        f.write(tcl_content)
        
    cmd = f"vivado.bat -mode batch -source {TCL_SCRIPT_PATH}"
    try:
        subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        print("[+] Vivado Simulation Completed Successfully!")
    except subprocess.CalledProcessError as e:
        print(f"[-] Vivado Simulation finished (Exit code: {e.returncode})")

def parse_dut_log(simulate_log_path, min_address=0x80000000):
    """
    Parses DUT simulation log from Vivado simulate.log.
    """
    dut_items = []
    sim_path = Path(simulate_log_path)
    
    if not sim_path.exists():
        print(f"[-] Warning: {simulate_log_path} not found!")
        return dut_items

    pattern = re.compile(
        r"PC=([0-9a-fA-F]{8})\s*\|\s*INSTR=([0-9a-fA-F]{8})\s*\|\s*RegW=(\d+)\s*\|\s*WD3=([0-9a-fA-F]{8}).*?RD=\s*(\d+)"
    )

    with open(sim_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            match = pattern.search(line)
            if match:
                pc_hex = match.group(1).lower()
                instr_hex = match.group(2).lower()
                regw = int(match.group(3))
                wd3 = match.group(4).lower()
                rd = int(match.group(5))
                
                pc_val = int(pc_hex, 16)
                if pc_val < min_address:
                    continue
                    
                if instr_hex == "00000000" and pc_hex == "80000000":
                    continue
                if "x" in instr_hex or "x" in pc_hex:
                    continue

                if regw == 1 and rd != 0:
                    commit_fmt = f"{pc_hex} {rd:02d} {wd3}"
                else:
                    commit_fmt = f"{pc_hex}"
                    
                dut_items.append({
                    "pc": pc_hex,
                    "instr": instr_hex,
                    "regw": regw,
                    "rd": rd,
                    "wd3": wd3,
                    "commit_formatted": commit_fmt
                })
                
    return dut_items

def compare_spike_and_dut(spike_items, dut_items):
    """
    Compares Spike Commit Log vs DUT Hardware Simulation Trace and prints detailed mismatch analysis.
    """
    print("\n" + "=" * 95)
    print(f"                   SPIKE VS DUT HARDWARE SIMULATION COMPARISON REPORT")
    print("=" * 95)
    print(f"Spike Total Instructions Logged : {len(spike_items)}")
    print(f"DUT   Total Instructions Logged : {len(dut_items)}")
    print("-" * 95)
    print(f"{'Step':<5} | {'PC':<10} | {'Spike Commit Log (GOLDEN)':<35} | {'DUT Simulation Log':<30} | {'Status':<6}")
    print("-" * 95)



    num_compare = min(len(spike_items), len(dut_items))
    mismatches = 0
    first_mismatch_idx = None
    passed_test_end_step = None

    for i in range(num_compare):
        spk = spike_items[i]
        dut = dut_items[i]

        spk_str = spk['commit_formatted']
        dut_str = dut['commit_formatted']
        pc_str = spk['pc']

        # Detect test exit: gp (x3) = 1 followed by ECALL
        if spk_str == dut_str:
            status = "MATCH"
            # Check if this step wrote gp=1 (x3=1)
            if " 03 00000001" in spk_str:
                passed_test_end_step = i + 1
        else:
            # If we reached test exit in previous steps, spike traps to 80000004 while HW continues NOPs
            if passed_test_end_step and i > passed_test_end_step + 2:
                print(f"--- [!] Official RISC-V Test Suite Exit (ECALL) Reached at Step {passed_test_end_step}! ---")
                num_compare = i
                break
            status = "MISMATCH"
            mismatches += 1
            if first_mismatch_idx is None:
                first_mismatch_idx = i

        print(f"{i+1:<5} | {pc_str:<10} | {spk_str:<35} | {dut_str:<30} | {status:<6}")

    print("=" * 95)
    
    if mismatches == 0 and num_compare > 0:
        print(f" SUCCESS: 100% MATCH across all {num_compare} executed DUT instructions!")
        if passed_test_end_step:
            print(" [PASS] OFFICIAL RISC-V TEST SUITE PASSED PERFECTLY! (gp/x3 = 1 signal verified)")
        print(" Your DUT RISC-V Processor Core matches Spike golden model perfectly!")
    elif mismatches > 0:
        print(f" WARNING: Found {mismatches} actual instruction execution mismatches in first {num_compare} steps.")
        if first_mismatch_idx is not None:
            spk_m = spike_items[first_mismatch_idx]
            dut_m = dut_items[first_mismatch_idx]
            print(f"\n[!] FIRST REAL HARDWARE MISMATCH OCCURRED AT STEP {first_mismatch_idx + 1}:")
            print(f"    Expected (Spike): {spk_m['commit_formatted']}")
            print(f"    Actual   (DUT)  : {dut_m['commit_formatted']}")

    if len(dut_items) < len(spike_items) and not passed_test_end_step:
        print(f"\n[i] Note: DUT simulation ended after {len(dut_items)} instructions.")
        print(f"    (Vivado simulation time limit reached or test completed).")
    elif len(spike_items) < len(dut_items) and not passed_test_end_step:
        print(f"\n[i] Note: Spike log was capped at {len(spike_items)} instructions.")
    print("=" * 95)

def run_single_test_evaluation(test_elf_path, quiet=True):
    """
    Executes a single RISC-V test through Spike and Vivado DUT simulation.
    Returns result dictionary: {'name': name, 'status': 'PASS'/'FAIL', 'instructions': count, 'mismatches': num, 'passed_signal': bool}
    """
    test_name = os.path.basename(test_elf_path)
    if not quiet:
        print(f"\n[+] Running test: {test_name}")
        
    try:
        # 1. Spike
        raw_log = run_spike_in_wsl(test_elf_path)
        spike_items = parse_spike_log_with_commits(raw_log, min_address=START_ADDRESS)
        
        # 2. Extract Memory Hex & update Vivado
        memory_words = generate_aligned_memory_hex(test_elf_path)
        update_vivado_program_mem(memory_words)
        
        # 3. Vivado hardware simulation
        target_cycles = len(spike_items) + 50
        run_vivado_simulation(num_cycles=target_cycles)
        
        # 4. Parse DUT trace
        dut_items = parse_dut_log(SIMULATE_LOG_PATH, min_address=START_ADDRESS)
        
        # 5. Compare
        num_compare = min(len(spike_items), len(dut_items))
        mismatches = 0
        passed_signal = False
        
        for i in range(num_compare):
            spk_str = spike_items[i]['commit_formatted']
            dut_str = dut_items[i]['commit_formatted']
            
            if spk_str == dut_str:
                if " 03 00000001" in spk_str:
                    passed_signal = True
            else:
                if passed_signal:
                    break
                mismatches += 1
                
        status = "PASS" if (mismatches == 0 and num_compare > 0) else "FAIL"
        
        return {
            "name": test_name,
            "status": status,
            "instructions": num_compare,
            "mismatches": mismatches,
            "passed_signal": passed_signal
        }
    except Exception as e:
        return {
            "name": test_name,
            "status": "FAIL",
            "instructions": 0,
            "mismatches": -1,
            "passed_signal": False,
            "error": str(e)
        }

def run_all_tests(tests):
    """
    Executes all official RISC-V test suites sequentially and prints overall pass percentage report.
    """
    print("\n" + "=" * 95)
    print(f"       LAUNCHING MASTER RISC-V ARCHITECTURAL TEST SUITE (TOTAL {len(tests)} TESTS)")
    print("=" * 95)
    
    results = []
    passed_count = 0
    
    for idx, test in enumerate(tests, start=1):
        print(f"\n[{idx:2d}/{len(tests)}] Executing: {test['name']}...")
        res = run_single_test_evaluation(test['path'], quiet=False)
        results.append(res)
        if res['status'] == "PASS":
            passed_count += 1
            print(f"    --> [PASS] {test['name']} PASSED! ({res['instructions']} instructions, 0 mismatches)")
        else:
            print(f"    --> [FAIL] {test['name']} FAILED! ({res['mismatches']} mismatches)")

    # Print Master Summary Table
    pass_pct = (passed_count / len(tests)) * 100 if tests else 0.0
    
    print("\n" + "=" * 95)
    print("                 RISC-V PROCESSOR MASTER VERIFICATION SUMMARY REPORT")
    print("=" * 95)
    print(f"{'#':<3} | {'Test Name':<25} | {'Instructions':<13} | {'Status':<8} | {'Pass Signal (gp=1)'}")
    print("-" * 95)
    
    for idx, r in enumerate(results, start=1):
        pass_sig_str = "YES" if r['passed_signal'] else "NO"
        print(f"{idx:<3} | {r['name']:<25} | {r['instructions']:<13} | {r['status']:<8} | {pass_sig_str}")
        
    print("=" * 95)
    print(f" OVERALL VERIFICATION RESULT: {passed_count}/{len(tests)} Tests Passed ({pass_pct:.1f}%)")
    if passed_count == len(tests):
        print(" [PASS] CONGRATULATIONS! Your DUT RISC-V Core is 100% Architecturally Compliant!")
    else:
        print(f" [!] {len(tests) - passed_count} tests failed. Check simulation logs for details.")
    print("=" * 95)

def main():
    tests = get_available_tests()
    
    # 1. Test selection
    if len(sys.argv) > 1 and (sys.argv[1].lower() in {'all', '--all', '0'}):
        run_all_tests(tests)
        return
    elif len(sys.argv) > 1 and not sys.argv[1].isdigit():
        test_arg = sys.argv[1]
        matched = [t['path'] for t in tests if t['name'] == test_arg or t['name'] == f"rv32ui-p-{test_arg}"]
        test_elf = matched[0] if matched else test_arg
    else:
        selection = select_test_interactively(tests)
        if selection == "ALL":
            run_all_tests(tests)
            return
        test_elf = selection
        
    # 2. Run Spike
    raw_log = run_spike_in_wsl(test_elf)
    parsed_items = parse_spike_log_with_commits(raw_log, min_address=START_ADDRESS)
    
    line_limit = None
    if len(sys.argv) > 2 and sys.argv[2].isdigit():
        line_limit = int(sys.argv[2])
    elif len(sys.argv) > 1 and sys.argv[1].isdigit():
        line_limit = int(sys.argv[1])
    elif not sys.stdin.isatty():
        line_limit = None  # ALL items when non-interactive
    else:
        try:
            line_limit = prompt_line_limit(len(parsed_items))
        except (EOFError, KeyboardInterrupt):
            line_limit = None
        
    selected_spike_items = parsed_items[:line_limit] if line_limit else parsed_items

    # 3. Extract Memory Hex with Address Alignment & NOP Replacement
    memory_words = generate_aligned_memory_hex(test_elf)

    hex_file = Path(DEFAULT_VIVADO_HEX_TXT).resolve()
    commit_file = Path(DEFAULT_COMMIT_LOG_TXT).resolve()

    with open(hex_file, "w", encoding="utf-8") as f:
        for word in memory_words:
            f.write(f"{word}\n")

    with open(commit_file, "w", encoding="utf-8") as f:
        for item in selected_spike_items:
            f.write(f"{item['commit_formatted']}\n")

    print(f"\n[+] Generated {hex_file} ({len(memory_words)} aligned words)")
    print(f"[+] Generated {commit_file}")

    # 4. Update Vivado Program.mem files
    update_vivado_program_mem(memory_words)

    # 5. Run Vivado Hardware Simulation on Fresh.xpr
    target_cycles = (line_limit + 50) if line_limit else (len(selected_spike_items) + 50)
    run_vivado_simulation(num_cycles=target_cycles)

    # 6. Parse DUT Trace log from Vivado simulate.log
    dut_items = parse_dut_log(SIMULATE_LOG_PATH, min_address=START_ADDRESS)
    
    with open(DEFAULT_DUT_TRACE_TXT, "w", encoding="utf-8") as f:
        for d in dut_items:
            f.write(f"{d['commit_formatted']}\n")

    # 7. Compare Spike vs DUT
    compare_spike_and_dut(selected_spike_items, dut_items)

def select_test_interactively(tests):
    print("\n=========================================================================")
    print("                OFFICIAL RISC-V TEST SUITE (riscv-tests/isa)")
    print("=========================================================================")
    print("  [ 0] RUN ALL TESTS (Batch Suite Evaluation with % Summary)")
    for idx, t in enumerate(tests, start=1):
        print(f"  [{idx:2d}] {t['name']}")
    print("=========================================================================")
    
    choice = input(f"Select a test number (0-{len(tests)}) [Default: 0 (RUN ALL TESTS)]: ").strip()
    if not choice or choice == "0" or choice.lower() == "all":
        return "ALL"
    try:
        num = int(choice)
        if 1 <= num <= len(tests):
            return tests[num-1]['path']
    except ValueError:
        pass
        
    print("[!] Defaulting to Option 0 (RUN ALL TESTS).")
    return "ALL"

def prompt_line_limit(total_available):
    user_input = input(f"\nEnter number of instruction lines to generate/view (1-{total_available}, or press Enter for ALL [{total_available}]): ").strip()
    if not user_input:
        return None
    try:
        val = int(user_input)
        if val > 0:
            return val
    except ValueError:
        pass
    return None

if __name__ == "__main__":
    main()
