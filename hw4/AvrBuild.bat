@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "U:\mmuldown\ee010b\hw4\labels.tmp" -fI -W+ie -o "U:\mmuldown\ee010b\hw4\hw4.hex" -d "U:\mmuldown\ee010b\hw4\hw4.obj" -e "U:\mmuldown\ee010b\hw4\hw4.eep" -m "U:\mmuldown\ee010b\hw4\hw4.map" "U:\mmuldown\ee010b\hw4\hw4test.asm"
