%--------------------------------------------------------------------------
% Do pitch marking based-on pitch contour using dynamic programming
%--------------------------------------------------------------------------
function pm = PitchMarking(x, p, fs)

global config;
global data;
if length(p) > 44100
     st = find((p > 1));
 p(st) = repmat(config.real_pitch,size(p(st)));
[u, v] = UVSplit(p);
else
    period = round(fs/config.real_pitch*2.5);
p(period:max(end-period,period*4)) = config.real_pitch;
[u, v] = UVSplit(p);
v = [v(1,1), v(end,end)];
end
%[~,locs] = findpeaks(x,'NPeaks',10,'MinPeakDistance',44);
%p(locs) = repmat(config.real_pitch,size(p(locs)));
%split voiced / unvoiced segments
%[u, v] = UVSplit(p);
%  pitch marking for voiced segments
%v = [v(1,1), v(end,end)];
pm = [];
ca = [];
first = 1;
waveOut = [];
fact = 2;
for i = 1 : length(v(:,1))
    range = (v(i, 1) : v(i, 2));
    avgperiod = round(fs/mean(p(range)));
    in = x(range);
    rangem = round(max(v(i, 1)-fact*avgperiod,1) : v(i, 2)+fact*avgperiod );
    w = blackman(length(2*avgperiod+1));
    markin = conv(x(rangem),w,'same');
    markin = markin(fact*avgperiod+1:end-fact*avgperiod);
    [marks, cans] = VoicedSegmentMarking(markin, p(range), fs);

    pm = [pm  (marks + range(1))];
    ca = [ca;  (cans + range(1))];
    
    ra = first:marks(1)+range(1)-1;
    first = marks(length(marks))+range(1)+1;
    waveOut = [waveOut UnvoicedMod(x(ra), fs, config.timeScale)'];
    waveOut = [waveOut PSOLA(in, fs, marks)];
end

data.waveOut = waveOut;
data.pitchMarks = pm;
data.candidates = ca;

