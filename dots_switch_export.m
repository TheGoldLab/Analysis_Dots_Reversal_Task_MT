
function dots_switch_export
addpath(genpath([pwd,'/FIRA']))
data_path = '/Users/hannahlefumat/Box Sync/Matlab_postdoc/Dot Motion Task/data/';
% chdir(data_path);
files = dir(strcat(data_path, 'ch*.plx'));
nfiles = length(files);
spmfile = 'spmLDdots_reversal';
for i=1:nfiles
    file = files(i).name;
    if isempty(dir([file(1:end-4) 'good.csv']))
        full_name = [data_path file];
        file_out = [full_name(1:end-4) '_all.mat'];
        export_file(full_name, spmfile, file_out);
    end
end


function export_file(full_name, spmfile, file_out)

    if isempty(dir(file_out))
        bFile(full_name, [], spmfile, file_out, 'all', [15 16], 0, 1, 0, []);
    end
    load(file_out, 'data');
    dotsonID = find(ismember(data.ecodes.name, 'dot_on'));
    dotsoffID = find(ismember(data.ecodes.name, 'dot_off'));
    choiceID = find(ismember(data.ecodes.name, 'choice'));
    dirID = find(ismember(data.ecodes.name, 'dot_dir'));
    cohID = find(ismember(data.ecodes.name, 'dot_coh'));
    sacID = find(ismember(data.ecodes.name, 'sac_on_offline'));
    fpoffID = find(ismember(data.ecodes.name, 'fp_off'));
    correctID = find(ismember(data.ecodes.name, 'correct'));
    onlineID = strcmp('OLscore', data.ecodes.name);

    % Conditions of interest:
    % #switch before final, coh_switch, coh_final, dir_final, dur_last_before_final, dur_final, choice_final, RT, correct 

    ntrials = size(data.ecodes.data, 1);
    i = 1;
    trialKeep = [];
    for j=1:ntrials
        % if it's not the paradigm 3 to 6 it's not going to work
        if data.ecodes.data(j,27)<3
            continue
        else
            num = length(data.ecodes.multi{j, cohID})-1;
            if num >0
                num_switch(i) = num;
                coh_switch(i) = data.ecodes.multi{j, cohID}(1); 
                coh_final(i) = data.ecodes.multi{j, cohID}(end);
                dir_final(i) = data.ecodes.multi{j, dirID}(end); 
                dur_last_before_final(i) = data.ecodes.multi{j, dotsonID}(end) - data.ecodes.multi{j, dotsonID}(end-1);
                dur_final(i) = data.ecodes.data(j, dotsoffID) - data.ecodes.multi{j, dotsonID}(end);
                choice_final(i) = data.ecodes.data(j, choiceID);
                RT_final(i) = data.ecodes.data(j, sacID) - data.ecodes.data(j, fpoffID);
                correct(i) = data.ecodes.data(j, correctID);
                OLscore(i) = data.ecodes.data(j, onlineID);
                trialKeep = [trialKeep,j];
                i = i + 1;
            end
        end
    end

    paradigm = find(data.ecodes.data(:,27)>2);
    if isempty(paradigm) == 0
        
        d = [num_switch; ...
            coh_switch; ...
            coh_final; ...
            dir_final; ...
            dur_last_before_final; ...
            dur_final; ...
            choice_final; ...
            RT_final;...
            correct]';

        % remove bad trials : fix-break; no-choice
        bad_trials = ( d(:,1)==0 | d(:, 7)<1 | isnan(d(:, 8)) | d(:,9)<0 );
        d = d(~bad_trials, :);
        trialKeep = trialKeep(~bad_trials);
        d(:,10) = trialKeep;
        fout = [full_name(1:end-4) 'good.csv'];

        matRelevantVal = array2table(d,'VariableNames',{'HR', 'coh_switch', 'coh_final', 'dir_final', 'dur_last_before_final', ...
                    'dur_final', 'choice_final', ...
                    'RT_final', 'correct','good_trials'});

        save([full_name(1:end-4) '_val.mat'],'matRelevantVal');

        write_out(d, fout);
    else
        save([full_name(1:end-4) '.mat'],'data');
    end
        


function write_out(val, f)
    
    headers = {'#switch', 'coh_switch', 'coh_final', 'dir_final', 'dur_last_before_final', ...
                'dur_final', 'choice_final', ...
                'RT_final', 'correct'};

    fid = fopen(f, 'w');
    fprintf(fid, '%s,', headers{1:end-1});
    fprintf(fid, '%s\n', headers{end});
    fclose(fid);
    dlmwrite(f, val,'delimiter',',','-append');


