% normalize CVS and DS to became Markov matrices


[m,n] = size(CVS);
CVS_trans = CVS';
DS_trans = DS';

for i = 1 : m
   if (sum(CVS_trans(:,i)) > 0) 
        CVS_trans(:,i) = CVS_trans(:,i)./sum(CVS_trans(:,i)); 
   end
   if (sum(DS_trans(:,i)) > 0) 
        DS_trans(:,i) = DS_trans(:,i)./sum(DS_trans(:,i));
   end
   
   if (mod(i,500) ~= 0)
       continue;
   else
       disp( strcat( num2str(i*100/m),' %'));
   end
end
CVS_norm = CVS_trans';
DS_norm = DS_trans';

