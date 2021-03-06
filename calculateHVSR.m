function [HVSR_R, HVSR_X, HVSR_Y, XX, YY, VV, RR] = ...
	calculateHVSR(signal, frame_starts, window, draw)

    global HVSR 
	persistent SkipFrames
	
	frame_size = length(window);
	fftSmoothN = HVSR.params.fftSmoothN;
	Fs = HVSR.Fs;
	
    freq = Fs*(0:frame_size/2-1)'/frame_size;
	
	[b, a] = butter(4, 2*0.1/Fs, 'high');
% 	signal = filtfilt(b, a, signal);

    window_size = length(window);
    Nch = floor(size(signal,2)/3);
    Nframes = length(frame_starts);
    HVSR_R = zeros(window_size/2, Nframes, Nch);
    HVSR_Y = HVSR_R;
    HVSR_X = HVSR_R;
	VV = HVSR_R;
	RR = HVSR_R;
	XX = HVSR_R;
	YY = HVSR_R;
	
	window = repmat(window, 1, Nch*3);
	if(draw~=0)
		axes(draw);
		hold on
	end
    for ch=1:1:Nch
        for idx = frame_starts
            windata = signal(idx:idx+window_size-1,(3*ch-2):(3*ch)).*window;
            fftdata = abs(fft(windata, window_size, 1));
            fftdata = fftdata(1:window_size/2,:)+fftdata(end:-1:1+window_size/2,:);
			if(fftSmoothN >=1)
				fftdata = smoothFFT(fftdata, fftSmoothN, freq, 0);
			end
				
            X = fftdata(:,1);
            Y = fftdata(:,2);
            Z = fftdata(:,3);
			Z(1) = Z(2);
            R = sqrt(X.^2 + Y.^2);
            HVSR_R(:,frame_starts==idx,ch) = R ./ Z;
            HVSR_X(:,frame_starts==idx,ch) = X ./ Z;
            HVSR_Y(:,frame_starts==idx,ch) = Y ./ Z;
			VV(:,frame_starts==idx,ch) = Z;
			RR(:,frame_starts==idx,ch) = R;
			XX(:,frame_starts==idx,ch) = X;
			YY(:,frame_starts==idx,ch) = Y;
			if(draw~=0)
				if(SkipFrames)
					SkipFrames = SkipFrames - 1;
				else
					cla(draw);
					draw.XScale = 'log';
					semilogx(freq, Z, 'LineWidth', 1, 'Parent', draw);
					semilogx(freq, R, 'LineWidth', 1, 'Parent', draw);
					semilogx(freq, R./Z, 'LineWidth', 2, 'Parent', draw)
					grid on; xlim([min(freq),50]);
					legend('V','R','HVSR');
					drawnow;
					SkipFrames = 0;
				end
			end
        end
    end
end