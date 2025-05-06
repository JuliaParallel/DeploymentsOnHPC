default: ../dist/juliaup-hpc.lua

%.lua:
	./bin/build.lua module.lua $@
	awk 'NR==1 {print "#!/usr/bin/env lua"}; {print}' $@ > $(basename $@)
	chmod u+x $(basename $@)

clean:
	rm ../dist/juliaup-hpc.lua
	rm ../dist/juliaup-hpc
