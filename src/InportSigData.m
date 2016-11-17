function [address, inports] = InportSigData(address)
%  INPORTSIGDATA List Imports for a system.
%
%   Function:
%       INPORTSIGDATA(address)
%  
%	Inputs:
%		address     Simulink system path.
%
%	Outputs:
%       address     Simulink system path.
%		inports     List of Inport names.

    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    for i = 1:length(inports)
        inports{i} = get_param(inports{i}, 'Name');
    end
        