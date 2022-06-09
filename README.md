# Knuth × Wirth

The merging of the work of these two great computer scientists into a complete bootstrapping system.

## Existing material I've written for it

* https://github.com/guidoism/computerbook/blob/main/Knuth×Wirth.tex
* https://guidoism.github.io/escape/#status

## Open Questions

* Should I try to get a PEG running as soon as possible or write most of Oberon in MMIX. I've noticed that there's about a 1:1 mapping between Oberon statements and MMIX instructions so writing the OS in assembly might be really cool. The Oberon compiler also doesn't produce particularly good code so maybe I should follow my own advice and write the whole system in MMIX. But that sort of defeats some of the purpose of the book which is to show how elegantly we can build a system from nothing. Hmm. Maybe we do both? First build it up with the PEG showing how quickly we can do it and later optimize by rewriting in MMIX? Doing that actually might be good because we can compare the output of the compiler with the hand-written code and decide which one makes the most sense.

## Supplementary 

* [Awesome MMIX](https://github.com/guidoism/awesome-mmix)
