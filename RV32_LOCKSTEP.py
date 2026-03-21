# step 1. Create Asm file :- nano test.S
# step 2. Compile to ELF :- riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x80000000 -o focus.elf focus.S
# step 3. Generate Hardware Hex File :- riscv64-unknown-elf-objcopy -O verilog --change-addresses -0x80000000 test.elf testvector.mem
# step 4. Run Spike :- spike --isa=rv32i -m0x7fe00000:0x2000000 --pc=0x80000000 --log-commits --instructions=8 test.elf > spike_final.log 2>&1

import subprocess

VIV_LIST=[]
SPK_LIST=[]
MAC_CODE=[]
PASS_COUNT = 0
FAIL_COUNT = 0

INST_COUNT = int(input("Instructions:- "))

p1 = subprocess.run(['wsl',
                'spike',
                '--isa=rv32i',
                '-m0x7fe00000:0x2000000',
                '--pc=0x80000000',
                '--log-commits',
                f'--instructions={INST_COUNT}', 
                '/home/creat/riscv-isa-sim/build/focus.elf','>','spike_final.log','2>&1'],
                text=True)
  
with open("spike_final.log",'r') as file:
   lines = file.readlines()
   lines = lines[6:]
   


   with open("spike_final.log",'a') as spike_file:
      for line in lines:
         MAC_CODE.append(line[26:34])
         line = line.replace(line[23:35],"")
         line = line.replace("  "," ")
         line = line.replace("0x","")
         line = line.replace("x","")
         if len(line) == 31:
            line = line[:20] + "0" + line[20:] # Fragile Area
         spike_file.write((line[11:]))

   with open("spike_final.log",'r') as file:
      lines = file.readlines() 

   lines = lines[INST_COUNT+1:] # Here do 1 + of total instruction asked in the spike

   with open("spike_final.log",'w') as file:
      file.writelines(lines)
   
   with open("spike_final.log",'r') as spike_log:
      lines = spike_log.readlines()
      for line in lines:
         SPK_LIST.append(line)

with open(r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim/Program.mem",'w') as file:
   for instruction in MAC_CODE:
      file.write(f"{instruction}\n")

VIVADO_BIN = r"C:/AMDDesignTools/2025.2/Vivado/bin"
SIM_DIR = r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim"

subprocess.run(
    [VIVADO_BIN+r"/xsim.bat", "tb_behav", "-runall"],
    cwd=SIM_DIR,
    check=True
)

with open("C:/Users/creat/Desktop/dut_trace.log",'r') as vivado_log:
   lines = vivado_log.readlines()
   for line in lines:
      VIV_LIST.append(line)
# print(VIV_LIST,len(VIV_LIST))
# print(SPK_LIST,len(SPK_LIST))

for i in range(0,len(VIV_LIST)):
   if (VIV_LIST)[i] == SPK_LIST[i]:
      print(f"Instruction:- {MAC_CODE[i]} => Pass")
      PASS_COUNT += 1
   else:
      print(f"Instruction:- {MAC_CODE[i]} => Fail")
      FAIL_COUNT += 1

print(f"PASS => {PASS_COUNT}, FAIL => {FAIL_COUNT}, MACHINE CODES => {len(MAC_CODE)}")
