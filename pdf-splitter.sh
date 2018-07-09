#!/bin/sh

# Description:
# This bash-script splits a pdf-document whenever
# a barcode/qr-code is found that matches the regular expression (regex)

# Example:
# A pdf-file with 6 pages has a barcode which matches the regex on the first page, the third page and the last page
# This script will split the pdf into the following pieces: Page 1-2, Page 3-5, Page 6

# Usage:
#ÂThe first argument is the Input-PDF-file. The second argument is the regular expression.
# example: bash pdf-splitter.sh ~/input/merged2.pdf 20[1-3][0-9]000[0-9]{6}

# Which programs need to be installed?
# ghostscript, poppler-utils (pdfinfo), zbar-tools (barcode-detection)

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

inputfile=$1
regex=$2

tempdir=$(/bin/mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
cd $tempdir
trap "rm -rf $tempdir" EXIT

echo $tempdir

totalpages=$(pdfinfo $inputfile | grep Pages | awk '{print $2}')

echo "===> Inputfile '$inputfile' has $totalpages pages"

fromPage=1
currentPage=1

while [ $currentPage -lt $totalpages ]
do
  currentPage=$(($currentPage+1))
  echo "currentPage: $currentPage"
  #==================================================
  # use Ghostscript to extract the current page of the PDF-file to a single JPEG-file

  gs        				\
    -o $tempdir/currentPage.jpeg	\
    -sDEVICE=jpeg                	\
    -dNOPAUSE -r300x300			\
    -dFirstPage=$currentPage		\
    -dLastPage=$currentPage		\
    $inputfile

  #==================================================
  # extract ALL the barcodes from currentPage.jpeg
  # because the first extracted barcode might not be the one we are looking for

  barcodes="$(zbarimg --raw -q currentPage.jpeg)"
  echo $barcodes

  #==================================================
  # match the regex against the barcode

  if [[ $barcodes =~ $regex ]]
  then
    echo "Regex match found"
    # here we export the pages fromPage to currentPage-1
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

