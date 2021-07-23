
all: plugins
	cd FusionInspector && make

plugins:
	cd plugins && make

clean:
	cd plugins && make clean
	cd FusionInspector && make clean

pull_tutorial_data:
	git clone https://github.com/STAR-Fusion/STAR-Fusion-Tutorial.git
