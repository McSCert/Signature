        function yOffsetFinal=RepositionOutportSig(address,outGo, outFrom, outports, gotoLength, yOffset)
	%  RepositionOutportSig - A function that repositions and outport gotos
	%  and froms
    %
    %   Typical use:
    %		yOffsett=RepositionOutportSig(outaddress, OutportGoto, OutportFrom, outports, gotoLength, yOffset);
    %  
	%	Inputs:
	%		address: the name and location in the model
	%		outGo: the outport goto handles
	%		outFrom: the outport from handles
	%		outports: the outport handles
	%		gotoLength: the max length of the output signal names
	%		yOffset: the point in the y axis to start reposition of the
	%			blocks for other 
	%	Outputs:
	%		yOffsetFinal: the point in the y axis to start reposition of the
	%			blocks 
	%
	
            offset=50+10*gotoLength;
			%reposition outport
			for zt=1:length(outports)
				iPosition=get_param(outports{zt}, 'Position');
				iPosition(1)=20;
				if yOffset==0
					iPosition(2)=60;
				else
					iPosition(2)=yOffset+20;
				end
				iPosition(3)=30+20;
				iPosition(4)=iPosition(2)+14;
				yOffset=iPosition(4);
				set_param(outports{zt}, 'Position', iPosition);
				set_param(outFrom{zt}, 'Position', iPosition);
			end
			%reposition outport Goto
            for y=1:length(outGo)
                fPosition=get_param(outGo{y}, 'Position');
                fPosition(3)=fPosition(3)+10*gotoLength;
                set_param(outGo{y}, 'Position', fPosition);
			end
			%reposition outports againa
           for z=1:length(outports)
                bPosition=get_param(outports{z}, 'Position');
                bPosition(1)=bPosition(1)+offset;
                bPosition(3)=bPosition(3)+offset;
                set_param(outports{z}, 'Position', bPosition);                
		   end
			%reposition outport from
            for x=1:length(outFrom)
                gPosition=get_param(outFrom{x}, 'Position');
                gPosition(3)=gPosition(3)+10*gotoLength;
                set_param(outFrom{x}, 'Position', gPosition);
                
                outFromLineHanles=get_param(outFrom{x}, 'LineHandles');

                try
                    srcport=get_param(outFromLineHanles.Outport,'SrcPortHandle');
                    destport=get_param(outFromLineHanles.Outport,'DstPortHandle');
                    delete_line(outFromLineHanles.Outport)
                    add_line(address,srcport,destport,'autorouting','on');
                catch
                end
			end
			yOffsetFinal=yOffset;
        end 