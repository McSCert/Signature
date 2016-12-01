function yOffsetFinal = RepositionOutportSig(address,outGo, outFrom, outports, gotoLength, yOffset)
%  REPOSITIONOUTPORTSIG Reposition Outports and Outport Goto/Froms

%   Inputs:
%       address     The name and location in the model.
%       outGo       Outport Goto handles.
%       outFrom     Outport From handles.
%       outports    Outport handles.
%       gotoLength  Max length of the output signal names.
%       yOffset     Point in the y-axis to start positioning blocks.
%
%   Outputs:
%       yOffsetFinal Point in the y-axis to start repositioning blocks next time.

    tagLength = 10 * gotoLength;
    
    % Reposition Outport
    for zt = 1:length(outports)
        iPosition = get_param(outports{zt}, 'Position');
        iPosition(1) = 20;
        if yOffset == 0
            iPosition(2) = 60;
        else
            iPosition(2) = yOffset + 20;
        end
        iPosition(3) = 20 + 30;
        iPosition(4) = iPosition(2) + 14;
        yOffset = iPosition(4);
        set_param(outports{zt}, 'Position', iPosition);
        set_param(outFrom{zt}, 'Position', iPosition);
    end

    % Reposition Outport Goto
    for y = 1:length(outGo)
        fPosition = get_param(outGo{y}, 'Position');
        fPosition(3) = fPosition(3) + tagLength;
        set_param(outGo{y}, 'Position', fPosition);
    end

    % Reposition Outport again
    offset = 50 + tagLength; % Dist between Goto and Outport in Signature
    for z = 1:length(outports)
        bPosition = get_param(outports{z}, 'Position');
        bPosition(1) = bPosition(1) + offset;
        bPosition(3) = bPosition(3) + offset;
        set_param(outports{z}, 'Position', bPosition);                
    end

    % Reposition Outport Froms
    for x = 1:length(outFrom)
        gPosition = get_param(outFrom{x}, 'Position');
        gPosition(3) = gPosition(3) + tagLength;
        set_param(outFrom{x}, 'Position', gPosition);

        outFromLineHandles = get_param(outFrom{x}, 'LineHandles');

        try
            srcPort = get_param(outFromLineHandles.Outport, 'SrcPortHandle');
            destPort = get_param(outFromLineHandles.Outport, 'DstPortHandle');
            delete_line(outFromLineHandles.Outport)
            add_line(address, srcPort, destPort, 'autorouting', 'on');
        catch
            % Do nothing
        end
    end
    % Update offset output
    yOffsetFinal = yOffset;