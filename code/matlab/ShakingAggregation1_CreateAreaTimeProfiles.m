function ShakingAggregation1_CreateAreaTimeProfiles(years, path2shp, path2id, path2save_shake, ID)

    area=shaperead(path2shp);
    [area_grid_id,R] = readgeoraster(path2id);
    %to visualize regions
    %imagesc(area_grid)
    
    %% Import Shaking Data
    load('./data/earthquakes/raw/ShakeMap_Info.mat');
    load('./data/earthquakes/raw/ShakeMap_Grid_PGALand.mat');
    load('./data/earthquakes/raw/ShakeMap_Grid_PGVLand.mat');

    % Clean
    ulxmap(ulxmap<-180)=ulxmap(ulxmap<-180)+360;
    %! we should remove negative NAs and turn them to zero. (Stephanie)
    area_grid_id(area_grid_id<0)=0;

    %% Calculate variables
    resolution=round(1/R.CellExtentInLatitude);

    [a,b]=size(area);

    %go through polygons
    ulxmap0=ulxmap;
    for i=1:a
        %! using the Identifier is better, in case ID is not a running
        %number. (Stephanie)
        Identifier=eval(['area(i).' ID]); 
        if isnumeric(Identifier)~=1
            Identifier=str2double(Identifier);
        end
        Identifier=round(double(Identifier));

        MapY=area(i).Y;
        ulxmap=ulxmap0;
        %When almost the whole world is in the shape, separate at 0 instead of 180,
        %otherwise matrix gets too big.
        [MapX,box,ulxmap,breakswitch]=worldborderswitch(area(i).X,area(i).BoundingBox,ulxmap);
        %adjust box to resolution grid
        box=box_limit(MapX,MapY,resolution);

        %check what resolutions we need and which shakemaps overlap with
        %area box (around shape polygon) for that time period
        res_sample=[];
        for y=years
            subset=(YMDHMS(:,1)==y);
            [res_Boxsample, inBoxArea]=worldboxoverlap(box,ulxmap,ulymap,1./res_event,1./res_event,ncols,nrows,res_event,subset,breakswitch);
            eval(['inBoxArea' num2str(y) '=inBoxArea;']);
            if isempty(res_Boxsample)==0
                resolperiod=lcm_multi([res_Boxsample resolution]);
                if resolperiod>resolution
                    resolperiod=resolution;
                end
                eval(['reso_' num2str(y) '=resolperiod;']);
                res_sample=[res_sample resolperiod];
            end
        end
        res_sample=unique(res_sample);

        %creating grid for individual area (counties) with 1/0 identification
        if ~isempty(res_sample)
            [x1,x2,y1,y2] = evengrid_limit(box,R.LongitudeLimits(1)+180*breakswitch,R.LatitudeLimits(2),resolution);
            if breakswitch==1
                %breakswitch posibility
                area_grid_id_breakswitch=create_breakswitch_matrix(area_grid_id,R.LongitudeLimits(1));
                area_gridres=round(double(area_grid_id_breakswitch(y1:y2,x1:x2))); 
            else
                area_gridres=round(double(area_grid_id(y1:y2,x1:x2))); 
            end
            area_gridres(area_gridres~=Identifier)=0;
            area_gridres(area_gridres>0)=1;
        end

        %Now overlap with shaking
        quake=0;
        for y=years
            quakeinyear=0;
            eval(['subset=inBoxArea' num2str(y) ';']);
            if sum(subset>0)>0.1 %actually 0 instead of 0.1, but to make sure machine error doesnt cause problems)
                eval(['reso=reso_' num2str(y) ';']);
                area_grid=area_gridres;
                %PGA
                [ mpga, number_quakes, sum_lpga, sum_pga, sum_pga_square, mag_map, list] = shakelap(area_grid,box,reso,subset,breakswitch,PGALand,1./res_event,ulxmap,ulymap,res_event,magnitude);
                if isempty(list)==0
                    quake=1;
                    quakeinyear=1;
                    eval(['mpga_' num2str(y) '=mpga;']);
                    eval(['number_quakes_' num2str(y)  '=number_quakes;']);
                    eval(['mag_map_' num2str(y) '=mag_map;']);
                end
                clear mpga mag_map number_quakes sum_lpga sum_pga sum_pga_square
                %PGV
                [ mpgv, number_quakes, sum_lpgv, sum_pgv, sum_pgv_square, mag_map, list] = shakelap(area_grid,box,reso,subset,breakswitch,PGVLand,1./res_event,ulxmap,ulymap,res_event,magnitude);
                if isempty(list)==0
                    quake=1;
                    quakeinyear=1;
                    eval(['mpgv_' num2str(y) '=mpgv;']);
                    eval(['number_quakes_pgv_' num2str(y)  '=number_quakes;']);
                    eval(['mag_map_pgv_' num2str(y) '=mag_map;']);
                end
                clear mpgv mag_map number_quakes sum_lpgv sum_pgv sum_pgv_square
                %save output
                if quakeinyear==1
                    %! exchanged i for Identifier (Stephanie
                    save([path2save_shake '/RegionShaking/ShakingProfiles_' num2str(Identifier) '_' num2str(y) '.mat'],'mpg*', 'number_quakes*', 'mag_map*', 'reso', '-v7.3');
                    clear list mpg* mag_map* number_quakes* sum_*
                end
            end
        end
        % if quake==0 print message that it's done (maybe id)
        if quake==0
            i
        end
        %clean up
        clear res_Boxsample* inBoxArea* area_box* reso_* area_gridres* area_grid
    end

end
