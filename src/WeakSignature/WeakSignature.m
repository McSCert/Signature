function [metrics signatures] = WeakSignature(address, exportType, ...
    hasUpdates, sys, docFormat)
% WEAKSIGNATURE Generate documentation/model of a system's weak signature.
%
%   Inputs:
%       address     Simulink model name or path.
%
%       exportType  Number indicating whether to export the signature as
%                   a model(0) or as documentation(1).
%
%       hasUpdates  Number indicating whether reads and writes in the same
%                   subsystem are kept separate(0), or combined and listed
%                   as an update(1).
%
%       sys         Name of the system to generate the documentation for.
%                   It can be a specific subsystem name, or 'All' to get
%                   documentation for the entire hierarchy.
%
%       docFormat   Number indicating which docmentation type to generate:
%                   no doc(0), .txt(1), .tex(2), .doc(3), else no doc.
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
%   Examples:
%       WeakSignature('SignatureDemo', 0, 1, 'All', 0)
%           Generates a weak signature model, that include updates, for
%           the model SignatureDemo and all its subsystems.
%
%       WealSignature('SignatureDemo', 1, 1, 'SignatureDemo/Subsystem/Subsystem0', 0)
%           Generates weak signature documentation, that includes updates,
%           for a specific subsystem of SignatureDemo, as a .txt file.

    % Check number of arguments
    try
        assert(nargin == 5)
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Not enough arguments.' char(10)])
        return
    end

    % Check address argument
    % 1a) Check that address is a model and is open
    try
        assert(ischar(address));
        assert(bdIsLoaded(bdroot(address)));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Invalid argument: address. Model may not be loaded or name is invalid.' char(10)])
        return
    end
    % Check address argument
    % 1a) Check that address is a model and is open
    try
        assert(ischar(address));
        assert(bdIsLoaded(bdroot(address)));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Invalid argument: address. Model may not be loaded or name is invalid.' char(10)])
        return
    end
    % 1b) Check that address is the root system
    % i.e. the user isn't passing a subsystem
    try
       assert(strcmp(get_param(address, 'Type'), 'block_diagram'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Warning using ' mfilename ':' char(10) ...
                ' Invalid argument: address. It must be the root system name.' char(10) ...
                ' Using ' bdroot(address) ' instead of ' address '.' char(10)])
            address = bdroot(address);
        end
    end

    % 1c) Check that model is unlocked
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

    % 1d) Check that model doesn't already have a signature
    try
        assert(isempty(regexp(bdroot(address), '.*(_WeakSig|_StrongSig).*', 'once')));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Cannot generate a signature when one exists.' ...
                '  The filename indicates that there may already be' char(10) ...
                ' a signature in the model.'])
            return
        end
    end

    % 2) Check that exportType is in range
    try
        assert(any(exportType == [0,1]))
        assert(length(exportType) == 1)
    catch ME
         if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid argument: exportType. Valid input is 0 or 1.'])
            return
        end
    end

    % 3) Check that hasUpdates is in range
    try
        assert(any(hasUpdates == [0,1]))
        assert(length(hasUpdates) == 1)
    catch ME
         if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid argument: hasUpdates. Valid input is 0 or 1.'])
            return
        end
    end

    % 4) Check that sys is an exisiting Subsystem
    if ~strcmp(sys, 'All')
        try
            find_system(sys, 'SearchDepth', 0, 'BlockType', 'SubSystem');
        catch
            disp(['Error using ' mfilename ':' char(10) ...
                    ' Invalid argument: sys. Subsystem ' sys ' is not found.'])
            return
        end
    end

    % 5) Check that docFormat is in range
    try
        assert(isnumeric(docFormat))
        assert(length(docFormat) == 1)
        %assert(any(docFormat == [0,1,2]))
    catch ME
         if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid argument: docFormat. Valid input is 0, 1, or 2.'])
            return
        end
    end

    if exportType % If producing documentation
        dataTypeMap = mapDataTypes(address);
        [metrics, signatures] = ...
            TieInData(address, 0, {}, {}, {}, {}, {}, {}, sys, {}, ...
                {}, hasUpdates, docFormat, dataTypeMap);
    else % If producing model
        sigModel = strcat(address, '_WeakSig');

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
        set_param(sigModel, 'Lock', 'off');

        % Update to new model name
        if ~strcmp(sys, 'All')
            i = strfind(sys, address);
            i = i(1);
            sys =  [sys(1:i-1), sigModel, sys(i+length(address):end)]; % Replace first occurance
        end
        address = sigModel;

        % Generate signature
        TieIn(address, 0, {}, {}, {}, {}, {}, {}, hasUpdates, sys);
        metrics = 0;
        signatures = {};

        % Automatically save, otherwise if the user closes the new model,
        % they will be left with a model named as a signature, but without
        % the signature
        save_system(address, sigModel);

        if ~strcmp(sys, 'All')
            open_system(sys);
        end
    end