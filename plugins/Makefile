
all:
	tar xvf Set-IntervalTree-0.01.tar.gz && \
       cd Set-IntervalTree-0.01 && \
       perl Makefile.PL && \
       make && \
       mv lib/Set ../../PerlLib/ && \
       mv blib/arch/auto ../../PerlLib && \
       mv blib/lib/auto/Set/IntervalTree/autosplit.ix ../../PerlLib/auto/Set/IntervalTree/.



clean:
	rm -rf ./Set-IntervalTree-0.01
	rm -rf ../PerlLib/Set
	rm -rf ../PerlLib/auto

