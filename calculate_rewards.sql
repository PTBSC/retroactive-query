BEGIN 

declare lp_total numeric; 

create temp table scaled_down_deltas AS(
SELECT address, delta_blocks,  prev_balance/1e10 as prev_balance,source FROM `psyched-ceiling-302219.retroactive_753178ea421b7f820aad4dd352316abbc2954883.all_versions_final_deltas`

);


-- finding total sum of overall lp and set variable
set lp_total = (SELECT sum(total_lp_shares)FROM(
    SELECT 
        address,
        sum(lp_shares) as total_lp_shares,
        source FROM(
            SELECT 
                address,
                prev_balance * delta_blocks as lp_shares,
                source
                FROM(
                    SELECT *  FROM `scaled_down_deltas`
                )
            )
        GROUP BY address, source
    ORDER BY address, source
)
);


-- get fraction of total lp

    SELECT 
    address,
    sum(lp_shares)/lp_total as total_lp_shares_fraction,
    source
    FROM(
        SELECT address,
        prev_balance * delta_blocks as lp_shares,
        source
        FROM(
            SELECT *  FROM `scaled_down_deltas`
        )
        )
        GROUP BY address, source
    ORDER BY address, source;


    

end;

-- formula query
create table pool_rewards AS(
    SELECT address,
            10 * log10(1 + prev_balance * 0.0002) * (2/1+ exp(-10 * delta_blocks)) as POOL, -- formula
            source
    FROM(        
        SELECT * FROM `all_versions_final_deltas`
        WHERE (prev_balance > 0
        AND delta_blocks > 0)
    )
    order by address, source, block_number, log_index
);

-- table for historgram
select *, 
    case
    WHEN POOL BETWEEN 0 AND 100 THEN "0-100"
    WHEN POOL BETWEEN 100 AND 200 THEN "100-200"
    WHEN POOL BETWEEN 200 AND 300 THEN "200-300"
    WHEN POOL BETWEEN 300 AND 400 THEN "300-400"
    WHEN POOL BETWEEN 400 AND 500 THEN "400-500"
    WHEN POOL BETWEEN 500 AND 600 THEN "500-600"
    WHEN POOL > 600 THEN ">600"
    END AS amount
 FROM(
    SELECT
        address,
        10 * LOG10(1 + prev_balance * 0.0002) * (2/1+ EXP(-10 * delta_blocks)) AS POOL,
        -- formula
        source
        FROM (
        SELECT
            *
        FROM
            `all_versions_final_deltas`
        WHERE
            prev_balance > 0
            AND delta_blocks > 0
        )
        order by address
);




END;