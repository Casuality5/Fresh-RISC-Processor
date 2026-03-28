# step 1. Create Asm file :- nano test.S
# step 2. Compile to ELF :- riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x80000000 -o focus.elf focus.s
# step 3. Generate Hardware Hex File :- riscv64-unknown-elf-objcopy -O verilog --change-addresses -0x80000000 test.elf testvector.mem
# step 4. Run Spike :- spike --isa=rv32i -m0x7fe00000:0x2000000 --pc=0x80000000 --log-commits --instructions=150 focus.elf > spike_final.log 2>&1

import subprocess

class ISA_VERIFICATION:

   def __init__(self,ASM_NAME, INST_COUNT):
      self.ASM_NAME     = ASM_NAME
      self.INST_COUNT   = INST_COUNT
      self.VIV_LIST     = []
      self.SPK_LIST     = []
      self.MAC_CODE     = []
      self.PASS_COUNT   = 0
      self.FAIL_COUNT   = 0

      self.COMPILE_DUT()


   def COMPILE_DUT(self):
      TAR_DIR = r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim"
      CMD     = ".\compile.bat ; .\elaborate.bat"
      subprocess.run(['powershell.exe',"-Command",CMD],
                     cwd=TAR_DIR,
                     check=True)
      print("DUT Compiled!")

      self.COMPILE_TO_ELF()

   def COMPILE_TO_ELF(self):
      subprocess.run(['wsl','riscv64-unknown-elf-gcc',
                     '-march=rv32i','-mabi=ilp32','-nostdlib',
                     '-Ttext','0x80000000',
                     '-o',f'/home/creat/riscv-isa-sim/build/{self.ASM_NAME}.elf',
                     f'/home/creat/riscv-isa-sim/build/{self.ASM_NAME}.s'])
      self.GENERATE_HEX()

   def GENERATE_HEX(self):
      subprocess.run(['wsl',
                     'riscv64-unknown-elf-objcopy',
                     '-O','verilog',
                     '--change-addresses',
                     '-0x80000000',
                     f'/home/creat/riscv-isa-sim/build/{self.ASM_NAME}.elf',
                     'testvector.mem'], text=True)
   
      with open("testvector.mem",'r') as f:
         lines = f.readlines()[1:]  # skip first line
         bytes_list = [int(b, 16) for b in " ".join(lines).split()]

      with open("Program.mem", "w") as f:
         for i in range(0, len(bytes_list), 4):
            word = bytes_list[i] | (bytes_list[i+1]<<8) | (bytes_list[i+2]<<16) | (bytes_list[i+3]<<24)
            f.write(f"{word:08X}\n")
      self.RUN_SPIKE()

   def RUN_SPIKE(self):
      subprocess.run(['wsl',
                     'spike',
                     '--isa=rv32i',
                     '-m0x7fe00000:0x2000000',
                     '--pc=0x80000000',
                     '--log-commits',
                     f'--instructions={self.INST_COUNT}', 
                     f'/home/creat/riscv-isa-sim/build/{self.ASM_NAME}.elf','>','spike_final.log','2>&1'],
                     text=True)
   
      self.PARSE_SPIKE_LOG()

   def PARSE_SPIKE_LOG(self):  
      with open("spike_final.log",'r') as file:
         lines = file.readlines()
         lines = lines[6:]
   
      with open("spike_final.log",'a') as spike_file:
         for line in lines:
            line = line.replace(line[23:35],"")
            line = line.replace("  "," ")
            line = line.replace("0x","")
            line = line.replace("x","")
            if len(line) == 31:
               line = line[:20] + "0" + line[20:] # Fragile Area
            spike_file.write((line[11:]))

      with open("spike_final.log",'r') as file:
         lines = file.readlines() 

         lines = lines[self.INST_COUNT+1:] # Here do 1 + of total instruction asked in the spike

         with open("spike_final.log",'w') as file:
            file.writelines(lines)
         
         with open("spike_final.log",'r') as spike_log:
            lines = spike_log.readlines()
            for line in lines:
               self.SPK_LIST.append(line)

      self.FEED_MAC_TO_VIVADO()

   def FEED_MAC_TO_VIVADO(self): 
      with open("Program.mem",'r') as file:
         Hex_code = file.readlines()
         for code in Hex_code:
            self.MAC_CODE.append(code)

      with open(r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim/Program.mem",'w') as file:
         for instruction in self.MAC_CODE:
            file.write(f"{instruction}\n")
   
      self.RUN_VIVADO()

   def RUN_VIVADO(self):
      VIVADO_BIN = r"C:/AMDDesignTools/2025.2/Vivado/bin"
      SIM_DIR = r"C:/Users/creat/Fresh/Fresh.sim/sim_1/behav/xsim"

      subprocess.run(
         [VIVADO_BIN+r"/xsim.bat", "tb_behav", "-runall"],
         cwd=SIM_DIR,
         check=True)

      with open("C:/Users/creat/Desktop/dut_trace.log",'r') as vivado_log:
         lines = vivado_log.readlines()
         lines1 = lines[:len(self.SPK_LIST)]
         for line in lines1:
            self.VIV_LIST.append(line)
      print(len(self.SPK_LIST))
      print(len(self.VIV_LIST))

      with open("C:/Users/creat/Desktop/dut_trace.log",'w') as vivado_log:
         for line in lines[:len(self.SPK_LIST)]:
            vivado_log.write(line)

      self.COMPARE_TRACE()

   def COMPARE_TRACE(self):
      with open("C:/Users/creat/Desktop/dut_trace.log", 'r') as f:
         DUT_LINE = f.readlines()
      with open("spike_final.log", 'r') as f:
         SPK_LINE = f.readlines()

      for i in range(len(SPK_LINE)):
         if self.MAC_CODE[i].strip() == '00000000':
            break
         if DUT_LINE[i].strip() == SPK_LINE[i].strip():    # ← strip both
            print(f"Instruction:- {self.MAC_CODE[i].strip()} => Pass")
            self.PASS_COUNT += 1
         else:
            print(f"Instruction:- {self.MAC_CODE[i].strip()} => Fail")
            print(f"  SPK: {SPK_LINE[i].strip()}")
            print(f"  DUT: {DUT_LINE[i].strip()}")
            self.FAIL_COUNT += 1

      print(f"\nPASS => {self.PASS_COUNT}, FAIL => {self.FAIL_COUNT}, TOTAL => {self.PASS_COUNT + self.FAIL_COUNT}")

      return "Script Ended !"


ISA_VERIFICATION('focus',100)