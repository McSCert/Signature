function [address, outports] = OutportSigData(address)
% OUTPORTSIGDATA
%
%   Inputs:
%       address     Simulink system path.
%
%   Outputs:
%       address     Simulink system path.
%       outports

    outports = find_system(address, 'SearchDepth', 1, 'BlockType', 'Outport');
    for i = 1:length(outports)
        outports{i} = get_param(outports{i}, 'Name');
    end