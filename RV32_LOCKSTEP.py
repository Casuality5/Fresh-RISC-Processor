# step 1. Create Asm file :- nano test.S
# step 2. Compile to ELF :- riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x80000000 -o test.elf test.S
# step 3. Generate Hardware Hex File :- riscv64-unknown-elf-objcopy -O verilog --change-addresses -0x80000000 test.elf testvector.mem
# step 4. Run Spike :- spike --isa=rv32i -m0x7fe00000:0x2000000 --pc=0x80000000 --log-commits --instructions=8 test.elf > spike_final.log 2>&1


vivado_list=[]
spike_list=[]
machine_code=[]

with open("SPIKE_TRACE.log",'w') as file:
   file.write("")
   



with open("//wsl$/Ubuntu/home/creat/riscv-isa-sim/build/spike_final.log",'r') as file:
    lines = file.readlines()

    for line in lines[6:]:
        machine_code.append(line[26:34])
        
    
    with open("SPIKE_TRACE.log",'a') as spike_file:
       for line in lines[6:]:
          line = line.replace(line[23:35],"")
          line = line.replace("  "," ")
          line = line.replace("x","")
          spike_file.write((line[12:]))  
        
with open("C:/Users/creat/Desktop/dut_trace.log",'r') as vivado_log:
     lines = vivado_log.readlines()
     for line in lines:
          vivado_list.append(line)

with open("C:/Users/creat/BackUp/Coding projects/Fresh RISC Processor/SPIKE_TRACE.log",'r') as spike_log:
     lines = spike_log.readlines()
     for line in lines:
          spike_list.append(line)

# if vivado_list == spike_list:
#      print("Success")

# else:
#      print("Fail")

# print(vivado_list)
# print(spike_list)

for i in range(0,len(machine_code)):
     if vivado_list[i] == spike_list[i]:
        print(f"Instruction:- {machine_code[i]} => Pass")
     
     else:
         print(f"Instruction:- {machine_code[i]} => Fail")
# print(machine_code)

