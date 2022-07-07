function [ mpga, inArea, years, coord1, coord2, coord10] = shakelapIndividual(grid,box,resolution,inBoxArea,breakswitch,ShakeMap,xdim,ulxmap,ulymap,res_event,magnitude, YMDHMS)
% Gives shaking summary for area
%  INPUTS:
%
%     box = [x1 y1;         map:  y2 ----
%            x2 y2]                 |    |
%                                   |    |
%                              x1,y1 ---- x2
%
% OUTPUTS:
%   mpga ... Maximum PG over time in location (matrix)
%   number_quakes ... Number of events above 10 PG threshold
%   sum_lpga ... Sum of Log PG values
%   sum_pga ... Sum of PG values
%   sum_pga_square ... Sum of PG squares
%   magnitude_map ... Max magnitude of Q affecting that grid cell with at least PG 1 threshold
%   inArea .. vector of which events are in the area
%
% This function requires the Package matlab_scale which can be downloaded here
% https://github.com/slackner0/matlab_scale


%grid=area_grid;
%resolution=reso;
%inBoxArea=subset;
%ShakeMap=PGALand;

mpga=[];
years=[];
inArea=[];
coord1=struct();
coord2=struct();
coord10=struct();

mapsize=size(grid);
inBoxArea=find(inBoxArea>0.1);

%% STEP 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Go through events and fit to matrix to see if they are atually in the
%grid
for i=1:length(inBoxArea)
    event=inBoxArea(i);
    %map is shakemap sample
    eval(['map=ShakeMap.id' num2str(event) ';']);
    ncols=size(map,2);

    % resize to correct resolution, if artifical lowering of resolution
    % to 120 was necessary, then use resizem_by_max
    if resolution==120 && round(resolution/res_event(event))~=resolution/res_event(event)
        map=resizem_by_max(map,resolution/res_event(event));
    else
        map=resizem(map,resolution/res_event(event));
    end

    %distance in cells from grid box upper left border to shakemap upper left border
    %(negative when shakemap starts further north/west than grid box)
    ydist=round((box(2,2)-ulymap(event))*resolution);
    xdist=round((ulxmap(event)-box(1,1))*resolution);

    [a,b]=size(map);
    %prep for problem that shakemap might cross "world border"
    %old, but same: xdist2=(360-round((180-ulxmap(event))))*resolution-xdist;
    %xdist2 is distance in cells from left wordl border to grid box
    %xdist3 is distance in cells from left world border to end of
    %shakemap (if shakemap crosses world border)
    xdist2=round((box(1,1)+180-180*breakswitch)*resolution);
    xdist3=b-round((180+180*breakswitch-ulxmap(event))*resolution);

    %sample from area grid
    if (ulxmap(event)+xdim(event)*ncols<180+breakswitch*180) % check if shakemap crosses worldborder
        sample=grid(max(ydist+1,1):min(ydist+a,mapsize(1)),max(xdist+1,1):min(xdist+b,mapsize(2)));
    else  % Shakemap crosses world border
        if xdist>=mapsize(2) %left part of shakemap does not overlap with grid
            sample=grid(max(ydist+1,1):min(ydist+a,mapsize(1)),1:min(mapsize(2),xdist3-xdist2));
        elseif xdist2>xdist3 %right part of shakemap does not overlap with grid
            sample=grid(max(ydist+1,1):min(ydist+a,mapsize(1)),max(xdist+1,1):mapsize(2));
        else %both overlap
            left=grid(max(ydist+1,1):min(ydist+a,mapsize(1)),max(xdist+1,1):mapsize(2));
            right=grid(max(ydist+1,1):min(ydist+a,mapsize(1)),1:min(mapsize(2),xdist3-xdist2));
            sample=[left right];
        end
    end

    %IF MAP HAS ONES THEN INAREA otherwise NO
    if sum(sum(sample==1))>=1
        inArea=[inArea event];
    end
end

%% STEP 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Go through events that are in the grid and fit to matrix
if isempty(inArea)==0
    mpga=0;
end

%Go through events and fit to matrix
'Shakelap Events Match'
for i=1:length(inArea)
    mpga_1 = [];
    mpga_2 = [];
    mpga_10 = [];
    mpga(i)=0;
    years(i)=0;
    event=inArea(i);
    %map is shakemap sample
    eval(['map=ShakeMap.id' num2str(event) ';']);
    ncols=size(map,2);
    land=grid-1;

    % resize to correct resolution, if artifical lowering of resolution
    % to 120 was necessary, then use resizem_by_max
    if resolution==120 && round(resolution/res_event(event))~=resolution/res_event(event)
        map=resizem_by_max(map,resolution/res_event(event));
    else
        map=resizem(map,resolution/res_event(event));
    end

    %y-distance from grid box upper border to shakemap
    ydist=round((box(2,2)-ulymap(event))*resolution);
    xdist=round((ulxmap(event)-box(1,1))*resolution);

    [a,b]=size(map);
    %prep for problem that shakemap might cross "world border"
    %old, but same: xdist2=(360-round((180-ulxmap(event))))*resolution-xdist;
    %xdist2 is distance in cells from left wordl border to grid box
    %xdist3 is distance in cells from left world border to end of
    %shakemap (if shakemap crosses world border)
    xdist2=round((box(1,1)+180-180*breakswitch)*resolution);
    xdist3=b-round((180+180*breakswitch-ulxmap(event))*resolution);
    if (ulxmap(event)+xdim(event)*ncols<180+breakswitch*180) % check if shakemap crosses worldborder
        cross=0;
    else  % Shakemap crosses world border
        if xdist>=mapsize(2) %left part of shakemap does not overlap with grid
            cross=1;
        elseif xdist2>xdist3 %right part of shakemap does not overlap with grid
            cross=2;
        else %both overlap
            cross=3;
        end
    end

    %assign values
    for ypos=1:size(map,1)
        for xpos=1:size(map,2)
            cypos=ypos+ydist;
            if cross==0 || cross==2 || (cross==3 && ulxmap(event)+xpos/resolution<180+breakswitch*180)
                cxpos=xpos+xdist;
            elseif cross==1 || (cross==3 && ulxmap(event)+xpos/resolution>=180+breakswitch*180)
                    cxpos=xpos+xdist-360;
            end
            if cypos>0 && cypos<=mapsize(1) && cxpos>0 && cxpos<=mapsize(2)
                if land(cypos,cxpos)~=-1
                    mpga(i)=max(map(ypos,xpos),mpga(i));
                    years(i)=YMDHMS(event,1);
                    if map(ypos,xpos)>1
                        %store coordinates for future use (areas)
                        mpga_1=[mpga_1; cypos,cxpos];
                        if map(ypos,xpos)>2
                            mpga_2=[mpga_2; cypos,cxpos];
                            if map(ypos,xpos)>10
                                mpga_10=[mpga_10; cypos,cxpos];
                            end
                        end
                    end
                end
            end
        end
    end
    field = sprintf('id%d', event);
    coord1.(field) = mpga_1;
    coord2.(field) = mpga_2;
    coord10.(field) = mpga_10;
end
