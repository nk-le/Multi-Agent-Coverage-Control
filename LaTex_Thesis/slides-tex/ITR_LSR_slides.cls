\ProvidesClass{ITR_LSR_slides}[2007/05/31 class for ITR and LSR slides]
\typeout{-- 2019/07/02 revision V1.6 by D. Wollherr}
\typeout{-- 2017/10/18 revision V1.5 by D. Wollherr}
\typeout{-- 2017/10/17 revision V1.4 by D. Wollherr}
\typeout{-- 2017/01/16 revision V1.3 by V.Gabler}
\typeout{-- 2015/04/17 revision V1.1 by M. Kimmel}
\typeout{-- 2015/04/16 revision V1.2 by C. Landsiedel and A. Lawitzky}
\typeout{-- 2015/04/01 revision V1.1 by C. Landsiedel and A. Lawitzky}
\typeout{-- 2012/11/08 revision V1.0 by B. Weber and D. Althoff}
\typeout{-- 2012/09/27 revision V0.3 by B. Weber}
\typeout{-- 2011/10/05 revision V0.2 by M. Rank}
\typeout{-- 2007/05/31 revision V0.1 by M. Sobotka}
\typeout{-- 2007/05/31 most recent changes by Marion Sobotka}
\NeedsTeXFormat{LaTeX2e}
%\directlua{pdf.setminorversion(4)}


%%%%% Definition of Options
\newif\if@student      \global\@studentfalse
\newif\if@center       \global\@centerfalse
\newif\if@longpres     \global\@longpresfalse
\newif\if@noshadow     \global\@noshadowfalse
\newif\if@linebreak    \global\@linebreakfalse
\newif\if@secondline   \global\@secondlinefalse
\newif\if@langGer      \global\@langGertrue
\newif\if@ITR 		   \global\@ITRfalse
\newif\if@LSR          \global\@LSRfalse
\newif\if@lecture      \global\@lecturefalse

% define style input options
\DeclareOption{german}{\@langGertrue}
\DeclareOption{english}{\@langGerfalse}
\DeclareOption{student}{\@studenttrue}
\DeclareOption{center}{\@centertrue}
\DeclareOption{longpres}{\@longprestrue}
\DeclareOption{noshadow}{\@noshadowtrue}
\DeclareOption{ITR}{\@ITRtrue}
\DeclareOption{LSR}{\@LSRtrue}
\DeclareOption{itr}{\@ITRtrue}
\DeclareOption{lsr}{\@LSRtrue}
\DeclareOption{lecture}{\@lecturetrue}

% Pass through beamer options, e.g. 'handout' and 'aspectratio=169' (for slides with aspect ratio of 16:9 e.g. at interactive sessions)
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{beamer}}
\ProcessOptions
\if@center
    \ClassWarningNoLine{ITR_LSR_slides.cls}{Option 'center' is deprecated}
\fi

%%%%% Beamer class
\LoadClass[hyperref={pdfpagelabels=true}]{beamer}

\let\Tiny=\tiny

%%%%% Packages
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{graphicx}
\RequirePackage{xcolor}
\RequirePackage{multicol}
\RequirePackage{url}
\RequirePackage{ifxetex}
\RequirePackage{ifpdf}
\RequirePackage{tcolorbox}
\RequirePackage{tikz}
\@ifpackagelater{tikz}{2013/12/13}{%
    % Package is new enough
}{%
    \PackageError{tikz}{Package tikz is too old, please install at least version 3.0.0.}%
    \endinput
}
\usetikzlibrary{calc}
\ifxetex
    \RequirePackage{fontspec}
\else
    \RequirePackage[utf8]{inputenc}
\fi
\RequirePackage[url=false,citestyle=authoryear,block=ragged,backend=bibtex8,maxcitenames=1]{biblatex}
\def\blx@maxline{77}
%% if number of authors exceeds maxcitenames, the rest ist shortend with just a "+"
\DefineBibliographyStrings{english}{andothers={\texttt{+}}}
\DefineBibliographyStrings{german}{andothers={\texttt{+}}}
\renewcommand{\andothersdelim}{} %no space between authorlist and "and others"-part
\AtBeginDocument{\renewcommand\finalandcomma{}}

%% for right spacing after itemize
\RequirePackage{enumitem}
\setitemize{noitemsep,topsep=0pt,parsep=0pt,partopsep=0pt}
\setlist[itemize,1]{label=\tiny\raise0.4ex\hbox{\donotcoloroutermaths$\blacksquare$}}
\setlist[itemize,2]{label=\tiny\raise0.4ex\hbox{\scalebox{0.8}{\donotcoloroutermaths$\blacksquare$}}}
\setlist[enumerate,1]{label=\arabic*., ref=\arabic*}
\setlist[enumerate,2]{label=\alph*), ref=\theenumi.\alph*}


%%%%%% TUM Corporate Design Colors
\definecolor{tum_blue}{rgb} {0.00,0.40,0.74}
\definecolor{tum_dblue}{rgb}{0.00,0.20,0.35}
\definecolor{tum_lblue}{rgb}{0.39,0.63,0.78}
\definecolor{lsr_blue}{rgb}{0.63,0.73,0.91}
\definecolor{itr_blue}{rgb}{0.63,0.73,0.91}

\definecolor{tum_lgray}{rgb}{0.85,0.85,0.86}
\definecolor{tum_mgray}{rgb}{0.45,0.46,0.46}
\definecolor{tum_gray}{rgb}{0.60,0.61,0.61}
\definecolor{tum_dgray}{rgb}{0.35,0.35,0.35}

\definecolor{tum_red} {rgb}{0.77,0.03,0.09}
\definecolor{tum_dred}{rgb}{0.61,0.05,0.09}
\definecolor{lsr_red} {rgb}{0.55,0.00,0.16}
\definecolor{itr_red} {rgb}{0.55,0.00,0.16}

\definecolor{tum_green} {rgb}{0.64,0.68,0.0}
\definecolor{tum_dgreen}{rgb}{0.0,0.49,0.19}
\definecolor{tum_lgreen}{rgb}{0.4,0.60,0.11}

\definecolor{tum_orange}{rgb}{0.89,0.45,0.13}
\definecolor{tum_ivory} {rgb}{0.86,0.84,0.80}
\definecolor{tum_purple}{rgb}{0.41,0.03,0.35}
\definecolor{tum_violet}{rgb}{0.06,0.11,0.37}
\definecolor{tum_yellow}{rgb}{1.00,0.71,0.00}

\ifxetex
    \usefonttheme{professionalfonts} % for keeping math font unchanged
    \setsansfont[
        ExternalLocation    = ./fonts/,
        BoldFont            = TUMNeueHelvetica-Bold,
        ItalicFont          = TUMNeueHelvetica-Italic,
        BoldItalicFont      = TUMNeueHelvetica-BoldItalic
        ]{TUMNeueHelvetica-Regular}
    %\setmonofont[ExternalLocation=./fonts/]{LTYPE.TTF}
\fi

\if@LSR
	\if@langGer
		\newcommand{\chairname}{Lehrstuhl für Steuerungs- und Regelungstechnik}
		\newcommand{\tumname}{Technische Universität München}
	\else
		\newcommand{\chairname}{Institute of Automatic Control Engineering}
		\newcommand{\tumname}{Technical University of Munich}
	\fi
	\newcommand{\chairweb}{www.lsr.ei.tum.de}
\else
	\if@ITR
		\if@langGer
			\newcommand{\chairname}{Lehrstuhl für Informationstechnische Regelung}
			\newcommand{\tumname}{Technische Universität München}
		\else
			\newcommand{\chairname}{Institute of Information-oriented Control}
			\newcommand{\tumname}{Technical University of Munich}
		\fi
		\newcommand{\chairweb}{www.itr.ei.tum.de}
	\else
		\PackageError{ITR_LSR_slides}{Please specify either "ITR" or "LSR" in the options.}
	\fi
\fi



%%%%% Create Boxes for Presenter, Authors, Supervisor, and Affiliations
\newlength{\bottomlinelen}
\newlength{\blockwidth}

\if@student
    %\newsavebox{\authorsboxone}
    \def\@varpresenter{leer}
    \newcommand{\presenter}[1]{\def\@varpresenter{\textbf{#1}}}
    \def\@varsupervisor{S. Supervisor}
    \newcommand{\supervisor}[1]{\def\@varsupervisor{#1}}

    \def\@vartypeofpres{Zwischenbericht/Abschlussbericht Diplomarbeit/Studienarbeit}
    \newcommand{\typeofpres}[1]{\def\@vartypeofpres{#1}}
\else
%%%% Scientific Presentation
    \newsavebox{\affilsbox}             % all affiliations
    \newsavebox{\authorsboxone}     % first line of authors
    \newsavebox{\authorsboxtwo}     % second line of authors
    \newbox{\newauthorbox}              % box for current author
    \newlength{\boxlen}
    \newlength{\boxaffillen}
    \newlength{\authorlen}
    \newlength{\maillen}
    \newcount\authornum
    \newlength\firstaffillen
    \newlength\secondaffillen
    \authornum=0
    %%  \presenter[linebreak]{name}{opt: affil}%%{dep: email}%%
    \newcommand{\presenter}[3][\empty]{\presenterwithmail[#1]{#2}{#3}{}}
    \newcommand{\presenterwithmail}[4][\empty]{             %call this for email support !deprecated!
        \ifx#1\empty
            \ifnum\authornum=4
                \@linebreaktrue
            \fi
        \else
            \ifnum\authornum<4
                \@linebreaktrue
            \fi
        \fi
        \settowidth{\authorlen}{\textbf{#2}\textsuperscript{#3}}
        \settowidth{\maillen}{\texttt{\scriptsize #4}}
        \ifdim\authorlen<\maillen
            \boxlen\maillen
        \else
            \boxlen\authorlen
        \fi
        \if@center
            \setbox\newauthorbox\vtop{%
             \hbox to \boxlen{\hfil \textbf{#2}\textsuperscript{#3} \hfil}%
                \ifx#4\empty
                \else
                    \vskip -2mm
                    \hbox to \boxlen{\hfil \texttt{\scriptsize{%
                        \ifxetex
                            \addfontfeatures{Color=tum_mgray}%
                        \else
                            \color{tum_mgray}%
                        \fi
                        #4}}\hfil}
                \fi}
        \else
                \ifx&#4&
                        \setbox\newauthorbox\vbox{\hbox to \boxlen{\textbf{\underline{#2}}\textsuperscript{#3}}}
                \else
                        \setbox\newauthorbox\vtop{%
                            \hbox to \boxlen{\textbf{\underline{#2}}\textsuperscript{#3} \hfil}%
                            \vskip -2mm
                            \hbox to \boxlen{\texttt{\scriptsize{%
                                    \ifxetex
                                        \addfontfeatures{Color=tum_mgray}%
                                    \else
                                        \color{tum_mgray}%
                                    \fi
                                    #4}}\hfil}
                                \vskip 5mm
                            }
                \fi
        \fi%\if@center

    \if@linebreak
        \sbox\authorsboxtwo{\usebox{\newauthorbox}}
        \authornum=5
        \@linebreakfalse
        \@secondlinetrue
    \else
        \ifnum\authornum=4
            \sbox\authorsboxtwo{\usebox{\newauthorbox}}
            \advance\authornum1
            \@linebreakfalse
            \@secondlinetrue
        \else
            \ifnum\authornum=0
                \sbox\authorsboxone{\usebox{\newauthorbox}}
                \advance\authornum1
            \else
                \ifnum\authornum<4
                    \sbox\authorsboxone{\usebox{\authorsboxone}\hspace{5mm}\usebox{\newauthorbox}}
                    \advance\authornum1
                \else
                    \sbox\authorsboxtwo{\usebox{\authorsboxtwo}\hspace{5mm}\usebox{\newauthorbox}}
                    \advance\authornum1
                \fi %\ifnum\authornum<4
            \fi %\ifnum\authornum=0
        \fi%\ifnum\authornum=4
    \fi%\if@linebreak
    }

    %%  \addauthor[linebreak]{name}{opt: affil}%%{dep: email}%%
    \newcommand{\addauthor}[3][\empty]{\addauthorwithmail[#1]{#2}{#3}{}}
    \newcommand{\addauthorwithmail}[4][\empty]{             %call this for email support !deprecated!
        \ifx#1\empty
            \ifnum\authornum=4
                \@linebreaktrue
            \fi
        \else
            \ifnum\authornum<4
                \@linebreaktrue
            \fi
        \fi
        \settowidth{\authorlen}{\textbf{#2}\textsuperscript{#3}}
        \settowidth{\maillen}{\texttt{\scriptsize #4}}
        \ifdim\authorlen<\maillen
            \boxlen\maillen
        \else
            \boxlen\authorlen
        \fi
        \if@center
            \setbox\newauthorbox\vtop{%
             \hbox to \boxlen{\hfil \textbf{#2}\textsuperscript{#3} \hfil}%
                \ifx#4\empty
                \else
                    \vskip -2mm
                    \hbox to \boxlen{\hfil \texttt{\scriptsize{%
                        \ifxetex
                            \addfontfeatures{Color=tum_mgray}%
                        \else
                            \color{tum_mgray}%
                        \fi
                        #4}}\hfil}
                \fi}
        \else
                \ifx&#4&
                        \setbox\newauthorbox\vbox{\hbox to \boxlen{\textbf{#2}\textsuperscript{#3}}}
                \else
                        \setbox\newauthorbox\vtop{%
                            \hbox to \boxlen{\textbf{#2}\textsuperscript{#3} \hfil}%
                            \vskip -2mm
                            \hbox to \boxlen{\texttt{\scriptsize{%
                                    \ifxetex
                                        \addfontfeatures{Color=tum_mgray}%
                                    \else
                                        \color{tum_mgray}%
                                    \fi
                                    #4}}\hfil}
                            \vskip 5mm
                            }
                \fi
        \fi%\if@center

    \if@linebreak
        \sbox\authorsboxtwo{\usebox{\newauthorbox}}
        \authornum=5
        \@linebreakfalse
        \@secondlinetrue
    \else
        \ifnum\authornum=4
            \sbox\authorsboxtwo{\usebox{\newauthorbox}}
            \advance\authornum1
            \@linebreakfalse
            \@secondlinetrue
        \else
            \ifnum\authornum=0
                \sbox\authorsboxone{\usebox{\newauthorbox}}
                \advance\authornum1
            \else
                \ifnum\authornum<4
                    \sbox\authorsboxone{\usebox{\authorsboxone}\hspace{5mm}\usebox{\newauthorbox}}
                    \advance\authornum1
                \else
                    \sbox\authorsboxtwo{\usebox{\authorsboxtwo}\hspace{5mm}\usebox{\newauthorbox}}
                    \advance\authornum1
                \fi
            \fi
        \fi
    \fi
    }

    %%  \addaffiliations[opt: footnote]{line 1}{opt: line 2}
    \newcommand{\addaffiliations}[3][\empty]{
        \settowidth{\firstaffillen}{\textsuperscript{\scriptsize #1}#2}
        \settowidth{\secondaffillen}{#3}
        \ifdim\boxaffillen<\firstaffillen
            \ifdim\firstaffillen<\secondaffillen
                \boxaffillen\secondaffillen
            \else
                \boxaffillen\firstaffillen
            \fi
        \else
            \ifdim\boxaffillen<\secondaffillen
                \boxaffillen\secondaffillen
            \fi
        \fi
    \if@center
        \setbox\affilsbox\vbox{
                \hbox to \boxaffillen{\hfil\usebox{\affilsbox}\hfil}%
                \hbox to \boxaffillen{\hfil\textsuperscript{\scriptsize #1}{\footnotesize #2}\hfil}
                \vskip -1.5mm
                \ifx#3\empty
                \else
                    \vskip .5mm
                    \hbox to \boxaffillen{\hfil\footnotesize%
                            \ifxetex
                                \addfontfeatures{Color=tum_mgray}%
                            \else
                                \color{tum_mgray}%
                            \fi
                            #3\hfil}\vskip 2mm plus 1mm
                \fi
                }
    \else
        \setbox\affilsbox\vbox{
                \hbox to \boxaffillen{\usebox{\affilsbox}}%
                \hbox to \boxaffillen{\textsuperscript{\scriptsize #1}{\footnotesize #2} \hfil}
                    \vskip -1.5mm
                \ifx#3\empty
                \else
                    \vskip .5mm
                    \hbox to \boxaffillen{\phantom{\textsuperscript{\scriptsize #1}}\footnotesize{%
                            \ifxetex
                                \addfontfeatures{Color=tum_mgray}%
                            \else
                                \color{tum_mgray}%
                            \fi
                            #3} \hfil}\vskip 1mm
                \fi
                }
    \fi
    }

\def\@varoccasion{}
\def\@vardate{}
%% \date{month}{day}{year}
\renewcommand{\date}[3]{
    \ifx#3\empty
    \else
        \def\@vardate{#1/#2/#3}
    \fi
}
\newcommand{\occasion}[1]{
        \def\@varoccasion{#1}
}
\fi %endif student

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Beamer specific definitions %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%\useoutertheme{smoothbars}
\usefonttheme[onlymath]{serif}

%%%%%%%%%% remove Figure: from Caption
\setbeamertemplate{caption}{\raggedright\insertcaption\par}

%%%%%%%%%% sidebar left empty
\setbeamertemplate{sidebar left}{}

%%%%%%%%%% sidebar right empty
\setbeamertemplate{sidebar right}{}

%%%%%%%%%% header
%% \setprojectlogo[opt: website]{filename}{height}
\newcommand{\setprojectlogo}[3][\empty]{
    \newlength{\projectheight}
    \setlength{\projectheight}{#3}
    \def\@projectlogo{#2}
    \setbeamertemplate{headline}{\vspace{2mm}
        \hspace{0mm plus 1fill}
        \ifx#1\empty
            \includegraphics[height=\projectheight]{\@projectlogo}
        \else
            \href{#1}{\includegraphics[height=\projectheight]{\@projectlogo}}
        \fi
        \hspace{2mm}
        \addtolength{\projectheight}{2mm}
        \vspace{-\projectheight}
    %\usebeamertemplate***{navigation symbols}
}}


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

\newlength{\lengtha}
\setlength{\lengtha}{\paperwidth}
\addtolength{\lengtha}{-34mm}

% \setlength{\footheight}{1cm}
\patchcmd{\beamer@calculateheadfoot}{\advance\footheight by 4pt}{\advance\footheight by 1.2cm}{}{}
%%%%%%%%%% footer
\setbeamertemplate{footline}{%
  \setlength{\bottomlinelen}{\textwidth}
  % \addtolength{\bottomlinelen}{-6mm}
  \ifnum\thepage>1
  	\if@longpres
  		\begin{tikzpicture}[remember picture,overlay]
      		\draw [] ($(current page.south west) + (.3, 1.)$) -- ($(current page.south east) + (-.3, 1.)$);
      		\pic (tumlogo) [scale=.7, tum_blue] at ($(current page.south west) + (0.96, 0.5)$) {tumlogo};
      		\if@LSR
      			\pic (lsrlogo) [scale=.9] at ($(current page.south east) +
            		(-0.42, 0.5) +
            		(-0.26, 0)
            		$) {lsrlogo};
      		\fi
      		\if@ITR
        		\pic (itrlogo) [scale=.4] at ($(current page.south east) + (-1, 0.5) $) {itrlogo};
      		\fi
    	\end{tikzpicture}
    	\if@ITR
        	\addtolength{\lengtha}{-7mm} % adjust for larger ITR logo. If we do this in the Tiks-environment, 
        								 % the length is only changed within the tikz scope, 
        								 % therefore we need an addition if...
        \fi
    	\hspace{1.6cm} \raisebox{5.5mm}{\insertnavigation{\lengtha}{}{}}
    	\raisebox{4mm}{\scriptsize\insertframenumber}
  	\else % longpres
  		\begin{tikzpicture}[remember picture,overlay]
      		\draw [] ($(current page.south west) + (.3, .6)$) -- ($(current page.south east) + (-.3, .6)$);
      		\pic (tumlogo) [scale=.5, tum_blue] at ($(current page.south west) + (0.78, 0.3)$) {tumlogo};
      		\if@LSR
      			\pic (lsrlogo) [scale=.53] at ($(current page.south east) +
            		(-0.53, 0.3)$) {lsrlogo};
      		\fi
      		\if@ITR
        		\pic (itrlogo) [scale=.26] at ($(current page.south east) +
            		(-0.75, 0.29) $) {itrlogo};
      		\fi
    	\end{tikzpicture}
    	\hspace{1.6cm} \raisebox{4mm}{\insertnavigation{\lengtha}{}{}}
    	\raisebox{2.5mm}{\scriptsize\insertframenumber}
  	\fi % longpres
    
  \else % title page has different footer
  	\if@longpres
    	\begin{tikzpicture}[remember picture,overlay]
    		\if@LSR
            	\coordinate (chairlogoposition) at ($(current page.south east) +
            		(-0.42, 0.5) +
            		(-0.26, 0)
            		$);
            	\coordinate (chairlogocutoutbottomleft) at ($(chairlogoposition)+(-0.5,-0.45)$);
            	\coordinate (chairlogocutoutbottomright) at ($(chairlogoposition)+(0.5,-0.45)$);
            \fi
            \if@ITR
            	\coordinate (chairlogoposition) at ($(current page.south east) + (-1, 0.5) $);
            	\coordinate (chairlogocutoutbottomleft) at ($(chairlogoposition)+ (-0.9,-0.45)$);
            	\coordinate (chairlogocutoutbottomright) at ($(chairlogoposition)+(0.8,-0.45)$);
            \fi
            \coordinate (footerbartopleft) at ($(current page.south west) + (0, 1)$);
            % filled bar at footer
            \fill[sharp corners,tum_blue] %
            % top part
            (footerbartopleft) [rounded corners=0.2cm]-| (chairlogocutoutbottomleft) -| (chairlogocutoutbottomright |- footerbartopleft) [sharp corners]-- ($(current page.south east) + (0, 1)$) --
            %bottom part
                (current page.south east) -- (current page.south west) --cycle;
      		\pic (tumlogo) [scale=.7, white] at ($(current page.south west) - (-0.95, -0.5)$) {tumlogo};
      		\if@LSR
            	\pic (lsrlogo) [scale=.9] at  (chairlogoposition){lsrlogo};
            \fi
            \if@ITR
            	\pic (itrlogo) [scale=.4] at  (chairlogoposition){itrlogo};
            \fi
            \node [anchor=south, white] (url) at ($(current page.south) + (0.0, 0.25)$) {\bf  \large \href{http://\chairweb}{\chairweb}};
    	\end{tikzpicture}
    \else % longpres
       	\begin{tikzpicture}[remember picture,overlay]
       		\if@LSR
            	\coordinate (chairlogoposition) at ($(current page.south east) + (-0.53, 0.3)$);
            	\coordinate (chairlogocutoutbottomleft) at ($(chairlogoposition)+(-0.4,-0.27)$);
            	\coordinate (chairlogocutoutbottomright) at ($(chairlogoposition)+(0.4,-0.27)$);
            \fi
            \if@ITR
            	\coordinate (chairlogoposition) at ($(current page.south east) + (-0.75, 0.28)$);
            	\coordinate (chairlogocutoutbottomleft) at ($(chairlogoposition)+(-0.6,-0.25)$);
            	\coordinate (chairlogocutoutbottomright) at ($(chairlogoposition)+(0.6,-0.25)$);
            \fi
            \coordinate (footerbartopleft) at ($(current page.south west) + (0, .6)$);
            % filled bar at footer
            \fill[sharp corners,tum_blue] %
            % top part
            (footerbartopleft) [rounded corners=0.2cm]-| (chairlogocutoutbottomleft) -| (chairlogocutoutbottomright |- footerbartopleft) [sharp corners]-- ($(current page.south east) + (0, .6)$) --
            %bottom part
                (current page.south east) -- (current page.south west) --cycle;
      		\pic (tumlogo) [scale=.5, white] at ($(current page.south west) +	 (0.78, 0.3)$) {tumlogo};
      		\if@LSR
            	\pic (lsrlogo) [scale=.53] at  (chairlogoposition){lsrlogo};
            \fi
            \if@ITR
            	\pic (itrlogo) [scale=.26] at  (chairlogoposition){itrlogo};
            \fi
            \node [anchor=south, white] (url) at ($(current page.south) + (0.0, 0.12)$) {\bf \normalsize \href{http://\chairweb}{\chairweb}};
    	\end{tikzpicture}

    \fi %longpres
  \fi%\ifnum\thepage>1
  }

\if@lecture % this just overrides the previous definition of footline. Therefore the order is important
			% not very nice, but saves a lot of if statements...
\setbeamertemplate{footline}{%
	\hfill\raisebox{2.5mm}{\scriptsize\insertframenumber}\qquad\qquad\mbox{}
	}
\fi

%%%%%%%%%% standard navigation bar for long presentations
\if@longpres
\else
%%%%%%%%%% default for short presentations
%%%%%%%%%% only sections and one dot per frame in the navigation bar
    \let\ORIGsection=\section
    \renewcommand{\section}[2][\empty]{
            \ifx#1\empty
                \ORIGsection[#2]{#2}
                \subsection*{dummy}
            \else
                \ORIGsection[#1]{#2}
                \subsection*{dummy}
            \fi
    }
\fi

%%%%%%%%%% title page
%%%%% for student presentations
\if@student
\setbeamertemplate{title page}{
    \if@center
        \centering
        \usebeamerfont{title}\usebeamercolor[fg]{title}\textbf{\inserttitle}\par
        \usebeamerfont{author}
        \begin{table}
            \begin{tabular}{c}
                \hspace{33mm} \\
                \mbox{} \\
                \usebox\authorsboxone\\
                \mbox{} \\
                {\textsl{\chairname}} \\ 
                {\textsl{\tumname}} \\
%                \if@langGer
%                	{\textsl{Lehrstuhl für Steuerungs- und Regelungstechnik}} \\
%                	{\textsl{Technische Universität München}} \\
%                \else
%                	{\textsl{Chair of Automatic Control Engineering}} \\
%                	{\textsl{Technical University of Munich}} \\
%                \fi
                \mbox {} \\
                {\@vartypeofpres}\\
                                                    \mbox {} \\
                                                    \if@langGer
                                                    	{Betreuer: \@varsupervisor}\\
                                                    \else
                                                    	{Supervisor: \@varsupervisor}\\
                                                    \fi
            \end{tabular}
        \end{table}
    \else
        \vskip 8mm
        \huge
        \usebeamercolor[fg]{title}
        \textbf{\inserttitle}\\
        \vskip 6mm plus 5filll
        \small
        \usebeamercolor[fg]{author}
        \@varpresenter\\
        \@vartypeofpres\\
        \ifxetex
        	\if@langGer
	            {\addfontfeatures{Color=tum_mgray}
    	            Betreuer: \@varsupervisor}%
			\else
               	{\addfontfeatures{Color=tum_mgray}
                	Supervisor: \@varsupervisor}%
            \fi
        \else
            \if@langGer
            	{\color{tum_mgray}
                	Betreuer: \@varsupervisor}%
			\else
            	{\color{tum_mgray}
                	Supervisor: \@varsupervisor}%
            \fi
        \fi     
        \vskip 0mm plus 4filll
        %\if@langGer
       % 	{Lehrstuhl für Steuerungs- und Regelungstechnik}\\
		%\else
        %	{Chair of Automatic Control Engineering} \\
        %\fi        
        \chairname\\
        \ifxetex
            \addfontfeatures{Color=tum_mgray}
        \else
            \color{tum_mgray}
        \fi
        \if@langGer
        	Technische Universität München\\
		\else
        	Technical University of Munich\\
        \fi     
        \vskip 2mm
    \fi
}
%%%%%%%%%% title page
%%%%% for research presentations
\else
\setbeamertemplate{title page}{
    \if@center
        \begin{center}
            \vskip 2mm plus 4filll
            \usebeamercolor[fg]{title}\huge{\textbf{\inserttitle}}\\
            \vskip 4mm plus 5filll
            \usebeamerfont{author}
            \usebox{\authorsboxone}\\
            \vskip 2mm
            \usebox{\authorsboxtwo}\\
            \vskip 0mm plus 4filll
            \hspace{\stretch{1}}
                \usebox{\affilsbox}
            \hspace{\stretch{1}} %stretch hack!
            \vskip 0mm plus 3filll
        \end{center}
    \else
        \vskip 4mm
        \usebeamercolor[fg]{title}\LARGE{\textbf{\inserttitle}}\\
        \vskip 2mm plus 3filll
        \normalsize
        \usebeamercolor[fg]{author}
        \usebox{\authorsboxone}\\
        \if@secondline
            %\vskip 0mm minus 4mm
            \usebox{\authorsboxtwo}\\
        \fi
        \vskip 1mm
        \usebox{\affilsbox}
        \vskip 0mm
        \ifx\@vardate\empty
            \textbf{\footnotesize\@varoccasion}
        \else
            \ifx\@varoccasion\empty
                \textbf{\footnotesize\@vardate}
            \else
                \textbf{\footnotesize\@varoccasion, \@vardate}
            \fi
        \fi
    \fi
}

\fi


%%%%%%%%%% frame title bold and centered
\setbeamertemplate{frametitle}
{
\if@center
    \begin{centering}
            \vspace{1mm}
            \textbf{\vphantom{Sp}\insertframetitle\vphantom{Sp}}
            \par
    \end{centering}
\else
        \vspace{1mm}
        \textbf{\vphantom{Sp}\insertframetitle\vphantom{Sp}}
        \par
\fi
}


%%%%%%%%% itemize items
%\setbeamertemplate{itemize item}[square]
\setbeamertemplate{itemize item}
{
    %\scriptsize\raise0.25ex\hbox{\donotcoloroutermaths$\blacksquare$}
    \tiny\raise0.4ex\hbox{\donotcoloroutermaths$\blacksquare$}
}
\setbeamertemplate{itemize subitem}
{
    %\scriptsize\raise0.25ex\hbox{\donotcoloroutermaths$\blacksquare$}
    \tiny\raise0.4ex\hbox{\scalebox{0.8}{\donotcoloroutermaths$\blacksquare$}}
}

%%%%%%%%%% FONTS COLORS
\setbeamercolor{title}{fg=tum_blue}
\setbeamercolor{author}{fg=black}
\setbeamercolor{frametitle}{fg=tum_blue}
\setbeamercolor{section in toc}{fg=black}
\setbeamercolor{section in toc shaded}{fg=black}
\setbeamercolor{subsection in toc}{fg=black}
\setbeamercolor{subsection in toc shaded}{fg=black}
\setbeamercolor{itemize item}{fg=black}
\setbeamercolor{itemize subitem}{fg=black}
\setbeamercolor{structure}{fg=black}
% Alert environment
\setbeamercolor{alerted text}{fg=tum_orange}

%%%%%%%%%%% Navigation Bar
%\setbeamercolor{section in head/foot}{fg=white, bg=tum_blue}
%\setbeamertemplate{section in head/foot shaded}[default][70]

%%%%%%%% Blocks
% Simple block and shadow
\tcbuselibrary{skins}
\usetikzlibrary{shadows,positioning}
\if@noshadow
    \tcbset{
        skin=enhanced,
        boxsep=.5mm,
        left=0mm,
        top=0.5mm,
        bottom=0.5mm,
        right=0mm,
        coltitle=white,
        colframe=tum_blue,
        colback=white,
        fonttitle=\bfseries
    }
\else
    \tcbset{
        skin=enhanced,
        frame style={drop shadow},
        boxsep=.5mm,
        left=0mm,
        top=0.5mm,
        bottom=0.5mm,
        right=0mm,
        coltitle=white,
        colframe=tum_blue,
        colback=white,
        fonttitle=\bfseries
    }
\fi
\newcommand{\simpleblock}[1]{%
\vskip 2.5mm%
    \begin{tcolorbox}%
    #1%
    \end{tcolorbox}
    \vskip .5mm%
}

\renewenvironment{block}[1]{%
    \vskip 2.5mm%
    \begin{tcolorbox}[title=#1]
}
{%
    \end{tcolorbox}%
    \vskip .5mm
}%




%%%%%%%% Bibliography
\renewcommand{\bibfont}{\normalfont\tiny}
\DeclareFieldFormat*{title}{\textbf{\MakeCapital{#1}}}
%prevent wrong order of names for first author
\DeclareNameAlias{author}{default}
%remove heading
\defbibheading{bibliography}[]{}

\@ifpackagelater{biblatex}{2011/06/01}
{
    %newer version
    \ExecuteBibliographyOptions{maxbibnames=99, minbibnames=6}
    \setbeamertemplate{bibliography item}{\makebox(7,1)[rt]{\href{\thefield{url}}{\includegraphics[width=4mm]{pdf_logo}}}}
}
{
    %older version
    %does not work
    %\setbeamertemplate{bibliography item}{\makebox(7,1)[rt]{\href{}{\includegraphics[width=4mm]{pdf_logo}}}}
    %to remove numbers [1] and so on
    \defbibenvironment{bibliography}
    {\list{}
        {
        %\settowidth{\labelwidth}{}
        %To align with headline, no logo since old version
        \setlength{\leftmargin}{0cm}%
        %\setlength{\rightmargin}{\labelwidth}%
        %\setlength{\labelsep}{\biblabelsep}%
        %\addtolength{\leftmargin}{\labelsep}%
        %\setlength{\itemsep}{\bibitemsep}%
        %\setlength{\parsep}{\bibparsep}
        }}
        {\endlist}
    {\item}
    \ExecuteBibliographyOptions{maxbibnames=99, minbibnames=6}
    \DeclareFieldFormat*{title}{\newline\textbf{\MakeCapital{#1}.}\newline}
}
\setbeamercolor{bibliography entry location}{fg=gray,bg=white}
\setbeamercolor{bibliography entry note}{fg=gray,bg=white}

%% different cite commands
\let\ORIGcite=\cite
\newcommand{\bcite}[1]{[\ORIGcite{#1}]}
\renewcommand{\cite}[2][1]{%
    \AtNextCite{\defcounter{maxnames}{#1}\defcounter{minnames}{#1}}
    {\footnotesize[\ORIGcite{#2}]}%
}
\newcommand{\scite}[1]{{\small[\ORIGcite{#1}]}}

%% cite command for variable number of names
%\newrobustcmd{\varcite}[2]{%
%  \AtNextCite{\defcounter{maxnames}{#2}\defcounter{minnames}{#2}}\cite{#1}}


%%%%%%%%%% sync page counter with frame counter
%%%%%%%%%%      only useful in conjunction with:
%%%%%%%%%%      \documentclass[hyperref={pdfpagelabels=true}]{beamer}
\renewcommand{\thepage}{\insertframenumber}

%%%%% math definitions
\newcommand{\argmin}{\operatornamewithlimits{arg\,min}}
\newcommand{\argmax}{\operatornamewithlimits{arg\,max}}
\renewcommand{\d}{\, \mathrm{d}}

\if@langGer
	\newcommand{\LSRITRRefTitle}{Referenzen}
\else
	\newcommand{\LSRITRRefTitle}{References}
\fi


% vim: set ft=tex:
