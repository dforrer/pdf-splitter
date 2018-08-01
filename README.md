# pdf-splitter

```
 pdf-splitter is a bash- and batch-script that splits a pdf-document whenever
 a barcode/qr-code is found that matches the regular expression (regex)
                                                                             
 Author:    Daniel Forrer, 2018-08-01
 
 Libraries: ghostscript   (mac/linux/windows)
            zbar          (mac/linux/windows)
            poppler-utils (mac/linux)
            pdftk         (windows)
                                                                       
 Example:   A pdf-file with 6 pages has a barcode which matches the regex on 
            the first page, the third page and the last page.                
 Result:    The script will split the pdf into the following pieces:         
            Page 1-2, Page 3-5, Page 6                                       
                                                                             
 Usage:     The 1. argument is the path to the input-PDF-file.               
            The 2. argument is the regular expression.                       
 Examples:  bash pdf-splitter.sh ~/input/merged.pdf 20[1-3][0-9]000[0-9][0-9][0-9]
            pdf-splitter.bat C:\input\merged.pdf 20[1-3][0-9]000[0-9][0-9]
                                                                             
 Tested on: Linux Mint 18.3 Sylvia (bash), macos 10.13.5 (bash), Windows 7 (batch)

```