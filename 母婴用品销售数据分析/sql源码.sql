
#数据预处理与导入
# 1.创建trade表
create table trade(
	user_id varchar(20) not null comment '用户id',
	auction_id varchar(20) not null comment '购买行为编号',
	cat_id varchar(20) comment '商品所属的大类下的子类',
	cat1 varchar(15) comment '商品所属的大类',
	property text comment '商品属性',
	buy_mount int comment '购买数量',
	day varchar(8) comment '购买日期'
);

#2.创建babyinfo表
create table babyinfo(
	user_id varchar(20) not null comment '用户id',
	birthday varchar(8) comment '出生日期',
	gender char comment '性别' 
);

#trade 表
#统计缺失值信息
select 
	sum(user_id is null),
	sum(auction_id is null),
	sum(cat1 is null),
	sum(cat_id is null),
	sum(trade.property is null),
	sum(trade.buy_mount is null),
	sum(trade.day is null)
from trade;


#用户数量
select
	count(user_id),
	count(distinct user_id)
from trade;

#统计不同购买次数的用户
select 
	buy_num,
	count(user_id) as user_num
from(
	select 
	user_id,
	count(user_id) as buy_num
	from trade
	group by user_id
	) as tem
group by buy_num
order by user_num;

# 购买行为编号
select count(auction_id),count(distinct auction_id) from trade;

# property商品属性
select count(property) ,count(distinct property) from trade;

#商品大类
select
	cat1,
	count(distinct cat_id) as 子类数量
from trade
group by cat1
order by 子类数量;


# 商品小类
select count(cat_id),count(distinct cat_id) from trade;
# 统计每个cat1大类有多少个cat_id小类：
select cat1,count(distinct cat_id) as num
from trade
group by cat1
order by num desc;


#每次购买数量
select
	buy_mount 每次购买数量,
	count(user_id) 消费次数
from trade
group by buy_mount
order by 消费次数;


# 时间跨度
select max(day), min(day) from trade;
select  left(day,7),count(left(day,7)) 
from trade  group by left(day,7) order by count(left(day,7)) ;
select day from trade where left(day,7) = '2015-02' group by day order by day;


#babyinfo表
# 缺失值统计
select 
	sum(user_id is null),
	sum(birthday is null),
	sum(gender is null)
from babyinfo;

#有信息的用户数量
select count(user_id),count(distinct user_id) from babyinfo;

#不同性别婴儿的数量
select gender,count(gender) from babyinfo group by gender;



#探索分析
#购买情况
#按天统计每天的销量和每天购买的用户数量
select 
	day,
	sum(buy_mount) as 销量,
	count(distinct user_id) as 用户数量
from trade
group by day
order by day;


# 查询销量异常记录
# 查询单次购买超过100的记录数
select user_id,day,buy_mount
from trade
where buy_mount>100
order by buy_mount desc;

# 剔除异常销量数据
select day,cat1,cat_id,
       sum(buy_mount) as 销量,
       count(distinct user_id) as 用户数量
from mum_baby.trade
where buy_mount < 30
group by day
order by day


#观察销量在一周内的变化
#分析按星期的销量，用户量
#dayname 返回对应的工作日英文名称，SUMDAY,MONDAY
#dayofweek 返回一周中的索引 1表示周日，2表示周一...7表示周六
select dayname(day) as D,
       sum(buy_num) as 销量,
       sum(user_num) as 活跃用户量
from
    (
        select
            day,
            sum(buy_mount ) as buy_num,
            count(distinct user_id) as user_num
        from trade
        where buy_mount<30
        group by day
        ) as tem
group by dayname(day),dayofweek(day)
order by dayofweek(day);

#分析按月购买的情况
select 
	月份, 
	sum(case 年份 when 2012 then buy_num  else 0 end) as 2012年,
	sum(case 年份 when 2013 then buy_num  else 0 end) as 2013年,
	sum(case 年份 when 2014 then buy_num  else 0 end) as 2014年,
	sum(case 年份 when 2015 then buy_num  else 0 end) as 2015年
from(
	select 
	month(day) as 月份,
	year(day) as 年份,
	sum(buy_mount) as buy_num,
	count(distinct user_id) as user_num
	from trade
	where buy_mount<30
	group by year(day), month(day)
	) as tem
group by 月份
order by 月份;


# 月同比
select 
	day,月份,年份,
	sum(case 年份 when 2012 then buy_num end) as 2012年,
	sum(case 年份 when 2013 then buy_num end) as 2013年,
	sum(case 年份 when 2014 then buy_num end) as 2014年,
	sum(case 年份 when 2015 then buy_num end) as 2015年
from(
	select
	day,
	month(day) as 月份,
	year(day) as 年份,
	sum(buy_mount) as buy_num,
	count(distinct user_id) as user_num
	from trade
	where buy_mount<30
	group by year(day), month(day)
) as tem
group by 年份,月份
order by 年份,月份;


# 2015年春节前销量
select day,月份,年份,buy_num as 销量,
sum(case 年份 when 2013 then buy_num end) as 2013年,
sum(case 年份 when 2014 then buy_num end) as 2014年,
sum(case 年份 when 2015 then buy_num end) as 2015年
from(
	select 
	day,
	month(day) as 月份,
	year(day) as 年份,
	sum(buy_mount) as buy_num,
	count(distinct user_id) as user_num
	from trade
	where buy_mount<30
	group by day) as tem
group by day
order by day;


# 观察2014年和2015年腊月初一到腊月十五个产品大类的销量与产品增速
select 
	day,
	cat1,
	年份,
	buy_num as 销量,
	sum(case 年份 when 2014 then buy_num end) as 2014年,
	sum(case 年份 when 2015 then buy_num end) as 2015年
from(
	select 
	day,
	year(day) as 年份,
	cat1,
	sum(buy_mount) as buy_num,
	count(distinct user_id) as user_num
	from trade
	where buy_mount<30
	group by day,cat1) as tem
group by day,cat1
order by day,cat1


# 每月出生人数
select month(birthday) as 月份,count(distinct user_id) 出生人数
from babyinfo
group by month(birthday)
order by month(birthday)


# 产品类别分析
# 每个大类商品的购买情况
select
	cat1 as 类别,
	sum(buy_mount) as 销量,
	count(distinct user_id) as 用户数
from trade
where buy_mount<30
group by cat1
order by cat1


# 找到热销的子类信息
# 寻找热销子类（销量前10或用户数量前10）
select day,cat_id,sum(buy_mount) as 销量,count(distinct user_id) as 用户量
from trade where buy_mount<30  and cat_id in
(
	select tem1.cat_id
	from
	(
		select a.cat_id,a.销量,rank() over(order by a.销量 desc) as 销量排名 from
		(
			select cat_id,sum(buy_mount) as 销量 from trade where buy_mount<30 group by cat_id
		) a
	) tem1
	join 
	(	
		select b.cat_id,b.用户量,rank() over(order by 用户量 desc) as 用户量排名 from 
		(
			select cat_id,count(distinct user_id) as 用户量 from trade where buy_mount<30 group by cat_id
		) b
	) tem2
	on tem1.cat_id=tem2.cat_id where tem1.销量排名<10 or tem2.用户量排名<10
)
group by day,cat_id
order by day


# 婴儿阶段分析
# 创建年龄信息视图
create view mum_baby.age_info as
(
	select 
	b.user_id,
	cat1,
	cat_id,
	buy_mount,
	day as buy_day,
	birthday,
	(
		case 
		when datediff(day,birthday)/365<0 then '未出生'
		when datediff(day,birthday)/365<1 then '0-1岁'
		when datediff(day,birthday)/365<2 then '1-2岁'
		when datediff(day,birthday)/365<3 then '2-3岁'
		when datediff(day,birthday)/365<4 then '3-4岁'
		when datediff(day,birthday)/365<5 then '4-5岁'
		else '5岁以上'
		end
	) as 年龄分段,
		round(datediff(day,birthday)/365,1) as 年龄,
	(	
	case gender when 0 then '男' when 1 then '女' else '不明' end
	) as 性别 
from babyinfo as b
join trade as t on b.user_id=t.user_id  where t. buy_mount<30)


# 各年龄段购买情况
select 
	年龄分段,
	count(distinct user_id) as 人数,
	sum(buy_mount) as 购买总量
from age_info
group by 年龄分段
order by FIELD(年龄分段,'未出生','0-1岁','1-2岁','2-3岁','3-4岁','4-5岁','5岁以上')


# 年龄和性别组合偏好
select 年龄分段,性别,cat1,cat_id,count(distinct user_id) as 人数,sum(buy_mount) as 销量
from age_info
where 性别 <> '不明'
group by 年龄分段,性别,cat1
order by FIELD(年龄分段,'未出生','0-1岁','1-2岁','2-3岁','3-4岁','4-5岁','5岁以上');



# 产品用户画像分析
# 不同性别用户大类产品分布
select cat1,性别,年龄分段,cat_id,count(distinct user_id) as 人数,sum(buy_mount) as 销量
from age_info
where 性别 <> '不明'
group by cat1,性别,年龄分段

#热销子类的用户画像
select * from age_info where cat_id in(
select tem1.cat_id from 
(select a.cat1,a.cat_id,a.销量,rank() over(order by a.销量 desc) as 销量排名 from
(select cat1,cat_id,sum(buy_mount) as 销量 from trade where buy_mount<30 group by cat_id) a) tem1
join 
(select b.cat1,b.cat_id,b.用户量,rank() over(order by 用户量 desc) as 用户量排名 from  
(select cat1,cat_id,count(distinct user_id) as 用户量 from trade where buy_mount<30 group by cat_id) b) tem2
on tem1.cat_id=tem2.cat_id where tem1.销量排名<10 or tem2.用户量排名<10)



select day,cat1,cat_id,sum(buy_mount) as 销量,
count(distinct user_id) as 用户量
from trade where buy_mount<30 
and cat_id in
(select tem1.cat_id
from
(select a.cat_id,a.销量,
rank() over(order by a.销量 desc) as 销量排名
from
(select cat_id,sum(buy_mount) as 销量
from trade where buy_mount<30
group by cat_id) a) tem1
join 
(select b.cat_id,b.用户量,
rank() over(order by 用户量 desc) as 用户量排名
from 
(select cat_id,count(distinct user_id) as 用户量
from trade where buy_mount<30
group by cat_id) b) tem2
on tem1.cat_id=tem2.cat_id
where tem1.销量排名<10 or tem2.用户量排名<10)
group by day,cat_id
order by day




# 复购情况分析
# 创建复购用户的视图
create view mum_baby.multi_info 
as 
(
	select user_id,cat_id,cat1,buy_mount,day
	from trade
	where user_id in 
	(
		select user_id
		from trade
		where buy_mount<30
		group by user_id
		having count(auction_id)>1
	)
	order by user_id,day
)


# 计算复购率
select a.num1 复购用户数,count(distinct user_id) 总用户数,
	a.num1/count(distinct user_id) as 复购率
from 
	(
		select count(distinct user_id) as num1 from multi_info
	) as a,trade b

# 查看有重复购买行为用户复购的是否是同一小类的奶粉
select
	t.num as 复购产品种类数,
	count(user_id) as 用户数
from 
	(
		select user_id,
					 count(distinct cat_id) as num
		from multi_info
		group by user_id
	) as t
group by t.num


# 查询有重复购买行为用户复购的是否是同一种大类的奶粉
select
	t.num as 复购产品种类数,
	count(user_id) as 用户数
from 
	(
		select user_id,count(distinct cat1) as num 
		from multi_info
		group by user_id
	) as t
group by t.num

 