#LampAID: simplified bash minipipeline to help lamp primersets design and selection

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

lampAIDsplt() {

    echo "$(date) >>> Split"
    if [ ! -e splitout ];then
    mkdir splitout;
    fi
    
    for file in step1/found.tab; do
    awk '{print $1"\t"$0}' $file | \
    sed 's/:/\t/1' | \
    sed 's/:/\t/1' | \
    sed 's/:/\t/1' | \
    awk '{print $1"\t"$2"\t"$2":"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11}' | \
    sed 's/seqID\tseqID\tseqID:patternName\t/feat\tgenus\tspecies\tmisc\tchr\tprimer\t/g' \
    > splitout/split.tab; done
    
    names=`awk 'NR > 1 {print $6}' splitout/split.tab | sed 's/\(.*\)-.*/\1/' | sort -u`
    
    for i in $names; do 
    #head -n 1 splitout/split.tab | \
    #sed 's/primer/ref\tprimer/g' > $i.split
    grep -P "\t$i" splitout/split.tab | \
    awk -F'\t' 'BEGIN {OFS = FS} {gsub(/-set/,"\tset",$6);print}' >> splitout/$i.split
    
    sed 's/\t\t\t//g' splitout/$i.split -i

    
    echo " $i"; done
    echo "Search mode outputs ready"
    
}

[[ -z "$1" ]] && { \
echo -e "\
Error:\n\
Positional parameter 1 is empty: You should pass the mode\n\
syntax; lampAID.sh [MODE] [OPTIONS]\n" ; \
exit 1; }

if [ $1 = search ]; then

    if [ ! -e step1/merged-refs.fna ];then
    echo -e "Search mode - Error:\n\
    merged-refs.fna file not found: Merged reference genomes are obligatory\n\
    syntax; lampAID [MODE] [OPTIONS]\n"
    exit 1
    fi
    
    if [ ! -e step1/primersets.fna ];then
    echo -e "Search mode - Error:\n\
    primersets.fna file not found: Merged reference genomes are obligatory\n\
    syntax; lampAID [MODE] [OPTIONS]\n"
    exit 1
    fi
    
    
[[ -z "$2" ]] && { \
echo -e "\
Search mode - Error:\n\
Positional parameter 2 is empty: You should pass the number of mismatches\n\
syntax; lampAID [MODE] [PRIMERSETS FASTA] [MERGEDREFS FASTA] [NUMBER OF MISMATCHES] [NUMBER OF THREADS]\n" ; \
exit 1; }

[[ -z "$3" ]] && { \
echo -e "\
Search mode - Error:\n\
Positional parameter 3 is empty: You should pass the number of threads\n\
syntax; lampAID [MODE] [PRIMERSETS FASTA] [MERGEDREFS FASTA] [NUMBER OF MISMATCHES] [NUMBER OF THREADS]\n" ; \
exit 1; }

    if (( $2 < 0 || $2 > 3 )); then
    echo -e "Search mode - Error:\n\
    Expected mismatches should be an integer within 0 - 3"
    exit 1
    fi
    
    [[ ! "$2" =~ ^[0-9]+$ ]] && { \
    echo -e "Search mode - Error:\n\
    Expected mismatches should be an integer within 0 - 3";
    exit 1; }

    [[ ! "$3" =~ ^[0-9]+$ ]] && { \
    echo -e "Search mode - Error:\n\
    Threads should be an integer";
    exit 1; }




nmmt=$2
ncpus=$3

    if [ ! -e merged-refs-ready.fna ];then
    sed 's/ /:/g' step1/merged-refs.fna > step1/merged-refs-ready.fna;
    fi

echo "$(date) >>> Search"

echo -e "Total `grep -c "^>" step1/primersets.fna` input primersets "
echo -e "Total `grep -c "^>" step1/merged-refs.fna` input ref genomes "

time \
seqkit locate -i -m $nmmt -j $ncpus \
-f step1/primersets.fna step1/merged-refs-ready.fna > step1/found.tab
echo ""

lampAIDsplt


#lampAID build mode

elif [ $1 = build ]; then

    if [ ! -e step1/found.tab ];then
    echo -e "\
    Build mode - Error:\n\
    found.tab file not found: You should run search mode first\n\
    syntax; lampAID [MODE] [OPTIONS]\n"
    exit 1
    fi
            
    if [ ! -e LampAid ];then
    mkdir LampAid;
    fi
    
    seqkit split step1/primersets.fna -i --id-regexp "^(.*[\w]+)\-" \
    -O LampAid --by-id-prefix "" --quiet
    
    mv LampAid/*.fna splitout
    
    echo "$(date) >>> Build"
    
    time for npt in `basename -a -s .split splitout/*.split`; do    
    
    i=splitout/${npt}.split
    j=splitout/${npt}.fna    
    echo -e "\n input is $i"

    #
    if [ ! -e ${i}-tmp ];then
    mkdir ${i}-tmp;
    fi

    sort $i -k1,1 -k10,10n -k11,11n \
    > $i-tmp/pivot
    
    awk '{ print $0"\t"$10 - prev } { prev = $10 }' ${i}-tmp/pivot \
    > $i-tmp/tmp && cp $i-tmp/tmp $i-tmp/pivot
    
    
    awk -v mycounter=0 \
    'OFS="\t" {if (sqrt($13^2) < 200) $14=$1":"mycounter; else $14=$1":"++mycounter; print;}' \
    $i-tmp/pivot \
    > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot
    
    
    sed -r 's/(\s+)?\S+//13' $i-tmp/pivot -i
    sed -r 's/(\s+)?\S+//5' $i-tmp/pivot -i
    sed '1s/feat:0/grouped/' $i-tmp/pivot -i
    
    awk '{print $0":"$3}' $i-tmp/pivot > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot
    
    datamash --header-in --filler=x crosstab 12,6 first 11 < $i-tmp/pivot | sed 's/"//g' | sed '1s/^/grouped/' \
    > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot
    
    
    grep ">" $j | sed -z 's/\n/\t/g' | sed 's/>//g' > $i-tmp/head
    echo "" >> $i-tmp/head
    grep -v ">" $j | sed -z 's/\n/\t/g' | sed 's/>//g' > $i-tmp/seq

    cat $i-tmp/head $i-tmp/seq > $i-tmp/actual
    rm $i-tmp/seq
    
    cat $i-tmp/head | sed 's/\t/\n/g' > $i-tmp/expec
    head -n 1 $i-tmp/pivot | sed 's/\t/\n/g' > $i-tmp/found
    rm $i-tmp/head
    
    names=`grep -f $i-tmp/found $i-tmp/expec -v`
    
    for line in $names; do
    echo $names
    
    awk -v sets=$line 'NR==1{print $0"\t"sets}  NR>1{print $0"\t""x"}' \
    $i-tmp/pivot > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot; done
    
    rm $i-tmp/expec
    rm $i-tmp/found
    
    sed -i '1s/-F3/_2-F3/' $i-tmp/pivot
    sed -i '1s/-F2/_3-F2/' $i-tmp/pivot
    sed -i '1s/-LF/_4-LF/' $i-tmp/pivot
    sed -i '1s/-F1c/_5-F1c/' $i-tmp/pivot
    sed -i '1s/-B1c/_6-B1c/' $i-tmp/pivot
    sed -i '1s/-LB/_7-LB/' $i-tmp/pivot
    sed -i '1s/-B2/_8-B2/' $i-tmp/pivot
    sed -i '1s/-B3/_9-B3/' $i-tmp/pivot
    
    reorder=`head -n 1 $i-tmp/pivot | \
    sed 's/\t/\n/g' | \
    sort | \
    sed -z 's/\n/,/g' | \
    rev | \
    sed 's/,//' | \
    rev`
    
    csvcut -c $reorder $i-tmp/pivot -t | \
    csvformat -T | \
    sed -E '1s/_[0-9]//g' > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot
    
    
    sed -i '1s/-F3/_2-F3/' $i-tmp/actual
    sed -i '1s/-F2/_3-F2/' $i-tmp/actual
    sed -i '1s/-LF/_4-LF/' $i-tmp/actual
    sed -i '1s/-F1c/_5-F1c/' $i-tmp/actual
    sed -i '1s/-B1c/_6-B1c/' $i-tmp/actual
    sed -i '1s/-LB/_7-LB/' $i-tmp/actual
    sed -i '1s/-B2/_8-B2/' $i-tmp/actual
    sed -i '1s/-B3/_9-B3/' $i-tmp/actual
    
    
    reorder=`head -n 1 $i-tmp/actual | \
    sed 's/\t/\n/g' | \
    sort | \
    sed -z 's/\n/,/g' | \
    rev | \
    sed 's/,//' | \
    rev`

    csvcut -c $reorder $i-tmp/actual -t | \
    csvformat -T | \
    sed -E '1s/_[0-9]//g' |\
    sed '1s/\t/primerset\t/1' |\
    sed '2s/\t/actual\t/1' > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/actual
    
    cat $i-tmp/actual $i-tmp/pivot |\
    sed '3d'> $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot
    
    ncols=`head -n 1 $i-tmp/pivot | awk '{print NF}'`

    for col in $(seq 2 $ncols); do
    
    lmax=`awk '{ print $'"$col"' }' $i-tmp/pivot |\
    awk 'NR >1 {print length}' | sort -rnu | head -n 1`

    maxgap=`printf '%.0s-' $(seq 1 $lmax)`

    awk -v maxgap=${maxgap} 'OFS="\t" {gsub("x",maxgap,$'"$col"');print}' $i-tmp/pivot \
    > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot; done
    
    cat $i-tmp/pivot | \
    { sed -u 2q; sort -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 -k8,8 -r; } \
    > $i-tmp/tmp && mv $i-tmp/tmp $i-tmp/pivot
    
    
    sed '1d' $i-tmp/pivot | \
    sed 's/^/>/g' | \
    sed 's/\t/\n/1' | \
    sed 's/\t/-|-/g' > $i-tmp/fna
    
    mview \
    $i-tmp/fna \
    -in fasta -sort cov:pid -minident 30 -bold -css on -gap " " -html head \
    -pagecolor "black" -textcolor "white" -alncolor "black" -labcolor \
    "white" -symcolor "darkgray" -coloring mismatch -colormap myseaview_nuc \
    -colorfile david-pal> LampAid/$npt.html
    
    
    sed -e '1,269d' LampAid/$npt.html -i

    sed '0,/^/s//@/' LampAid/$npt.html -i

    grep -v "<SMALL>" LampAid/$npt.html > $i-tmp/tmp && mv $i-tmp/tmp LampAid/$npt.html

    #
    cat david-ml LampAid/$npt.html > $i-tmp/tmp && mv $i-tmp/tmp LampAid/$npt.html

    sed -z "s#>\n@  #>   #" LampAid/$npt.html -i

    sed -z 's#</STRONG>\n#</STRONG>\n</div></div>#' LampAid/$npt.html -i
    
    
    spcnm=`echo $npt | sed 's/set.*//g'`
    primernames=`head $i-tmp/actual -n 1|sed 's/primerset\t/\t/g'|sed -z 's/\t/\n/g'|sed 's/.*-set/set/g'|sed -z 's/\n/\t/g'|sed 's/B3\t/B3\n/g'`
    
    sed "s#   cov    pid .*>#cov    pid	 $primernames#g" LampAid/$npt.html -i
    rm $i-tmp/actual

    sed -z "s#\tset#</div>\n<div class=\'flex-child\'>set#g" LampAid/$npt.html -i

    sed -z "s#\n 1 actual#</div></div>\n 1 actual#" LampAid/$npt.html -i
    
    
    sed 's/-|-/NN/g' $i-tmp/fna -i

    mview \
    $i-tmp/fna \
    -in fasta -sort cov:pid -gap "-" \
    -out fasta > LampAid/$npt.fasta
    
    rm $i-tmp/ -r
    
    
done


else
    echo -e "Error:\n\
    Mode parameter wrong; should either 'search' or 'build'"
    exit 1

fi






