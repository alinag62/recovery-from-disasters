*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
local results_general ../simultaneous_regs

* Housekeeping
clear
clear matrix
set more off

texdoc init ./output/regressions_tex/combined_tex/combined_regressions_growth_rates.tex, replace

/***
\documentclass[12pt]{article}

\usepackage[utf8]{inputenc}

\usepackage{amssymb,amsmath,amsfonts,eurosym,geometry,ulem,graphicx,caption,color,setspace,sectsty,comment,footmisc,caption,pdflscape,subfigure,array,hyperref, xurl,booktabs, url, lscape}

\usepackage[table,xcdraw]{xcolor}

\geometry{margin=0pt}
\pagestyle{empty}
\setlength{\parskip}{1em}
\setlength{\parindent}{0em}

\title{Primary Regressions (growth rates): Combined All Countries}
\author{Alina Gafanova}
\date{\today}

\usepackage[nottoc,numbib]{tocbibind}
\usepackage[authoryear]{natbib} 
\bibliographystyle{chicago}

\begin{document}
\maketitle

\begin{landscape}

***/


foreach dep in labor wages tot_invent_eoy capital output exports dom_sales bldings_val tot_invest {
	foreach var in "" _popmpga_aw _num_qs_aw {

	texdoc write \input{`results_general'/`dep'_5_and_10`var'.tex}
	texdoc write \clearpage
	
	}
}



/***
\end{landscape}
\end{document}
***/


texdoc do code/do/create_tex_file_combined_all_growth_rates.do
