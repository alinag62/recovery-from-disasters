*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
local results_country ../India_adm2/growth_rates

* Housekeeping
clear
clear matrix
set more off

texdoc init ./output/regressions_tex/combined_tex/India_adm2_primary_regressions_growth_rates.tex, replace

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


foreach dep in log_wages_diff log_sales_diff log_tot_invent_eoy_diff log_capital_diff log_exports_diff log_labor_diff log_output_diff log_dom_sales_diff {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {

	texdoc write \input{`results_country'/reg_year_plant_fe_`var'_`dep'.tex}
	texdoc write \clearpage
	
	}
}


/*foreach dep in log_tot_emp_diff log_tot_invest_diff log_tot_invent_diff log_totasst_val_diff log_tot_output_diff log_bldings_val_diff   {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	
	texdoc write {\small Treatment: "\$`var'\$"}
	texdoc write \input{`results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}

foreach dep in log_tot_emp_diff log_tot_invest_diff log_tot_invent_diff log_totasst_val_diff log_tot_output_diff log_bldings_val_diff  {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		
	texdoc write \input{`results_country'/reg_year_plant_district_fe_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}

foreach dep in log_tot_emp_diff log_tot_invest_diff log_tot_invent_diff log_totasst_val_diff log_tot_output_diff log_bldings_val_diff  {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		
	texdoc write \input{`results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex}
	texdoc write \clearpage
	}
}*/


/***
\end{landscape}
\end{document}
***/


texdoc do code/do/create_tex_file_India_adm2_growth_rates.do
