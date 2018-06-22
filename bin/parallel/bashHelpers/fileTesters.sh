#!/bin/bash

doTempFileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      echo "Temporary file not found or empty file : ${testedFile}" >&2
      echo "EXITING!!" >&2
      exit 1
    fi
}

doTempFileInfo(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      echo "Temporary file not found or empty file : ${testedFile}" >&2
      echo "Continuing, but may create some NONSENSE data.." >&2
      #echo "EXITING!!" >&2
      #exit 1
    fi
}

doTempFileFYI(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      echo "Probably harmless : file not found or empty file : ${testedFile}" >&2
      
      #echo "EXITING!!" >&2
      #exit 1
    fi
}
