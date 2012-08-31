######

ATSHOMEQ="$(ATSHOME)"
ATSCC=$(ATSHOMEQ)/bin/atscc
ATSCTRB=\
  $(ATSHOMEQ)/contrib/bitcoin/atsctrb_bitcoin.o
CFLAGS += -g `pkg-config libevent --cflags` `pkg-config jansson --cflags`
LIBS += `pkg-config libevent --libs` `pkg-config jansson --libs` $(ATSHOME)/contrib/task/atsctrb_task.o
######

checkall: compall cleanall

######

compall: \
  test1

######

test1: test1.dats
	$(ATSCC) $(CFLAGS) -o $@ $< $(ATSCTRB) $(LIBS) 

######

clean:
	rm -f *_?ats.c *.o *~

cleanall: clean
	rm -f test1

###### end of [Makefile] ######
