extensions [ vid csv time]

globals [
  ;initial-trees   ;; how many trees (green patches) we started with
  parar
  fire-patches    ;; number of patches that catch fire
  powexp          ;; power law dispersal exponent of forest
  powexp-fire     ;; power law dispersal exponent of fire into forest
  forest-growth-prob
  forest-recovery-after-fire-prob
  total-forest
  f-prob
  start-fire-season
  end-fire-season
  fire-prob-list
  fire-prob-list-se
  burned-by-month             ; To calculate the burned area by month
  previous-month-burned
  actual-burned
  tick-date                   ; anchor ticks to first date in the file
  last-mes                    ; to control month changing
  accum-mes
  eval-burned-clusters-list        ; list with the ticks to eval burned clusters
  col-burned                       ; color of the burned patches
]

patches-own [
  last-fire-time    ; time of the last time the patch was burned
  fire-interval     ; the time interval between the last two fires
  number-of-fires   ; the number of times the patch was burned
  cluster-label             ; find clusters (patches)
  deforested        ; false = Not deforested, true deforested
  deforested-time   ;
]


to setup
  clear-all

  ;
  ; Set initial number of patches
  ;
  ;ifelse world500x000 [
  ;  resize-world 0 499 0 499
  ;  set-patch-size 1

  ;][
  ;  resize-world 0 249 0 249
  ;  set-patch-size 2
  ;]
  set col-burned red - 3.5
  set total-forest world-width * world-height
  set fire-prob-list []                               ;  fire prob readed from file
  set fire-prob-list-se []                            ;  SE of fire prob readed from file

  if not empty? fire-prob-filename [
    ;set fire-prob-filename "Data/Predicted_bF_rcp45.csv"
    read-fire-prob              ; Read file with fire-probability
  ]

  set accum-mes 0

  ask patches [
    set fire-interval  0     ; the time interval between the last two fires
    set last-fire-time 1     ; time of the last time the patch was burned
    set number-of-fires 0    ; the number of times the patch was burned
    set deforested false
    set deforested-time 1    ; the time of deforestation
    set pcolor green         ; All the patches are forest initially
    ;
  ]


  ;;
  ;; calculate power law exponent from dispersal distance, deriving the power exponent of a distribution with mean = birds-dispersal-distance
  ;;
  set powexp (1 - 2 * forest-dispersal-distance ) / (1 - forest-dispersal-distance )
  set powexp-fire (1 - 2 * fire-dispersal-distance ) / (1 - fire-dispersal-distance )

  ;;
  ;; Calculate forest growth probability
  ;;
  ifelse forest-growth = 0 [
    set forest-growth-prob 0

  ][
    set forest-growth-prob 1 / forest-growth
  ]
  set start-fire-season int ( ( 365 / 2 ) - ( days-fire-season / 2 ) )
  set end-fire-season   int ( start-fire-season + days-fire-season - 1 )

  ;print (word "INICIO: " start-fire-season " FIN: " end-fire-season " f-prob: " f-prob)

  ;; keep track of how many trees there are
  ;set initial-trees count patches with [pcolor = green]
  reset-ticks

  set-fire-prob-by-month
  set eval-burned-clusters-list read-from-string eval-burned-clusters

  set f-prob  world-width * world-height * fire-probability
  set parar false

  ;; initial-deforestion
  ;;
  ifelse initial-highway-deforestation [
    deforestation-roads initial-deforested-density
  ][                                   ;; Initial Random deforestation
    ask patches [

      if (random-float 1) < initial-deforested-density [
        ;show " Initial deforestation "

        set deforested true
        set pcolor black
      ]
    ]
  ]



  ;print video
  if video [
          vid:reset-recorder
          vid:start-recorder
          ;vid:record-interface
          vid:record-view
          ;print "Setup video"
        ]

end

to go
  ; Stops the model when ticks reach end-simulation or when pressing Stop Video button
  ;
  if ticks = end-simulation or parar [
    if video [
        ;print "Guardo video!!!!!!!!!!!!"
        let fname (word "DynamicFire_" initial-deforested-density "_" fire-probability "_" forest-dispersal-distance "_" forest-growth "_" ticks "_" world-height "_" world-width ".mp4")
        vid:save-recording fname
    ]
    ;export-fire-interval
    stop
  ]

  ;; Forest natural growth
  ask patches with [pcolor = green ] [
      grow-forest
  ]
  ifelse periodicity [
    set-fire-prob-by-month
    let day-of-year remainder ticks 365
    if (day-of-year = start-fire-season ) [

      set f-prob  world-width * world-height * fire-probability * increase-fire-prob-seasonality
      ;print (word "INICIO Day-of-year: " day-of-year " f-prob: " f-prob)

    ]
    if (day-of-year = end-fire-season ) [
;        let var-seasonality increase-fire-prob-seasonality / 2
;        let alpha increase-fire-prob-seasonality * increase-fire-prob-seasonality / var-seasonality
;        let lambda increase-fire-prob-seasonality / var-seasonality
;        let max-f-prob random-gamma alpha lambda
      set f-prob  world-width * world-height * fire-probability
      ;print (word "FIN Day-of-year: " day-of-year " f-prob: " f-prob)

    ]
  ][
    set-fire-prob-by-month
    set f-prob  world-width * world-height * fire-probability
  ]

  ;; Deforest forest
  ;;
  deforestation deforestation-prob

  ;; Deforested patches burn
  ;;
  ;print word "f-prob " f-prob
  ;print word "fire-probability " fire-probability
  set fire-patches random-poisson f-prob
  ask n-of fire-patches patches with [deforested] [
      burn-patch
  ]

  ;; Fire spread only in deforested patches after 1 year
  ;;
  ask patches with [ pcolor = red ] [                     ;; ask the burning trees
    ask neighbors4 with [deforested and (ticks - deforested-time > 365) and (ticks - last-fire-time) > 365 ] [        ;; ask deforested forest after 1 year to burn
      burn-patch
    ]
    ;;
    ;;
    let effective-dispersal  random-power-law-distance 1 powexp-fire

    ;; ask non deforested forest to burn with some probability  ADD HERE the power-law kernel to simulate probability of fire to a distance of actual fires.
    ;;
    ;; print (word "fire effective dispersal: " effective-dispersal)
    let non-deforested-neighbors max-one-of patches with [not deforested and (ticks - last-fire-time) > 365 ] in-radius effective-dispersal [distance self]
    ;;print (word "Dispersal set: " non-deforested-neighbors )
    if non-deforested-neighbors != nobody [
      ask non-deforested-neighbors [
        if random-float 1 < probability-of-spread [
          burn-patch
        ]
      ]
    ]

    set pcolor col-burned                                 ;; once the tree is burned, darken its color
  ]

  tick
  count-fires-export
;; advance the clock by one “tick”
end



to burn-patch
  ;print "Burn-patch"
  set pcolor red                                ;; to catch on fire
  set fire-interval  ticks - last-fire-time     ;; the time interval between the last two fires
  set last-fire-time ticks                      ;; time of the last time the patch was burned
  set number-of-fires number-of-fires + 1         ;; the number of times the patch was burned

end

;; Deforested forest can recover after 3 years (1095 days)
;;

to grow-forest
  if random-float 1 < forest-growth-prob
  [
    ;print "growth forest"
    let effective-dispersal  random-power-law-distance 1 powexp

    ask max-one-of patches in-radius effective-dispersal [distance self][
      ;show "max-one"
      ;;show (word "in-radius eff-disp " effective-dispersal " - Real distance " distance myself)
      if (pcolor = black or pcolor = col-burned) and ( ticks - deforested-time > 1095 or not deforested) and ( ticks - last-fire-time > 1095) [
         ;;show "growth forest"
         set deforested false
         set pcolor green
      ]
    ]
  ]
end

to-report random-power-law-distance [ xmin alpha ]
  ; median = xmin 2 ^( 1 / alpha )
  let dis xmin * (random-float 1) ^ (-1 / ( alpha - 1 ))
  if dis > world-width [set dis world-width]
  report dis
end

to count-fires-export
  let mes (ticks mod 30)

  if video [
    ;vid:record-interface
    vid:record-view
  ]

  ;if ticks > 7200 and mes = 0 [
  ;  if save-view [
  ;  ;print (word "Modulo Ticks : " mes " - " ticks)
  ;    let fname (word "Data/Fire_" initial-deforested-density "_" fire-probability "_" forest-dispersal-distance "_" forest-growth "_" ticks "_" world-height "_" world-width ".txt")
  ;    csv:to-file fname   [ (list pycor pxcor pcolor) ] of patches
  ;  ]
  ;]
end

to-report percent-burned
  report (count patches with [shade-of? pcolor red]) / total-forest
end

to-report percent-forest
  report (count patches with [pcolor = green]) / total-forest
end

to-report active-burned
  report (count patches with [pcolor = red]) / total-forest
end

to-report median-fire-interval
  let p-with-fire patches with [ last-fire-time > (ticks - 7300 ) and number-of-fires > 2]
  ifelse any? p-with-fire [
     report median [ fire-interval ] of p-with-fire
  ][
    report 0
  ]
end

to-report percent-deforested
  report (count patches with [deforested]) / total-forest
end

to read-fire-prob
  ifelse file-exists? fire-prob-filename [
    file-open fire-prob-filename ; open the file with the turtle data
                                            ;; To skip the header row in the while loop,
                                            ;  read the header row here to move the cursor down to the next line.
    let headings csv:from-row file-read-line
    let first-fecha ""

    ; We'll read all the data in a single loop
    while [ not file-at-end? ] [

      ; here the CSV extension grabs a single line and puts the read data in a list
      let fire_data csv:from-row file-read-line
      ;print fire_data
      let fecha        item 0 fire_data
      if empty? first-fecha [ set first-fecha fecha]
      let fireP        item 1 fire_data
      ;print (word "Date: " fecha " ProbFire: " fireP )
      set fire-prob-list lput fireP fire-prob-list
      if use-fire-prob-se [
        let firePse      item 2 fire_data
        ;print (word "Date: " fecha " ProbFire: " fireP " SE: " firePse )
        set fire-prob-list-se lput firePse fire-prob-list-se
      ]
    ]
    file-close ; make sure to close the file
    set periodicity false
    set tick-date time:anchor-to-ticks (time:create first-fecha) 1 "days"
    set end-simulation (length fire-prob-list) * 31                                 ; Simulate all the time in the file
  ][

    set tick-date time:anchor-to-ticks (time:create "2001-01-01") 1 "days"
  ]
end


to set-fire-prob-by-month
  ifelse not empty? fire-prob-list [
    let new-mes time:get "month" tick-date


    set actual-burned actual-burned + active-burned

    if last-mes != new-mes [
      set last-mes new-mes
      ifelse use-fire-prob-se [
        let fire-prob-mean ln item accum-mes fire-prob-list                                   ; prediction model has ln scale
        let fire-prob-se item accum-mes fire-prob-list-se                                     ; se was not exponentiated so no convertion is needed
        set fire-probability exp ( random-normal fire-prob-mean fire-prob-se ) / 30           ; Monthly probability have to be divided by 30
        ;print (word "mes: " accum-mes " fire-prob: " fire-probability " Fire-prob-mean: " fire-prob-mean  " Fire-prob-se: " fire-prob-se " Fecha: " ( time:show tick-date "yyyy-MM-dd" ))

      ][
        set fire-probability item accum-mes fire-prob-list / 30           ; Monthly probability have to be divided by 30
      ]
      set burned-by-month  actual-burned
      set actual-burned 0

      ;print (word "mes: " accum-mes " fire-prob: " fire-probability " Monthly burned: " burned-by-month  " Fecha: " ( time:show tick-date "yyyy-MM-dd" ))

      ;print word "Patch sizes: " burned-clusters 30
      set accum-mes accum-mes + 1
      if accum-mes  = ( length fire-prob-list ) [ set parar true ]

    ]
  ][
    let new-mes int ( ticks / 30 )
    set actual-burned actual-burned + active-burned
    if last-mes != new-mes [
      set last-mes new-mes
      set burned-by-month  actual-burned
      set actual-burned 0
      ;print (word "mes: " new-mes " last-mes: " last-mes " Monthly burned: " burned-by-month )

    ]
  ]
end

to export-fire-interval

    ;print (word "Modulo Ticks : " mes " - " ticks)
  let fname (word "Data/FireInterval_" nlrx-experiment "_" initial-deforested-density  "_" forest-dispersal-distance "_" forest-growth "_" ticks "_" world-height "_" world-width ".txt")
  csv:to-file fname   [ (list pycor pxcor fire-interval) ] of patches

end

to-report Date
  report time:show tick-date "yyyy-MM-dd"
end

;
; Hoshen–Kopelman algorithm for burned patches of the last "days" ticks
;
to-report burned-clusters [days]

  let cluster-sizes []
  if member? ticks eval-burned-clusters-list [
    let month-burned patches with [last-fire-time >= ticks - days] ;
    print (word "Ticks: " ticks " month-burned: " month-burned)
    if any? month-burned [
      ask month-burned [ set cluster-label 0 ]
      set month-burned sort month-burned
      let largest-label 0

      ;
      ; label clusters
      ;
      foreach month-burned [
        t -> ask t [

          let pleft patch-at -1 0  ; same row to the left x-1
          let pabove patch-at 0 1  ; same column abobew   y+1
          ifelse  not member? pabove month-burned and not member? pleft month-burned [
            ;show "NO neighbor!!!!"

            set largest-label largest-label + 1
            set cluster-label largest-label
          ][
            ifelse member? pleft month-burned and not member? pabove month-burned [
              ;show "LEFT neighbor!!!!"
              set cluster-label [cluster-label] of pleft
            ][
              ifelse member? pabove month-burned and not member? pleft month-burned [
                ;show "ABOVE neighbor!!!!"
                set cluster-label [cluster-label] of pabove
              ][
                ;show "BOTH neighbors!!!"
                let lblabove [cluster-label] of pabove
                let lblleft  [cluster-label] of pleft
                ifelse lblleft = lblabove [
                  set cluster-label lblleft
                ][
                  ifelse lblleft < lblabove [
                    set cluster-label lblleft
                    foreach month-burned [r -> ask r [ if cluster-label = lblabove[ set cluster-label lblleft] ] ]
                  ][
                    set cluster-label lblabove
                    foreach month-burned [r -> ask r [ if cluster-label = lblleft [ set cluster-label lblabove] ] ]
                  ]
                ]


              ]
            ]
          ]
        ]
      ]

      ;
      ;
      ;
      set month-burned patches with [member? self month-burned]
      let label-list [cluster-label] of month-burned
      ;print word "label-list: " label-list
      set label-list remove-duplicates label-list
      ;print word "label-list: " label-list

      foreach label-list [
        t -> set cluster-sizes lput count month-burned with [cluster-label = t] cluster-sizes
      ]
    ]
  ]
  report cluster-sizes

end



;
; Deforest adjacent to other deforested patch
;
to deforestation [ prob ]
  let deforest-forest random-poisson ( total-forest * prob )
  let count-deforest 0
  while [count-deforest < deforest-forest ][
    ;print word "Deforestation number: " deforest-forest
    ask up-to-n-of deforest-forest patches with [deforested and  ( member? true [not deforested] of neighbors4 )][
      ;;show "Before deforest"
      let one-not-deforested one-of neighbors4 with [not deforested ]
      if one-not-deforested != nobody [
        ask one-not-deforested [                                  ;; defores a not deforested neighbor
          ;;show "Deforest"
          set deforested true
          set deforested-time ticks   ;
          set pcolor black
        ]
      ]
    ]
    set count-deforest count patches with [deforested]

  ]
end

;
; Deforest adjacent to other deforested patch
;
to deforestation-roads [ prob ]
  let deforest-forest  total-forest * prob

  ;;print word "deforest-forest: " deforest-forest

  if deforest-forest > 0 [
    ;; Build ROADS using turtles
    ;;
    let deforest-forest-turtles 3 ;;deforest-forest / 1000
    let count-deforest 0

    set count-deforest count patches with [deforested]
    while [count-deforest <= (0.1 * deforest-forest)] [
      crt 1 [
        set color white
        set size 4
        let side random 4
        (ifelse side = 0 [ set xcor min-pxcor set ycor random-pycor set heading 90 lt random 90 rt random 90]
          side = 1 [ set ycor min-pycor set xcor random-pxcor set heading 0 lt random 90 rt random 90]
          side = 2 [ set xcor max-pxcor set ycor random-pycor set heading 270 lt random 90 rt random 90]
          side = 3 [ set ycor max-pycor set xcor random-pxcor set heading 180 lt random 90 rt random 45]
        )
        if abs [pxcor] of patch-ahead 0.1 = max-pxcor [ lt random 90  ]
        if abs [pycor] of patch-ahead 0.1 = max-pycor [ lt random 90  ]
        if abs [pxcor] of patch-ahead 0.1 = min-pxcor [ rt random 90  ]
        if abs [pxcor] of patch-ahead 0.1 = min-pycor [ rt random 90  ]

        ;;show (word "xcor: " xcor " ycor: "ycor " heading: " heading)
      ]
      display
      ;;print (word "Before deforestf: " deforest-forest " count-deforest: " count-deforest)
      ;;print word  "Total turtles before: " count turtles
      ask one-of turtles [
        ;;show "Turtle to deforest"
        let steps 0
        let border false
        while [not border] [
          fd 1
          ;;show "After fd"
          set steps steps + 1
          set deforested true
          set deforested-time ticks   ;
          set pcolor black
          ;;if ( abs pxcor = max-pxcor) or ( abs [pxcor] of patch-ahead 0.1 = max-pxcor) [ set border true  ]
          ;;if ( abs pycor = max-pycor) or ( abs [pycor] of patch-ahead 0.1 = max-pycor) [ set border true  ]
          ;;if ( abs pxcor = min-pxcor) or ( abs [pxcor] of patch-ahead 0.1 = min-pxcor) [ set border true  ]
          ;;if ( abs pycor = min-pycor) or ( abs [pycor] of patch-ahead 0.1 = min-pycor) [ set border true  ]
          if ( abs pxcor = max-pxcor) [ set border true  ]
          if ( abs pycor = max-pycor) [ set border true  ]
          if ( abs pxcor = min-pxcor) [ set border true  ]
          if ( abs pycor = min-pycor) [ set border true  ]

          ;;print (word "step: " steps " border: " border)
          ifelse steps > sqrt ( 2 * ( max-pxcor ^ 2 ) ) [
            ;;show "before die"
            die
            stop
          ]
          [
            if random-float 1 < 0.3 [
              fd random-poisson  ceiling ( max-pxcor / 50 )
            ]
          ]

        ]
        set count-deforest count patches with [deforested]
        ;;show (word "count-deforest and DIE: " count-deforest)
        display
        die
      ]
    ]
    ask turtles [ die ]
    if count-deforest < deforest-forest [
       let further-deforest prob - ( count-deforest  / total-forest )
       ;;print (word "further-deforest: " further-deforest " initial-deforest: " prob)
       deforestation further-deforest
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
275
10
778
514
-1
-1
1.1
1
10
1
1
1
0
0
0
1
0
449
0
449
1
1
1
ticks
30.0

MONITOR
800
305
912
350
percent burned
percent-burned * 100
4
1
11

SLIDER
10
10
257
43
Initial-deforested-density
Initial-deforested-density
0.0
1
0.05
0.001
1
NIL
HORIZONTAL

BUTTON
90
135
159
171
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
12
135
82
171
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
15
525
118
558
video
video
1
1
-1000

BUTTON
11
178
118
211
Stop Video
set parar true
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
225
240
258
Fire-probability
Fire-probability
0
.00001
6.929346060076389E-7
.0000001
1
NIL
HORIZONTAL

PLOT
800
12
1214
296
Fire dynamics
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Burned" 1.0 0 -12251123 true "" "plot burned-by-month * 100\nif ticks > 3600 \n[\n  ; scroll the range of the plot so\n  ; only the last 200 ticks are visible\n  set-plot-x-range (ticks - 3600) ticks                                       \n]\nif ticks mod 1095 = 0 \n[\n  set-plot-y-range 0  0.5                                        \n]"
"Active (x100)" 1.0 0 -2674135 true "" "plot active-burned * 100"

SLIDER
10
50
182
83
end-simulation
end-simulation
7200
14760
14973.0
360
1
NIL
HORIZONTAL

SWITCH
15
566
141
599
Save-view
Save-view
1
1
-1000

SLIDER
10
310
182
343
Forest-growth
Forest-growth
0
6000
1720.0
10
1
NIL
HORIZONTAL

SLIDER
10
270
242
303
forest-dispersal-distance
forest-dispersal-distance
1.01
100
1.2
0.01
1
NIL
HORIZONTAL

MONITOR
800
360
915
405
Percent Forest
Percent-forest
4
1
11

SWITCH
15
370
142
403
Periodicity
Periodicity
1
1
-1000

SLIDER
15
415
255
448
increase-fire-prob-seasonality
increase-fire-prob-seasonality
0
30
10.0
1
1
NIL
HORIZONTAL

PLOT
940
310
1225
570
fire-prob
NIL
NIL
0.0
10.0
0.0
1.0E-5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot f-prob"

MONITOR
800
420
937
465
median fire interval
median-fire-interval
4
1
11

SLIDER
15
460
187
493
days-fire-season
days-fire-season
0
180
90.0
1
1
NIL
HORIZONTAL

INPUTBOX
15
610
257
670
fire-prob-filename
Data/Estimated_bF.csv
1
0
String

MONITOR
805
585
1007
630
Date
Date
17
1
11

INPUTBOX
15
680
257
740
nlrx-experiment
NIL
1
0
String

INPUTBOX
275
680
517
740
eval-burned-clusters
[14671]
1
0
String

SWITCH
280
610
447
643
use-fire-prob-se
use-fire-prob-se
1
1
-1000

PLOT
1240
10
1590
290
Fire-interval
NIL
NIL
0.0
3500.0
0.0
10.0
true
false
"set-plot-x-range 0 10000\nset-histogram-num-bars 20" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [fire-interval] of patches with [ number-of-fires > 2 and last-fire-time > (ticks - 3650 )]"

PLOT
1240
310
1590
570
Percent Forest %
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot percent-forest\nif ticks > 3600 \n[\n  ; scroll the range of the plot so\n  ; only the last 200 ticks are visible\n  set-plot-x-range (ticks - 3600) ticks \n]\n\nif ticks mod 360 = 0 \n[\n  set-plot-y-range 0  precision ( percent-forest * 2)  2                                      \n]"

MONITOR
480
610
667
655
Forest power law exponent
powexp
4
1
11

SLIDER
550
685
742
718
deforestation-prob
deforestation-prob
0
.0001
1.0E-5
0.000001
1
NIL
HORIZONTAL

SLIDER
765
685
987
718
probability-of-spread
probability-of-spread
0
1
0.1
.01
1
NIL
HORIZONTAL

MONITOR
800
475
925
520
Percent Deforested
percent-deforested * 100
2
1
11

SLIDER
1025
685
1242
718
fire-dispersal-distance
fire-dispersal-distance
1.01
100
11.27
0.01
1
NIL
HORIZONTAL

BUTTON
545
740
687
773
SetupOnePatch
ask patches [ set deforested false set pcolor green]\nask patch 75 75 [ set deforested true set pcolor black ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
545
780
692
813
SetupOneForest
ask patches [ set deforested true set pcolor black]\nask patch 75 75 [ set deforested false set pcolor green ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
10
90
267
123
initial-highway-deforestation
initial-highway-deforestation
0
1
-1000

@#$#@#$#@
## ACKNOWLEDGMENT

## WHAT IS IT?

This model simulates the spread of a fire through a forest that suffers deforestation.  
It has some realistic features like the simulation of a fire-season or the reading of a file with ignition probabilities. The green pixels are are the ones with enough fuel to be burned, the magenta ones are deforested, the brown are burned without fuel, and the red are the actual burning ones. 


## HOW IT WORKS

## HOW TO USE IT

Click the SETUP button to set up the trees (green) and fire (red on the left-hand side).

Click the GO button to start the simulation.

The DENSITY slider controls the density of trees in the forest. (Note: Changes in the DENSITY slider do not take effect until the next SETUP.)

## THINGS TO NOTICE


## THINGS TO TRY


## EXTENDING THE MODEL


## NETLOGO FEATURES

The `neighbors4` primitive is used to spread the fire.


## RELATED MODELS

Fire, Percolation, Rumor Mill

## CREDITS AND REFERENCES

This model is based on:

* Wilensky, U. (1997).  NetLogo Fire model.  http://ccl.northwestern.edu/netlogo/models/Fire.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

## COPYRIGHT AND LICENSE

Copyright 2020 Leonardo A. Saravia

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
set density 60.0
setup
repeat 180 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="DispersalEffect" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>percent-burned</metric>
    <metric>percent-forest</metric>
    <enumeratedValueSet variable="Fire-probability">
      <value value="2.0E-7"/>
      <value value="1.0E-6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Save-view">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world500x000">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forest-dispersal-distance">
      <value value="1.01"/>
      <value value="2.01"/>
      <value value="10.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="video">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Forest-growth">
      <value value="360"/>
      <value value="1800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-simulation">
      <value value="14400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-forest-density">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Periodicity">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FireRegimes" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Fire-probability">
      <value value="1.3040349103855413E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="increase-fire-prob-seasonality">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-fire-season">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-prob-filename">
      <value value="&quot;Data/Estimated_bF.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Save-view">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world500x000">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forest-dispersal-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Forest-growth">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-simulation">
      <value value="14942"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-forest-density">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Periodicity">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
