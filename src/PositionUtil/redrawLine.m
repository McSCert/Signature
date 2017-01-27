function redrawLine(address, block1, block2)
%% REDRAWLINE Redraw a line between blocks.
%   Note: Only works on non-branched lines and between blocks with at most
%   one inport or outport for the start and end blocks.
%
%   Inputs:
%       block1  Handle of the start block.
%       block2  Handle of the end block.
%
%   Outputs:
%       N/A

    % Get block1's current position
    block1Port = get_param(block1, 'PortHandles');
    block1Port = block1Port.Outport;

    % Get block2's curent position
    block2Port = get_param(block2, 'PortHandles');
    block2Port = block2Port.Inport;

    try
        delete_line(address, block1Port, block2Port);
    catch ME
        if strcmp(ME.identifier, 'Invalid line specifier')
            % no line to delete
        end
    end
    add_line(address, block1Port, block2Port);