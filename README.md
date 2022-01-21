# Engel-Lab-MF-Code
Code I wrote for Engel Lab at NHMFL.

Igor Pro 8.0 or greater code written to process data for Engel Lab at National High Magnetic Field Laboratory.

Labview 2018 or greater code written for data acquisition.

Required Drivers: 

Cryogenic Limited - This will need fixed if aquired from the manufacturer.  Their code is unfinished.

-Their full update code does a search for "OUTPUT:" (the last line the controller sends) to terminate reading from the buffer.

-This erroneously causes the code to terminate early when it comes across "HEATER OUTPUT:" before the end of the buffer.

-Read Output From SMS via Serial Port.vi in the first while loop the case switch "Expected response Recieved?" case "Full Update"

-Add a string search for "Heater OUTPUT:" in parrallel to the "OUTPUT:" search, both use offset past match tied to greater than zero.

-Exclusive or the output of the two searches together into the boolean out of the case.

Keithley 24XX 

Keithley 2450 

Lake Shore Cryotronics 340 

AMI model 420 

AVS47IB

This is predominantly an archive for the Engel Lab.
