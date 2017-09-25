function [exchangetable,file_name,t_config, real_pitch] = autoshift(phoneme_stream,pitch_stream,pitch_bend,method)
%% shift correspond source audio to target pitch
%% for more detail use information, please infer to simple_concat.m
    %vardname = {'file_name','alias','offset','cons','cutoff','preutter','overlap'};
    oto_file = {'oto_high.ini','oto_mid.ini','oto_low.ini'};
    tone_list = {'C_','C#Db','D_','D#Eb','E_Fb','F_','F#Gb','G_','G#Ab','A_','A#Bb','B_'};
    exchangetable{1,7} = [];
    voice_dataset_path = 'E:\UTAU\App\UTAU\voice\Xia_Voice_Bank_TZH\';
    %% Parsing the information data (oto.ini)
    for ii=1:3
        oto_fp = fopen(oto_file{ii});
        curr_table = textscan(oto_fp, '%s %s %f %f %f %f %f ','Delimiter',',=');
        for jj=1:7
            exchangetable{1,jj} = vertcat( exchangetable{1,jj},curr_table{1,jj} );
        end
        fclose(oto_fp);
    end
    fund_tone = [57,51,46];
    fund_tonename = {'A4','D#4','A3'};
    source_name = {'high','mid','low'};
    %% pitch shifting for needed sound file
    if length(phoneme_stream) ~= length(pitch_stream)
        err('Input size not consistent!')
    end
    t_config = zeros([length(phoneme_stream),5]);
    for ii = 1:length(phoneme_stream)
        find_alias = cellfun(@(s)strfind(exchangetable{2},s),{phoneme_stream{ii}},'UniformOutput',false);
        position = zeros(size(exchangetable{2}));
        for jj = 1:length(find_alias{1})
            if ~isempty(find_alias{1}{jj})
                position(jj) = 1;
            end            
        end
            %% Find the shortest pitch distance for pitch shifting
        in_oct = regexp(pitch_stream{ii},'\d*','Match'); % extract octave number part in string
        find_tonation = cellfun(@(s)strfind(tone_list,s),{pitch_stream{ii}(1:end-1)},'UniformOutput',false);
        for jj=1:length(find_tonation{1})
            if ~isempty(find_tonation{1}{jj})
                pitch_pos = jj+12*str2double(in_oct)-1;
            end
        end
        distance = pitch_pos-fund_tone;
        [~,source_choice] = min(abs(distance));
            %% Choose the correct sound source
        target_alias = [phoneme_stream{ii},'_',fund_tonename{source_choice(1)}];
        find_sound_name = cellfun(@(s)strfind(exchangetable{2},s),{target_alias},'UniformOutput',false);
        for jj=1:length(find_sound_name{1})
            if ~isempty(find_sound_name{1}{jj})
                if find_sound_name{1}{jj}(1)==1
                    jj
                    for p_num = 1:5
                        t_config(ii,p_num) = exchangetable{p_num+2}(jj);
                    end
                    path = strcat(voice_dataset_path,source_name{source_choice},'\',exchangetable{1}(jj));
                    output_name = strcat('..\waves\',phoneme_stream{ii},'_',pitch_stream{ii}(1),pitch_stream{ii}(end),'.wav');
                    file_name{ii} = output_name;
                    real_pitch(ii) = (2^((pitch_pos+pitch_bend(ii)-8-49)/12)*440);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if method == 0
                        [x,fsAudio] = audioread(path{1});
                        clear parameter
                        parameter.fsAudio = fsAudio;
                        parameter.algTSM = @twoStepTSM;
                        y = pitchShiftViaTSM(x,(distance(source_choice)+pitch_bend(ii))*100,parameter);
                        clear parameter
                        parameter.anaHop = 512;
                        parameter.win = win(2048,1); % sin window
                        parameter.filterLength = 60;
                        y_formantAdapted = modifySpectralEnvelope(y,x,parameter);
                        audiowrite(output_name,y_formantAdapted,fsAudio);
                    else
                        run(path{1},distance(source_choice)+pitch_bend(ii),1,output_name,(2^((fund_tone(source_choice)-8-49)/12)*440));
                    end
                end
            end
        end
    end
end