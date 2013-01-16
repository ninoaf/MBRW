% This file creates model = (DS, CVS) from clickstream
% file clickstream file -> which has users vs items vs raitings (are neglected)
% in each row

% The DS[m, n] element of this matrix denotes the number of clickstreams in C in which the
% item m immediately follows the item n. 

% The CV S[m, n] element of this matrix denotes the number of occurrences in which the item m and
% the item n belong to the same clickstream in C.



num_cs = length( unique (clickstreams_pairwise(:,1)) );
clickstreams = cell( num_cs, 1 );
clickstreams_train_user = zeros ( num_cs, 1);

tmp_user = clickstreams_pairwise ( 1,1 );
cs_count = 1;
tmp_cs = [];
first_init = 0;

num_item = max(clickstreams_pairwise(:,2)); 


clickstream_matrix = sparse(num_cs, num_item);
DS = sparse(num_item,num_item);
CVS = sparse(num_item,num_item);
cs_pairwise_size = length( clickstreams_pairwise );


%Tranforms clickstreams_pairwise -> clicstreams (cell structure)
for i = 1: cs_pairwise_size
    %small DKA 
    if ( clickstreams_pairwise(i,1) == tmp_user )
        % old user
        new_item = clickstreams_pairwise(i,2);
        
        if (first_init == 1)
            % when first_init is zero we do not put anything into DS,CVS
            new_item_array = zeros(1, length(tmp_cs));
            new_item_array(:) = new_item; 
            % this is new_item which is combined with tmp_cs in order to
            % get all pairs
            idx = sub2ind( size(CVS), tmp_cs, new_item_array);
            % idx- indexes for matrix 
            CVS(idx) = CVS(idx) + 1;
            idx = sub2ind( size(CVS), new_item_array, tmp_cs);
            % Matrix cvs is symetric
            CVS(idx) = CVS(idx) + 1;
        
            % only for direct neghbours
            DS(last_item, new_item) = DS(last_item, new_item) + 1;
        end
        
        tmp_cs = [tmp_cs new_item];
        last_item = new_item;
    else
        % new user 
        clickstreams{cs_count}= tmp_cs;
        clickstreams_train_user(cs_count) = tmp_user;
        tmp_cs = clickstreams_pairwise(i,2);
        cs_count = cs_count + 1;
        tmp_user = clickstreams_pairwise(i,1);
        last_item = clickstreams_pairwise(i,2);
    end  
    
    clickstream_matrix(clickstreams_pairwise(i,1),clickstreams_pairwise(i,2)) = 1;
    
    first_init = 1; 
  
    if (mod(i,10000) ~= 0)
       continue; 
    else
        disp( strcat( num2str(i*100/cs_pairwise_size),' %'));
    end
end
clickstreams{cs_count}= tmp_cs;
clickstreams_train_user(cs_count) = tmp_user;









