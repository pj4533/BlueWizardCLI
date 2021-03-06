# BlueWizardCLI
Swift command line application for easily generating custom Plaits LPC code

A command line wrapper around BlueWizard, with specific enhancements for generating Mutable Instruments Plaits source code.

Create a text file with one phrase per line, with a blank line separating banks of phrases. For example, here is a file with two banks:

```
you want a lexus, or justice?
fake.   records.
to all the killas and the hundred dolla billas
ain't no such thing as half way crooks

wu tang again?
i'm gettin hustled only knowing half the game
```

Then run the application on the command line and pass it the name of your text file:

`./BlueWizardCLI banks.txt`

It will output two source code files `lpc_speech_synth_words.h` and `lpc_speech_synth_words.cc` These file contain the LPC byte codes generated by the BlueWizard source code, and automatically formatted for compilation of a custom Plaits firmware. This includes the calculation of the array sizes, etc.

Then just copy the generated source files into your Plaits codebase and follow the instructions for building the firmware.