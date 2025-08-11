#!/bin/bash
#LampAID: simplified bash minipipeline to help lamp primersets design and selection

clock1=$(date +%s.%3N)

echo "$(date)"
echo -e "
   LampAID: simplified folderwise bash minipipeline to help lamp primersets design and selection
   see the main repository at https://github.com/Aciole-David/lampAID
   Paper is comming soon!\n"


trap "echo ''; trap - SIGTERM && (kill -- -$$) & disown %" EXIT


davidml="david-ml"
davidpal="david-pal"


# Define the usage function
usage() {
  echo -e "
  Usage:
  lampAID.sh
  [-o Options    ('search' or 'tab-build' or 'html-build')]
  [-m Mismatches (0 to 3)] Only needed in search mode 
  [-c CPUs       (number of cpus allowed to parallel search or build)]"
}

searchinputs() {
  echo "    A folder called 'step1' should contain 'merged-refs.fna' and 'primersets.fna' files"
}

buildinputs() {
  echo -e "    Run search mode first,
  step1/found.tab and splitout/*.split files are needed to build the outputs"
}

# Process options with getopts
while getopts ":o:m:c:h" opt; do
  case $opt in
    o|--option)
      mode="$OPTARG" ;;
    m)
      nmmt="$OPTARG" ;;
    c)
      ncpus="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Error: Invalid parameter '-$OPTARG'; check usage"
      usage
      exit 1
      ;;
    :)
      echo "Error: Parameter -$OPTARG requires an argument; check usage"
      usage
      exit 1
      ;;
  esac
done


# parameters
if [[ "$mode" == 'html-build' && -z "$ncpus" ]]; then
  echo "Missing parameters; check usage"
  usage
  exit 1

elif [[ "$mode" != 'search' && "$mode" != 'html-build' && "$mode" != 'tab-build' ]]; then
  echo "Mode parameter accepts either 'search' or 'html-build' or 'tab-build' "
  usage
  exit 1

elif [[ "$mode" != 'html-build' && "$mode" != 'tab-build' && -z "$nmmt" ]]; then
  echo "Missing parameters; check usage"
  usage
  exit 1
  
elif [[ -z "$mode" && -z "$nmmt" && -z "$ncpus" ]]; then
  echo "Missing parameters; check usage"
  usage
  exit 1

elif [[ "$mode" == 'search' && ! "$nmmt" =~ ^[0-9]+$ ]]; then
    echo -e "integer Search mode - Error:
    Expected mismatches should be an integer within 0 - 3
    You typed '$nmmt'"
    exit 1

elif [[ "$nmmt" < 0 && "$mode" == 'search' ]] ; then
  echo -e "<0 Search mode - Error:
  Expected mismatches should be an integer within 0 - 3\n
  You typed $nmmt"
  exit 1
  
elif [[ "$nmmt" > 5 && "$mode" == 'search' ]] ; then
  echo -e ">3 Search mode - Error:
  Expected mismatches should be an integer within 0 - 3\n
  You typed $nmmt"
  exit 1

elif ! [[ "$ncpus" =~ ^[0-9]+$ ]]; then
    echo -e "Error:
    CPUs should be an integer greater than 0
    You typed '$ncpus'"
    exit 1
  
fi

# build inputs
if [[ "$mode" == 'html-build' && ! -e step1/found.tab ]]; then
    echo -e "Build mode - Error:
    found.tab file not found:"
    buildinputs
    exit 1

elif [[ "$mode" == 'html-build' && ! -e splitout/ ]]; then
    echo -e "Build mode - Error:
    Splitout folder not found"
    buildinputs
    exit 1

elif [[ "$mode" == 'html-build' && $(ls -1 splitout/*.split 2> /dev/null | wc -l) < 1 ]]; then
    echo "$mode"
    echo -e "Build mode - Error:
    .split files not found:"
    buildinputs
    exit 1
    
elif [[ "$mode" == 'search' && ! -e step1/primersets.fna ]];then
    echo -e "@Search mode - Error:
    primersets.fna file not found:"
    searchinputs
    exit 1
fi

if [[ "$mode" == 'search' && ! -e step1/merged-refs.fna && ! -e step1/merged-refs.fna ]]; then
    echo -e "@Search mode - Error:
    Input folder or files not found:"
    searchinputs
    exit 1
    
elif [[ "$mode" == 'search' && ! -e step1/merged-refs.fna ]]; then
    echo -e "@Search mode - Error:
    merged-refs.fna file not found:"
    searchinputs
    exit 1
    
elif [[ "$mode" == 'search' && ! -e step1/primersets.fna ]];then
    echo -e "@Search mode - Error:
    primersets.fna file not found:"
    searchinputs
    exit 1
fi


# dependencies
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

#spinner
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

# ncpus overwrite
if (( $ncpus > 3 ));then
    ncpus=$(($ncpus - 2))
else
    ncpus=1
fi
    
# lampAIDsplt
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
    echo $names
        
    varlen=$(wc -w <<< "$names")
    
    count=$varlen
    
    echo "inside split fun $ncpus"
    
    time (
    for i in $names; do 
    
    set +e

    
    ((k=k%ncpus)); ((k++==0)) && wait
    (
    #head -n 1 splitout/split.tab | \
    #sed 's/primer/ref\tprimer/g' > $i.split
    grep -P "\t$i" splitout/split.tab | \
    awk -F'\t' 'BEGIN {OFS = FS} {gsub(/-set/,"\tset",$6);print}' >> splitout/$i.split
    
    sed 's/\t\t\t//g' splitout/$i.split -i
    

    echo -ne "   Total "$count " of $varlen to process; " $(( (100-$count *100/$varlen) )) "% done; $i\r"

    
    
    
    ) &
    
    count=$(expr $count - 1)
    
    done
    wait 
    
    printf "%100s" ""
    sleep 1
    echo " "
    echo -e "Search mode outputs ready"
    
    )
    
    
}

# searchmode
searchmode() {
echo $mode
    
    #nmmt=$2
    
    echo "Number of mismatches $nmmt"
    echo "cpu $ncpus; ncpus $ncpus"


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


#time parallel -j 10 " seqkit locate -F -I -i -f step1/primersets.fna {1}" ::: step1/tmp/merged-refs-ready.*> step1/found.tab ; echo -ne '\007'



totall=`wc -l < step1/merged-refs-ready.fna`


#time ( head -n 99999 step1/merged-refs-ready.fna | seqkit locate -I -i -m $nmmt -j $ncpus \
#-f step1/primersets.fna > step1/found.tab )

echo " Searching primers"
time ( cat step1/merged-refs-ready.fna | pv -N "   " -l -s $totall | seqkit locate -P -I -i -m $nmmt -j $ncpus \
-f step1/primersets.fna > step1/found.tab ) #& spinner


# // Split function
echo ""

lampAIDsplt

}

htmlout() {

  	sed 's/ /@/g' LampAid/$npt.fasta | sed 's/\t/\t/g' | \
	awk -v OFS='' -F '' '/>/ {printf $0"@"; next} NR==2 {
	
	IGNORECASE = 1
	for (i = 1; i <= NF; i++)
	
	{ faheader[i] = $i}; print $0 "\t"; next }

	{
	{
    
    for (i = 1; i <= NF; i++)
	    
	{
    if ($i != faheader[i] && $i == "a") 
    {$i="\033[41m" $i "\033[0m"} #red for a
    if ($i != faheader[i] && $i == "t")
    {$i="\033[44m" $i "\033[0m"} #blue for t
    if ($i != faheader[i] && $i == "c")
    {$i="\033[42m" "\033[1;30m" $i "\033[0m"} #green for c
    if ($i != faheader[i] && $i == "g")
    {$i="\033[43m" "\033[1;30m" $i "\033[0m"} #yellow for g
    }
    printf $0 "\n"
    print ""

    
    }
	}' | sed 's/NN/@/g' | sed -z 's/\n\n/\n/g' > LampAid/$npt.html #| aha --black --title $npt > LampAid/$npt.html
     

    
    cat $i-tmp-head3 LampAid/$npt.html | sed -z "s|@@>|@@\n>|g" | \
    sed -z "s|>actual|actual|1" | aha --black --title $npt > $i-tmp-tmp && mv $i-tmp-tmp LampAid/$npt.html
    
    sed '12d' LampAid/$npt.html -i
    
    sed "s|@@|</th><th>|g" LampAid/$npt.html -i   
    sed '11s|@|\n|g' LampAid/$npt.html -i
    sed "11s|&gt;|</tr><tr><th>|g" LampAid/$npt.html -i
    
    

    
    
    
    sed "s|@|</td><td>|g" LampAid/$npt.html -i
    sed "s|&gt;|</tr><tr><td>|g" LampAid/$npt.html -i
    sed -z "s|<pre>|<style>td {padding-left: 7px;padding-right: 7px;}\n</style><pre><table>\n$primernames|g" LampAid/$npt.html -i
    sed -z "s|</pre>|</td></tr></table></pre>|g" LampAid/$npt.html -i
    sed '11i\
    table tr:nth-child(odd) td{background: black;}\
    table tr:nth-child(even) td{background: #333;}' LampAid/$npt.html -i
    
    sed "8i\<div class=\'cursor\'>\n<div class=\'vt\'></div>\n<div class=\'hl\'></div>\n\
    </div><script>\nconst cursorVT = document.querySelector(\'.vt\')\nconst cursorHL = document.querySelector(\'.hl\')\ndocument.addEventListener(\'mousemove\', e => {\ncursorVT.setAttribute(\'style\', \`left: \${e.clientX}px;\`)\ncursorHL.setAttribute(\'style\', \`top: \${e.clientY}px;\`)\n})\n</script>" LampAid/$npt.html -i
        
    sed "22i\.cursor {position: fixed; top: 0; right: 0; bottom: 0; left: 0; z-index: 1; pointer-events: none;}" LampAid/$npt.html -i
    
    sed "23i\.vt {position: absolute; top: 0; bottom: 0; width: 1px; background: cyan;}" LampAid/$npt.html -i
    
    sed "24i\.hl {position: absolute; height: 1px; left: 0; right: 0; background: cyan;}" LampAid/$npt.html -i
    
    sed '27i\th {background:#b6b6ba; color:black;position: sticky;top: 0px;\
    border: 0px solid red;line-height:1; padding: 1px; margin:2px; font-size: 12px; font-family:monospace}' LampAid/$npt.html -i
    } #make html

tabout() {
  
  	sed 's/ /@/g' LampAid/$npt.fasta | sed 's/\t/\t/g' | \
	awk -v OFS='' -F '' '/>/ {printf $0"@"; next} NR==2 {
	
	IGNORECASE = 1
	for (i = 1; i <= NF; i++)
	
	{ faheader[i] = $i}; print $0 "\t"; next }

	{
	{
    
    for (i = 1; i <= NF; i++)
	    
	{
    if ($i == faheader[i] && $i != "N") 
    {$i="." }
    }
    printf $0 "\n"
    print ""

    
    }
	}' | sed 's/NN/\t/g' | sed 's/@/\t/g' | sed -z 's/\n\n/\n/g' | sed '1s/\t.*%/\tFirst\tStt\tEnd\tCov\tPid/' > LampAid/$npt.tab #| aha --black --title $npt > LampAid/$npt.html
      
    } #make html


# buildmode
buildmode() {
if [ ! -e LampAid ];then
  mkdir LampAid;
fi
    
    
echo " $(date) >>> Build"
echo ""


time (
cat step1/primersets.fna | \
pv -N "   " | \
seqkit -j $ncpus split step1/primersets.fna -i --id-regexp "^(.*[\w]+)\-" \
-O splitout --by-id-prefix "" --quiet 2>/dev/null
)


    #mv LampAid/*.fna splitout
    
    
    npts=`basename -a -s .split $(ls -Sr splitout/*.split)`
    echo -e "splitfiles
    $npts"
    
    varlen=$(wc -w <<< "$npts")
    
    count=$varlen
    
    echo ' Start building '
    
    echo "will use $ncpus cpus"
    
    
    time (
    for npt in $npts; do
    

    ((k=k%ncpus)); ((k++==0)) && wait
    
    (
    
    i=splitout/${npt}.split
    j=splitout/${npt}.fna

    #
    #if [ ! -e ${i}-tmp ];then
    #mkdir ${i}-tmp;
    #fi
    
    
    sort $i -k1,1 -k10,10n -k11,11n \
    > $i-tmp-pivot
    
    awk '{ print $0"\t"$10 - prev } { prev = $10 }' ${i}-tmp-pivot \
    > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    cp $i-tmp-pivot aaa.csv
    
    awk -v mycounter=0 \
    'OFS="\t" {if (sqrt($13^2) < 200) $14=$1":"mycounter; else $14=$1":"++mycounter; print;}' \
    $i-tmp-pivot \
    > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    
    sed -r 's/(\s+)?\S+//13' $i-tmp-pivot -i
    sed -r 's/(\s+)?\S+//5' $i-tmp-pivot -i
    sed '1s/feat:0/grouped/' $i-tmp-pivot -i
    
	

    
	  awk '{print $0":"$3":"$4}' $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    cp $i-tmp-pivot qqq.csv
    
    #grep 'F3' $i-tmp-pivot | sed 's/\t/\t@/g' | head 
    	  
	  cp $i-tmp-pivot qqq2.csv
	  
	  #awk -F'\t' 'BEGIN {OFS = FS} { if ($6 != "arsenal") $11 =  $8"@"$9"@"$10"@"$11; print $0}' $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot

	  sed -i 's/-F3/_1-F3/g' $i-tmp-pivot
    sed -i 's/-F2/_2-F2/g' $i-tmp-pivot
    sed -i 's/-LF/_3-LF/g' $i-tmp-pivot
    sed -i 's/-F1/_4-F1/g' $i-tmp-pivot
    sed -i 's/-B1/_5-B1/g' $i-tmp-pivot
    sed -i 's/-LB/_6-LB/g' $i-tmp-pivot
    sed -i 's/-B2/_7-B2/g' $i-tmp-pivot
    sed -i 's/-B3/_8-B3/g' $i-tmp-pivot

	  cp $i-tmp-pivot qqq3.csv
	  
	  (printf "grouped\n"; cat $i-tmp-pivot | awk -F'\t' 'BEGIN {OFS=FS} {print $12,$9,"@",$6"\n"$12,$10,"@",$6}' | \
	  sed 's/@.*-//g' | \
	  datamash -g 1 first 3 min 2 max 2 --output-delimiter="@"| sort -k1,1) > $i-tmp-pivothead
	  
	  
	  
    
    datamash --filler=x crosstab 12,6 first 11 < $i-tmp-pivot | sed '1s/^/grouped/' | sed 's/"//g' > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
    
    cp $i-tmp-pivot qqqmash.csv
    
    
    paste $i-tmp-pivothead $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
	  
	  
	  
	  cut -f -1,3- $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot
	 
	  
    sed -i 's/_1-F3/-F3/g' $i-tmp-pivot
    sed -i 's/_2-F2/-F2/g' $i-tmp-pivot
    sed -i 's/_3-LF/-LF/g' $i-tmp-pivot
    sed -i 's/_4-F1/-F1/g' $i-tmp-pivot
    sed -i 's/_5-B1/-B1/g' $i-tmp-pivot
    sed -i 's/_6-LB/-LB/g' $i-tmp-pivot
    sed -i 's/_7-B2/-B2/g' $i-tmp-pivot
    sed -i 's/_8-B3/-B3/g' $i-tmp-pivot
    
    #awk -F'\t' 'BEGIN {OFS = FS} {$1 = $1"\t"$2";"$3; print;}' $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot 
    
    
    

    
    
    grep ">" $j | sed -z 's/\n/\t/g' | sed 's/>//g' > $i-tmp-head
    echo "" >> $i-tmp-head
    grep -v ">" $j | sed -z 's/\n/\t/g' | sed 's/>//g' > $i-tmp-seq

    cat $i-tmp-head $i-tmp-seq > $i-tmp-actual
    rm $i-tmp-seq
    
    cat $i-tmp-head | sed 's/\t/\n/g' > $i-tmp-expec
    

    head -n 1 $i-tmp-pivot | sed 's/\t/\n/g' > $i-tmp-found
    rm $i-tmp-head
    
    grep -f $i-tmp-found $i-tmp-expec -v
    
    names=`grep -f $i-tmp-found $i-tmp-expec -v`
    
    echo $names
    for line in $names; do
    
    awk -v sets=$line 'NR==1{print $0"\t"sets}  NR>1{print $0"\t""x"}' \
    $i-tmp-pivot > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot; done
    
    rm $i-tmp-expec
    rm $i-tmp-found
    
    sed -i '1s/-F3/_2-F3/' $i-tmp-pivot
    sed -i '1s/-F2/_3-F2/' $i-tmp-pivot
    sed -i '1s/-LF/_4-LF/' $i-tmp-pivot
    sed -i '1s/-F1/_5-F1/' $i-tmp-pivot
    sed -i '1s/-B1/_6-B1/' $i-tmp-pivot
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
    sed -i '1s/-F1/_5-F1/' $i-tmp-actual
    sed -i '1s/-B1/_6-B1/' $i-tmp-actual
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
    
    
    #cat $i-tmp-pivot | \
    #{ sed -u 2q; sort -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 -k8,8 -r; } \
    #> $i-final-pivot
    
    cat $i-tmp-pivot | \
    { sed -u 2q; sort -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 -k8,8 -r; } \
    > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-pivot

	


    
    
		

    sed '1d' $i-tmp-pivot | \
    sed 's/^/>/g' | \
    sed 's/\t/\n/1' | \
    sed 's/\t/NN/g' > $i-tmp-fna
    
    sed 's/:/@@/2' $i-tmp-fna | sed 's/:.*@@/@/' > $i-tmp-tmp && mv $i-tmp-tmp $i-tmp-fna
    
    (
    #cat $i-tmp-fna | \
    #pv -l -s $(wc -l < $i-tmp-fna) | \
    #tee >(
    
    
    mview $i-tmp-fna \
    -in fasta -sort cov:pid -gap "-" -minident 30 \
    -out fasta | seqkit seq -j 1 -w 999 > LampAid/$npt.fasta #2>/dev/null
	#)
	
	head1=`head $i-tmp-actual -n 1 | sed 's/primerset\t//g' |sed -z 's/\t/\n/g' | \
	sed 's/.*-set/set/g' | sed '1i\>Ref\nRef\nFirst\nStt\nEnd\nCov\nPid'`
	
	head2=`head -n 2 LampAid/$npt.fasta | sed 's/>actual/Acc\nDesc\nPrimer\nPos\nPos/g' |sed -z 's/ /\n/g' | sed 's/NN/\n/g'`
	
	paste <(echo "$head1") <(echo "$head2") --delimiters '@' | sed -z 's/\n/@@/g' > $i-tmp-head3
	
	#printf $primernames
	
	
	#awk '{for(i=1;i<=NF;i++)cols[i]=(cols[i]==""?$i:cols[i]" "$i)}END{for(i=1;i<=length(cols);i++)print cols[i]}' actual.tab

if [[ "$mode" == 'html-build' ]]; then
htmlout

elif [[ "$mode" == 'tab-build' ]]; then
tabout

fi

    
    #sed '29i\th2 {background:#b6b6ba; color:black;position: sticky;top: 0px;\
    #border: 0px solid red;line-height:1; padding: 1px; margin:2px; font-size: 12px; font-family:monospace}' LampAid/$npt.html -i
    
    #sed '33s/td/th2/g' LampAid/$npt.html -i
    
    #| column -t -s '@' -N $primernames > LampAid/$npt.html #| aha --black --title $npt > LampAid/$npt.html # & spinner
	echo -ne "   Total "$count " of $varlen to process; " $(( (100-$count *100/$varlen) )) "% done; $npt;\r"
    
    #sed 's/-|-/NN/g' $i-tmp-fna -i
    
    )
    
    rm $i-tmp* -r 
    
        
    ) &
        
    count=$(expr $count - 1)
    
done

wait
    sed 's/-|-/NN/g' LampAid/*.fasta -i
    sed 's/@/_/g' LampAid/*.fasta -i
    printf "%100s" ""
    echo " "
    echo -e " Build outputs ready"
    
    echo "$(date) >>> Finished"

) # time process .fna and .split

}


if [[ "$mode" = 'search' ]]; then
searchmode

elif [[ "$mode" = 'html-build' || "$mode" == 'tab-build' ]]; then
buildmode

fi & spinner


clock2=$(date +%s.%3N)
duration=$(echo "scale=4; $clock2 - $clock1" | bc | xargs printf "%.3f" | sed 's/,/./')

echo ""

echo "$(date) >>> Lampaid ran in total $duration seconds"



