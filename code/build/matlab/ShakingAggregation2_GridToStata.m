function ShakingAggregation2_GridToStata(years, path2shp, path2id, path2save_shake, path2save_pop, path2grid_area, ID)
    %% Import
    area=shaperead(path2shp);
    [area_grid_km2,R_km2] = readgeoraster(path2grid_area);
    [area_grid_id,R_id] = readgeoraster(path2id);

    %% By region
    % make sure that Rgrump is equal to pop data extent
    [grump, R_grump]=readgeoraster('./data/grump/glurextents.asc');
    grump(grump<0)=-1;
    %check imagesc! of grump

    resolution=round(1/R_km2.CellExtentInLatitude);
    for i=1:length(area)
      %define country ID and population density threshold
      i
      Identifier=eval(['area(i).' ID]); 
      %if ID is not numeric
      if isnumeric(Identifier)~=1
          Identifier=str2double(Identifier);
      end
      Identifier=round(double(Identifier));
      
      %Get a bounding box of region
      MapY=area(i).Y;
      [MapX,box,ulxmap,breakswitch] = worldborderswitch(area(i).X,area(i).BoundingBox,0);
      box = box_limit(MapX,MapY,resolution);

      %adjust box to resolution grid
      box=box_limit(MapX,MapY,resolution);

      %We need to define the area map for the region (from the ID files
      %prepared before)
      [x1,x2,y1,y2] = evengrid_limit(box,R_km2.LongitudeLimits(1)+180*breakswitch,R_km2.LatitudeLimits(2),resolution);
      [x1_grump,x2_grump,y1_grump,y2_grump] = evengrid_limit(box,R_grump.XWorldLimits(1)+180*breakswitch,R_grump.YWorldLimits(2),resolution);
        if breakswitch==1
            %breakswitch functionality
            area_grid_id_breakswitch=create_breakswitch_matrix(area_grid_id,R_km2.LongitudeLimits(1));
            area_grid_km2_breakswitch=create_breakswitch_matrix(area_grid_km2,R_km2.LongitudeLimits(1));
            grump_breakswitch=create_breakswitch_matrix(grump,R_grump.XWorldLimits(1));
            area_map=round(double(area_grid_km2_breakswitch(y1:y2,x1:x2)));
            area_gridres=round(double(area_grid_id_breakswitch(y1:y2,x1:x2))); 
            urban_level=grump_breakswitch(y1_grump:y2_grump,x1_grump:x2_grump); 
        else
            area_map=round(double(area_grid_km2(y1:y2,x1:x2)));
            area_gridres=round(double(area_grid_id(y1:y2,x1:x2))); 
            urban_level=grump(y1_grump:y2_grump,x1_grump:x2_grump); 
        end
      % area that is not in the designated region is set to 0
      area_map(area_gridres~=Identifier)=0;

      % urban level 
      load([path2save_pop '/Pop' num2str(Identifier) '_2010to2014.mat'],'pop_map_area2010');
      urban_level(pop_map_area2010<0.1)=0;

      clear pop_map_area* 

      for y=years 
          y
        %load appropriate population map
        if y>=1970 
            if y < 1980
              load([path2save_pop '/Pop' num2str(Identifier) '_1970to1979.mat'],['pop_map_area' num2str(y)]);
            elseif y < 1990
                load([path2save_pop '/Pop' num2str(Identifier) '_1980to1989.mat'],['pop_map_area' num2str(y)]);
            elseif y < 2000
              load([path2save_pop '/Pop' num2str(Identifier) '_1990to1999.mat'],['pop_map_area' num2str(y)]);
            elseif y < 2005
              load([path2save_pop '/Pop' num2str(Identifier) '_2000to2004.mat'],['pop_map_area' num2str(y)]);
            elseif y < 2010
              load([path2save_pop '/Pop' num2str(Identifier) '_2005to2009.mat'],['pop_map_area' num2str(y)]);
            elseif y < 2015
              load([path2save_pop '/Pop' num2str(Identifier) '_2010to2014.mat'],['pop_map_area' num2str(y)]);
            else
              load([path2save_pop '/Pop' num2str(Identifier) '_2015to2019.mat'],['pop_map_area' num2str(y)]);
            end
            
            pop_now=double(eval(['pop_map_area' num2str(y) ]));
            clear pop_map_area*
        end
       
        %prep reshaping
        length_now=size(area_map,1)*size(area_map,2);

        mpga_now=zeros(length_now,1);
        number_quakes_now=zeros(length_now,1);
        mag_now=zeros(length_now,1);
        mpgv_now=zeros(length_now,1);
        number_quakes_pgv_now=zeros(length_now,1);
        mag_pgv_now=zeros(length_now,1);

        %check if year exists and assign appropriate shakingprofiles
        if exist([path2save_shake '/RegionShaking/ShakingProfiles_' num2str(Identifier) '_' num2str(y) '.mat'],'file')==2
          load([path2save_shake '/RegionShaking/ShakingProfiles_' num2str(Identifier) '_' num2str(y) '.mat']);
          if ~isempty(eval(['mpga_' num2str(y)]))   
            mpga_now=eval(['mpga_' num2str(y)]);
            number_quakes_now=eval(['number_quakes_' num2str(y)]);
            mag_now=eval(['mag_map_' num2str(y)]);
            eval(['clear mpga_' num2str(y) ' number_quakes_' num2str(y) ' mag_map_' num2str(y)]);
          end
          if ~isempty(eval(['mpgv_' num2str(y)]))   
            mpgv_now=eval(['mpgv_' num2str(y)]);
            number_quakes_pgv_now=eval(['number_quakes_pgv_' num2str(y)]);
            mag_pgv_now=eval(['mag_map_pgv_' num2str(y)]);
            eval(['clear mpgv_' num2str(y) ' number_quakes_pgv_' num2str(y) ' mag_map_pgv_' num2str(y)]);
          end           
        end

        %reshape everything to a vector
        if y>=1970 
            pop_now=reshape(pop_now,length_now,1);
        end
        urban_level_reshaped=reshape(urban_level,length_now,1);
        areakm2_now=reshape(area_map,length_now,1);
        mpga_now=reshape(mpga_now,length_now,1);
        number_quakes_now=reshape(number_quakes_now,length_now,1);
        mag_now=reshape(mag_now,length_now,1);
        mpgv_now=reshape(mpgv_now,length_now,1);
        number_quakes_pgv_now=reshape(number_quakes_pgv_now,length_now,1);
        mag_pgv_now=reshape(mag_pgv_now,length_now,1);

        %kick out parts that are not in the area
        index=(areakm2_now==0);
        if y>=1970 
            pop_now(index)=[];
        end
        urban_level_reshaped(index)=[];
        mpga_now(index)=[];
        number_quakes_now(index)=[];
        mag_now(index)=[];
        mpgv_now(index)=[];
        number_quakes_pgv_now(index)=[];
        mag_pgv_now(index)=[];
        areakm2_now(index)=[];

        %%%%%%%%%%%%%%%%%%%%%
        % summarize no-shaking (mpga_now<1) gridcells in (three - maybe split by population?) observations and
        % then remove those individual gridcells
        % This is done to decrease size of output file.
        %%%%%%%%%%%%%%%%%%%%%

        noshaking=(mpga_now<1);
        unpopulated=(urban_level_reshaped==0);
        rural=(urban_level_reshaped==1);
        urban=(urban_level_reshaped==2);

        %1) Unpopulated
        index=(noshaking.*unpopulated==1);
        if y>=1970 
            NSpop_notpop=sum(pop_now(index));
        end
        NSarea_notpop=sum(double(areakm2_now(index)));
        %2) Rural
        index=(noshaking.*rural==1);
        if y>=1970 
            NSpop_rural=sum(pop_now(index));
        end
        NSarea_rural=sum(double(areakm2_now(index)));
        %3) Urban
        index=(noshaking.*urban==1);
        if y>=1970 
            NSpop_urban=sum(pop_now(index));
        end
        NSarea_urban=sum(double(areakm2_now(index)));

        %Remove no-shaking observations
        mpga_now(noshaking)=[];
        if y>=1970 
            pop_now(noshaking)=[];
        end
        urban_level_reshaped(noshaking)=[];
        number_quakes_now(noshaking)=[];
        mag_now(noshaking)=[];
        mpgv_now(noshaking)=[];
        number_quakes_pgv_now(noshaking)=[];
        mag_pgv_now(noshaking)=[];
        areakm2_now(noshaking)=[];
        length_now=length(areakm2_now);

        %Add the three noshaking observations to the data
        if NSarea_notpop>0
          if y>=1970 
            pop_now(length_now+1,1)=NSpop_notpop;
          end
          urban_level_reshaped(length_now+1,1)=0;
          mpga_now(length_now+1,1)=0;
          number_quakes_now(length_now+1,1)=0;
          mag_now(length_now+1,1)=0;
          mpgv_now(length_now+1,1)=0;
          number_quakes_pgv_now(length_now+1,1)=0;
          mag_pgv_now(length_now+1,1)=0;
          areakm2_now(length_now+1,1)=NSarea_notpop;
          length_now=length_now+1;
        end
        if NSarea_rural>0
          if y>=1970 
            pop_now(length_now+1,1)=NSpop_rural;
          end
          urban_level_reshaped(length_now+1,1)=1;
          mpga_now(length_now+1,1)=0;
          number_quakes_now(length_now+1,1)=0;
          mag_now(length_now+1,1)=0;
          mpgv_now(length_now+1,1)=0;
          number_quakes_pgv_now(length_now+1,1)=0;
          mag_pgv_now(length_now+1,1)=0;
          areakm2_now(length_now+1,1)=NSarea_rural;
          length_now=length_now+1;
        end
        if NSarea_urban>0
          if y>=1970 
            pop_now(length_now+1,1)=NSpop_urban;
          end
          urban_level_reshaped(length_now+1,1)=2;
          mpga_now(length_now+1,1)=0;
          number_quakes_now(length_now+1,1)=0;
          mag_now(length_now+1,1)=0;
          mpgv_now(length_now+1,1)=0;
          number_quakes_pgv_now(length_now+1,1)=0;
          mag_pgv_now(length_now+1,1)=0;
          areakm2_now(length_now+1,1)=NSarea_urban;
          length_now=length_now+1;
        end

        %%%%%%%%%%%%%%%%%%%%%
        % Define output
        %%%%%%%%%%%%%%%%%%%%%
        year=y*ones(length_now,1);
        region=cell(length_now,1);
        region(:,1)={Identifier};

        if y>=1970 
            PanelH={'region','year','mpga','number_quakes','mag','mpgv','number_quakes_pgv','mag_pgv','area','pop','urban_level'};
            Data=[year mpga_now number_quakes_now mag_now mpgv_now number_quakes_pgv_now mag_pgv_now areakm2_now, pop_now, urban_level_reshaped];
            nanloc=isnan(Data);
            Data=[num2cell(uint16(year)) num2cell(single(mpga_now)) num2cell(uint16(number_quakes_now)) num2cell(single(mag_now)) num2cell(single(mpgv_now)) num2cell(uint16(number_quakes_pgv_now)) num2cell(single(mag_pgv_now))  num2cell(double(areakm2_now)) num2cell(double(pop_now)) num2cell(double(urban_level_reshaped))];
        else 
            PanelH={'region','year','mpga','number_quakes','mag','mpgv','number_quakes_pgv','mag_pgv','area','urban_level'};
            Data=[year mpga_now number_quakes_now mag_now mpgv_now number_quakes_pgv_now mag_pgv_now areakm2_now, urban_level_reshaped];
            nanloc=isnan(Data);
            Data=[num2cell(uint16(year)) num2cell(single(mpga_now)) num2cell(uint16(number_quakes_now)) num2cell(single(mag_now)) num2cell(single(mpgv_now)) num2cell(uint16(number_quakes_pgv_now)) num2cell(single(mag_pgv_now))  num2cell(double(areakm2_now)) num2cell(double(urban_level_reshaped))];
        end
        Data(nanloc)={'.'};
        cell2csv([PanelH; region, Data], [path2save_shake '/region_csvs/' num2str(Identifier) '_' num2str(y)]);
        clear mpga_* number_quakes_* mag_map_* 
      end


    end

