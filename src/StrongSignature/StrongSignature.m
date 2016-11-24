function [metrics signatures] = StrongSignature(address, exportType,...
    hasUpdates, system, docFormat)
% STRONGSIGNATURE Generate documentation of a system's strong signature or
% 	produce the model of the strong signature.
%
%   Function:
%       STRONGSIGNATURE(address, exportType, hasUpdates, system, docFormat)
%
%   Inputs:
%       address     Simulink model name or path.
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
%       metrics     Cell array listing the system and its subsystems, with
%                   the size of their signature (i.e. number of elements in 
%                   the signature).
%
%       signatures  Cell array of signature data for the system and its 
%                   subsystems. Signature data includes: Subsystem, Size, 
%                   Inports, Outports, GlobalFroms, GlobalGotos, 
%                   ScopedFromTags, ScopedGotoTags, DataStoreReads, 
%                   DataStoreWrites, Updates, GotoTagVisibilities, and 
%                   DataStoreMemories.
%
%   Example 1:
%       StrongSignature('SignatureDemo', 0, 1, 'All', 0)
%           Generates a strong signature model, that include updates, for 
%           the model 'SignatureDemo' and all its subsystems.
%
%   Example 2:
%       StrongSignature('SignatureDemo', 1, 1, 'SignatureDemo/Subsystem/Subsystem0', 0)
%           Generates strong signature documentation, that includes updates, 
%           for a specific subsystem of 'SignatureDemo', as a .txt file.

    % Check number of arguments
    try
        assert(nargin == 5)
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Not enough arguments.' char(10)])
        return
    end        

    % Check address argument
    % 1) Check model at address is open
    try
       assert(ischar(address));
       assert(bdIsLoaded(bdroot(address)));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Invalid argument: address. Model may not be loaded or name is invalid.' char(10)])
        return
    end

    % 2) Check that model is unlocked
    try
        assert(strcmp(get_param(bdroot(address), 'Lock'), 'off'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' File is locked.'])
            return
        end
    end

    % Check system argument
    try
        find_system(system, 'SearchDepth', 0, 'BlockType', 'SubSystem');
    catch
        disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid argument: system. Subsystem ' system ' is not found.'])
        return
    end
    
    if exportType % If producing documentation
        dataTypeMap = mapDataTypes(address);
        [scopeGotoAddOut, DataStoreWriteAddOut, DataStoreReadAddOut, ...
            scopeFromAddOut, globalGotosAddOut, globalFromsAddOut, ...
            metrics, signatures] = ...
            TieInStrongData(address, system, hasUpdates, docFormat, dataTypeMap);
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
        [carryOut] = TieInStrong(address, hasUpdates, system);
        metrics = 0;
        signatures = {};
        
        % Automatically save, otherwise if the user closes the new model,
        % they will be left with a model named as a signature, but without
        % the signature
        save_system(address, sigModel);
    end