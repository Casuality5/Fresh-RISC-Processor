import subprocess

# ─── CONFIG ───────────────────────────────────────────────────────────────────
ASM_NAME   = "focus"
INST_COUNT = 100
VIVADO_BIN = r"C:/AMDDesignTools/2025.2/Vivado/bin"
SIM_DIR    = r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim"
WSL_BUILD  = f"/home/creat/riscv-isa-sim/build"
PROG_MEM   = r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim/Program.mem"
DUT_TRACE  = r"C:/Users/creat/Desktop/dut_trace.log"

VIV_LIST   = []
SPK_LIST   = []
MAC_CODE   = []
PASS_COUNT = 0
FAIL_COUNT = 0
# ──────────────────────────────────────────────────────────────────────────────


def COMPILE_TO_ELF():
    subprocess.run(['wsl', 'riscv64-unknown-elf-gcc',
                    '-march=rv32i', '-mabi=ilp32', '-nostdlib',
                    '-Ttext', '0x80000000',
                    '-o', f'{WSL_BUILD}/{ASM_NAME}.elf',
                    f'{WSL_BUILD}/{ASM_NAME}.s'])
    GENERATE_HEX()


def GENERATE_HEX():
    subprocess.run(['wsl', 'riscv64-unknown-elf-objcopy',
                    '-O', 'verilog',
                    '--change-addresses', '-0x80000000',
                    f'{WSL_BUILD}/{ASM_NAME}.elf',
                    'testvector.mem'], text=True)
    PARSE_TO_PROGRAM_MEM()


def PARSE_TO_PROGRAM_MEM():
    with open("testvector.mem", 'r') as f:
        lines = f.readlines()[1:]
        bytes_list = [int(b, 16) for b in " ".join(lines).split()]

    with open("Program.mem", 'w') as f:
        for i in range(0, len(bytes_list), 4):
            word = (bytes_list[i]       |
                   (bytes_list[i+1]<<8) |
                   (bytes_list[i+2]<<16)|
                   (bytes_list[i+3]<<24))
            f.write(f"{word:08X}\n")
    RUN_SPIKE()


def RUN_SPIKE():
    subprocess.run(['wsl', 'spike',
                    '--isa=rv32i',
                    '-m0x7fe00000:0x2000000',
                    '--pc=0x80000000',
                    '--log-commits',
                    f'--instructions={INST_COUNT}',
                    f'{WSL_BUILD}/{ASM_NAME}.elf',
                    '>', 'spike_final.log', '2>&1'], text=True)
    PARSE_SPIKE_LOG()


def PARSE_SPIKE_LOG():
    with open("spike_final.log", 'r') as f:
        lines = f.readlines()[6:]

    with open("spike_final.log", 'a') as f:
        for line in lines:
            line = line.replace(line[23:35], "")
            line = line.replace("  ", " ")
            line = line.replace("0x", "")
            line = line.replace("x", "")
            if len(line) == 31:
                line = line[:20] + "0" + line[20:]   # Fragile Area
            f.write(line[11:])

    with open("spike_final.log", 'r') as f:
        lines = f.readlines()

    lines = lines[INST_COUNT+1:]   # 1 + total instructions asked in spike

    with open("spike_final.log", 'w') as f:
        f.writelines(lines)

    with open("spike_final.log", 'r') as f:
        for line in f.readlines():
            SPK_LIST.append(line)

    COPY_TO_VIVADO()


def COPY_TO_VIVADO():
    with open("Program.mem", 'r') as f:
        for code in f.readlines():
            MAC_CODE.append(code)

    with open(PROG_MEM, 'w') as f:
        for instruction in MAC_CODE:
            f.write(f"{instruction}\n")

    RUN_VIVADO()


def RUN_VIVADO():
    subprocess.run(
        [VIVADO_BIN + r"/xsim.bat", "tb_behav", "-runall"],
        cwd=SIM_DIR,
        check=True
    )
    PARSE_DUT_TRACE()


def PARSE_DUT_TRACE():
    with open(DUT_TRACE, 'r') as f:
        for line in f.readlines():
            VIV_LIST.append(line)
    COMPARE()


def COMPARE():
    global PASS_COUNT, FAIL_COUNT
    for i in range(len(SPK_LIST)):
        if VIV_LIST[i] == SPK_LIST[i]:
            print(f"Instruction:- {MAC_CODE[i].strip()} => Pass")
            PASS_COUNT += 1
        else:
            print(f"Instruction:- {MAC_CODE[i].strip()} => Fail")
            FAIL_COUNT += 1
    print(f"\nPASS => {PASS_COUNT}, FAIL => {FAIL_COUNT}, TOTAL => {len(MAC_CODE)}")


# ─── ENTRY POINT ──────────────────────────────────────────────────────────────
COMPILE_TO_ELF()