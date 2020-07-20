\ProvidesClass{LSR_thesis}[2016/04/05 class for LSR slides]
\typeout{-- 2018/03/20 revision V0.4 by V.Gabler}
\typeout{-- 2017/07/24 revision V0.3 by D.Wollherr}
\typeout{-- 2017/01/17 revision V0.2 by V.Gabler}
\typeout{-- 2016/04/05 revision V0.1 by V.Gabler}
\typeout{-- This is early beta.}
\NeedsTeXFormat{LaTeX2e}

% define flags in use
\newif\if@langGer      \global\@langGertrue
\newif\if@typeFinal    \global\@typeFinaltrue
\newif\if@addAddress   \global\@addAddresstrue
\newif\ifLSRITRtutorial \LSRITRtutorialfalse


% define style input options
\DeclareOption{LSR}{\def\@institute{LSR}}%
\DeclareOption{ITR}{\def\@institute{ITR}}%
\DeclareOption{german}{\@langGertrue}
\DeclareOption{english}{\@langGerfalse}
\DeclareOption{final}{\@typeFinaltrue}
\DeclareOption{intermediate}{\@typeFinalfalse}
\DeclareOption{BA}{\def\@worktype{BA}}%
\DeclareOption{DA}{\def\@worktype{DA}}%
\DeclareOption{MA}{\def\@worktype{MA}}%
\DeclareOption{HS}{\def\@worktype{HS}}%
\DeclareOption{PP}{\def\@worktype{PP}}%
\DeclareOption{SeA}{\def\@worktype{SeA}}%
\DeclareOption{IP}{\def\@worktype{IP}}%
\DeclareOption{FP}{\def\@worktype{FP}}%
\DeclareOption{homeless}{\@addAddressfalse}
\DeclareOption{tutorial}{\LSRITRtutorialtrue}

% default to german
\ExecuteOptions{german}
% default to final submission
\ExecuteOptions{final}
% make it into effect
\ProcessOptions

% so far only standard format
\LoadClass[a4paper,twoside, openright,12pt]{report}

% load packages
\RequirePackage{subfigure}
\RequirePackage{verbatim}
\RequirePackage{psfrag,amsmath,amssymb,amsbsy,graphics,float}
\RequirePackage{graphicx, color, soul}
\RequirePackage{pdfpages}
\RequirePackage{ifthen}
\RequirePackage{anyfontsize}
\RequirePackage{ifxetex}
\if@langGer
 \RequirePackage[ngerman]{babel}
 \ifxetex
   \RequirePackage{fontspec}
 \else
   \RequirePackage[utf8]{inputenc}
 \fi
\else
 \ifxetex
   \RequirePackage{fontspec}
 \else
   \RequirePackage[latin1]{inputenc}
 \fi
\fi
% tutorial / explanation settings
\ifLSRITRtutorial
\RequirePackage[colorinlistoftodos]{todonotes}        % for handling TODOs
	\newcommand{\add}[2][]{\todo[color=blue!40,#1]{#2}{}}
	\newcommand\optional[2][]{\todo[inline, color=cyan!40, caption={2do},
	#1]{\begin{minipage}{\textwidth-4pt}#2\end{minipage}}{}}
\else
	\RequirePackage[disable]{todonotes}        % for handling TODOs
	\newcommand{\add}[2][]{{#2}}
	\newcommand\optional[2][]{{#2}}
\fi



% some helper variables for \ifx
\def\@worktypeDA{DA}
\def\@worktypeBA{BA}
\def\@worktypeMA{MA}
\def\@worktypeHS{HS}
\def\@worktypePP{PP}
\def\@worktypeSeA{SeA}
\def\@worktypeIP{IP}
\def\@worktypeFP{FP}
\def\@instituteLSR{LSR}
\def\@instituteITR{ITR}

\newdimen\LSRx
\newdimen\LSRzero
\newdimen\LSRborder
\LSRborder 6mm
\LSRx 10mm
\LSRzero 10pt



%%%%%%%%%%%%%%%%%%%%%%%
%%% Logo definitions
%%%%%%%%%%%%%%%%%%%%%%%
\RequirePackage{tikz}
\@ifpackagelater{tikz}{2013/12/13}{%
	% Package is new enough
}{%
\PackageError{tikz}{Package tikz is too old, please install at least version 3.0.0.}%
\endinput
}
\usetikzlibrary{calc}
\tikzset{
  tumlogo/.pic={
    \fill[pic actions]
    (-0.95,  0.5 ) --
    (-0.22,  0.5 ) --
    (-0.22, -0.32) --
    (-0.02, -0.32) --
    (-0.02,  0.5 ) --
    ( 0.95,  0.5 ) --
    ( 0.95, -0.5 ) --
    ( 0.75, -0.5 ) --
    ( 0.75,  0.32) --
    ( 0.55,  0.32) --
    ( 0.55, -0.5 ) --
    ( 0.37, -0.5 ) --
    ( 0.37,  0.32) --
    ( 0.16,  0.32) --
    ( 0.16, -0.5 ) --
    (-0.4 , -0.5 ) --
    (-0.4 ,  0.32) --
    (-0.6 ,  0.32) --
    (-0.6 , -0.5 ) --
    (-0.79, -0.5 ) --
    (-0.79,  0.32) --
    (-0.95,  0.32) -- cycle;
  }
}
\tikzset{
  lsrlogo/.pic={
        \fill[tum_blue]
        (-0.42,  0.37) --
        (-0.17,  0.25) --
        (-0.17,  0.32) --
        ( 0.32,  0.32) --
        ( 0.32, -0.07) --
        (-0.17, -0.07) --
        (-0.17, -0.17) --
        ( 0.42, -0.17) --
        ( 0.42,  0.42) --
        (-0.17,  0.42) --
        (-0.17,  0.5 ) --   cycle;
    \fill[lsr_red]
        ( 0.42, -0.37) --
        ( 0.17, -0.5 ) --
        ( 0.17, -0.42) --
        (-0.42, -0.42) --
        (-0.42,  0.17) --
        ( 0.17,  0.17) --
        ( 0.17,  0.07) --
        (-0.32,  0.07) --
        (-0.32, -0.32) --
        ( 0.17, -0.32) --
        ( 0.17, -0.25) --   cycle;
  }
}
\tikzset{
  itrlogo/.pic={
  %\begin{scope}[cm={{1.66944,0.0,0.0,1.41938,(-20.65341,-29.76687)}}]% g2985
  \begin{scope}[cm={{.166944,0.0,0.0,-.141938,(-2.3,4.6)}}]% g2985
       % path5
       
    \path[fill=itr_blue] (1.7147,38.0926) -- (1.7147,25.9804) -- (4.2352,25.9804) --
      (4.2352,38.0926) -- (1.7147,38.0926) -- cycle;

    % path7
    \path[fill=itr_blue] (8.7700,38.0926) -- (8.7700,27.6418) -- (4.4325,27.6418) --
      (4.4325,25.9804) -- (15.6362,25.9804) -- (15.6362,27.6418) --
      (11.2987,27.6418) -- (11.2987,38.0926) -- (8.7700,38.0926) -- cycle;

    % path9
    \path[fill=itr_blue] (15.8300,38.0926) -- (15.8300,25.9804) -- (20.3640,25.9804)
      .. controls (22.8248,25.9804) and (24.0547,26.9817) .. (24.0547,28.9839) ..
      controls (24.0547,29.7313) and (23.8463,30.4120) .. (23.4286,31.0257) ..
      controls (23.0113,31.6394) and (22.4371,32.1100) .. (21.7061,32.4375) --
      (25.6672,38.0926) -- (22.5983,38.0926) -- (19.5947,33.1414) --
      (18.2036,33.1414) -- (18.2036,38.0926) -- (15.8300,38.0926) --
      cycle(18.2036,31.4800) -- (18.7846,31.4800) .. controls (20.6124,31.4800) and
      (21.5260,30.7408) .. (21.5260,29.2620) .. controls (21.5260,28.1816) and
      (20.7104,27.6414) .. (19.0790,27.6414) -- (18.2032,27.6414) --
      (18.2032,31.4800) -- cycle;
      \end{scope}
  }
}

%%%%%% TUM Corporate Design Colors
\definecolor{tum_blue}{rgb} {0.00,0.40,0.74}
\definecolor{tum_dblue}{rgb}{0.00,0.20,0.35}
\definecolor{tum_lblue}{rgb}{0.39,0.63,0.78}
\definecolor{lsr_blue}{rgb}{0.63,0.73,0.91}

\definecolor{tum_lgray}{rgb}{0.85,0.85,0.86}
\definecolor{tum_mgray}{rgb}{0.45,0.46,0.46}
\definecolor{tum_gray}{rgb}{0.60,0.61,0.61}
\definecolor{tum_dgray}{rgb}{0.35,0.35,0.35}

\definecolor{tum_red} {rgb}{0.77,0.03,0.09}
\definecolor{tum_dred}{rgb}{0.61,0.05,0.09}
\definecolor{lsr_red} {rgb}{0.55,0.00,0.16}

\definecolor{tum_green} {rgb}{0.64,0.68,0.0}
\definecolor{tum_dgreen}{rgb}{0.0,0.49,0.19}
\definecolor{tum_lgreen}{rgb}{0.4,0.60,0.11}

\definecolor{tum_orange}{rgb}{0.89,0.45,0.13}
\definecolor{tum_ivory} {rgb}{0.86,0.84,0.80}
\definecolor{tum_purple}{rgb}{0.41,0.03,0.35}
\definecolor{tum_violet}{rgb}{0.06,0.11,0.37}
\definecolor{tum_yellow}{rgb}{1.00,0.71,0.00}




%_______Kopf- und Fußzeile_______________________________________________________
\RequirePackage{fancyhdr}
\pagestyle{fancy}
%um Kopf- und Fußzeile bei chapter-Seiten zu reaktivieren
\newcommand{\helv}{%
   \fontfamily{phv}\fontseries{a}\fontsize{9}{11}\selectfont}
\fancypagestyle{plain}{	
	\fancyfoot{}% keine Fußzeile
	\fancyhead[RE]{\helv\leftmark}% Rechts auf geraden Seiten=innen; in \leftmark stehen \chapters
	\fancyhead[LO]{\helv\rightmark}% Links auf ungeraden Seiten=außen;in \rightmark stehen \sections
	\fancyhead[RO,LE]{\thepage}}%Rechts auf ungeraden und links auf geraden Seiten
%Kopf- und Fußzeile für alle anderen Seiten
\fancyfoot{}
\fancyhead[RE]{\helv\leftmark}
\fancyhead[LO]{\helv\rightmark}%alt:\fancyhead[LO]{\itshape\rightmark}
\fancyhead[RO,LE]{\thepage}
%________________________________________________________________________________


%_Definieren der Ränder und Längen__________
\setlength{\textwidth}{15cm}
\setlength{\textheight}{22cm}
\setlength{\evensidemargin}{-2mm}
\setlength{\oddsidemargin}{11mm}
\setlength{\headwidth}{15cm}
\setlength{\headheight}{15pt}
\setlength{\topmargin}{10mm}
\setlength{\parindent}{0pt} % Kein Einrücken beim Absatz!!
%___________________________________________

%_Hyperref for CC Url__________
\RequirePackage{hyperref}
%___________________________________________


%_________select correct heading________________
\if@langGer
  \typeout{-- language set to german.}
  \ifx\@worktype\@worktypeDA
    \def\@worktypetext{DIPLOMARBEIT}
    \typeout{-- Type: Diplomarbeit.}
  \else
  \ifx\@worktype\@worktypeBA
    \def\@worktypetext{BACHELORARBEIT}
    \typeout{-- Type: Bachelorarbeit.}
  \else
  \ifx\@worktype\@worktypeMA
    \def\@worktypetext{MASTERARBEIT}
    \typeout{-- Type: Masterarbeit.}
  \else
  \ifx\@worktype\@worktypeHS
    \def\@worktypetext{HAUPTSEMINAR}
    \typeout{-- Type: Hauptseminar.}
  \else
  \ifx\@worktype\@worktypePP
    \def\@worktypetext{PROJEKTPRAKTIKUM}
    \typeout{-- Type: Projektpraktikum.}
  \else
  \ifx\@worktype\@worktypeSeA
    \def\@worktypetext{SEMESTERARBEIT}
    \typeout{-- Type: Semesterarbeit.}
  \else
  \ifx\@worktype\@worktypeIP
    \def\@worktypetext{INGENIEURPRAXIS}
    \typeout{-- Type: Industriepraxis.}
  \else
  \ifx\@worktype\@worktypeFP
    \def\@worktypetext{FORSCHUNGSPRAXIS}
    \typeout{-- Type: Forschungspraxis.}
  \else
    \def\@worktypetext{BACHELORARBEIT/MASTERARBEIT}
    \typeout{-- Type: not specified.}
  \fi
  \fi
  \fi
  \fi
  \fi
  \fi
  \fi
  \fi
\else % english
  \typeout{-- language set to english.}
  \ifx\@worktype\@worktypeDA
    \def\@worktypetext{DIPLOMA THESIS}
    \typeout{-- Type: Diplomarbeit.}
  \else
  \ifx\@worktype\@worktypeBA
    \def\@worktypetext{BACHELOR'S THESIS}
    \typeout{-- Type: Bachelorarbeit.}
  \else
  \ifx\@worktype\@worktypeMA
    \def\@worktypetext{MASTER'S THESIS}
    \typeout{-- Type: Masterarbeit.}
  \else
  \ifx\@worktype\@worktypeHS
    \def\@worktypetext{SCIENTIFIC SEMINAR}
    \typeout{-- Type: Scientific Seminar.}
  \else
  \ifx\@worktype\@worktypePP
    \def\@worktypetext{PRACTICAL COURSE}
    \typeout{-- Type: Projektpraktikum.} 
  \else
  \ifx\@worktype\@worktypeSeA
    \def\@worktypetext{SEMESTER THESIS}
    \typeout{-- Type: Semesterarbeit.}
  \else
  \ifx\@worktype\@worktypeIP
    \def\@worktypetext{INGENIEURPRAXIS}
    \typeout{-- Type: Industriepraxis.}
  \else
  \ifx\@worktype\@worktypeFP
    \def\@worktypetext{FORSCHUNGSPRAXIS}
    \typeout{-- Type: Forschungspraxis.}
  \else
    \def\@worktypetext{FINAL THESIS}
    \typeout{-- Type: not specified.}
    \fi
    \fi
    \fi
    \fi
    \fi
    \fi
    \fi
    \fi
    \fi
%___________________________________________

% 
%___________the student data variables______________
\def\@student{N.N.}
\newcommand{\student}[1]{\def\@student{\mbox{}#1}}
\def\@vartitle{}
\newcommand{\studtitle}[1]{\def\@vartitle{#1}}
\def\@studenttwo{\mbox{}}
\newcommand{\studenttwo}[1]{\def\@studenttwo{\mbox{}#1}}
\def\@vartitletwo{}
\newcommand{\studtitletwo}[1]{\def\@vartitletwo{#1}}
\def\@studentthree{\mbox{}}
\newcommand{\studentthree}[1]{\def\@studentthree{\mbox{}#1}}
\def\@vartitlethree{\mbox{}}
\newcommand{\studtitlethree}[1]{\def\@vartitlethree{\mbox{}#1}}
\def\@studentfour{\mbox{}}
\newcommand{\studentfour}[1]{\def\@studentfour{\mbox{}#1}}
\def\@vartitlefour{\mbox{}}
\newcommand{\studtitlefour}[1]{\def\@vartitlefour{\mbox{}#1}}

\def\@varyearone{DD. MM. YYYY}
\newcommand{\yearofbirth}[1]{\def\@varyearone{#1}}
\def\@varstreetone{Bakerstreet 221B}
\newcommand{\street}[1]{\def\@varstreetone{#1}}
\def\@varcity{8xxxx München}
\newcommand{\city}[1]{\def\@varcity{#1}}
\def\@vartele{089 - 1234567}
\newcommand{\phone}[1]{\def\@vartele{#1}}
% todo: additional informations for multiple students
%_____________________________________________________
\ifx\@institute\@instituteLSR
\def\@varprofessor{M. Buss}
\else
\ifx\@institute\@instituteITR
\def\@varprofessor{S. Hirche}
\fi
\fi
\newcommand{\professor}[1]{\def\@varprofessor{\mbox{}#1}}
\def\@varprofessortype{Univ.-Professor}
\newcommand{\professortype}[1]{\def\@varprofessortype{\mbox{}#1}}

\def\@vartitletranslation{}
\newcommand{\titletranslation}[1]{\def\@vartitletranslation{#1}}


\def\@varsupervisor{Dipl.-Ing. N.N.}
\newcommand{\supervisor}[1]{\def\@varsupervisor{#1}}

\def\@varstart{xx.xx.xxxx}
\newcommand{\start}[1]{\def\@varstart{#1}}

\def\@varprog{xx.xx.xxxx}
\newcommand{\progrep}[1]{\def\@varprog{#1}}

\def\@varfinal{xx.xx.xxxx}
\newcommand{\finalrep}[1]{\def\@varfinal{#1}}






%___________________footer______________________

%%%%%%%%%%%%%%%%%%%%% F O O T E R %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\if@langGer
  \ifx\@worktype\@worktypeHS
  \newcommand{\footer}{
    Wissenschaftliche Arbeit im Rahmen des Hauptseminars\\
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \ifx\@worktype\@worktypePP
  \newcommand{\footer}{
    Wissenschaftliche Arbeit im Rahmen des Projektpraktikums\\
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \ifx\@worktype\@worktypeIP
  \newcommand{\footer}{
    Wissenschaftliche Arbeit im Rahmen der Ingenieurspraxis\\
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \ifx\@worktype\@worktypeFP
  \newcommand{\footer}{
    Wissenschaftliche Arbeit im Rahmen der Forschungspraxis\\
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \ifx\@worktype\@worktypeSeA
  \newcommand{\footer}{
    Wissenschaftliche Arbeit im Rahmen der Semesterarbeit\\
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \ifx\@worktype\@worktypeMA
  \newcommand{\footer}{
    Wissenschaftliche Arbeit zur Erlangung des Grades M.Sc.\\
%    \if@typeFinal \else(Zwischenbericht) \\ \fi
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \ifx\@worktype\@worktypeBA
  \newcommand{\footer}{
    Wissenschaftliche Arbeit zur Erlangung des Grades B.Sc.\\
%    \if@typeFinal \else(Zwischenbericht) \\ \fi
    an der Fakult\"at f\"ur Elektrotechnik und Informationstechnik der\\ Technischen Universit\"at M\"unchen.
  }
  \else
  \newcommand{\footer}{
    Unbekannte wissenschaftliche Arbeit
  }
  \fi % BA
  \fi % MA
  \fi % SeA
  \fi % FP
  \fi % IP
  \fi % PP
  \fi % HS
\else
  \ifx\@worktype\@worktypeHS
  \newcommand{\footer}{
    Scientific work within the scientific seminar\\
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \ifx\@worktype\@worktypePP
  \newcommand{\footer}{
    Scientific work within the practical course\\
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \ifx\@worktype\@worktypeIP
  \newcommand{\footer}{
    Scientific work within the Ingenieurspraxis\\
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \ifx\@worktype\@worktypeFP
  \newcommand{\footer}{
    Scientific work within the Forschungspraxis\\
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \ifx\@worktype\@worktypeSeA
  \newcommand{\footer}{
    Scientific work within the semester thesis\\
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \ifx\@worktype\@worktypeMA
  \newcommand{\footer}{
    Scientific Thesis for the procurance of the degree M.Sc.\\
    \if@typeFinal \else(Intermediate report) \\ \fi
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \ifx\@worktype\@worktypeBA
  \newcommand{\footer}{
    Scientific thesis for the procurance of the degree B.Sc.\\
    \if@typeFinal \else(Intermediate report) \\ \fi
    from the Department of Electrical and Computer Engineering at the \\ Technical University of Munich.
  }
  \else
  \newcommand{\footer}{
    Unknown scientific thesis
  }
  \fi % BA
  \fi % MA
  \fi % SeA
  \fi % FP
  \fi % IP
  \fi % PP
  \fi % HS
  \fi % Ger
\pagestyle{empty}
%%%%%%%%%%%%%%%%%%%%% M A K E T I T L E %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\renewcommand{\maketitle}{
\vspace*{-3cm}
\hfill
\begin{tikzpicture}
      \pic [tum_blue](tumlogo) {tumlogo};
\end{tikzpicture}
%\includegraphics{./logos/tum_logo.pdf}%

\vspace*{1.2cm}
\begin{minipage}[t][10cm][t]{\textwidth}
\sffamily
{\fontsize{24pt}{26pt}\selectfont\textbf{\@title}\par}

\vspace*{14pt}
{\fontsize{18pt}{20pt}\selectfont\textbf{\@vartitletranslation}\par}

\end{minipage}

\begin{minipage}[t][4cm][t]{\textwidth}
\large\sffamily\selectfont
\footer
\end{minipage}

\begin{minipage}{\textwidth}
\normalsize\sffamily\selectfont

\if@langGer
  \begin{tabbing}
  \hspace*{4cm} \= blub \kill
  \textbf{Betreut von} \>
    \begin{minipage}[t]{10cm}
      \ifx\@institute\@instituteLSR
        Univ.-Prof.~Dr.-Ing./Univ.~Tokio habil.~Martin Buss\\
        \@varsupervisor\\
        Lehrstuhl f\"ur Steuerungs- und Regelungstechnik\strut
      \fi
      \ifx\@institute\@instituteITR
        Univ.-Prof.~Dr.-Ing.~Sandra Hirche\\
        \@varsupervisor\\
        Lehrstuhl f\"ur Informationstechnische Regelung\strut
      \fi
    \end{minipage}\\[4.3mm]

  \textbf{Eingereicht von}\>
    \begin{minipage}[t]{8cm}
      \@vartitle~\@student\\
      \@varstreetone\\
      \@varcity\\
      \@vartele
    \end{minipage}\\[2mm]

  \textbf{Eingereicht am}\>
    \begin{minipage}[t]{10cm}
      M\"unchen, den \@varfinal\strut
    \end{minipage}
  \end{tabbing}
\else % english
  \begin{tabbing}
  \hspace*{4cm} \= blub \kill
  \textbf{Supervised by} \>
    \begin{minipage}[t]{10cm}
      \ifx\@institute\@instituteLSR
        Univ.-Prof.~Dr.-Ing./Univ.~Tokio habil.~Martin Buss\\
        \@varsupervisor\\
        Chair of Automatic Control Engineering\strut
      \fi
      \ifx\@institute\@instituteITR
        Univ.-Prof.~Dr.-Ing.~Sandra Hirche\\
        \@varsupervisor\\
        Chair of Information-Oriented Control\strut
      \fi
    \end{minipage}\\[4.3mm]

  \textbf{Submitted by}\>
    \begin{minipage}[t]{8cm}
      \@vartitle~\@student\\
      \@varstreetone\\
      \@varcity\\
      \@vartele
    \end{minipage}\\[2mm]

  \textbf{Submitted on}\>
    \begin{minipage}[t]{10cm}
      Munich, \@varfinal\strut
    \end{minipage}
  \end{tabbing}
\fi
\end{minipage}
}


%____________________________________________________________
