Bitcoin module for ATS
======================

Provides an API around the Bitcoin RPC interface.

Install
-------

The library is best used by cloning from under a parent directory that
is used to store ATS libraries. This directory can then be passed to
the 'atscc' command line using the '-I' and '-IATS' options to be
added to the include path. In the examples below this directory is
$ATSCCLIB.

Clone this repository in a directory with the name 'bitcoin':

    cd $ATSCCLIB
    git clone git://github.com/doublec/ats-bitcoin bitcoin
    cd bitcoin
    make

Contact
-------
* Github: http://github.com/doublec/ats-bitcoin
* Email: chris.double@double.co.nz
* Weblog: http://www.bluishcoder.co.nz
