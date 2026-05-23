RTL = rtl/regfile.sv rtl/fetch.sv rtl/decode.sv rtl/execute.sv \
      rtl/memory_stage.sv rtl/writeback.sv rtl/hazard.sv rtl/bht.sv rtl/cpu_top.sv

TB = tb/tb_cpu.sv

sim:
	verilator --binary -sv --top-module tb_cpu $(RTL) $(TB) \
	--Mdir obj_dir -o sim_cpu && ./obj_dir/sim_cpu

clean:
	rm -rf obj_dir

