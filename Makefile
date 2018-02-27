
all:
	cd plugins && make


clean:
	cd plugins && make clean


pull_tutorial_data:
	git clone git@github.com:STAR-Fusion/STAR-Fusion-Tutorial.git
