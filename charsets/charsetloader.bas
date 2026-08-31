10 input "drive"; d
20 input "filename"; f$
30 poke 53272, peek(53272) and 240 or 14
40 sys 57812 f$,d,0
50 poke 780, 0
60 poke 781, 2
70 poke 782,56
80 sys 65493
90 poke 55,0
100 poke 56,56
