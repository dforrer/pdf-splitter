@echo off
setlocal EnableDelayedExpansion
setlocal EnableExtensions

echo ###############################################################################
echo # pdf-splitter is a bash-script that splits a pdf-document whenever           #
echo # a barcode/qr-code is found that matches the regular expression (regex)      #
echo #                                                                             #
echo # Author:    Daniel Forrer, 2018-08-01                                        #
echo #                                                                             #
echo # Libraries: ghostscript, pdftk, zbar-tools (barcode-detection)               #
echo #            https://www.ghostscript.com/download/gsdnld.html + set PATH      #
echo #            https://sourceforge.net/projects/zbar/ + set PATH                #
echo #            https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/ + set PATH  #
echo #                                                                             #
echo # Example:   A pdf-file with 6 pages has a barcode which matches the regex on #
echo #            the first page, the third page and the last page.                #
echo # Result:    The script will split the pdf into the following pieces:         #
echo #            Page 1-2, Page 3-5, Page 6                                       #
echo #                                                                             #
echo # Usage:     The 1. argument is the path to the input-PDF-file.               #
echo #            The 2. argument is the regular expression.                       #
echo # Example:   pdf-splitter.bat C:\input\merged.pdf 20[1-3][0-9]000[0-9][0-9]   #
echo #                                                                             #
echo # Tested on: Windows 7                                                        #
echo ###############################################################################

rem TODO: Make sure we have two parameters, then save them

SET inputfile=%1
SET regex=%2

rem Create temporary directory and make sure it gets deleted on EXIT

set cmd="pdftk !inputfile! dump_data | findstr /R /C:"NumberOfPages""
FOR /F "tokens=*" %%i IN (' !cmd! ') DO SET totalpages=%%i

set /a count=0
for %%a in (%totalpages%) do (
    set /a count+=1
    set "variable!count!=%%a"
)
set /a totalpages=variable2

echo -----Total number of pages: %totalpages%

rem WORKS TIL HERE------------------------------------

rem fromPage is the beginning of the next pdf

set /a fromPage=1
set /a currentPage=1

:WHILE_0
if !currentPage! LSS !totalpages! (
  echo =========================================
  set /a currentPage=^(!currentPage! + 1^)
  echo -----CurrentPage: !currentPage!
  
  rem use Ghostscript to extract the current page of the PDF-file to a single JPEG-file

  gswin32c -o ____currentPage.jpeg ^
     -sDEVICE=jpeg ^
     -dNOPAUSE -r300x300 ^
     -dFirstPage=!currentPage! ^
     -dLastPage=!currentPage! ^
     !inputfile!

  rem extract ALL the barcodes from currentPage.jpeg
  rem because the first extracted barcode might not be the one we are looking for

  set cmd="zbarimg --raw -q ____currentPage.jpeg"
  set barcodes=
  FOR /F "tokens=*" %%i IN (' !cmd! ') DO SET barcodes=!barcodes! %%i
  echo -----Barcodes: !barcodes!

  rem match the regular expression against the barcodes-string

  echo !barcodes! | findstr /r "!regex!" >nul 2>&1 && (
    echo -----Regex match found

    rem here we export the pages fromPage to currentPage-1 as a pdf

    set /a toPage=^(!currentPage! - 1^) 
    pdftk !inputfile! cat !fromPage!-!toPage! output !inputfile:~0,-4!_p!fromPage!-p!toPage!.pdf
    set fromPage=!currentPage!
  ) || (
    echo -----NO regex match found
  )

  if !totalpages! EQU !currentPage! (
    pdftk !inputfile! cat !fromPage!-!currentPage! output !inputfile:~0,-4!_p!fromPage!-p!currentPage!.pdf
  )
  goto WHILE_0
)

del ____currentPage.jpeg
