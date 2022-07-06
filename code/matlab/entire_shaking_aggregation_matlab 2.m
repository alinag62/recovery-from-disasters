%% MANUAL CHOICE, DONE IN SHELL
path=getenv('path_from_shell');
year_start=getenv('year_start_from_shell'); 
year_end=getenv('year_end_from_shell'); 
ID=getenv('ID_from_shell');
country=getenv('country_from_shell');
country_abbr=getenv('country_abbr_from_shell');
adm_level=getenv('adm_level_from_shell');
raster_name=getenv('raster_name_from_shell');

% year_start='1972'; 
% year_end='1990'; 
% ID='ID_2';
% country='Colombia';
% country_abbr='COL';

%% Add Paths
cd(path);
addpath('./code/matlab/matlab_shakemaptools');
addpath('./code/matlab/matlab_scale');
addpath('./code/matlab/matlab_stata_translation');

%% paths to folders 
path2shp=['./data/firm-data/' country '/Shapefile/' country_abbr '_adm_shp/' country_abbr '_' adm_level '.shp'];
path2id=['./data/firm-data/' country '/Shapefile/rasterized_districts/' raster_name '_dist_id_only.tif'];
path2grid_area=['./data/firm-data/' country '/Shapefile/rasterized_districts/' raster_name '_area_only.tif'];
path2save_pop=['./data/population/intermediate/' country '_' adm_level];
path2save_shake=['./data/earthquakes/intermediate/' country '_' adm_level];
years=[str2double(year_start):str2double(year_end)];
%% create folders if they don't exist
if not(isfolder(path2save_pop))
    mkdir(path2save_pop);
end

if not(isfolder(path2save_shake))
    mkdir(path2save_shake);
end

if not(isfolder([path2save_shake '/RegionShaking']))
    mkdir([path2save_shake '/RegionShaking']);
end

if not(isfolder([path2save_shake '/region_csvs']))
    mkdir([path2save_shake '/region_csvs']);
end

%% set project directory
addpath('./code/matlab');

%Step 0
ShakingAggregation0_Population_area_year(1970,1979,path2shp,path2id,path2save_pop,ID)
ShakingAggregation0_Population_area_year(1980,1989,path2shp,path2id,path2save_pop,ID)
ShakingAggregation0_Population_area_year(1990,1999,path2shp,path2id,path2save_pop,ID)
ShakingAggregation0_Population_area_year(2000,2004,path2shp,path2id,path2save_pop,ID)
ShakingAggregation0_Population_area_year(2005,2009,path2shp,path2id,path2save_pop,ID)
ShakingAggregation0_Population_area_year(2010,2014,path2shp,path2id,path2save_pop,ID)
ShakingAggregation0_Population_area_year(2015,2019,path2shp,path2id,path2save_pop,ID)
disp('Done with Population_area_year!');

%Step 1
ShakingAggregation1_CreateAreaTimeProfiles(years,path2shp,path2id,path2save_shake,ID)
disp('Done with CreateAreaTimeProfiles!');

%Step 2
ShakingAggregation2_GridToStata(years,path2shp,path2id,path2save_shake,path2save_pop,path2grid_area,ID)
disp('Done with GridToStata!');
