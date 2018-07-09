#!/bin/sh

function display_usage()
{
     echo '###############################################################################'
     echo '# pdf-splitter is a bash-script that splits a pdf-document whenever           #'
     echo '# a barcode/qr-code is found that matches the regular expression (regex)      #'
     echo '#                                                                             #'
     echo '# Author:    Daniel Forrer, 2018-07-09                                        #'
     echo '#                                                                             #'
     echo '# Libraries: ghostscript, poppler-utils (pdfinfo),                            #'
     echo '#            zbar-tools (barcode-detection)                                   #'
     echo '#                                                                             #'
     echo '# Example:   A pdf-file with 6 pages has a barcode which matches the regex on #'
     echo '#            the first page, the third page and the last page.                #'
     echo '# Result:    The script will split the pdf into the following pieces:         #'
     echo '#            Page 1-2, Page 3-5, Page 6                                       #'
     echo '#                                                                             #'
     echo '# Usage:     The 1. argument is the path to the input-PDF-file.               #'
     echo '#            The 2. argument is the regular expression.                       #'
     echo '# Example:   bash pdf-splitter.sh ~/input/merged2.pdf 20[1-3][0-9]000[0-9]{6} #'
     echo '#                                                                             #'
     echo '# Tested on: Linux Mint 18.3 Sylvia, macos 10.13.5                            #'
     echo '###############################################################################'
}

# Source: https://www.linuxjournal.com/content/tech-tip-extract-pages-pdf
function pdfpextr()
{
    # this function uses 3 arguments:
    #     $1 is the first page of the range to extract
    #     $2 is the last page of the range to extract
    #     $3 is the input file
    #     output file will be named "inputfile_pXX-pYY.pdf"
    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER\
       -dFirstPage=${1} \
       -dLastPage=${2} \
       -sOutputFile=${3%.pdf}_p${1}-p${2}.pdf \
       ${3}
}

# Make sure we have two parameters, then save them

if [ ! $# -eq 2 ]; then 
    echo ' Wrong number of parameters! '
    display_usage
    exit 0
fi

inputfile=$1
regex=$2

# Create temporary directory and make sure it gets deleted on EXIT

tempdir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
cd $tempdir
trap "rm -rf $tempdir" EXIT

totalpages=$(pdfinfo $inputfile | grep Pages | awk '{print $2}')
echo "Inputfile '$inputfile' has $totalpages pages"

# fromPage is the beginning of the next pdf

fromPage=1
currentPage=1

while [ $currentPage -lt $totalpages ]
do
  currentPage=$(($currentPage+1))
  echo "currentPage: $currentPage"
  
  # use Ghostscript to extract the current page of the PDF-file to a single JPEG-file

  gs        				\
    -o $tempdir/currentPage.jpeg	\
    -sDEVICE=jpeg                	\
    -dNOPAUSE -r300x300			\
    -dFirstPage=$currentPage		\
    -dLastPage=$currentPage		\
    $inputfile

  # extract ALL the barcodes from currentPage.jpeg
  # because the first extracted barcode might not be the one we are looking for

  barcodes="$(zbarimg --raw -q currentPage.jpeg)"
  echo $barcodes

  # match the regular expression against the barcode

  if [[ $barcodes =~ $regex ]]
  then
    echo "Regex match found"

    # here we export the pages fromPage to currentPage-1 as a pdf

    pdfpextr $fromPage $(($currentPage-1)) $inputfile
    fromPage=$currentPage

  else
    echo "Regex NOT found"
  fi

  if [[ $totalpages -eq $currentPage ]]
  then
    echo "$totalpages = $currentPage (totalpages = currentPage)"
    pdfpextr $fromPage $currentPage $inputfile
  fi
done

