*#############################################################################
cd /Users/alina/Box/recovery-from-disasters
local results_country ../Colombia_adm1/logs

* Housekeeping
clear
clear matrix
set more off

texdoc init ./output/regressions_tex/combined_tex/Colombia_adm1_primary_regressions_logs.tex, replace

/***
\documentclass[12pt]{article}

\usepackage[utf8]{inputenc}

\usepackage{amssymb,amsmath,amsfonts,eurosym,geometry,ulem,graphicx,caption,color,setspace,sectsty,comment,footmisc,caption,pdflscape,subfigure,array,hyperref, xurl,booktabs, url, lscape}

\usepackage[table,xcdraw]{xcolor}

\geometry{margin=0pt}
\pagestyle{empty}
\setlength{\parskip}{1em}
\setlength{\parindent}{0em}

\title{Primary Regressions (log-linear): Colombia ADM1}
\author{Alina Gafanova}
\date{\today}

\usepackage[nottoc,numbib]{tocbibind}
\usepackage[authoryear]{natbib} 
\bibliographystyle{chicago}

\begin{document}
\maketitle

\begin{landscape}

***/


foreach dep in log_tot_emp log_wage_tot log_tot_invent_eoy log_totasst_val  log_exports log_bldings_val {
	*foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		
	foreach var in mpga_aw popmpga_aw {	
	texdoc write \input{`results_country'/reg_year_plant_fe_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}

/*foreach dep in tot_emp wage_tot_th tot_invent_eoy_th totasst_val_th tot_sales_th exports_th bldings_val_th {
	foreach var in mpga_aw populatedmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw populatednum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 populatedmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 populatednum_qs_aw10{
		
	texdoc write \input{`results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}

foreach dep in tot_emp wage_tot_th tot_invent_eoy_th totasst_val_th tot_sales_th exports_th bldings_val_th {
	foreach var in mpga_aw populatedmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw populatednum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 populatedmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 populatednum_qs_aw10{
		
	texdoc write \input{`results_country'/reg_year_plant_district_fe_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}

foreach dep in tot_emp wage_tot_th tot_invent_eoy_th totasst_val_th tot_sales_th exports_th bldings_val_th {
	foreach var in mpga_aw populatedmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw populatednum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 populatedmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 populatednum_qs_aw10{
		
	texdoc write \input{`results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}*/


/***
\end{landscape}
\end{document}
***/


texdoc do code/do/create_tex_file_Colombia_adm1_logs.do
