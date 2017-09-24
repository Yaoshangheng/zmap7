function [pv, pstd, cv, cstd, kv, kstd, loopout] = brutebootloglike(time_as,bootloops)
    % brutebootloglike Bootstrap analysis of Omori parameters calculated by bruteforceloglike
    %
    % [pv, pstd, cv, cstd, kv, kstd, loopout] = brutebootloglike(time_as, bootloops);
    % ----------------------------------------------------------------------
    % (p,c,k)-pair is mean of the bootstrap values by determining the mean cumulative number modeled a end of the learning period
    % Standard deviations are calculated as the 2nd moment, not to rely fully on normal distributions
    %
    % Input parameters:
    %   time_as     Delay times [days]
    %   bootloops   Number of bootstraps
    %
    % Output parameters:
    %   pv / pstd   p value / standard deviation
    %   cv / cstd   c value / standard deviation
    %   kv / kstd   k value / standard deviation
    %   loopout     contains all results
    %
    % Samuel Neukomm / S. Wiemer / J. Woessner
    % last update: 17.07.03

    time_as = sort(time_as);
    n = length(time_as);
    loopout = [];
    % hWaitbar1 = waitbar(0,'Bootstrapping...');
    % set(hWaitbar1,'Numbertitle','off','Name','Bootstrap Omori parameters')
    for j = 1:bootloops
        clear newtas
        randnr = ceil(rand(n,1)*n);
        i = (1:n)';
        newtas(i,:) = time_as(randnr(i),:); % bootstrap sample
        [pval, cval, kval] = bruteforceloglike(sort(newtas));
        loopout = [loopout; pval cval kval];
        % waitbar(j/bootloops)
    end
    % close(hWaitbar1)

    % New version: Choose mean (p,c,k)-variables by modelling the cumulative number at end of
    % the learning period

    % 2nd moment i.e. Standard deviations
    [pstd] = calc_StdDev(loopout(:,1));
    [cstd] = calc_StdDev(loopout(:,2));
    [kstd] = calc_StdDev(loopout(:,3));

    % pstd = round(100*pstd)/100;
    % cstd = round(100*cstd)/100;
    % kstd = round(10*kstd)/10;

    % Compute best fitting pair of variates
    loopout = [loopout , loopout(:,1)*0];
    for j = 1:length(loopout(:,1))

        cumnr = (1:length(time_as))'; cumnr_model = [];
        pvalb = loopout(j,1);
        cvalb = loopout(j,2);
        kvalb = loopout(j,3);
        for i=1:length(time_as)
            if pval ~= 1
                cm = kvalb/(pvalb-1)*(cvalb^(1-pvalb)-(time_as(i)+cvalb)^(1-pvalb));
            else
                cm = kvalb*log(time_as(i)/cvalb+1);
            end
            cumnr_model = [cumnr_model; cm];
        end
        loopout(j,4) = max(cumnr_model);
    end

    [Y, in] = sort(loopout(:,4));
    loops = loopout(in,:);
    nMeanVal = round(length(loops(:,1))/2);
    pv = loops(nMeanVal,1);
    cv = loops(nMeanVal,2);
    kv = loops(nMeanVal,3);

