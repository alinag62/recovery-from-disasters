*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
local results_general ../simultaneous_regs

* Housekeeping
clear
clear matrix
set more off

texdoc init ./output/regressions_tex/combined_tex/combined_regressions_growth_rates_vs_linear.tex, replace

/***
\documentclass[12pt]{article}

\usepackage[utf8]{inputenc}

\usepackage{amssymb,amsmath,amsfonts,eurosym,geometry,ulem,graphicx,caption,color,setspace,sectsty,comment,footmisc,caption,pdflscape,subfigure,array,hyperref, xurl,booktabs, url, lscape, afterpage, float}

\usepackage[table,xcdraw]{xcolor}


\geometry{left=1.0in,right=1.0in,top=1.0in,bottom=1.0in}
\setlength{\parskip}{1em}
\setlength{\parindent}{0em}

\title{Primary Regressions (growth rates vs linear models): Combined All Countries}
\author{Alina Gafanova}
\date{\today}

\usepackage[nottoc,numbib]{tocbibind}
\usepackage[authoryear]{natbib} 
\bibliographystyle{chicago}

\begin{document}
\maketitle

The main specification in growth rates (always assumed if not stated the opposite): 
$$\Delta ln (y_{it}) =  \sum_{l=0}^L \beta_l S_{i, t-l} + \alpha_i + \gamma_t + \varepsilon_{it},$$
where $\Delta ln (y_{it}) \equiv  ln (y_{it}) -  ln (y_{it-1})$ is the growth rate of a particular variable of a firm $i$ in year $t$, $S_{i, t-l}$ is one of the shaking measures, lagged $L$ times.  $\alpha_i $ is a plant fixed effect, $\gamma_t$ is a year time fixed effect. $\varepsilon_{it}$ is a standard error, clustered on a firm-level.

The linear specification:

$$y_{it} =  \sum_{l=0}^L \beta_l S_{i, t-l} + \alpha_i + \gamma_t + \varepsilon_{it},$$
where $y_{it}$ is a particular variable of a firm $i$ in year $t$ and all other parts are identical to growth rates specification. 

Shaking measures used in this summary are $mpga\_aw\footnote{average area-weighted of maximum of PGA/PGV (peak ground acceleration/velocity) over each gridcell in each year}$, $popmpga\_aw\footnote{average area-weighted of maximum of PGA/PGV (peak ground acceleration/velocity) over each gridcell in each year only across populated areas}$ and $num\_qs\_aw\footnote{average area-weighted number of earthquakes}. $

Dependent variables used in this summary are labor, wages, inventory, assets' value, buildings' value, output, domestic sales, exports, total investment.

Reminder: we use both ADM2 and ADM1 level regressions for Colombia, since we only have few ADM2-level regions identified in firms' data.

\afterpage{%
\newgeometry{margin=0pt}

\begin{landscape}

***/


foreach dep in labor wages tot_invent_eoy capital output exports dom_sales bldings_val tot_invest {
	foreach var in "" _popmpga_aw _num_qs_aw {

	texdoc write \input{`results_general'/`dep'_5_and_10`var'.tex}
	texdoc write \clearpage
	
	}
	
	foreach var in mpga_aw popmpga_aw num_qs_aw {

	texdoc write \input{`results_general'/`dep'_5_and_10_`var'_linear.tex}
	texdoc write \clearpage
	
	}
}



/***

\end{landscape}

\clearpage
\restoregeometry
}

\end{document}
***/


texdoc do code/do/create_tex_file_combined_all_growth_rates_vs_linear.do
