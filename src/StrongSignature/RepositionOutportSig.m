function yOffsetFinal = RepositionOutportSig(address, outGo, outFrom, outports, gotoLength, yOffset)
% RESPOSITIONOUTPORTSIG
%
%   Function:
%       REPOSITIONOUTPORTSIG(address, outGo, outFrom, outports, gotoLength, yOffset)
%
%   Inputs:
%       address         Simulink system path.
%		outGo            Outport goto handles.
%		outFrom          Outport from handles.
%		outports         Outport handles.
%		gotoLength       Max length of the goto signal names.
%		yOffset          Point in the y-axis to start positioning blocks.
%
%	Outputs:
%		yOffsetFinal    Point in the y-axis to start repositioning blocks next time.

    offset = 50 + 10 * gotoLength;
    
    for zt = 1:length(outports)
        iPosition = get_param(outports{zt}, 'Position');
        iPosition(1) = 20;
        if yOffset == 0
            iPosition(2) = 60;
        else
            iPosition(2) = yOffset + 20;
        end
        iPosition(3) = 30 + 20;
        iPosition(4) = iPosition(2) + 14;
        yOffset = iPosition(4);
        set_param(outports{zt}, 'Position', iPosition);
        set_param(outFrom{zt}, 'Position', iPosition);
    end
    
    for y = 1:length(outGo)
        fPosition = get_param(outGo{y}, 'Position');
        fPosition(3) = fPosition(3) + 10 * gotoLength;
        set_param(outGo{y}, 'Position', fPosition);
    end
    
   for z = 1:length(outports)
        bPosition = get_param(outports{z}, 'Position');
        bPosition(1) = bPosition(1) + offset;
        bPosition(3) = bPosition(3) + offset;
        set_param(outports{z}, 'Position', bPosition);                
   end
    
    for x = 1:length(outFrom)
        gPosition = get_param(outFrom{x}, 'Position');
        gPosition(3) = gPosition(3) + 10 * gotoLength;
        set_param(outFrom{x}, 'Position', gPosition);

        outFromLineHandles = get_param(outFrom{x}, 'LineHandles');
        srcport = get_param(outFromLineHandles.Outport, 'SrcPortHandle');
        destport = get_param(outFromLineHandles.Outport, 'DstPortHandle');
        
        delete_line(outFromLineHandles.Outport)
        add_line(address, srcport, destport, 'autorouting', 'on');
    end
    yOffsetFinal = yOffset;