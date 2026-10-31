# Skip intro

`skipintro.asm`: pressing Start during the boot logos goes straight to the title. The Start latch is an NMI callback that unregisters itself after the logos, so it costs nothing during attract-mode demos. It is part of the main patch only.
