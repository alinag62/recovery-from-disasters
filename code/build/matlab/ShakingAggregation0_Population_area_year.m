function ShakingAggregation0_Population_area_year(yearfrom, yearto, path2shp, path2id, path2save_pop, ID)
    %% Import

    if yearfrom>=2000
      [GPWold, R_GPWold] = readgeoraster(['./data/population/raw/gpw-v4-population-count-rev11_' num2str(yearfrom) '_30_sec_tif/gpw_v4_population_count_rev11_' num2str(yearfrom) '_30_sec.tif']);
      [GPWnew, R_GPWnew] = readgeoraster(['./data/population/raw/gpw-v4-population-count-rev11_' num2str(yearto+1) '_30_sec_tif/gpw_v4_population_count_rev11_' num2str(yearto+1) '_30_sec.tif']);
    else
      [GPWold, R_GPWold]=readgeoraster(['./data/population/raw/popdynamics-global-pop-count-time-series-estimates-' num2str(yearfrom) '-geotiff/popdynamics-global-pop-count-time-series-estimates_' num2str(yearfrom) '.tif']);
      [GPWnew, R_GPWnew]=readgeoraster(['./data/population/raw/popdynamics-global-pop-count-time-series-estimates-' num2str(yearto+1) '-geotiff/popdynamics-global-pop-count-time-series-estimates_' num2str(yearto+1) '.tif']);
      GPWold=GPWold(:,1:end-1);
      GPWnew=GPWnew(:,1:end-1);
    end

    [country, R_country] = readgeoraster(path2id);
    area=shaperead(path2shp);

    resolution=round(1/R_country.CellExtentInLatitude);
    %% prep
    %country=double(country);
    GPWold=double(GPWold);
    GPWnew=double(GPWnew);
    GPWold(GPWold<0)=0;
    GPWnew(GPWnew<0)=0;

    %% by district
    for i=1:length(area)
        Identifier=eval(['area(i).' ID]); 
        %! added to make sure if identifier is not numeric that it still
        %works (Stephanie)
        if isnumeric(Identifier)~=1
            Identifier=str2double(Identifier);
        end
        Identifier=round(double(Identifier));
        
        MapY=area(i).Y;
        [MapX,box,ulxmap,breakswitch] = worldborderswitch(area(i).X,area(i).BoundingBox,0);
        box = box_limit(MapX,MapY,resolution);

        %Determine region extent within country ID raster
        [x1,x2,y1,y2] = evengrid_limit(box,R_country.LongitudeLimits(1)+180*breakswitch,R_country.LatitudeLimits(2),resolution);
        % replaced x1 from xpop1, y1 from ypop1 etc

        if breakswitch==0
            %! Added round(double()) to make sure there are now machine
            %error comarison issues (Stephanie)
            map=round(double(country(y1:y2,x1:x2)));
            map(map~=Identifier)=0;
            map(map>0)=1;
        else
            %! added: make pop maps for events over worldborder (Stephanie)
            GPWoldBS=create_breakswitch_matrix(GPWold,-180);
            GPWnewBS=create_breakswitch_matrix(GPWnew,-180);
            countrybreakswitch=create_breakswitch_matrix(country,R_country.LongitudeLimits(1));
            %! Added round(double()) to make sure there are now machine
            %error comarison issues (Stephanie)
            map=round(double(countrybreakswitch(y1:y2,x1:x2)));
            map(map~=Identifier)=0;
            map(map>0)=1;
        end

        %Determine region extent within GPW population rasters
        [x1,x2,y1,y2] = evengrid_limit(box,R_GPWold.LongitudeLimits(1)+180*breakswitch,R_GPWold.LatitudeLimits(2),resolution);
        %get GPW pop map
        for year=yearfrom:yearto
          if year==yearfrom
            if breakswitch==0
                GPW=GPWold(y1:y2,x1:x2);
            else
                GPW=GPWoldBS(y1:y2,x1:x2);
            end
          else
            if breakswitch==0
                old=GPWold(y1:y2,x1:x2);
                new=GPWnew(y1:y2,x1:x2);
            else
                old=GPWoldBS(y1:y2,x1:x2);
                new=GPWnewBS(y1:y2,x1:x2);
            end
              k=log(new./old)/(yearto-yearfrom);
              %if it was zero, assume it was 0.1
              k(old<0.1)=log(new(old<0.1)/0.1)/(yearto-yearfrom);
              %if it becomes zero, assume it becomes 0.1
              k(new<0.1)=log(0.1./old(new<0.1))/(yearto-yearfrom);
              %if it was and stays zero no change
              k((old<0.1).*(new<0.1)==1)=0;
              GPW=old.*exp(k*(year-yearfrom));
          end
          %population map
          pop_map=GPW.*map;
          eval(['pop_map_area'  num2str(year) '=single(pop_map);']);
        end
        save([path2save_pop '/Pop' num2str(Identifier) '_' num2str(yearfrom) 'to' num2str(yearto) '.mat'], 'pop_map_area*','-v7.3');
        clear pop_map_area*
    end
end
