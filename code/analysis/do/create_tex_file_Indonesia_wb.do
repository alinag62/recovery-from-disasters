*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

texdoc init ./output/regressions_tex/combined_tex/Indonesia_wb.tex, replace

/***
\documentclass[12pt]{article}

\usepackage[utf8]{inputenc}

\usepackage{amssymb,amsmath,amsfonts,eurosym,geometry,ulem,graphicx,caption,color,setspace,sectsty,comment,footmisc,caption,pdflscape,subfigure,array,hyperref, xurl,booktabs, url, lscape}

\usepackage[table,xcdraw]{xcolor}

\geometry{margin=0pt}
\pagestyle{empty}
\setlength{\parskip}{1em}
\setlength{\parindent}{0em}

\title{Primary Regressions (growth rates): India ADM2}
\author{Alina Gafanova}
\date{\today}

\usepackage[nottoc,numbib]{tocbibind}
\usepackage[authoryear]{natbib} 
\bibliographystyle{chicago}

\begin{document}
\maketitle

\begin{landscape}

***/


foreach var in mpga_aw num_qs_aw popmpga_aw {
	foreach dep in log_rout log_lbr log_rvad log_rnetInv log_rlabprod log_rwage log_rmat log_rinv {

	texdoc write \begin{landscape}
	texdoc write \newgeometry{left=0in,right=0in,top=0in, top=2in}
	texdoc write \pagestyle{empty}
	texdoc write \input{reg_tables/table_`var'_`dep'_v4}
	texdoc write \restoregeometry
	texdoc write \end{landscape}
	
	}
}






/***
\end{landscape}
\end{document}
***/


texdoc do code/do/create_tex_file_Indonesia_wb.do
