function [pulse changedout]=pdapply(pd,pulse,time,ind)
%function [pulse changed]=pdapply(pd, pulse,time)
% Apply a pulse dictionary to a pulse.  Return the new pulse.  Changed is
% true if the application was non-trivial
% new feature; an entry like '@1;foo,2;bar,...' will expand to foo for the
%   first pulse, 2 for the second, etc.

% (c) 2010 Hendrik Bluhm.  Please see LICENSE and COPYRIGHT information in plssetup.m.

if ~exist('time','var')
    time=[];
end
if ~exist('ind')
    ind='';
end

if ~strcmp(pulse.format,'elem')
    changedout=0;
    return;
end

% If pd is a cell array, apply each dictionary in sequence.  This allows
% for some *neat* effects. :p
if iscell(pd)
    changedout=0;
   while 1
     changed = 0;
     for i=1:length(pd)
       [pulse c2] = pdapply(pd{i},pulse,time,ind);
       changed = changed || c2;
     end
     changedout = changed | changedout;
     if ~changed
         break;
     end
   end
   return;
end

if ischar(pd)
    pd=pdload(pd,time);
end
changedout=0;
changed = 1;
while changed
    changed=0;
    for i=1:length(pulse.data)
        if ~changed && (pulse.data(i).type(1) == '#')         
            entries=regexp(pulse.data(i).type(2:end),'(\d*;)?([^,])*','tokens');
            for e=1:length(entries)
                if isempty(ind) || isempty(entries{e}{1}) || (ind == str2num(entries{e}{1}))
                    changed = 1;
                    pulse.data(i).type = entries{e}{2};
                end
            end
        end
        if ~changed && (pulse.data(i).type(1) == '@')
            if isfield(pd,pulse.data(i).type(2:end))
                nels=getfield(pd,pulse.data(i).type(2:end));
                if ischar(nels)
                    nels={nels};
                end
                if iscell(nels)
                    nels=struct('type',nels,'time',[],'val',[]);
                end
                template=pulse.data(i);
                pulse.data(i)=[];
                ot = ~isnan(template.time);
                ov = ~isnan(template.val);
                for j=1:length(nels)
                    if ischar(nels(j))
                        nels(j) = struct('type',nels(j),'time',[],'val',[]);
                    end
                    nels(j).time(ot)=template.time(ot);
                    nels(j).val(ov)=template.val(ov);
                end
                pulse.data = [pulse.data(1:i-1) orderfields(nels,pulse.data(1)) pulse.data(i:end)];
                changed=1;
                changedout=1;
                if isfield(pulse,'pardef') && ~isempty(pulse.pardef)
                    pulse.pardef = bump_pardef(pulse.pardef,i,length(nels)-1);
                end
                break;
                
            end
        end
    end
end
return

function pardef = bump_pardef(pardef, from, by)
  tobump=find(pardef(:,1) > from);
  pardef(tobump,1)=pardef(tobump,1)+by;
return;
