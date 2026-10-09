10 sc=0
20 for c=0 to 999
30 nc=0
40 if c<1000 and peek(1024+c+1)<>32 then nc=nc+1
50 if c>0 and peek(1024+c-1)<>32 then nc=nc+1
60 if c<960 and peek(1024+c+40)<>32 then nc=nc+1
70 if c<960 and peek(1024+c+40+1)<>32 then nc=nc+1
80 if c<960 and peek(1024+c+40-1)<>32 then nc=nc+1
90 if c>39 and peek(1024+c-40)<>32 then nc=nc+1
100 if c>39 and peek(1024+c-40+1)<>32 then nc=nc+1
110 if c>39 and peek(1024+c-40-1)<>32 then nc=nc+1
120 if nc<2 or nc>3 then poke 1024+c,32
130 if nc=3 then poke 1024+c,83 : poke 55296+c,sc
140 next
150 sc=sc+1 and 15
160 goto 20
