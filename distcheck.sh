TOP=`pwd`

echo
echo "  Make Distribution"
CONFIG=""
CFLAGS="-O0 -g -Wall -ansi -Wdeclaration-after-statement -Werror" ./configure $CONFIG
make clean all
make distcheck DISTCHECK_CONFIGURE_FLAGS="$CONFIG"

