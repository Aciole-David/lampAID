# lampAID
Simplified folderwise bash pipeline to help lamp PCR primersets design and selection


![image](https://github.com/user-attachments/assets/18c0c995-518b-4446-a7b3-0e01c9d0e7ca)

![image](https://github.com/user-attachments/assets/fcc39448-2406-4d02-a858-e0de379b2152)

![image](https://github.com/user-attachments/assets/477bb667-713b-4543-a919-63d39ceefb4c)


## 1. Install dependencies with conda/mamba:
    mamba install -n lampaid bioconda::seqkit conda-forge::sed anaconda::gawk bioconda::mview conda-forge::pv bioconda::datamash conda-forge::csvkit
then activate the env

    mamba activate lampaid

## 2. Download the files from repository:
    git clone https://github.com/Aciole-David/lampAID.git
then cd to dir

    cd lampAID

## 3. Prepare input files:
Copy your reference NCBI genomes in a file named 'merged-refs.fna'
and lamp primers in a file named 'primersets.fna' to a folder named 'step1'

## 4. Run lampAID search:

### Search mode syntax

  lampAID.sh [SEARCH] [MISMACTHES] [CPUs]

### example to search allowing 3 mismatches and 10 CPUs

    ./lampAID.sh search 3 10
This first step creates intermediary files with mathes found

### Build results mode syntax
  ./lampAID.sh [build] [CPUs]

### example to build results using 10 CPUs
      ./lampAID.sh build 10
This second step builds fasta and html files of alignment-like results
      
You can open html results in any web browser






