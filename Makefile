#
# Bitcoin API
#
# Author: Chris Double (chris DOT double AT double DOT co DOT nz)
# Time: August, 2012
#

######
ATSHOMEQ="$(ATSHOME)"
ATSCC=$(ATSHOMEQ)/bin/atscc -Wall

######

all: atsctrb_bitcoin.o clean

######

atsctrb_bitcoin.o: rpc_dats.o base64_dats.o
	ld -r -o $@ $^

######

rpc_dats.o: DATS/rpc.dats
	$(ATSCC) $(CFLAGS) -o $@ -c $<

base64_dats.o: DATS/base64.dats
	$(ATSCC) $(CFLAGS) -o $@ -c $<

######

clean::
	rm -f *_?ats.c *_?ats.o

cleanall: clean
	rm -f atsctrb_rpc.o

###### end of [Makefile] ######
