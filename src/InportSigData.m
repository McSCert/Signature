function [inports] = InportSigData(address)
%  INPORTSIGDATA List Imports for a system.
%
%	Inputs:
%		address     Simulink model name.
%
%	Outputs:
%		inports     List of Inport names.

    inports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Inport');
    for i = 1:length(inports)
        inports{i} = get_param(inports{i}, 'Name');
    end