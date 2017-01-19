function globalGotos = FindGlobals(address)
% GLOBALGOTOS Find names of global Gotos.
%
%   Inputs:
%		address      The name and location of the system.
%
%   Outputs:
%   	globalGotos	 List of global Goto names.

	globalGotos = {};
    
	allBlocks = find_system(address, 'SearchDepth', 1);
    for z = 2:length(allBlocks) % 2 to omit the current system
        blocktype = get_param(allBlocks{z}, 'Blocktype');
        switch blocktype
            case 'Goto'
                TagVisibility = get_param(allBlocks{z}, 'TagVisibility');
                if strcmp(TagVisibility, 'global')
                    globalGotos{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                end
            case 'From'
                TagVisibility = get_param(allBlocks{z}, 'TagVisibility');
                if strcmp(TagVisibility, 'global')
                    globalGotos{end + 1} = get_param(allBlocks{z}, 'GotoTag');
                end				
            case 'SubSystem'
                globalGotos = [FindGlobals(allBlocks{z}) globalGotos];
        end
    end