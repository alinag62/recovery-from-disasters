%% Set path
path='/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters';
cd(path);

%% paths to folders 
path2shp = './data/shapefiles/qgis_world_basemap/qgis_basemap.shp';
path2id='./data/shapefiles/qgis_basemap_rasterized/world_ids_only.tif';
path2grid_area='./data/shapefiles/qgis_basemap_rasterized/world_area_only.tif';

addpath('./code/matlab/matlab_shakemaptools');
addpath('./code/matlab/matlab_scale');
addpath('./code/matlab/matlab_stata_translation');
addpath('./code/matlab/matlab_alina_functions');

%% Import files
area=shaperead(path2shp);
[area_grid_km2,R_km2] = readgeoraster(path2grid_area);
[area_grid_id,R_id] = readgeoraster(path2id);
load('./data/earthquakes/raw/ShakeMap_Info.mat');
load('./data/earthquakes/raw/ShakeMap_Grid_PGALand.mat');

% Clean
ulxmap(ulxmap<-180)=ulxmap(ulxmap<-180)+360;
%! we should remove negative NAs and turn them to zero. (Stephanie)
area_grid_id(area_grid_id<0)=0;


%% Assign EQs to Each Country
resolution=round(1/R_id.CellExtentInLatitude);
%number of countries in this map of the world
[a,b]=size(area);

% subset for 1973-2018 
years=[1974:2018];
subset = (YMDHMS(:,1)==1973); 
for y=years
    subset = subset + (YMDHMS(:,1)==y);
end

% Pick countries by their ids
%country_list = {104, 13, 15, 9, 117, 121, 126, 112};
%country_list = {33, 22, 12, 19, 11}; 
country_list = {121};

for country = 1:length(country_list)
	i = country_list{country};
    MapY=area(i).Y;

    %adjust box to resolution grid
    [MapX,box,ulxmap,breakswitch]=worldborderswitch(area(i).X,area(i).BoundingBox,ulxmap);
    box=box_limit(MapX,MapY,resolution);

    %check what resolutions we need and which shakemaps overlap with
    %area box (around shape polygon) for that time period
    res_sample=[];

    %overlap with the country: get ids for EQ in the country
    [res_Boxsample, inBoxArea]=worldboxoverlap(box,ulxmap,ulymap,1./res_event,1./res_event,ncols,nrows,res_event,subset,breakswitch);

    %get highest resolution available
    if isempty(res_Boxsample)==0
        resolperiod=lcm_multi([res_Boxsample resolution]);
        if resolperiod>resolution
            resolperiod=resolution;
        end
        res_sample=[res_sample resolperiod];
    end
    res_sample=unique(res_sample);

    %creating grid for individual area (counties) with 1/0 identification
    if ~isempty(res_sample)
        [x1,x2,y1,y2] = evengrid_limit(box,R_id.LongitudeLimits(1)+180*breakswitch,R_id.LatitudeLimits(2),resolution);
        if breakswitch==1
            %breakswitch posibility
            area_grid_id_breakswitch=create_breakswitch_matrix(area_grid_id,R_id.LongitudeLimits(1));
            area_grid_km2_breakswitch=create_breakswitch_matrix(area_grid_km2,R_km2.LongitudeLimits(1));
            area_gridres=round(double(area_grid_id_breakswitch(y1:y2,x1:x2))); 
            area_map=round(double(area_grid_km2_breakswitch(y1:y2,x1:x2)));
        else
            area_gridres=round(double(area_grid_id(y1:y2,x1:x2))); 
            area_map=round(double(area_grid_km2(y1:y2,x1:x2)));
        end
        area_gridres(area_gridres~=i)=0;
        area_gridres(area_gridres>0)=1;
    end

    % area that is not in the designated region is set to 0
    area_map(area_gridres~=1)=0;

    %count EQs if there is shaking at all
    'Shakelap Started'
    if sum(subset>0)>0.1 %actually 0 instead of 0.1, but to make sure machine error doesnt cause problems)

        area_grid=area_gridres;
        [ mpga, list, years, coord1, coord2, coord10, mpga_save] = shakelapIndividual2(area_grid,box,res_sample,subset,breakswitch,PGALand,1./res_event,ulxmap,ulymap,res_event,magnitude, YMDHMS);

    end
    
    'Shakelap Finished'

    %% Calculate Areas for each Earthquake (with different thresholds)

    final_table=[list, years, mpga];
    final_table=transpose(final_table);
    final_table=reshape(final_table, [], 3);

    %reshape everything to a vector
    length_now=size(area_map,1)*size(area_map,2);
    areakm2_now=reshape(area_map,length_now,1);

    country_coord=[];
    
    cxpos=transpose(repelem(1:size(area_grid,2), size(area_grid,1)));
    cypos=transpose(repmat(1:size(area_grid,1),1, size(area_grid,2)));
    country_coord=[cypos,cxpos];
    
%     for cxpos=1:size(area_grid,2)
%        for cypos=1:size(area_grid,1) 
%            country_coord=[country_coord; cypos, cxpos];  
%         end
%     end

    areakm2_now(:,2:3)=country_coord;
    areakm2_now = array2table(areakm2_now,...
        'VariableNames',{'area','y','x'});

    %sum areas for each threshold
    %by looping through events
    summed_areas1=zeros(length(list),1);
    summed_areas2=zeros(length(list),1);
    summed_areas10=zeros(length(list),1);

    for j=1:length(list)
        j
        event=list(j);
        eval(['area1=coord1.id' num2str(event) ';']);
        eval(['area2=coord2.id' num2str(event) ';']);
        eval(['area10=coord10.id' num2str(event) ';']);

        if isempty(area1)==1
            summed_areas1(j)=0;
            summed_areas2(j)=0;
            summed_areas10(j)=0;
        else
            area1=array2table(area1,...
            'VariableNames',{'y','x'});
            joined1 = join(area1, areakm2_now, ... 
            'Keys', {'y','x'});
            summed_areas1(j)=sum(joined1.area>0);

            if isempty(area2)==1
                summed_areas2(j)=0;
                summed_areas10(j)=0;
            else 
                area2=array2table(area2,...
                'VariableNames',{'y','x'});
                joined2 = join(area2, areakm2_now, ... 
                'Keys', {'y','x'});
                summed_areas2(j)=sum(joined2.area>0);
                    if isempty(area10)==1
                        summed_areas10(j)=0;
                    else 
                        area10=array2table(area10,...
                        'VariableNames',{'y','x'});
                        joined10 = join(area10, areakm2_now, ... 
                        'Keys', {'y','x'});
                        summed_areas10(j)=sum(joined10.area>0);
                    end
            end
        end
    end

    %combine into a table and save
    final_table=[final_table,summed_areas1,summed_areas2,summed_areas10];
    final_table=array2table(final_table,...
                        'VariableNames',{'id','year','max_pga','area_over_1pga','area_over_2pga','area_over_10pga'});
    cell2csv(final_table, ['./data/earthquakes/intermediate/summary_stats/', area(i).NAME]);  
    
    clear res_Boxsample* inBoxArea* area_box* reso_* area_gridres* area_grid
end


%%









