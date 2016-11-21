function [metrics signatures] = WeakSignature(address, exportType,...
    hasUpdates, system, docFormat)
% WEAKSIGNATURE Generate documentation of a system's weak signature or
% 	produce the model of the weak signature.
%
%   Function:
%       WEAKSIGNATURE(address, exportType, hasUpdates, system, docFormat)
%
%   Inputs:
%       address     The Simulink model path.
%
%       exportType  Boolean indicating whether to export the signature as
%                   a model(0) or as documentation (1).
%
%       hasUpdates  Boolean indicating whether updates are to be 
%                   included in the signature.
%
%       system      Name of the system to generate the documentation for. 
%                   One can use a specific system name, or use 'All' to get 
%                   documentation of the entire hierarchy.
%
%       docFormat   Number indicating which docmentation type to 
%                   generate: .txt(0) or .tex(1).
%
%   Outputs:
%       metrics     List of structs with fields Subsystem and Size (of
%                   signature)
%
%       signatures  List of structs with fields Subsystem, Size, 
%                   Inports, Outports, GlobalFroms, GlobalGotos, 
%                   ScopedFromTags, ScopedGotoTags, DataStoreReads, 
%                   DataStoreWrites, Updates, GotoTagVisibilities, and 
%                   DataStoreMemories (of signature)
%
%   Example:
%       WeakSignature('SignatureDemo', 1, 1, 'All', 0)
%           Generates weak signature documentation for model 'SignatureDemo'
%           and all its subsystems as .txt, including updates.

    set_param(address, 'Lock', 'off');

    if exportType % If producing documentation
        dataTypeMap = mapDataTypes(address);
        [metrics, signatures] = ...
            TieInData(address, 0, {}, {}, {}, {}, {}, {}, system, {}, {}, hasUpdates, docFormat, dataTypeMap);
    else % If producing model
        sigModel = strcat(address, '_WEAK_SIGNATURE');
        
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
        TieIn(address, 0, {}, {}, {}, {}, {}, {}, hasUpdates);
        metrics = 0;
        signatures = {};
        
        % Automatically save, otherwise if the user closes the new model,
        % they will be left with a model named as a signature, but without
        % the signature
        save_system(address, sigModel);
    end