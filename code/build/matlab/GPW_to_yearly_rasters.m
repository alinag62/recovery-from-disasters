%% Create yearly population rasters for all the world

path='/Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters';
cd(path);

%loop through pairs of years
yearfrom_list = {1970, 1980, 1990, 2000, 2005, 2010, 2015};
yearto_list = {1979, 1989, 1999, 2004, 2009, 2014, 2019};

for i=1:7 
    %select a pair of years
    yearfrom =  yearfrom_list{i};
    yearto = yearto_list{i};
    
    %load the data for selected years
    if yearfrom>=2000
      [GPWold, R_GPWold] = readgeoraster(['./data/population/raw/gpw-v4-population-count-rev11_' num2str(yearfrom) '_30_sec_tif/gpw_v4_population_count_rev11_' num2str(yearfrom) '_30_sec.tif']);
      [GPWnew, R_GPWnew] = readgeoraster(['./data/population/raw/gpw-v4-population-count-rev11_' num2str(yearto+1) '_30_sec_tif/gpw_v4_population_count_rev11_' num2str(yearto+1) '_30_sec.tif']);
    else
      [GPWold, R_GPWold]=readgeoraster(['./data/population/raw/popdynamics-global-pop-count-time-series-estimates-' num2str(yearfrom) '-geotiff/popdynamics-global-pop-count-time-series-estimates_' num2str(yearfrom) '.tif']);
      [GPWnew, R_GPWnew]=readgeoraster(['./data/population/raw/popdynamics-global-pop-count-time-series-estimates-' num2str(yearto+1) '-geotiff/popdynamics-global-pop-count-time-series-estimates_' num2str(yearto+1) '.tif']);
    end
    
    %clean
    GPWold=double(GPWold);
    GPWnew=double(GPWnew);
    GPWold(GPWold<0)=0;
    GPWnew(GPWnew<0)=0;
    
    %find k - annual growth rate to estimate populations
    k=log(GPWnew./GPWold)/(yearto-yearfrom);
    %if it was zero, assume it was 0.1
    k(GPWold<0.1)=log(GPWnew(GPWold<0.1)/0.1)/(yearto-yearfrom);
    %if it becomes zero, assume it becomes 0.1
    k(GPWnew<0.1)=log(0.1./GPWold(GPWnew<0.1))/(yearto-yearfrom);
    %if it was and stays zero no change
    k((GPWold<0.1).*(GPWnew<0.1)==1)=0;
    
    clear GPWnew R_GPWnew
    
    %loop through the years of the period
    for year=yearfrom:yearto
        if year==yearfrom
            GPW = GPWold;  
        else 
            GPW=GPWold.*exp(k*(year-yearfrom));
        end
        %save as annual data in raster format
        GPW = round(GPW, 1);
        geotiffwrite(['./data/population/intermediate/global_annual_gpw/gpw-v4-population-count-' num2str(year) '.tif'], GPW, R_GPWold)
        clear GPW
    end
    clear GPWold R_GPWold k 
end
    
















