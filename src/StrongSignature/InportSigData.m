function [address, inports] = InportSigData(address)
%  INPORTSIGDATA List inputs for the level's signature.
%
%   Function:
%       INPORTSIGDATA(address)
%  
%	Inputs:
%		address     Name and location in the model
%
%	Outputs:
%       address
%		inports     Inport handles

    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    for i = 1:length(inports)
        inports{i} = get_param(inports{i}, 'Name');
    end
        