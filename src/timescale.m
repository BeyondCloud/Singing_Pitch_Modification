function [Out] = timescale(sig,pitch_shift,t_scale,real_pitch)
%--------------------------------------------------------------------------
% main script to do pitch and time scale modification of speech signal
%--------------------------------------------------------------------------
% config contain all parameter of this program
global config;
config.pitchScale           = 2^(pitch_shift/12);	%pitch scale ratio
config.timeScale            = t_scale;	%time scale ratio
config.resamplingScale      = 1;		%resampling ratio to do formant shifting
config.reconstruct          = 1;		%if true do low-band spectrum reconstruction
config.displayPitchMarks    = 0;		%if true display pitch mark results
config.playWavOut           = 0;		%if true send output waveform to speaker
config.cutOffFreq           = 900;	%cut of frequency for lowpass filter
config.real_pitch = real_pitch;
%config.fileIn               = ['..\..\Xia_Voice_Bank_TZH',file_name];		%input file full path and name
%config.fileOut              = ['..\waves\',output_name];		%output file full path and name

%data contain analysis results
global data;
data.waveOut = [];		%waveform after do pitch and time scale modification
data.pitchMarks = [];	%pitch marks of input signal
data.Candidates = [];	%pitch marks candidates

WaveIn=sig;	%read input signal from file
WaveIn = WaveIn - mean(WaveIn); 				%normalize input wave
fs = 44100;
[LowPass] = LowPassFilter(WaveIn, fs, config.cutOffFreq); %low-pass filter for pre-processing
PitchContour = PitchEstimation(LowPass, fs);							%pitch contour estimation
PitchMarking(WaveIn, PitchContour, fs);										%do pitch marking and PSOLA
%audiowrite( config.fileOut,data.waveOut, fs);								%write output result to file

% if config.playWavOut
%     audioplay(data.waveOut, fs);
% end

if config.displayPitchMarks
    PlotPitchMarks(WaveIn, data.candidates, data.pitchMarks, PitchContour); %show the pitch marks
end
Out = data.waveOut;
end