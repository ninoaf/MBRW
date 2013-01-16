function [ artificial_clickstream_set, sequence_matrix_rw, cvs_matrix_rw ] = MBRW( clickstreams_train, clickstreams_train_user, clickstream_matrix, DS_norm, CVS_norm, mbrw_parameters )
%GENGAUSSIANCS_USERSAMPLINGFUNTION this function takes DS,CVS, and real
%dataset and creates artificial dataset along with the ds_tilda, cvs_tilda

rand('twister',sum(1000*clock));

% init MBRW parameters
num_cs = mbrw_parameters(1);
%num_synthetic_cs = mbrw_parameters(1);
% Memory parameters from Gauss distribution
mu1 = mbrw_parameters(2);
sigma1 = mbrw_parameters(3);
% Number of hops parameters from Gauss distribution
mu2 = mbrw_parameters(4);
sigma2 = mbrw_parameters(5);
% Last index parameter from Gauss distribution
mu3 = mbrw_parameters(6);
sigma3 = mbrw_parameters(7);
% Anonymization constant theta 
theta = mbrw_parameters(8);

% Make user vs item sparse matrix from clickstreams_train


artificial_clickstream_set = cell(num_cs,1);

[m,n] = size(DS_norm);
sequence_matrix_rw = sparse (m,n);
cvs_matrix_rw = sparse(m,n);

max_clickstream_size = 200;
clickstream_cvs = zeros(max_clickstream_size,n);
ds_norm_t = DS_norm';
cvs_norm_t = CVS_norm';

memory_gauss = mu1 + sigma1*randn(num_cs,1);

num_hops_gauss = mu2 + sigma2*randn(num_cs,1);

last_index_gauss = mu3 + sigma3*randn(num_cs,1);

rand_cs_index_array = randi(num_cs,num_cs,1);

num_discarded_cs = 0;

epsilon = 0.0000000001;
norm_clickstreams = (sqrt( sum( clickstream_matrix' ) + epsilon ))';

for cs_iter=1 : num_cs
    %sample clickstream from real clickstream data set
    
    sample_index = rand_cs_index_array(cs_iter); 
    real_cs = clickstreams_train{sample_index}; 
    
    memory = max(1,round(memory_gauss(cs_iter))); 
    middle = length(real_cs)/2;
    middle_rand = min( round( middle+last_index_gauss(cs_iter)), length(real_cs));
    last_real_cs_index = max(1, middle_rand ); 
    real_cs_sub = real_cs( max(1,last_real_cs_index-memory) : last_real_cs_index);
    
    tmp_artificial_clickstream = real_cs_sub;
    cs_tmp_size = length(real_cs_sub);
    start_node = real_cs(cs_tmp_size);
    clickstream_cvs(1:(cs_tmp_size-1),:) = ( cvs_norm_t(:,real_cs_sub(1:(cs_tmp_size-1))) )';
    
    %ADD to CVS and DS real_cs_sub - this is cheap even for for loop
    for i = 2 : length(real_cs_sub)
        sequence_matrix_rw(real_cs_sub(i-1), real_cs_sub(i)) = sequence_matrix_rw(real_cs_sub(i-1), real_cs_sub(i)) + 1;
        for j=i-1 : -1 : 1
            cvs_matrix_rw( real_cs_sub(i), real_cs_sub(j) ) = cvs_matrix_rw( real_cs_sub(i), real_cs_sub(j) ) + 1;
            cvs_matrix_rw( real_cs_sub(j), real_cs_sub(i) ) = cvs_matrix_rw( real_cs_sub(j), real_cs_sub(i) ) + 1;
        end
    end
    %------------------------------------------------
    
    
    
    num_random_hops = max(1,round(num_hops_gauss(cs_iter))); %or random variable
    tmp_random_hop = 0;
    while (tmp_random_hop < num_random_hops)
        % do num_random_hops with MBRW model where history = real_cs_sub
        ds_norm_t_col = ds_norm_t(:,start_node);	
        [row,col,ds_value] = find(ds_norm_t_col');
        ds_neighbours = col;
        
        if ((sum(ds_value))==0)
           break; 
        end
        
        clickstream_cvs(cs_tmp_size,:) = (cvs_norm_t(:,start_node))'; %column - wise operations
        
        p_trans_array = zeros(1,length(ds_neighbours)); % length(col) is num of neighbours
        
        for iter=1:length(ds_neighbours)				
            p_trans = ds_value(iter); % weight of neighbour
            prod_cvs_cs = prod(clickstream_cvs(max(1,(cs_tmp_size-memory)):(cs_tmp_size-1), ds_neighbours(iter)) );
            %we use Markov model with last 'memory' items
            p_trans = p_trans * prod_cvs_cs;
            p_trans_array(iter) = p_trans;
        end;
        suma = sum(p_trans_array);
        p_trans_array = p_trans_array./suma;
        
        cum_p_trans_array = cumsum(p_trans_array);
        dice = rand(1,1);
        next_rand_logic = ~(cum_p_trans_array<dice);
        next_index = find(next_rand_logic,1);
        
        sequence_matrix_rw(start_node, ds_neighbours(next_index)) = sequence_matrix_rw(start_node, ds_neighbours(next_index)) + 1;
        start_node = ds_neighbours(next_index);				% go to the new starting node
       
        
        clikstream_unique = unique( tmp_artificial_clickstream );
        for i=1 : length(clikstream_unique)
            lec_1 = clikstream_unique(i);
            if (lec_1 ~= start_node )
                cvs_matrix_rw( lec_1, start_node ) = cvs_matrix_rw( lec_1, start_node ) + 1;
                cvs_matrix_rw( start_node, lec_1 ) = cvs_matrix_rw( start_node, lec_1 ) + 1;
            end
        end
        
        tmp_artificial_clickstream = [tmp_artificial_clickstream start_node];
        tmp_random_hop = tmp_random_hop + 1;
    end
    
    tmp_artificial_clickstream_vec = zeros( size(clickstream_matrix,2) ,1);
    tmp_artificial_clickstream_vec ( tmp_artificial_clickstream ) = 1;
    sim_array = clickstream_matrix * tmp_artificial_clickstream_vec;
    
    cos_sim_array = sim_array ./ norm_clickstreams;
    norm_tmp_cs = sqrt( sum( tmp_artificial_clickstream_vec ) + epsilon );
    cos_sim_array = cos_sim_array ./ norm_tmp_cs;
    if ( max(cos_sim_array) >= theta )
        num_discarded_cs = num_discarded_cs + 1;
        continue;
    else
        artificial_clickstream_set{cs_iter} = tmp_artificial_clickstream;
    end
    
    if (mod(cs_iter,100)==0)
		disp( strcat( num2str(cs_iter/num_cs*100),' %'));
    end
end

disp(strcat('Percentage of discarded clickstreams that violate privacy gurantee is: ', num2str(num_discarded_cs/num_cs)));

end

