function [Q] = drop_missing(X)

%
% S. HSIANG
% SMH2137@COLUMBIA.EDU
% 5/10
%
% ----------------------------
%
% X2 = drop_missing(X)
%
% Takes the matrix X and drops any rows that contain at least one entry
% that is coded "missing" with NaN.  For use with multivariate regression.
% In the above command, X2 will contain no missing observations.
%

rows = (max(isnan(X),[],2)==0);

Q = X(rows,:);

return




