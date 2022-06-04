@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "U:\mmuldown\ee010b\binario\labels.tmp" -fI -W+ie -o "U:\mmuldown\ee010b\binario\utiltest.hex" -d "U:\mmuldown\ee010b\binario\utiltest.obj" -e "U:\mmuldown\ee010b\binario\utiltest.eep" -m "U:\mmuldown\ee010b\binario\utiltest.map" "U:\mmuldown\ee010b\binario\hw2test.asm"
