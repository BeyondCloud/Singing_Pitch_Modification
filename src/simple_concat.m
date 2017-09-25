function simple_concat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  TODO: Dynamic contour and pitch bend
%    A simple program for pitch shifting and time scaling
%    Based on 1) phase locking phase vocoder (developed by TSM toolbox)
%                http://www.dafx14.fau.de/papers/dafx14_jonathan_driedger_tsm_toolbox_matlab_imple.pdf
%             2)TD - PSOLA
%                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    addpath('tsm')
    %% Input setup
    ph = {'- hao','- yi','- duo','- mei','ei','- li','- di','- mo','- li','yi','- hua'};
    cons = [1    ,1    ,1       ,1     ,0    ,1     ,1     ,1   ,1    ,0     ,1   ];
    pitch = {'E_4','E_4','G_4','A_4','C_5','C_5','A_4','G_4','G_4','A_4','G_4'};
    pitch_bend = [0,0,0,0,0,-0.5,0,0.2,-0.5,0,0];
    method = 0;         % 0 for phase vocoder, 1 for TD - PSOLA. In generally, phase vocoder is better than PSOLA.
    %% shift the  pitch of original sound
    [table,file_name,time_config, real_pitch] = autoshift(ph,pitch,pitch_bend,method);
    outwave = [];
    fs = 44100;
    %% tempo information
    tempo = round((60/140)*44100);
    tempo_series=[2,1,1,1.1,0.9,1,1,2,1.1,0.9,3].*tempo;
    first = 1;
    timescale = 1;
    
    for ii = 1:length(file_name)
        ii
        if isempty(file_name{ii})
            continue;
        end
        
        [sample,fs] = audioread(file_name{ii});
        offset = round((time_config(ii,1))*fs/1000);
        
        if time_config(ii,3) < 0
            cutoff = length(sample)+round(time_config(ii,3)*fs/1000);
        else
            cutoff = round(time_config(ii,3)*fs/1000);
        end
        
        preutter = offset + 4410 + round((time_config(ii,4)+50)*fs/1000);%max(cutoff-441*15,);
        if cons(ii)==0
            preutter = preutter+4410*2;
        end
        %% sgementation time information
        if cons(ii)
            cutoff= round((preutter*0.8 + cutoff*0.2));
        else
            cutoff= round((preutter*0.9 + cutoff*0.1));
        end
        
        sig = sample(offset:cutoff)';
        sig_mid = sample(preutter:cutoff)';
        vary_part = (length(sig)-length(sig_mid));
        realExtL = abs(tempo_series(ii)-vary_part);
        %% Time scaling for correct duration
        if timescale
        parameter.synHop = round(44100*0.1*0.1);
        parameter.win = hann(round(44100*0.1));
        parameter.phaseLocking = 1;
        y = pvTSM(sig_mid',realExtL/length(sig_mid),parameter)';
        sig = [sample(offset:preutter)',y];
        end
        %sig = linear_fade(sample(offset:preutter)',y,0.05);
        length(sig)
        if cons(ii)
            ratio = 0.1;
        else
            ratio = 0.15;
        end
        if first == 1 || ratio == 0
            outwave = [outwave,sig];
            first = 0;
        else
            outwave = linear_fade(outwave,sig,ratio);
        end
        %% Dynamics contour
    end
    audiowrite('..\waves\simple_concat.wav',outwave,fs);
end

function out = linear_fade(a,b,lap_ratio) % An simple concatanation by linear decay and growth
    lap_len = round(length(b) * lap_ratio);
    fade_out = [1:-1/(lap_len-1):0];
    fade_in = fliplr(fade_out);
    lap = a(length(a)-lap_len+1:end).*fade_out+ b(1:lap_len).*fade_in;
    out = [a(1:length(a)-lap_len) lap b(lap_len+1:end)];
 end