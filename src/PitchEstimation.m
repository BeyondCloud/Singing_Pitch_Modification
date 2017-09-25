%--------------------------------------------------------------------------
% pitch estimation using autocorrelation method
%--------------------------------------------------------------------------
function PitchContour = PitchEstimation(x, fs)
% Init parameters
FrameSize = round(fs * 0.05); %number of sample in 30 ms
FrameRate = round(fs * 0.01); %number of sample in 10 ms
WaveLength = length(x);
NumberOfFrames = floor((WaveLength - FrameSize) / FrameRate) + 2;
FramePitch = zeros(NumberOfFrames + 2, 1);

% Calculate pitch for each frame
Range = 1 : FrameSize;
for Count = 2 : NumberOfFrames
    FramePitch(Count) = PitchDetection(x(Range), fs);
    Range = Range + FrameRate;
end

% Using median filter for Pos-processing
FramePitch = medfilt1(FramePitch, 2);

% calculate pitch contour
PitchContour = zeros(WaveLength, 1);
for i = 1 : WaveLength- FrameSize
    PitchContour(i) = FramePitch(floor(i / FrameRate) + 1);
end
