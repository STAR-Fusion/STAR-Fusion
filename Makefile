
all:
	cd plugins && make


clean:
	cd plugins && make clean


pull_tutorial_data:
	git clone https://github.com/STAR-Fusion/STAR-Fusion-Tutorial.git
