#!/bin/bash

davidml="david-ml"
davidpal="david-pal"

nmmt=$2
ncpus=$3



#LampAID: simplified bash minipipeline to help lamp primersets design and selection

echo "$(date)"
echo -e "
   LampAID: simplified folderwise bash minipipeline to help lamp primersets design and selection
   see the main repository at https://github.com/Aciole-David/lampAID
   Paper is comming soon!\n"


trap "echo ''; trap - SIGTERM && (kill -- -$$) & disown %" EXIT




if ! command -v awk &> /dev/null
then
    echo -e "Error:\n\
    Obligatory dependency awk not found"
    exit 1
    
elif ! command -v sed &> /dev/null; then
    echo -e "Error:\n\
    Obligatory dependency sed not found"
    exit 1

elif ! command -v seqkit &> /dev/null; then
    echo -e "Error:\n\
    Obligatory dependency seqkit not found"
    exit 1
    
elif ! command -v datamash &> /dev/null; then
    echo -e "Error:\n\
    Obligatory dependency datamash not found"
    exit 1
    
elif ! command -v csvcut &> /dev/null; then
    echo -e "Error:\n\
    Obligatory dependency csvkit not found"
    exit 1
    
elif ! command -v mview &> /dev/null; then
    echo -e "Error:\n\
    Obligatory dependency mview not found"
    exit 1    
fi

spinner() {
  local pid=$!
  spin='-\|/'

  i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(((i + 1) % 4))
    
    printf "%c" "${spin:$i:1}"
    printf "\b"
    
    sleep .1
  done
}

lampAIDsplt() {

    echo "$(date) >>> Split"
    if [ ! -e splitout ];then
    mkdir splitout;
    fi
    
    awk '{print $1"\t"$0}' step1/found.tab | \
    sed 's/:/\t/1' | \
    sed 's/:/\t/1' | \
    sed 's/:/\t/1' | \
    awk '{print $1"\t"$2"\t"$2":"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11}' | \
    sed 's/seqID\tseqID\tseqID:patternName\t/feat\tgenus\tspecies\tmisc\tchr\tprimer\t/g' \
    > splitout/split.tab
    
    names=`awk 'NR > 1 {print $6}' splitout/split.tab | sed 's/\(.*\)-.*/\1/' | sort -u`
    
    
    
    N=$(($ncpus - 2))
    
    varlen=$(wc -w <<< "$names")
    
    count=$varlen
    
    time (
    for i in $names; do 
    
    set +e
    
    ((k=k%N)); ((k++==0)) && wait
    (
    #head -n 1 splitout/split.tab | \
    #sed 's/primer/ref\tprimer/g' > $i.split
    grep -P "\t$i" splitout/split.tab | \
    awk -F'\t' 'BEGIN {OFS = FS} {gsub(/-set/,"\tset",$6);print}' >> splitout/$i.split
    
    sed 's/\t\t\t//g' splitout/$i.split -i
    
    
    echo -ne "Total "$cou	nt " of $varlen to process; " $(( (100-$count *100/$varlen) )) "% done\r"
    echo -ne "$i\r"
    
    
    
    ) &
    
    count=$(expr $count - 1)
    
    done
    wait 
    
    printf "%100s" ""
    echo " "
    echo -e "Search mode outputs ready"
    
    )
    
    
}

[[ -z "$1" ]] && { \
echo -e "\
Error:\n\
Positional parameter 1 is empty: You should pass the mode\n\
syntax: lampAID.sh [MODE] [OPTIONS]\n
MODE: either 'search' or 'build', without quotes
OPTIONS: [NUMBER OF MISMATCHES] followed by [NUMBER OF CPUs] 
NUMBER OF MISMATCHES: Max mismacthes allowed in search, between 0 (exact match) and 3
NUMBER OF CPUs: Max CPUs to run in parallel.
Be careful to use a value smaller than the actual number of CPUs in your computer\n
for example, use 'lampAID.sh search 3 10' to search allowing max 3 mismatches and using 10 cpus \n
             or  'lampAID.sh build 10' to build outputs using 10 cpus " ; \
exit 1; }

if [ $1 = search ]; then

    if [ ! -e step1/merged-refs.fna ];then
    echo -e "Search mode - Error:\n\
    merged-refs.fna file not found: Merged reference genomes are obligatory
       Put merged-refs.fna and primersets.fna in a folder called 'step1' \n
    syntax: lampAID.sh [MODE] [OPTIONS]\n
    for example, use 'lampAID.sh search 3 10' to search allowing max 3 mismatches and using 10 cpus \n
                 or  'lampAID.sh build 10' to build outputs using 10 cpus "
    exit 1
    fi
    
    if [ ! -e step1/primersets.fna ];then
    echo -e "Search mode - Error:\n\
    primersets.fna file not found: Primer sets are obligatory
       Put merged-refs.fna and primersets.fna in a folder called 'step1'\n
    syntax: lampAID.sh [MODE] [OPTIONS]\n
    for example, use 'lampAID.sh search 3 10' to search allowing max 3 mismatches and using 10 cpus \n
                 or  'lampAID.sh build 10' to build outputs using 10 cpus "
    exit 1
    fi
    
    
[[ -z "$2" ]] && { \
echo -e "\
Search mode - Error:\n\
Positional parameter 2 is empty: You should pass the number of mismatches\n\
syntax; lampAID.sh search [NUMBER OF MISMATCHES] [NUMBER OF CPUs]\n" ; \
exit 1; }

[[ -z "$3" ]] && { \
echo -e "\
Search mode - Error:\n\
Positional parameter 3 is empty: You should pass the number of cpus\n\
syntax: lampAID.sh search [NUMBER OF MISMATCHES] [NUMBER OF CPUs]\n
for example, use 'lampAID.sh search 3 10' to search allowing max 3 mismatches and using 10 cpus \n
             or  'lampAID.sh build 10' to build outputs using 10 cpus " ; \
exit 1; }

    if (( $2 < 0 || $2 > 3 )); then
    echo -e "Search mode - Error:\n\
    Expected mismatches should be an integer within 0 - 3\n
    You typed '$2'"

    exit 1
    fi
    
    [[ ! "$2" =~ ^[0-9]+$ ]] && { \
    echo -e "Search mode - Error:\n\
    Expected mismatches should be an integer within 0 - 3\n
    You typed '$2'";
    exit 1; }

    [[ ! "$3" =~ ^[0-9]+$ ]] && { \
    echo -e "Search mode - Error:\n\
    CPUs should be an integer\n
    You typed '$3'";
    exit 1; }





    if [ ! -e step1/merged-refs-ready.fna ];then
	echo "$(date) >>> Labels"
	echo " Preparing labels"
    
    echo " Punctuation characters found in merged-refs.fna:"
    echo `grep [[:punct:]] step1/merged-refs.fna -o | sort -u`
    echo " Punctuations (except '_' , '-' and '>') are replaced by underscore '_' "
    echo ""
    echo " Space characters are replaced by ':' "
    
    totall=`wc -l < step1/merged-refs.fna`
    
    cat step1/merged-refs.fna | pv -N "   " -l -s $totall | \
    sed \
    -e 's#(#_#g' \
    -e 's#)#_#g' \
    -e 's#\\#_#g' \
    -e 's#/#_#g' \
    -e 's#, #_#g' \
    -e 's/: /_/g' \
    -e 's/ /:/g' > step1/merged-refs-ready.fna
    
    echo ""
    #echo " Metagenome assemblies 'MAG:' prefix replaced by 'MAG_' "
    #sed 's/MAG: /MAG_/g' step1/merged-refs-ready.fna -i
    
    
    fi

echo "$(date) >>> Search"
echo ""
echo -e " Total `grep -c "^>" step1/primersets.fna` input primer sequences "
echo -e " Total `grep -c "^>" step1/merged-refs.fna` input ref sequences"

echo ""


echo ""
#echo " Split merged-refs"
#time seqkit split2 -p 10 -j 10 step1/merged-refs-ready.fna -O step1/tmp

echo " Search primers"
#time parallel -j 10 " seqkit locate -F -I -i -f step1/primersets.fna {1}" ::: step1/tmp/merged-refs-ready.*> step1/found.tab ; echo -ne '\007'



totall=`wc -l < step1/merged-refs-ready.fna`


#time ( head -n 99999 step1/merged-refs-ready.fna | seqkit locate -I -i -m $nmmt -j $ncpus \
#-f step1/primersets.fna > step1/found.tab )

time ( cat step1/merged-refs-ready.fna | pv -N "   " -l -s $totall | seqkit locate -I -i -m $nmmt -j $ncpus \
-f step1/primersets.fna > step1/found.tab ) & spinner



echo ""

lampAIDsplt


#lampAID.sh build mode

elif [ $1 = build ]; then

[[ -z "$2" ]] && { \
echo -e "\
Build mode - Error:\n\
Positional parameter 2 is empty: You should pass the number of cpus\n\
syntax; lampAID.sh build [NUMBER OF CPUs]\n
for example, use 'lampAID.sh build 10' to build outputs using 10 cpus " ; \
exit 1; }


    [[ ! "$2" =~ ^[0-9]+$ ]] && { \
    echo -e "Build mode - Error:\n\
    CPUs should be an integer
      You typed '$2'\n
    syntax: lampAID.sh build [NUMBER OF CPUs]\n
    for example, use 'lampAID.sh build 10' to run using 10 cpus ";
    exit 1; }


    if [ ! -e step1/found.tab ];then
    echo -e "\
    Build mode - Error:\n\
    found.tab file not found: You should run search mode first\n\
    syntax: lampAID.sh [MODE] [OPTIONS]\n
    for example, use 'lampAID.sh search 3 10' to search allowing max 3 mismatches and using 10 cpus "
    exit 1
    fi
            
    if [ ! -e LampAid ];then
    mkdir LampAid;
    fi
    
    
    echo " $(date) >>> Build"
    echo ""
    
    time(
    cat step1/primersets.fna | \
    pv -N "   " | \
    seqkit -j $2 split step1/primersets.fna -i --id-regexp "^(.*[\w]+)\-" \
    -O splitout --by-id-prefix "" --quiet 2>/dev/null
    )
    #mv LampAid/*.fna splitout
    
        
    N=$(($2 - 2))
    
    npts=`basename -a -s .split splitout/*.split`
    
    varlen=$(wc -w <<< "$npts")
    
    count=$varlen
    
    echo ' Start building '
    time (
    for npt in $npts; do

    ((k=k%N)); ((k++==0)) && wait
    
    (
    

    #sleep 5
    i=splitout/${npt}.split
    j=splitout/${npt}.fna

    #
    #if [ ! -e ${i}-tmp ];then
    #mkdir ${i}-tmp;
    #fi

    sort $i -k1,1 -k10,10n -k11,11n \
    > $i-tmp-pivot
    
    awk '{ print $0"\t"$10 - prev } { prev = $10 }' ${i}-tmp-pivot \
    > $i-tmp-tmp && cp $i-tmp-tmp $i-tmp-pivot
    
    
    awk -v mycounter=0 \
    'OFS="\t" {if (sqrt($13^2) < 200) $14=$1":"mycounter; else $14=$1":"++mycounter; print;}' \
    $i-tmp-pivot \
    > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    
    sed -r 's/(\s+)?\S+//13' $i-tmp-pivot -i
    sed -r 's/(\s+)?\S+//5' $i-tmp-pivot -i
    sed '1s/feat:0/grouped/' $i-tmp-pivot -i
    
    awk '{print $0":"$3}' $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    datamash --header-in --filler=x crosstab 12,6 first 11 < $i-tmp-pivot | sed 's/"//g' | sed '1s/^/grouped/' \
    > $i-tmp-tmp  2>/dev/null && mv $i-tmp-tmp $i-tmp-pivot 
    
    
    grep ">" $j | sed -z 's/\n/\t/g' | sed 's/>//g' > $i-tmp-head
    echo "" >> $i-tmp-head
    grep -v ">" $j | sed -z 's/\n/\t/g' | sed 's/>//g' > $i-tmp-seq

    cat $i-tmp-head $i-tmp-seq > $i-tmp-actual
    rm $i-tmp-seq
    
    cat $i-tmp-head | sed 's/\t/\n/g' > $i-tmp-expec
    head -n 1 $i-tmp-pivot | sed 's/\t/\n/g' > $i-tmp-found
    rm $i-tmp-head
    
    names=`grep -f $i-tmp-found $i-tmp-expec -v`
    
    for line in $names; do
    echo $names
    
    awk -v sets=$line 'NR==1{print $0"\t"sets}  NR>1{print $0"\t""x"}' \
    $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot; done
    
    rm $i-tmp-expec
    rm $i-tmp-found
    
    sed -i '1s/-F3/_2-F3/' $i-tmp-pivot
    sed -i '1s/-F2/_3-F2/' $i-tmp-pivot
    sed -i '1s/-LF/_4-LF/' $i-tmp-pivot
    sed -i '1s/-F1c/_5-F1c/' $i-tmp-pivot
    sed -i '1s/-B1c/_6-B1c/' $i-tmp-pivot
    sed -i '1s/-LB/_7-LB/' $i-tmp-pivot
    sed -i '1s/-B2/_8-B2/' $i-tmp-pivot
    sed -i '1s/-B3/_9-B3/' $i-tmp-pivot
    
    reorder=`head -n 1 $i-tmp-pivot | \
    sed 's/\t/\n/g' | \
    sort | \
    sed -z 's/\n/,/g' | \
    rev | \
    sed 's/,//' | \
    rev`
    
    csvcut -c $reorder $i-tmp-pivot -t | \
    csvformat -T | \
    sed -E '1s/_[0-9]//g' > $i-tmp-tmp 2>/dev/null && mv $i-tmp-tmp $i-tmp-pivot
    
    
    sed -i '1s/-F3/_2-F3/' $i-tmp-actual
    sed -i '1s/-F2/_3-F2/' $i-tmp-actual
    sed -i '1s/-LF/_4-LF/' $i-tmp-actual
    sed -i '1s/-F1c/_5-F1c/' $i-tmp-actual
    sed -i '1s/-B1c/_6-B1c/' $i-tmp-actual
    sed -i '1s/-LB/_7-LB/' $i-tmp-actual
    sed -i '1s/-B2/_8-B2/' $i-tmp-actual
    sed -i '1s/-B3/_9-B3/' $i-tmp-actual
    
    
    reorder=`head -n 1 $i-tmp-actual | \
    sed 's/\t/\n/g' | \
    sort | \
    sed -z 's/\n/,/g' | \
    rev | \
    sed 's/,//' | \
    rev`

    csvcut -c $reorder $i-tmp-actual -t | \
    csvformat -T | \
    sed -E '1s/_[0-9]//g' |\
    sed '1s/\t/primerset\t/1' |\
    sed '2s/\t/actual\t/1' > $i-tmp-tmp 2>/dev/null && mv $i-tmp-tmp $i-tmp-actual
    
    cat $i-tmp-actual $i-tmp-pivot |\
    sed '3d'> $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    ncols=`head -n 1 $i-tmp-pivot | awk '{print NF}'`

    for col in $(seq 2 $ncols); do
    
    lmax=`awk '{ print $'"$col"' }' $i-tmp-pivot |\
    awk 'NR >1 {print length}' | sort -rnu | head -n 1`

    maxgap=`printf '%.0s-' $(seq 1 $lmax)`

    awk -v maxgap=${maxgap} 'OFS="\t" {gsub("x",maxgap,$'"$col"');print}' $i-tmp-pivot \
    > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot; done
    
    cat $i-tmp-pivot | \
    { sed -u 2q; sort -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 -k8,8 -r; } \
    > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    
    sed '1d' $i-tmp-pivot | \
    sed 's/^/>/g' | \
    sed 's/\t/\n/1' | \
    sed 's/\t/-|-/g' > $i-tmp-fna
    
    (
    cat $i-tmp-fna | \
    #pv -l -s $(wc -l < $i-tmp-fna) | \
    tee >(
    mview \
    -in fasta -sort cov:pid -gap "-" \
    -out fasta > LampAid/$npt.fasta 2>/dev/null
    ) | (
    mview \
    -in fasta -sort cov:pid -minident 30 -bold -css on -gap " " -html head \
    -pagecolor "black" -textcolor "white" -alncolor "black" -labcolor \
    "white" -symcolor "darkgray" -coloring mismatch -colormap myseaview_nuc \
    -colorfile $davidpal> LampAid/$npt.html 2>/dev/null & spinner
    )
    
    sed 's/-|-/NN/g' LampAid/$npt.fasta -i
    
    echo -ne "    $npt; Total "$count " of $varlen to process; " $(( (100-$count *100/$varlen) )) "% done\r"
    
    sed -e '1,269d' LampAid/$npt.html -i

    sed '0,/^/s//@/' LampAid/$npt.html -i

    grep -v "<SMALL>" LampAid/$npt.html > $i-tmp-tmp && mv $i-tmp-tmp LampAid/$npt.html

    
    cat $davidml LampAid/$npt.html > $i-tmp-tmp && mv $i-tmp-tmp LampAid/$npt.html

    sed -z "s#>\n@  #>   #" LampAid/$npt.html -i

    sed -z 's#</STRONG>\n#</STRONG>\n</div></div>#' LampAid/$npt.html -i
    
    
    spcnm=`echo $npt | sed 's/set.*//g'`
    primernames=`head $i-tmp-actual -n 1|sed 's/primerset\t/\t/g'|sed -z 's/\t/\n/g'|sed 's/.*-set/set/g'|sed -z 's/\n/\t/g'|sed 's/B3\t/B3\n/g'`
    
    sed "s#   cov    pid .*>#cov    pid	 $primernames#g" LampAid/$npt.html -i
    rm $i-tmp-actual

    sed -z "s#\tset#</div>\n<div class=\'flex-child\'>set#g" LampAid/$npt.html -i

    sed -z "s#\n 1 actual#</div></div>\n 1 actual#" LampAid/$npt.html -i
    
    
    sed 's/-|-/NN/g' $i-tmp-fna -i
    
    )
    
    
    rm $i-tmp* -r 
    
        
    ) &
        
    count=$(expr $count - 1)
    
done

wait

    printf "%100s" ""
    echo " "
    echo -e " Build outputs ready"
    
    echo "$(date) >>> Finished"
)


else
    echo -e "Error:\n\
    syntax: lampAID.sh [MODE] [OPTIONS]\n
    MODE: either 'search' or 'build', without quotes
       You typed '$1'
    
    OPTIONS: [NUMBER OF MISMATCHES] followed by [NUMBER OF CPUs] 
    NUMBER OF MISMATCHES: Max mismacthes allowed in search, between 0 (exact match) and 3
    NUMBER OF CPUs: Max CPUs to run in parallel.
    Be careful to use a value smaller than the actual number of CPUs in your computer\n
    for example, use 'lampAID.sh search 3 10' to search allowing max 3 mismatches and using 10 cpus \n
             or  'lampAID.sh build 10' to build outputs using 10 cpus "
    exit 1

fi






