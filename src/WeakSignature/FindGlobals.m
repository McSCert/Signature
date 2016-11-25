function globalGotos = FindGlobals(address)
% GLOBALGOTOS Find names of global Gotos.
%
%   Inputs:
%		address      The name and location of the system.
%
%   Outputs:
%   	globalGotos	 List of global Goto names.

	allBlocks = find_system(address, 'SearchDepth', 1);
	allBlocks = setdiff(allBlocks, address);

	globalGotos = {};
	for z = 1:length(allBlocks)
		Blocktype = get_param(allBlocks{z}, 'Blocktype');
		switch Blocktype
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