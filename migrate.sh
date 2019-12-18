#!/bin/bash

function help(){
    echo "Usage: "
    echo "    $0 <foo.mbz> start"
    echo "    $0 <foo.mbz> find <1234>           # find instances of UID 1234"
    echo "    $0 <foo.mbz> set <1234> to <5678>  # migrate UID 1234 to 5678"
    echo "    $0 <foo.mbz> status                # show changes made thus far"
    echo "    $0 <foo.mbz> finish                # bundle the changes into a new .mbz"
    exit 1
}

DIR_CLEAN=".$1-clean.d"
DIR_DIRTY=".$1-dirty.d"

function log(){
    echo "$(date +'%T') $*" >&2
}

function die(){
    log $*
    exit 1
}

function unpack(){
    if [ -d $1 ]; then
        die "Please remove $1 manually"
    fi
    mkdir -p $1 && \
    cd $1 && \
    tar -zxvf ../$2 && \
    cd ..
}

function mig_start(){
    unpack ${DIR_CLEAN} $1
    unpack ${DIR_DIRTY} $1
}

function mig_find(){
    test -d ${DIR_DIRTY} || die "${DIR_DIRTY} does not exist; try \"$0 $1 start\""

    grep -r -E '\b'$2'\b' ${DIR_DIRTY}/*
}

function mig_user(){
    log "migrating $2->$3 in $1"
    test -d ${DIR_DIRTY} || die "${DIR_DIRTY} does not exist; try \"$0 $1 start\""

    for i in $(grep -r -E '\b'$2'\b' ${DIR_DIRTY}/* | grep -v "^Binary file" | awk -F: '{print $1}' | sort | uniq | grep -v users.xml); do
        log $i
        perl -pi -e 's/userid>'$2'<\/userid/userid>'$3'<\/userid/g' $i
        if [ $(basename $i) = "inforef.xml" ]; then
            perl -pi -e 'BEGIN{undef $/;} s/user>(\s*)<id>'$2'</user>$1<id>'$3'</smg' $i
        fi
        if [ $(basename $i) = "grades.xml" ] || [ $(basename $i) = "forum.xml" ]; then
            perl -pi -e 's/usermodified>'$2'<\/usermodified/usermodified>'$3'<\/usermodified/g' $i
        fi
    done

    if grep -q $2 ${DIR_DIRTY}/users.xml; then
        log ${DIR_DIRTY}/users.xml
        perl -pi -e 'BEGIN{undef $/;} s/<user\s+id="'$2'".*?<\/user>//smg' ${DIR_DIRTY}/users.xml
    fi
}

function mig_show(){
    test -d ${DIR_CLEAN} || die "${DIR_CLEAN} does not exist; try \"$0 $1 start\""
    test -d ${DIR_DIRTY} || die "${DIR_DIRTY} does not exist; try \"$0 $1 start\""

    pushd ${DIR_CLEAN} >/dev/null
    for i in $(find . -type f -print); do
        diff -q $i ../${DIR_DIRTY}/$i || diff -u $i ../${DIR_DIRTY}/$i
    done
    popd >/dev/null
}

function mig_finish(){
    test -d ${DIR_DIRTY} || die "${DIR_DIRTY} does not exist; try \"$0 $1 start\""

    pushd ${DIR_DIRTY} >/dev/null
    tar -zcvf ../$(echo $1 | sed 's/.mbz$/_'$(date +"%Y-%m-%d_%H%M%S")'.mbz/') *
    popd >/dev/null

    rm -fr ${DIR_DIRTY} ${DIR_CLEAN}
}

case "${2:-x}" in
    start)  if [ $# -ne 2 ]; then
                help
            fi
            mig_start $1
            ;;
    find)   if [ $# -ne 3 ]; then
                help
            fi
            mig_find $1 $3
            ;;
    set)    if [ $# -ne 5 ] || [ $4 != "to" ]; then
                help
            fi
            mig_user $1 $3 $5
            log "checking for things we didn't replace..."
            mig_find $1 $3
            log "done"
            ;;
    status) if [ $# -ne 2 ]; then
                help
            fi
            mig_show $1
            ;;
    finish) if [ $# -ne 2 ]; then
                help
            fi
            mig_finish $1
            ;;
    *)      help
esac

