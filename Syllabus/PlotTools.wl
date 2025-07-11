(* ::Package:: *)

(* :Time-Stamp: <2024-04-13 15:10:47> *)
(* :Package Version: 1.2.0 *)

(* :Title: PlotTools *)
(* :Context: PlotTools` *)
(* :Mathematica Version: "13+" *)

(* :Author: Sho Iwamoto / Misho *)
(* :Copyright: 2018-2022 Sho Iwamoto / Misho *)
(* This file is licensed under the Apache License, Version 2.0.
   You may not use this file except in compliance with it. *)

(* :History:
   1.0.0 (2022 Apr.) initial version
   1.1.0 (2022 May)  adopt to Mathematica 13.0 causing problems in FrameTicks
   1.2.0 (2023 Sep.) enforce Black in FrameStyle. Use CapStyle[None].
   2.0.0 (2023 Sep.) use ResourceFunction/PolygonMarker.
*)

BeginPackage["PlotTools`"];

MainFileName::usage = "MainFileName[] returns the main file name.";
EvaluatePlot::usage = "EvaluatePlot[object] fixes Tick-related problems appearing in Mathematica 13.0.";
OutputPDF::usage = "OutputPDF[object, suffix] exports object to PDF file, whose name is suffixed by suffix.";

Pixel::usage = "The unit of \"px\" on Mathematica Notebook.";
TicksLength::usage = "Set the length of ticks.";

(* plot helper *)
LaTeX::usage = "Invoke MaTeX with # instead of \\.";
LaTeXParams::usage = "Generate parameter list using MaTeX.";

colors::usage = "Return arranged colors.";
color::usage = "Return an arranged color.";
markers::usage = "Return arranged markers.";
marker::usage = "Return an arranged marker.";

LinLabelFormat::usage = "Specity tick format for linear axes.";
LogLabelFormat::usage = "Specity tick format for log axes.";
LinTicks::usage = "LinTicks[min, max] generates FrameTick for linear axes.";
LogTicks::usage = "LogTicks[min, max] generates FrameTick for log axes.";
FakeLog10Ticks::usage = "Fake10LogTicks[min, max] generates FrameTick for fake-log axes.";

OverrideGrids::usage = "Override GridLines of a graphic.";
OverrideTicks::usage = "Override FrameTicks with specified ticks, which may be generated by LinTicks and LogTicks.";

(* messages *)
PlotTools::WithoutMaTeX = "Package \"MaTeX\" not found; related features are turned off.";
PlotTools::WithoutPolygonPlotMarkers = "Package \"PolygonPlotMarkers\" not found; related features are turned off.";
OverrideGrids::Multiple = "The graphic has multiple GridLines.";


(* ::Subsubsection:: *)
(*Basic definitions*)


Begin["`Private`"];
dpi = 72;
Pixel = 100/dpi;

(* CONFIG in Pixel *)
TicksLength = {3, 2};


(* ::Subsubsection:: *)
(*PDF output*)


SyntaxInformation[MainFileName]={"ArgumentsPattern"->{}};
MainFileName[] := With[{ candidate = FileBaseName[If[$FrontEnd === Null, $Input, NotebookFileName[]]] },
  If[StringQ[candidate], Return[candidate]];
  Return["unknown"]];

SyntaxInformation[OutputPDF]={"ArgumentsPattern"->{_, _.}};
SetAttributes[OutputPDF, HoldFirst];
OutputPDF[obj_, title_String:None] := With[{
    t = If[StringQ[title], title, TextString[HoldForm[obj]]],
    prefix = MainFileName[] // If[StringQ[#], #, "unknown"]&
  },
  Export[prefix <> "_" <> t <> ".pdf", Magnify[EvaluatePlot[obj], 1]]];

EvaluatePlot[obj_] := Block[{range = Quiet[AbsoluteOptions[obj, PlotRange]], x, y, cases},
  If[Length[range[[1,2]]] =!= 2, Return[obj]];
  cases = (LinTicks | LogTicks | LogTicksExp | FakeLog10Ticks | RLinTicks | RLogTicks | RLogTicksExp );
  {x, y} = range[[1, 2]];
  obj //. {
    (FrameTicks->{{a___, b:cases, c___}, any_}) :> (FrameTicks->{{a, b@@y, c}, any}),
    (FrameTicks->{any_, {a___, b:cases, c___}}) :> (FrameTicks->{any, {a, b@@x, c}})
  }
]


(* ::Subsubsection:: *)
(*Customized colors*)


(* Color Scheme good for color-blind and monochromatic; cf. https://github.com/misho104/scicolpick ; colordistance 29.67 *)
colorsText = {"#000e83", "#a20d2c", "#3b7bcf", "#62cf44", "#ffbdf6"};
colors = RGBColor /@ colorsText;
colorsExpanded = Outer[Lighter, colors, {0, 0.2, 0.4, 0.6}] // Transpose // Flatten;
SyntaxInformation[color]={"ArgumentsPattern"->{_}};
color[i_Integer] := Which[
  TrueQ[i==0], RGBColor["#000000"],
  TrueQ[i<0],  Message[color::partd]; Abort[];,
  True,        colors[[1+Mod[i-1, Length[colorsText]]]]];


(* ::Subsubsection:: *)
(*Customized markers*)


(* Mathematica's font-based markers have alignment issue; use graphic-based markers
  https://mathematica.stackexchange.com/questions/84857/
  https://github.com/AlexeyPopkov/PolygonPlotMarkers/ *)

Options[FilledMarker] = {PointSize -> 3};
Options[EmptyMarker] = {PointSize -> 3, Thickness -> 0.75, FaceForm -> Transparent};
SyntaxInformation[FilledMarker] = {"ArgumentsPattern"->{_, OptionsPattern[]}};
SyntaxInformation[EmptyMarker] = {"ArgumentsPattern"->{_, OptionsPattern[]}};
FilledMarker[name_, OptionsPattern[]] := Graphics[{
    EdgeForm[], PolygonMarker[name, Offset[OptionValue[PointSize]Pixel]]
  },
  AlignmentPoint -> {0, 0}];
EmptyMarker[name_, OptionsPattern[]] := Graphics[{
    Dynamic@EdgeForm@Directive[CurrentValue["Color"], JoinForm["Round"], AbsoluteThickness[OptionValue[Thickness]Pixel], Opacity[1]],
    FaceForm[OptionValue[FaceForm]],
    PolygonMarker[name, Offset[OptionValue[PointSize]Pixel]]
  },
  AlignmentPoint -> {0, 0}];

markerNames = {"Circle", "Square", "Diamond", "Triangle", "DownTriangle", "EmptyCircle", "EmptySquare", "EmptyDiamond", "EmptyTriangle", "EmptyDownTriangle", "FivePointedStar", "Plus", "Cross"};

IsPPMLoaded = Not[FailureQ[Quiet[ResourceFunction["PolygonMarker"]]]];
If[IsPPMLoaded === True,
  coords = Symbol[ResourceFunction["PolygonMarker", "Context"] <> "coords"];
  coords["|"] = {{-0.1, 1}, {0.1, 1}, {0.1, 0}, {0.1, -1}, {-0.1, -1}, {-0.1, 0}} * Sqrt[2.5];
  coords["-"] = {{1, 0.1}, {1, -0.1}, {0, -0.1}, {-1, -0.1}, {-1, 0.1}, {0, 0.1}} * Sqrt[2.5];
  PolygonMarker = ResourceFunction["PolygonMarker", "Function"];
  marker[name_String, options___] := If[TrueQ[StringStartsQ[name, "Empty"]], EmptyMarker[StringDrop[name, 5], options], FilledMarker[name, options]];
  marker[i_Integer, options___] := If[TrueQ[i>0], marker[markerNames[[Mod[i-1, Length[markerNames]]+1]], options], Message[marker::partd]; Abort[]];
  markers = marker /@ markerNames;
  ,
  Message[PlotTools::WithoutPolygonPlotMarkers];
  markers = Graphics`PlotMarkers[];
  marker[i_Integer, options___] := If[TrueQ[i>0], markers[[Mod[i-1, Length[markers]]+1]], Message[marker::partd]; Abort[]];
  marker[name_String, options___] := With[{pos = FirstPosition[markerNames, name]}, If[Length[pos] === 1, marker[First[pos], options], Message[marker::partd]; Abort[]]];
  FilledMarker[name_, OptionsPattern[]] := (Message[PlotTools::WithoutPolygonPlotMarkers]; Abort[]);
  EmptyMarker[name_, OptionsPattern[]] := (Message[PlotTools::WithoutPolygonPlotMarkers]; Abort[]);
];


(* ::Subsubsection:: *)
(*MaTeX*)


IsMaTeXLoaded = Not[FailureQ[Quiet[Needs["MaTeX`"]]]];
MaTeXPreamble = {
  "\\usepackage{exscale,amsmath,amssymb,color,newtxtext}",
  "\\usepackage[varvw]{newtxmath}",
  ("\\definecolor{col" <> TextString[#[[2]]] <> "}{RGB}" <> ToString[StringTake[#[[1]], {{2,3},{4,5},{6,7}}] // Interpreter["HexInteger"]]) & /@ MapIndexed[Flatten[{##}] &, colorsText]
} // Flatten;

Attributes[LaTeXParamsSub] = {HoldAll};
LaTeXParamsSub[a_Symbol]    := {TextString[HoldForm[a]]<>" = "<>TextString[ReleaseHold[a]]//ReleaseHold}
LaTeXParamsSub[Rule[a_,b_]] := {TextString[HoldForm[a]]<>" = "<>TextString[ReleaseHold[b]]//ReleaseHold}
LaTeXParamsSub[a__,b_]      := Join[LaTeXParamsSub[a],LaTeXParamsSub[b]]
LaTeXParamsSub[{a__,b_}]    := Join[LaTeXParamsSub[a],LaTeXParamsSub[b]]

If[IsMaTeXLoaded,
  SetOptions[MaTeX, FontSize->12Pixel, "BasePreamble"->MaTeXPreamble, ContentPadding->False];
  (* Allow to use # instead of backslash *)
  SyntaxInformation[LaTeX] = {"ArgumentsPattern"->{_, OptionsPattern[MaTeX]}};
  LaTeX[cmd_String, opts:OptionsPattern[MaTeX]] := MaTeX[StringReplace[cmd, "#"->"\\"], opts];
  LaTeX[cmd_List, opts:OptionsPattern[MaTeX]] := MaTeX[StringReplace["#"->"\\"]/@cmd, opts];
  Attributes[LaTeXParams]={HoldAll};
  Options[LaTeXParams]={Method->"align"};
  LaTeXParams[args__, OptionsPattern[]] := With[{p = LaTeXParamsSub[args]}, Switch[OptionValue[Method],
    "align",     StringRiffle[StringReplace[#, "="->"&=", 1]&/@p, {"#begin{aligned}\n","##\n", "#end{aligned}"}],
    "alignleft", StringRiffle[("&"<>#)&/@p, {"#begin{aligned}\n","##\n", "#end{aligned}"}],
    "rowspace",  StringRiffle[p,"~~~"],
    _,           StringRiffle[p,",~"]]] // LaTeX;
  ,
  Message[PlotTools::WithoutMaTeX];
]


(* ::Subsubsection:: *)
(*FrameTicks*)


SyntaxInformation[LinLabelFormat] = {"ArgumentsPattern"->{_, _, OptionsPattern[]}};
Options[LinLabelFormat] = {};
LinLabelFormat[value_, origLabel_, OptionsPattern[]] := origLabel;

Options[LogLabelFormat] = {"RawRange" -> {0.1, 99}, "Separator" -> "\[CenterDot]"};
SyntaxInformation[LogLabelFormat] = {"ArgumentsPattern"->{_, _, OptionsPattern[]}};
LogLabelFormat[value_, origLabel_, OptionsPattern[]] := Module[{m, exp, mstr, v=Exp[value]},
  If[MatchQ[origLabel, _Spacer], Return[origLabel]];
  If[Between[v, OptionValue["RawRange"]], Return[StringTrim[TextString[v], RegularExpression["\\.0*$"]]]];
  {m, exp} = With[{r = MantissaExponent[v]}, {r[[1]]*10, r[[2]]-1}];
  mstr = StringTrim[TextString[m], RegularExpression["\\.0*$"]];
  If[mstr == "10", mstr = "1"; exp += 1];
  Switch[exp,
    0, mstr,
    1, If[mstr==="1", "10", mstr<>OptionValue["Separator"] <> "10"],
    _, If[mstr==="1", Superscript["10", exp], Row[{mstr<>OptionValue["Separator"], Superscript["10", exp]}]]
]]

(* TickLength is relative value to the plot region (320Pixel - (60+20) Pixel) *)
TickLength[label_] := If[MatchQ[label, _Spacer], {TicksLength[[2]]/240,0}, {TicksLength[[1]]/240,0}];
RemoveLabels[x_List] := {#[[1]], Spacer[List[0,0]], #[[3]]} &/@ x;
RemoveLabels[x:LinTicks|LogTicksExp|LogTicks] := RemoveLabels@*x;
RemoveLabels[x:Automatic|None] := x;

LinTicks[min_, max_, args___] := With[{
    original = Charting`ScaledTicks[{Identity, Identity}][min, max, args]
  },
  {#[[1]], LinLabelFormat[#[[1]], #[[2]]], TickLength[#[[2]]]} &/@ original]
LogTicks[min_, max_, args___] := With[{
    original = Charting`ScaledTicks[{Log, Exp}][Log[min], Log[max], args]
  },
  {#[[1]], LogLabelFormat[#[[1]], #[[2]]], TickLength[#[[2]]]} &/@ original]
LogTicksExp[args___] := {Exp[#[[1]]], #[[2]], #[[3]]} &/@ LogTicks[args]
FakeLog10Ticks[min_, max_, args___] := With[{
       original = Charting`ScaledTicks[{Log10, 10^# &}][min, max, args]
     },
    {#[[1]], LogLabelFormat[#[[1]] Log[10], #[[2]]],
     PlotTools`Private`TickLength[#[[2]]]} & /@ original]

RLinTicks[args___] := LinTicks[args] // RemoveLabels
RLogTicks[args___] := LogTicks[args] // RemoveLabels
RLogTicksExp[args___] := LogTicksExp[args] // RemoveLabels

FrameTicksType[_]                               := {{LinTicks,    RLinTicks},    {LinTicks,    RLinTicks}};
FrameTicksType[LogPlot|ListLogPlot]             := {{LogTicksExp, RLogTicksExp}, {LinTicks,    RLinTicks}};
FrameTicksType[LogLogPlot|ListLogLogPlot]       := {{LogTicksExp, RLogTicksExp}, {LogTicksExp, RLogTicksExp}};
FrameTicksType[LogLinearPlot|ListLogLinearPlot] := {{LinTicks,    RLinTicks},    {LogTicksExp, RLogTicksExp}};
(* Recent Mathematica somehow needs to use verbose [##]& in order to handle GridLines->Automatic properly. *)
FrameTicksType[ListPlot]                        := {{LinTicks[##]&, RLinTicks},  {LinTicks[##]&, RLinTicks}};


(* ::Subsubsection:: *)
(*The Style*)


(* ::Text:: *)
(*We can check the default style by Charting`ResolvePlotTheme[Automatic, Plot].*)


MishoStyle = Module[{
    (* original style = Detailed *)
    s = Charting`ResolvePlotTheme["Detailed", Plot] //. List[a:_Rule..]:>Association[a]
  },
  s[GridLines] = Automatic;
  s[GridLinesStyle] = Directive[GrayLevel[100/255, 0.4], AbsoluteThickness[0.25Pixel], AbsoluteDashing[{1,2}Pixel]];
  s[LabelStyle] = {Black, FontFamily->"Times New Roman", FontSize->12Pixel};
  s[Method]["DefaultPlotStyle"] = Thread@Directive[colorsExpanded, AbsoluteThickness[1Pixel], CapForm[None]];
  s[Method]["DefaultMeshStyle"] = AbsolutePointSize[5Pixel];
  s[Method]["DefaultIntervalMarkersStyle"] = CapForm[None];
  s[FrameStyle] = Directive[AbsoluteThickness[0.25Pixel], GrayLevel[0.5], FontColor -> Black];
  s[FrameTicksStyle] = Directive[AbsoluteThickness[0.25Pixel], GrayLevel[0.5], FontColor->Black];

  s//.{x_Association:>Normal[x]}//Normal
];
Themes`AddThemeRules["MishoStyle", MishoStyle];

SetOptions[#,
  (* PlotTheme -> "MishoStyle", *)
  Sequence@@MishoStyle,
  ImageSize -> {320 Pixel, Automatic},
  FrameTicks -> FrameTicksType[#],
  ImagePadding -> {{60, 20}, {60, 20}} Pixel,
  PlotRangePadding -> None
] &/@ {Plot, LogPlot, LogLogPlot, LogLinearPlot, ListPlot, ListLogPlot, ListLogLogPlot, ListLogLinearPlot, ContourPlot, ListContourPlot, StackedListPlot, ListStepPlot, RegionPlot};


(* ::Subsubsection:: *)
(*Override Ticks and Grids*)


SyntaxInformation[OverrideGrids] = {"ArgumentsPattern"->{_, _}};
OverrideGrids[xGrid:(_List|Automatic), yGrid:(_List|Automatic)] := Function[plot, Module[{tmp, xOrig=None, yOrig=None},
  tmp = Cases[plot, Rule[GridLines,g_]:>g, -1];
  If[Length[tmp] > 0, {xOrig, yOrig} = First[tmp]];
  plot /. {Rule[GridLines,_] -> Rule[GridLines, {If[xGrid === Automatic, xOrig, xGrid], If[yGrid === Automatic, yOrig, yGrid]}]}]]

SyntaxInformation[OverrideTicks] = {"ArgumentsPattern"->{_, _, _., _.}};
OverrideTicks[xTick1:(_List|Automatic), yTick1:(_List|Automatic), xTick2:(_List|Automatic), yTick2:(_List|Automatic)] := Function[plot,
  Module[{tmp, xOrig1=None, yOrig1=None, xOrig2=None, yOrig2=None, xNew1, xNew2, yNew1, yNew2, xGrid, yGrid},
    tmp = Cases[plot, Rule[FrameTicks,g_]:>g, -1];
    If[Length[tmp] > 0, {{yOrig1, yOrig2}, {xOrig1, xOrig2}} = First[tmp]];
    xNew1 = If[xTick1 === Automatic, xOrig1, xTick1];
    yNew1 = If[yTick1 === Automatic, yOrig1, yTick1];
    xNew2 = If[xTick2 === Automatic, RemoveLabels[xNew1], xTick2];
    yNew2 = If[yTick2 === Automatic, RemoveLabels[yNew1], yTick2];
    xGrid = TicksToGrid[xNew1, xNew2];
    yGrid = TicksToGrid[yNew1, yNew2];
(*Print[{xNew1, xNew2, yNew1, yNew2, xGrid, yGrid}]; *)
    plot /. {Rule[FrameTicks,_] -> Rule[FrameTicks, {{yNew1, yNew2}, {xNew1, xNew2}}]} // OverrideGrids[xGrid, yGrid]
  ]
];
TicksToGrid[t1_, t2_] := Which[
  Head[t1] === Head[t2] === List, Select[Join[t1, t2], Head[#[[2]]]=!=Spacer&][[All,1]] // DeleteDuplicates,
  Head[t1] === List,              Select[t1,           Head[#[[2]]]=!=Spacer&][[All,1]] // DeleteDuplicates,
  t1 === None,                    None,
  True,                           Automatic
];

OverrideTicks[xTick1:(_List|Automatic), yTick1:(_List|Automatic)] := OverrideTicks[xTick1, yTick1, Automatic, Automatic]


End[];
EndPackage[];
