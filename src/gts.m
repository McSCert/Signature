function system = gts
%simple function to get top level of current system
%Should replace all uses of this with bdroot
    address=gcs;
    numChars=strfind(address, '/');
    if ~isempty(numChars)
        system=address(1:numChars(1)-1);
    else
        system=address;
    end

end

