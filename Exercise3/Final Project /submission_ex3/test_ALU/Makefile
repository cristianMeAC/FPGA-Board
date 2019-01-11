all: compile

compile:
	vsim -c -do "do scripts/compile.do;quit -f"
	
sim_alu:
	vsim -c -do "do scripts/sim.do; run 3200 ns; quit -f"
	
clean:
	rm -fr work
	rm -f transcript
	rm -f *.wlf
	rm -f modelsim.ini
	
.PHONY: clean
.PHONY: compile
