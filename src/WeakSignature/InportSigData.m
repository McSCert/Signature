function [address, inports] = InportSigData(address)
	%  inportsigTable - A function that lists inputs for the level's
	%  signature
    %
    %   Typical use:
    %		[inaddress, InportGoto, InportFrom, inports, inGotoLength] = inportsig(address);
    %  
	%	Inputs:
	%		address: the name and location in the model
	%	Outputs:
	%		inports: List of inport names.
	%

    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    
    for i=1:length(inports)
        inports{i}=get_param(inports{i}, 'Name');
    end

end
        