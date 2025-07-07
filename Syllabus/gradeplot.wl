(* ::Package:: *)

SetDirectory[NotebookDirectory[]]
<<PlotTools`


(* ::Section:: *)
(*Final Grade Histogram*)


Grades={
  {90, "A+"}, {85, "A"},{80, "A-"},
  {77, "B+"}, {73, "B"},{70, "B-"},
  {67, "C+"}, {63,"C"}, {60, "C-"},
  {0.1, "\:4e0d\:53ca\:683c"}, {0, "\:4e0d\:6838\:4e88"},{-1, "\:68c4\:9078"}
};
Replacer = {"X" -> "\:4e0d\:6838\:4e88", "W" -> "\:68c4\:9078", "D" -> "\:4e0d\:53ca\:683c", "E" -> "\:4e0d\:53ca\:683c", "F" -> "\:4e0d\:53ca\:683c"};
Color[i_, j_] := Hue[{0.1, 0.24,0.4,0.56}[[i]], {0.3,0.4,0.5}[[j]] ,1]
ToGrade[s_] := If[StringQ[s], s, First[Select[Grades, s>=#[[1]]&]][[2]]] /. Replacer;
Stacks={
  {"\:68c4\:9078", "\:4e0d\:6838\:4e88", "\:4e0d\:53ca\:683c"},
  {"C-", "C", "C+"},
  {"B-", "B", "B+"},
  {"A-", "A", "A+"}
};

ToHistogram[score_, categories_]:=Block[{
    counts = Counts[ToGrade/@score],
    data, styled
  },
  Print[TextString[Length[score]] <> " data"];
  data = categories /. counts /. ({_String, b_String} :> {0, b});
  styled = Table[
    If[i <= Length[data] && j <= Length[data[[i]]], Style[data[[i, j]], Color[i, j]], None],
    {i, 10}, {j, 10}];
  styled=Select[(Select[#, #=!=None&]&/@styled), #=!={}&];
  BarChart[styled,
    ChartLayout->"Stacked",
    LabelingFunction->(Placed[categories[[#2[[1]],#2[[2]]]],Center]&),
    Ticks->None,
    Axes -> {True, False},
    LabelStyle->{16}
  ]
]
ToHistogram[score_] := ToHistogram[score, Stacks]

ToHistogram[{40, 50, 60, 70, 80, 90}]


(* ::Section:: *)
(*Scatter Plot*)


ExamScatter[data_, range_] := Module[{plot1, plot2, plot3},
  plot1 = Graphics[{PointSize[Large], Blue, Opacity[0.5], Point @ data}, Frame -> True, PlotRange->range[[1;;2, 1;;2]], LabelStyle->{16},
  GridLines->{{1,2,3,4,5},{1,2,3,4,5}}*10,FrameLabel->{"Midterm", "Term"}];
  plot2 = Histogram[data[[All, 1]], range[[1]], PlotRange->{range[[1,1;;2]], {0,Length[data]/2}}, Axes->None, PlotRangePadding->0];
  plot3 = Histogram[data[[All, 2]], range[[2]], PlotRange->{{0,Length[data]/2}, range[[2,1;;2]]}, Axes->None, PlotRangePadding->0, BarOrigin -> Left];
  ResourceFunction["PlotGrid"][{{plot2, None}, {plot1, plot3}}, 
    ItemSize -> {{300, 80}, {80, 300}}, AspectRatio -> 1]
  ];
ExamScatter[data_] := ExamScatter[data, {{0, 55, 5}, {0, 55, 5}}]
ExamScatter[{{10, 10}, {20, 20}, {30, 30}}]


(* ::Section:: *)
(*Description of Grading Formula*)


contours = {90, 85, 80, 77, 73, 70, 67, 63, 60} - 0.5;
contours2 = {90, 80, 70, 60} - 0.5;
Color[i_, j_] := Hue[{0.1, 0.24,0.4,0.56}[[i]], {0.3,0.4,0.5}[[j]] ,1]
f[core_, extra_] := Max[core, 0.62(core+Min[extra,30])+20]

Pos[0] = {47, 27};
Pos[1] = {64, 25};
Pos[2] = {81, 23};
Pos[3] = {95, 27};
D1[_] = {2, -3.5};
D2[_] = {5, -7};
ContourPlot[f[x, y], {x,40,100}, {y, 0, 30}, Contours->contours2, FrameLabel->{"Core score", "Performance"},  Epilog->{
  Inset[Text["C\[Minus]"], Pos[0]],
  Inset[Text["to"], Pos[0] + D1[0]],
  Inset[Text["C+"], Pos[0] + D2[0]],
  Inset[Text["B\[Minus]"], Pos[1]],
  Inset[Text["to"], Pos[1] + D1[1]],
  Inset[Text["B+"], Pos[1] + D2[1]],
  Inset[Text["A\[Minus]"], Pos[2]],
  Inset[Text["to"], Pos[2] + D1[2]],
  Inset[Text["A"],  Pos[2] + D2[2]],
  Inset[Text["A+"], Pos[3]]
}, BaseStyle->{FontSize->24}, ImageSize->Medium, MaxRecursion->0]
