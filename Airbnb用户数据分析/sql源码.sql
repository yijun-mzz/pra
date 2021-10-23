# 数据清洗
select id,count(id) as count_id from train_users_2	group by id having count(id) > 1

select count(id) from train_users_2 where age<10 or age>80;

update train_users_2 set age=0 where id not in(
select id from(select id from train_users_2 where age>=10 and age<=80) a);

delete from train_users_2 where date_first_booking < date_account_created;

select count(1) from train_users_2 where date_first_booking < date_account_created;

select count(1) from train_users_2;


# 用户分析
# 注册用户性别分布
select	concat(round((male/total)*100,2),'%') as male,
				concat(round((female/total)*100,2),'%') as female
from 
		(select count(case when gender='male' then 1 else null end) as male,
						count(case when gender='female' then 1 else null end) as female,
						count(case when gender<>'-unknown-' and gender<>'other' then 1 else null end) as total 
		 from train_users_2
		) t;


# 注册用户年龄分布
select	age,count(id) from train_users_2 where age>0 group by age order by age
select	agegroup,c,
				concat(round((c/(select count(1) from train_users_2))*100,2),'%') as per 
from 
		(select case 
								when age BETWEEN 10 and 15 then '10-15岁'
								when age BETWEEN 16 and 20 then '16-20岁'
								when age BETWEEN 21 and 25 then '21-25岁'
								when age BETWEEN 26 and 30 then '26-30岁'
								when age BETWEEN 31 and 35 then '31-35岁'
								when age BETWEEN 36 and 40 then '36-40岁'
								when age BETWEEN 41 and 45 then '41-45岁'
								when age BETWEEN 46 and 50 then '46-50岁'
								when age BETWEEN 51 and 55 then '51-55岁'
								when age BETWEEN 56 and 60 then '56-60岁'
								when age BETWEEN 61 and 65 then '61-65岁'
								when age BETWEEN 66 and 70 then '66-70岁'
								when age BETWEEN 71 and 75 then '71-75岁'
								when age BETWEEN 76 and 80 then '76-80岁'
					else null	end as agegroup,
					count(1) as c
		from train_users_2 where age>0 GROUP BY agegroup ORDER BY agegroup
	) t;


# 付费用户年龄分布
select pay_agegroup,c 
from
		(select case 
						when age between 10 and 15 then  '10-15岁'
						when age between 16 and 20 then  '16-20岁'
						when age between 21 and 25 then  '21-25岁'
						when age between 26 and 30 then  '26-30岁'
						when age between 31 and 35 then  '31-35岁'
						when age between 36 and 40 then  '36-40岁'
						when age between 41 and 45 then  '41-45岁'
						when age between 46 and 50 then  '46-50岁'
						when age between 51 and 55 then  '51-55岁'
						when age between 56 and 60 then  '56-60岁'
						when age between 61 and 65 then  '61-65岁'
						when age between 66 and 70 then  '66-70岁'
						when age between 71 and 75 then  '71-75岁'
						when age between 76 and 80 then  '76-80岁'
				else null	end as pay_agegroup,
						count(1) as c
		from train_users_2 where age>0 and date_first_booking<>''	group by pay_agegroup	order by pay_agegroup
	) t



# 注册用户设备分布情况
select	first_device_type,c,
				concat(round((c/(select count(1) from train_users_2))*100,2),'%') as per
from
			(select first_device_type,count(1) as c 
			 from train_users_2	group by first_device_type	order by count(1) desc
			) t 



# 浏览器
select	first_browser,c,
				concat(round((c/(select count(1) from train_users_2))*100,2),'%') as per
from
		(select first_browser,count(1) as c 
		 from train_users_2 group by first_browser order by count(1) desc
		) t;


# 浏览器转化率
select first_browser,count(1) as '新增用户',
			 count(case when date_first_booking<>'' then 1 else null end) '付费用户',
			 concat(round((count(case when date_first_booking<>'' then 1 else null end)/count(1))*100,2),'%')as per
from train_users_2 group by first_browser having count(1)>500;


# 注册方式和应用
select signup_method,count(id) as c from train_users_2 group by signup_method;
select signup_app,count(id) as c from train_users_2 group by signup_app;


# 国家目的地
select	country_destination,c,
				concat(round((c/(select count(1) from train_users_2 where country_destination <> 'NDF'))*100,2),'%') as per
from 
		(select country_destination,count(1) as c 
		from train_users_2 
		where country_destination <> 'NDF' group by country_destination order by count(1) desc
		) t



# 语言分布
select	language,c, 
				concat(round((c/(select count(1) from train_users_2 where language<>''))*100,2),'%') as per
from 	
			(select language,count(id) as c from train_users_2group by language order by count(id) desc) t



# 用户行为评估指标分析

# 每月新增注册用户数和每月转化率
select	left(date_account_created,7) as YM,
				count(1) as '注册用户数',
				count(case when date_first_booking <>'' then 1 else null end) as '付费用户数',
				concat(round((count(case when date_first_booking <>'' then 1 else null end)/count(1))*100,2),'%') as '每月转化率'
from train_users_2 	group by left(date_account_created,7)	order by left(date_account_created,7) asc

# 转化率
select	left(date_account_created,4) as ym,
				concat(round((count(case when date_first_booking <>'' then 1 else null end)/count(1))*100,2),'%') as '每月转化率'
from train_users_2	group by left(date_account_created,4)	order by left(date_account_created,4) asc

# 注册用户中活跃用户比例-月活
select d,count(id) as '注册用户数',count(user_id) as '活跃用户数',count(user_id)/count(id) as '活跃率' 
from
		(select id,user_id,left(date_account_created,7) as d from train_users_2 as t
left join 
		(select user_id,count(user_id) from sessions	group by user_id 	having count(user_id)>15) as s
on t.id=s.user_id) as b
group by d	having count(user_id) <> 0	order by d


# 首次注册与首次预定的时间间隔
alter table train_users_2 add column ctb varchar(255);
update train_users_2 set ctb = datediff(date_first_booking,date_account_created);
select ctb from train_users_2;
select ctb,count(1) as '人数' from train_users_2 where ctb <> '' group by ctb


# 首次活跃与首次预定的时间间隔
alter table train_users_2 add column atb varchar(255);
update train_users_2 set atb = DATEDIFF(date_first_booking,timestamp_first_active);
select atb,count(1) as '人数' from train_users_2 where atb <> '' group by atb;



# 营销渠道分析 
# 各营销渠道用户规模和付费转化率
alter table train_users_2 add column acp varchar(255) not null;
update train_users_2 set acp=concat(affiliate_channel,'-',affiliate_provider);

select	acp,count(1) as '渠道用户数',
				count(case when date_first_booking<>'' then 1 else null end) as '付费用户数',
				concat(round((count(case when date_first_booking<>'' then 1 else null end)/count(1))*100,2),'%') as '渠道转化率'
from train_users_2 	group by acp 	order by count(1) desc;


# 不同营销内容的注册量和转化率分析
select	first_affiliate_tracked,
				count(case when date_first_booking<>'' then 1 else null end) as num1,
				count(id) as fat_num,
				concat(round((count(case when date_first_booking<>'' then 1 else null end)/count(1))*100,2),'%') as fat_ratio
from train_users_2 
where first_affiliate_tracked <> ''
group by first_affiliate_tracked
order by fat_num desc;


# 各营销渠道每月增长用户数
select d,acp,count(1) 
from 
		(select id,left(date_account_created,7) as d,acp 
		 from train_users_2
		) t 
group by d,acp order by d asc;


select d,acp,count(1) as cc 
from 
		(select id,left(date_account_created,7) as d,acp from train_users_2) t 
where acp in
						(select acp
						 from	(select d,acp,count(1) as c, 
													ntile(5) over(order by count(1) desc) as n_rank 
									from (select id,left(date_account_created,7) as d,acp 
												from train_users_2) t 
									group by acp	order by count(1) desc) as s
									where n_rank=1 and acp<> 'direct-direct'
						)	group by d,acp order by d asc




# 各营销渠道活跃用户数和活跃率
select	b1.acp,c1 as '渠道用户数',c2 as '活跃用户数',
				concat(round((c2/c1)*100,2),'%') as per
from
		(select acp,count(1) as c1 from train_users_2 group by acp) b1
left join
		(select id,acp,count(id) as c2 
		 from	(select id,acp 
					 from train_users_2 as t
					join	
					(select user_id,count(user_id) 
					from sessions where user_id<>'' group by user_id having count(user_id)>15
					) as u
					on t.id=u.user_id) as o
		 group by acp order by count(id) desc) as b2
on b1.acp=b2.acp



# 各渠道的用户平均停留时长
select acp,round(avg(avg_s),2) as avg
from 
		(select id,acp,avg_s from train_users_2 as t
join
		(select user_id,avg(secs_elapsed) as avg_s 
from sessions where secs_elapsed<>'' and secs_elapsed<>0 group by user_id) as s
on t.id=s.user_id) as b
where acp<> 'direct-direct' group by acp



# 营销方式与渠道与国家目的地的关系
select id,affiliate_channel,country_destination from train_users_2 where date_first_booking<>'';
select id,affiliate_provider,country_destination from train_users_2 where date_first_booking<>'';


# 漏斗模型

# 用户总数
select count(distinct user_id) from sessions;

# 活跃用户数
SELECT count(1) from (select user_id from sessions GROUP BY user_id having count(user_id)>15) t;


# 注册用户数
select count(1) from train_users_2 as t
join
		(select distinct user_id from sessions) as s
on t.id = s.user_id


# 预定用户
select count(1) from (select distinct user_id from sessions 
where action_detail='reservations') as s;

# 支付用户
select count(1) from (select distinct user_id from sessions where action_detail='payment_instruments') as s;


# 复购用户
select count(1) from 
(select user_id,count(1) as c from sessions where action_detail='reservations' group by user_id) as s where c>=2;


 
 




