-- 连续登录天数   https://yuguiyang.github.io/2017/08/31/data-analyst-interview-sql-03/

/*
用户连续登录天数
背景描述
现在我们有一张用户登录日志表，记录用户每天的登录时间，
我们想要统计一下，用户每次连续登录的开始日期和结束日期，以及连续登录天数。
*/

CREATE TABLE tm_login_log
(
    user_id    integer,
    login_date date
);

-- 这里的数据是最简化的情况，每个用户每天只有一条登录信息，
insert into
    tm_login_log
values
    (1001, '2017-01-01'),
    (1001, '2017-01-02'),
    (1001, '2017-01-04'),
    (1001, '2017-01-05'),
    (1001, '2017-01-06'),
    (1001, '2017-01-07'),
    (1001, '2017-01-08'),
    (1001, '2017-01-09'),
    (1001, '2017-01-10'),
    (1001, '2017-01-12'),
    (1001, '2017-01-13'),
    (1001, '2017-01-15'),
    (1001, '2017-01-16'),
    (1002, '2017-01-01'),
    (1002, '2017-01-02'),
    (1002, '2017-01-03'),
    (1002, '2017-01-04'),
    (1002, '2017-01-05'),
    (1002, '2017-01-06'),
    (1002, '2017-01-07'),
    (1002, '2017-01-08'),
    (1002, '2017-01-09'),
    (1002, '2017-01-10'),
    (1002, '2017-01-11'),
    (1002, '2017-01-12'),
    (1002, '2017-01-13'),
    (1002, '2017-01-16'),
    (1002, '2017-01-17');

/*
步骤拆解
我们首先要思考，怎样才算连续登录呢？就是1号登录，2号也登录了，这样就连续2天登录，那我们怎么知道2号他有没有登录呢？
一种思路是根据排序来判断：
我们来根据日期来排个名
*/

select
    user_id,
    login_date,
    row_number() over (partition by user_id order by login_date) day_rank
from
    tm_login_log;
/*
1001	2017-01-01	1
1001	2017-01-02	2
1001	2017-01-04	3
1001	2017-01-05	4
1001	2017-01-06	5
1001	2017-01-07	6
1001	2017-01-08	7
1001	2017-01-09	8
1001	2017-01-10	9
1001	2017-01-12	10
1001	2017-01-13	11
1001	2017-01-15	12
1001	2017-01-16	13
1002	2017-01-01	1
1002	2017-01-02	2
1002	2017-01-03	3
1002	2017-01-04	4
1002	2017-01-05	5
1002	2017-01-06	6
1002	2017-01-07	7
1002	2017-01-08	8
1002	2017-01-09	9
1002	2017-01-10	10
1002	2017-01-11	11
1002	2017-01-12	12
1002	2017-01-13	13
1002	2017-01-16	14
1002	2017-01-17	15
*/


/*
现在，我们根据用户ID，对他的登录日期做了排序，但是我们还是没有办法知道，他是不是连续的。
我们根据这个排序再思考一下，对于一个用户来说，他的登录日期排序已经是连续的了，
如果登录日期也是个数字，那我们根据每行的差值，就可以判断登录日期是否连续了。
我们换个角度，我们找一个起始日期，来计算一个相差的天数，用它去和排序相对比，就可以了。
*/

select
    user_id,
    login_date,
    datediff(login_date, '2017-01-01')                           day_interval, -- 间隔天数
    row_number() over (partition by user_id order by login_date) day_rank      -- 日期排序
from
    tm_login_log;
/*
1001	2017-01-01	0	1
1001	2017-01-02	1	2
1001	2017-01-04	3	3
1001	2017-01-05	4	4
1001	2017-01-06	5	5
1001	2017-01-07	6	6
1001	2017-01-08	7	7
1001	2017-01-09	8	8
1001	2017-01-10	9	9
1001	2017-01-12	11	10
1001	2017-01-13	12	11
1001	2017-01-15	14	12
1001	2017-01-16	15	13
1002	2017-01-01	0	1
1002	2017-01-02	1	2
1002	2017-01-03	2	3
1002	2017-01-04	3	4
1002	2017-01-05	4	5
1002	2017-01-06	5	6
1002	2017-01-07	6	7
1002	2017-01-08	7	8
1002	2017-01-09	8	9
1002	2017-01-10	9	10
1002	2017-01-11	10	11
1002	2017-01-12	11	12
1002	2017-01-13	12	13
1002	2017-01-16	15	14
1002	2017-01-17	16	15
*/

/*
我们观察下数据，因为日期排序是连续的，我们统计的间隔天数都是一个起始日期，
所以，如果登录日期是连续的，那么，排序-间隔天数的差值也应该是一样的。
*/

select
    user_id,
    login_date,
    day_interval,
    day_rank,
    day_rank - day_interval diff_value
from
    (
        select
            user_id,
            login_date,
            datediff(login_date, '2017-01-01')                           day_interval, -- 间隔天数
            row_number() over (partition by user_id order by login_date) day_rank      -- 日期排序
        from
            tm_login_log
    ) t;
/*
1001	2017-01-01	0	1	1
1001	2017-01-02	1	2	1
1001	2017-01-04	3	3	0
1001	2017-01-05	4	4	0
1001	2017-01-06	5	5	0
1001	2017-01-07	6	6	0
1001	2017-01-08	7	7	0
1001	2017-01-09	8	8	0
1001	2017-01-10	9	9	0
1001	2017-01-12	11	10	-1
1001	2017-01-13	12	11	-1
1001	2017-01-15	14	12	-2
1001	2017-01-16	15	13	-2
1002	2017-01-01	0	1	1
1002	2017-01-02	1	2	1
1002	2017-01-03	2	3	1
1002	2017-01-04	3	4	1
1002	2017-01-05	4	5	1
1002	2017-01-06	5	6	1
1002	2017-01-07	6	7	1
1002	2017-01-08	7	8	1
1002	2017-01-09	8	9	1
1002	2017-01-10	9	10	1
1002	2017-01-11	10	11	1
1002	2017-01-12	11	12	1
1002	2017-01-13	12	13	1
1002	2017-01-16	15	14	-1
1002	2017-01-17	16	15	-1

*/

/*
差值一样的记录，就是连续登录的日期
好了，连续登录的判断标准，我们已经确定了，下面就是把题目中要的数据查出来即可
*/

select
    user_id,
    --diff_value, --差值
    min(login_date) start_date,  --开始日期
    max(login_date) end_date,    --结束日期
    count(1)        running_days --连续登录天数
from
    (
        select
            user_id,
            login_date,
            day_interval,
            day_rank,
            day_rank - day_interval diff_value
        from
            (
                select
                    user_id,
                    login_date,
                    datediff(login_date, '2017-01-01')                           day_interval, -- 间隔天数
                    row_number() over (partition by user_id order by login_date) day_rank      -- 日期排序
                from
                    tm_login_log
            ) t
    ) base
group by
    user_id,
    diff_value
order by
    user_id,
    start_date;
/*
1001	2017-01-01	2017-01-02	2
1001	2017-01-04	2017-01-10	7
1001	2017-01-12	2017-01-13	2
1001	2017-01-15	2017-01-16	2
1002	2017-01-01	2017-01-13	13
1002	2017-01-16	2017-01-17	2
*/

-- 拓展：获取用户最大的连续登录天数及开始日期和结束日期

with
    tmp as (
        select
            user_id,
            diff_value,                  --差值
            min(login_date) start_date,  --开始日期
            max(login_date) end_date,    --结束日期
            count(1)        running_days --连续登录天数
        from
            (
                select
                    user_id,
                    login_date,
                    day_interval,
                    day_rank,
                    day_rank - day_interval diff_value
                from
                    (
                        select
                            user_id,
                            login_date,
                            datediff(login_date, '2017-01-01')                           day_interval, -- 间隔天数
                            row_number() over (partition by user_id order by login_date) day_rank      -- 日期排序
                        from
                            tm_login_log
                    ) t
            ) base
        group by
            user_id,
            diff_value
    )
select
    a.user_id,
    a.start_date,
    a.end_date,
    a.running_days
from
    tmp a
        join (
        select user_id, max(running_days) running_days from tmp group by user_id
    ) b on a.user_id = b.user_id
        and a.running_days = b.running_days;
/*
1001	2017-01-04	2017-01-10	7
1002	2017-01-01	2017-01-13	13
*/


/*
连续5天登录用户
这里补充另一个类似的问题，这里，我们想看连续登录5天的用户，使用上面的方法可以实现，这里介绍一个更快的方法：
是使用一个函数

向前取n位
lag(value anyelement [, offset integer [, default anyelement ]])
*/


select
    user_id,
    login_date,
    pre_five_day
from
    (
        select
            a.user_id,
            a.login_date,
            -- 5天前的登录日期
            lag(a.login_date, 4) over (partition by a.user_id order by a.login_date) pre_five_day
        from
            tm_login_log a
    ) x
where
    datediff(x.login_date, pre_five_day) = 4;
/*
1001	2017-01-08	2017-01-04
1001	2017-01-09	2017-01-05
1001	2017-01-10	2017-01-06
1002	2017-01-05	2017-01-01
1002	2017-01-06	2017-01-02
1002	2017-01-07	2017-01-03
1002	2017-01-08	2017-01-04
1002	2017-01-09	2017-01-05
1002	2017-01-10	2017-01-06
1002	2017-01-11	2017-01-07
1002	2017-01-12	2017-01-08
1002	2017-01-13	2017-01-09
*/
