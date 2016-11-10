function [metrics signatures] = StrongSignature(address, exportType, hasUpdates, sys, docFormat)
% STRONGSIGNATURE Generate documentation of a system's strong signature or
% 	produce the model of the strong signature.
%
%   Function:
%       STRONGSIGNATURE(address, exportType, hasUpdates, sys, docFormat)
%
%   Inputs:
%       address     Simulink system path.
%
%       exportType  Boolean indicating whether to export the signature as
%                   a model(0) or as documentation (1).
%
%       hasUpdates  Boolean indicating whether updates are to be 
%                   included in the signature.
%
%       sys         Name of the system to generate the documentation for. 
%                   One can use a specific system name, or use 'All' to get 
%                   documentation of the entire hierarchy.
%
%       docFormat   Number indicating which docmentation type to 
%                   generate: .txt(0) or .tex(1).
%
%   Outputs:
%       metrics     ???
%
%       signatures  ???
%
%   Example:
%       StrongSignature('SignatureDemo', 1, 1, 'All', 0)
%           Generates strong signature documentation for model 'SignatureDemo'
%           and all its subsystems as .txt, including updates.

    set_param(address, 'Lock', 'off');
    
    if exportType % If producing documentation
        dataTypeMap = mapDataTypes(address);
        [scopeGotoAddOut, DataStoreWriteAddOut, DataStoreReadAddOut, ...
            scopeFromAddOut, globalGotosAddOut, globalFromsAddOut, ...
            metrics, signatures] = ...
            TieInStrongData(address, sys, hasUpdates, docFormat, dataTypeMap);
    else % If producing model
        sigModel = strcat(address, '_STRONG_SIGNATURE');
        
        % Create signature model
        if exist(sigModel, 'file') == 4
            n = 1;
            while exist(strcat(sigModel, num2str(n)), 'file') == 4
                n = n + 1;
            end
            sigModel = strcat(sigModel, num2str(n));   
        end
        save_system(address, sigModel, 'BreakAllLinks', true);
        open_system(sigModel);
        address = sigModel;
        set_param(address, 'Lock', 'off');

        % Generate signature
        [carryOut] = TieInStrong(address, hasUpdates, sys);
        metrics = 0;
        signatures = {};
        
        % Automatically save, otherwise if the user closes the new model,
        % they will be left with a model named as a signature, but without
        % the signature
        save_system(address, sigModel);
    end