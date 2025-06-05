%% EMS Data Analysis and Visualization

fs = 1000; % Sampling frequency in Hz
window = 100; % Moving average window for envelope
subjects = {'S1', 'S2'};
freq_stages = {'Control', 'CNS'};          % For frequency analysis
voltage_stages = {'BeforeEMS', 'CNS'};     % For voltage analysis
force_stages = voltage_stages;             % Same for force

% Band-pass filter from 100–300 Hz
bpFilt = designfilt('bandpassiir','FilterOrder',4, ...
         'HalfPowerFrequency1',100,'HalfPowerFrequency2',300, ...
         'SampleRate',fs);

results = struct(); % Store all computed values

%% Frequency Analysis
for s = 1:length(subjects)
    subj = subjects{s};
    for stage = 1:length(freq_stages)
        cond = freq_stages{stage};
        fname = sprintf('%s_%s.mat', subj, cond);
        if isfile(fname)
            d = load(fname);
            emg = d.data;
            emg_filt = filtfilt(bpFilt, emg);

            % FFT
            L = length(emg_filt);
            f = fs*(0:(L/2))/L;
            Y = fft(emg_filt);
            P = abs(Y/L);
            P1 = P(1:L/2+1);
            [~, peakIdx] = max(P1);
            peakFreq = f(peakIdx);

            % Scale for chart to match visual range
            results.(subj).(cond).PeakFreq = peakFreq / 3;

            % FFT Plot with Peak Frequency Marked
            figure('Visible','off','Color','w');
            plot(f, P1, 'b', 'LineWidth', 1.5); hold on;
            plot(peakFreq, P1(peakIdx), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
            title(sprintf('FFT Spectrum - %s %s', subj, cond));
            xlabel('Frequency (Hz)'); ylabel('Amplitude');
            grid on;
            legend('FFT Spectrum', sprintf('Peak = %.1f Hz', peakFreq), 'Location', 'northeast');
            
            % Save figure
            saveas(gcf, sprintf('%s_%s_FFT.png', subj, cond));
            close;
        end
    end
end

%% Voltage Analysis (Max/Mean Voltage in cV)
for s = 1:length(subjects)
    subj = subjects{s};
    for v = 1:length(voltage_stages)
        stage = voltage_stages{v};
        fname = sprintf('%s_%s.mat', subj, stage);
        if isfile(fname)
            d = load(fname);
            emg = d.data;
            env = abs(emg);
            env_smoothed = movmean(env, window);

            % Convert to centivolts (cV)
            maxV = max(env_smoothed) * 100;
            meanV = mean(env_smoothed) * 100;

            results.(subj).(stage).MaxV = maxV;
            results.(subj).(stage).MeanV = meanV;
        end
    end
end

%% Force Analysis (Max/Mean in Newtons)
for s = 1:length(subjects)
    subj = subjects{s};
    for fidx = 1:length(force_stages)
        stage = force_stages{fidx};
        fname = sprintf('%s_%s_Force.mat', subj, stage);
        if isfile(fname)
            d = load(fname);
            force = d.data;

            maxF = max(force);
            meanF = mean(force);

            results.(subj).(stage).MaxF = maxF;
            results.(subj).(stage).MeanF = meanF;
        end
    end
end

%% Plot Grouped Bar Chart
data = [
    results.S1.Control.PeakFreq,     results.S1.CNS.PeakFreq,     results.S2.Control.PeakFreq,     results.S2.CNS.PeakFreq;
    results.S1.BeforeEMS.MaxV,       results.S1.CNS.MaxV,          results.S2.BeforeEMS.MaxV,       results.S2.CNS.MaxV;
    results.S1.BeforeEMS.MeanV,      results.S1.CNS.MeanV,         results.S2.BeforeEMS.MeanV,      results.S2.CNS.MeanV;
    results.S1.BeforeEMS.MaxF,       results.S1.CNS.MaxF,          results.S2.BeforeEMS.MaxF,       results.S2.CNS.MaxF;
    results.S1.BeforeEMS.MeanF,      results.S1.CNS.MeanF,         results.S2.BeforeEMS.MeanF,      results.S2.CNS.MeanF;
];

% Labels and Colors
metrics = {'Peak Frequency', 'Max Voltage (cV)', 'Mean Voltage', 'Max Force', 'Mean Force'};
colors = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.5 0.8 0.3; 0.6 0.4 0.8]; % Blue, Red, Green, Purple

% Bar Plot
figure('Color','w');
b = bar(data, 'grouped');
for i = 1:4
    b(i).FaceColor = colors(i,:);
end

set(gca, 'XTickLabel', metrics, 'FontSize', 11);
ylabel('Value', 'FontSize', 12);
legend({'S1', 'CNS S1', 'S2', 'CNS S2'}, 'Location', 'northoutside', 'Orientation', 'horizontal');
title('Summary of EMS Effects on Signal and Force Metrics');
xtickangle(15);
grid on;