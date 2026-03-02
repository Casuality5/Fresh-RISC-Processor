# step 1. Create Asm file :- nano test.S
# step 2. Compile to ELF :- riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x80000000 -o test.elf test.S
# step 3. Generate Hardware Hex File :- riscv64-unknown-elf-objcopy -O verilog --change-addresses -0x80000000 test.elf testvector.mem
# step 4. Run Spike :- spike --isa=rv32i -m0x7fe00000:0x2000000 --pc=0x80000000 --log-commits --instructions=8 test.elf > spike_final.log 2>&1

import subprocess

vivado_list=[]
spike_list=[]
machine_code=[]

with open("SPIKE_TRACE.log",'w') as file:
   p1 = subprocess.run(['wsl',
                'spike',
                '--isa=rv32i',
                '-m0x7fe00000:0x2000000',
                '--pc=0x80000000',
                '--log-commits',
                '--instructions=8', 
                '/home/creat/riscv-isa-sim/build/test.elf'],
                stdout=file,
                stderr=file,
                text=True)
   
with open("SPIKE_TRACE.log",'r') as file:
   lines = file.readlines()
   


   with open("SPIKE_TRACE.log",'a') as spike_file:
      for line in lines[6:]:
         machine_code.append(line[26:34])
         line = line.replace(line[23:35],"")
         line = line.replace("  "," ")
         line = line.replace("x","")
         spike_file.write((line[12:])) 

   with open("SPIKE_TRACE.log",'r') as file:
      lines = file.readlines() 

   lines = lines[9:]

   with open("SPIKE_TRACE.log",'w') as file:
      file.writelines(lines)
   
   with open("SPIKE_TRACE.log",'r') as spike_log:
      lines = spike_log.readlines()
      for line in lines:
         spike_list.append(line)

with open("Program.mem",'a') as file:
   for instruction in machine_code:
      file.write(f"{instruction}\n")

VIVADO_BIN = r"C:/AMDDesignTools/2025.2/Vivado/bin"
SIM_DIR = r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim"
subprocess.run(
    [VIVADO_BIN + r"/xsim.bat", "tb_behav", "-runall"],
    cwd=SIM_DIR,
    check=True
)

with open("C:/Users/creat/Desktop/dut_trace.log",'r') as vivado_log:
   lines = vivado_log.readlines()
   for line in lines:
      vivado_list.append(line)

for i in range(0,len(machine_code)):
   if vivado_list[i] == spike_list[i]:
      print(f"Instruction:- {machine_code[i]} => Pass")
   else:
      print(f"Instruction:- {machine_code[i]} => Fail")




