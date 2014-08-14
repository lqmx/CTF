#!/bin/bash
##############################
#####Setting Environments#####
set -e
u_n=`uname`
case $u_n in
 MINGW*)
  if [ $GOPATH != "" ];then
   export GOPATH=`pathc -w2p $GOPATH`
  fi
esac
export PWD=`pwd`
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=$PATH:$GOPATH/bin:$HOME/bin:$GOROOT/bin:$PWD/bin
export GOPATH=$PWD:$GOPATH
export B_DIR=$PWD/build
export GO_B_DIR=$B_DIR/go
export JS_B_DIR=$B_DIR/js
export WS_B_DIR=$B_DIR/ws
###
pkgs="\
 org.cny.ctf/ctf\
"
ig_cpkgs="org.cny.ctf/ctf,org.cny.ctf/srv"
ig_pkg="org.cny.ctf/srv"
###
init_js(){
	echo "Setting JS Environments"
	rm -rf $JS_B_DIR
	mkdir $JS_B_DIR
	mkdir $JS_B_DIR/e2e
	mkdir $JS_B_DIR/uni
	mkdir $JS_B_DIR/all
}
init(){
	echo "Setting Environments"
	rm -rf $B_DIR
	mkdir $B_DIR
	mkdir $GO_B_DIR
	mkdir $JS_B_DIR
	mkdir $WS_B_DIR
	mkdir $WS_B_DIR/bin
	init_js
}
##############################
##### Running Unit Test ######
unit_test(){
	echo "Running Go Unit Test"
	echo "mode: set" > $GO_B_DIR/a.out
	for p in $pkgs;
	do
	 echo $p
	 go test -v --coverprofile=$GO_B_DIR/c.out $p
	 cat $GO_B_DIR/c.out | grep -v "mode" >>$GO_B_DIR/a.out
	done
	rm -f $GO_B_DIR/c.out
}

##############################
######## Build Exec ##########
build_ig(){
	echo "Build Executable"
	go test  -c -i -cover -coverpkg $c_pkgs
	cp srv.test* $WS_B_DIR/bin
}
build_main(){
	echo "Build Main"
	go build -o CTF org.cny.ctf/main
}
##############################
##Instrument Js And Web Page##
instrument(){
	echo "Instrument Js And Web Page"
	cp -r www $WS_B_DIR
	istanbul instrument --prefix $PWD/www --output $WS_B_DIR/www -x lib/** -x test/** www
	jcr app -d www -o $WS_B_DIR/www -ex www/lib/.*,tpl/.*
}
##############################
######## Run Grunt############
web_test(){
	echo "Running Web Testing"
	grunt --force
}

##############################
#####Create Coverage Report###
gocov_repo(){
	echo "Create Coverage Report"
	mrepo $GO_B_DIR/all.out $GO_B_DIR/a.out $GO_B_DIR/ig.out

	gocov convert $GO_B_DIR/a.out > $GO_B_DIR/coverage_a.json
	cat $GO_B_DIR/coverage_a.json | gocov-xml -b $PWD/src > $GO_B_DIR/coverage_a.xml
	cat $GO_B_DIR/coverage_a.json | gocov-html $GO_B_DIR/coverage_a.json > $GO_B_DIR/coverage_a.html

	gocov convert $GO_B_DIR/ig.out > $GO_B_DIR/coverage_ig.json
	cat $GO_B_DIR/coverage_ig.json | gocov-xml -b $PWD/src > $GO_B_DIR/coverage_ig.xml
	cat $GO_B_DIR/coverage_ig.json | gocov-html $GO_B_DIR/coverage_ig.json > $GO_B_DIR/coverage_ig.html

	gocov convert $GO_B_DIR/all.out > $GO_B_DIR/coverage.json
	cat $GO_B_DIR/coverage.json | gocov-xml -b $PWD/src > $GO_B_DIR/coverage.xml
	cat $GO_B_DIR/coverage.json | gocov-html $GO_B_DIR/coverage.json > $GO_B_DIR/coverage.html
}
js_repo(){
	cd www
	istanbul report --root=$JS_B_DIR --dir=$JS_B_DIR/all cobertura
	istanbul report --root=$JS_B_DIR --dir=$JS_B_DIR/all html
	cd ../
}
m_repo(){
	mcobertura -o $B_DIR/coverage.xml $JS_B_DIR/all/cobertura-coverage.xml $GO_B_DIR/coverage.xml
}
case $1 in
 "main")
  init
  build_main
 ;;
 "rsrv")
  init
  cp CTF* $WS_B_DIR/bin
  grunt w_srv
 ;;
 "re2e")
  init_js
  instrument
  grunt r_e2e
  js_repo
 ;;
 "runi")
  init_js
  grunt r_uni
  js_repo
 ;;
 "de2e")
  init
  cp CTF* $WS_B_DIR/bin
  instrument
  grunt d_e2e
  js_repo
 ;;
 "all")
  init
  unit_test
  build_ig
  instrument
  web_test
  gocov_repo
  js_repo
  m_repo
  ;;
 *)
  echo "Usage: ./build.sh cmd
  main	build main
  rsrv	run all server
  re2e	run e2e test by manual(only e2e)
  runi	run unit test
  de2e	run e2e test(auto start test server)
  all	run all"
  ;;
esac
