
all: plugins_only
	cd FusionInspector && make

plugins_only:
	cd plugins && make

clean:
	cd plugins && make clean
	cd FusionInspector && make clean

pull_tutorial_data:
	git clone https://github.com/STAR-Fusion/STAR-Fusion-Tutorial.git
