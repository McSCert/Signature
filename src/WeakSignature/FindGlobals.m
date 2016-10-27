function globalGotos=FindGlobals(address)
%findGlobals - A function that recurses through all subsystems of a system,
%               and passes out a list of the names of global gotos.
%
%   INPUTS
%
%   address: The address of the system to execute findGlobals.
%
%   OUTPUTS
%
%   globalGotos: A list of global goto names to be passed out.
	allBlocks=find_system(address, 'SearchDepth', 1);
	allBlocks=setdiff(allBlocks, address);
	globalGotos={};
	for z=1:length(allBlocks)
		Blocktype=get_param(allBlocks{z}, 'Blocktype');
		switch Blocktype
			case 'Goto'
				TagVisibility=get_param(allBlocks{z}, 'TagVisibility');
				if strcmp(TagVisibility, 'global')
					globalGotos{end+1}=get_param(allBlocks{z}, 'GotoTag');
				end
			case 'From'
				TagVisibility=get_param(allBlocks{z}, 'TagVisibility');
				if strcmp(TagVisibility, 'global')
					globalGotos{end+1}=get_param(allBlocks{z}, 'GotoTag');
				end				
			case 'SubSystem'
				globalGotos=[FindGlobals(allBlocks{z}) globalGotos];
		end
    end