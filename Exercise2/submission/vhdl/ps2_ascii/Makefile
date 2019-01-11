all: compile

compile: 
	vsim -c -do "do scripts/compile.do;quit -f"

sim_simple: 
	vsim -c -do "do scripts/sim_simple.do;run 10 us;quit -f"

sim_fileio: 
	vsim -c -do "do scripts/sim_fileio.do;run 10 us;quit -f"

clean:
	rm -fr work
	rm -f transcript
	rm -f *.wlf
	rm -f modelsim.ini

.PHONY: clean
.PHONY: compile

