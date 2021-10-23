# Airbnb用户数据分析

## 一.分析背景与目的

### 1.1分析背景

![image-20210923180416391](https://i.loli.net/2021/10/14/UZjtVeM2Ap93QBE.png)

Airbnb是一家联系旅游人士和家有空房出租的房主的服务型网站，它可以为用户提供多样的住宿信息。

用户可以通过网络或手机应用程序发布，搜索独家房屋租赁信息并完成在线预定程序。

### 1.2分析目的

利用Airbnb用户的注册，订单和日志行为等数据，将着重从Airbnb的用户画像，推广渠道分析，转化漏斗分析三个方面进行分析，去探索和分析Airbnb在产品和业务上有哪些可以改进的地方，并给出实际的建议，以提升和改进Airbnb的渠道推广策略和产品设计。

针对以上疑问，总结出四大分析目的：

构建Airbnb的目标用户群体画像

观察Airbnb的用户增长趋势和付费转化率情况

评估各推广渠道的质量

考察各流程转化率情况

三大分析方向：

用户画像分析

营销渠道分析

转化漏斗分析



## 二.数据清洗

### 2.1 数据集描述

数据集名称：Airbnb New User Bookings--Airbnb顾客预定数据
数据来源：https://www.kaggle.com/c/airbnb-recruiting-new-user-bookings/data

数据集简介：此数据集是kaggle上的一个竞赛项目，主要用来制作目的地信息的预测模型。此数据聚集包含两张数据表，train_users表中为用户数据，sessions表中为行为数据

数据集量：train_users表 21w * 15 ，sessions表 104w * 6

### 2.2 字段理解

train_users_2表：

| 字段                    | 含义                                     |
| ----------------------- | ---------------------------------------- |
| id                      | 用户id                                   |
| date_account_created    | 账号创建时间                             |
| timestamp_first_active  | 首次活跃时间                             |
| date_first_booking      | 首次预订时间                             |
| gender                  | 性别                                     |
| age                     | 年龄                                     |
| signup_method           | 注册方式                                 |
| signup_flow             | 用户注册的页面                           |
| language                | 语言                                     |
| affiliate_channel       | 营销方式，如SEM等                        |
| affiliate_provider      | 营销来源，例如google,craigslist,其他     |
| first_affiliate_tracked | 在注册之前，用户与之交互的第一个营销内容 |
| signup_app              | 注册使用的app                            |
| first_device_type       | 注册时设备类型                           |
| first_browser           | 注册使用的浏览器名称                     |
| country_destination     | 目的地国家                               |

session表：

| 字段          | 含义                              |
| ------------- | --------------------------------- |
| user_id       | 用户id，与train_users表中的id连接 |
| action        | 用户行为                          |
| action_type   | 用户行为类型                      |
| action_detail | 用户行为具体描述                  |
| device_type   | 设备类型                          |
| secs_elapsed  | 停留时长                          |

### 2.3 重复值的处理

对于train_users_2表，主键是id，每个用户只生成一条记录，所以如果train_users_2中id存在重复值，则需要处理。

对于sessions表，存在一个用户可以有多条记录，所以不作处理

### 2.4 缺失值

**train_users表：**

date_first_booking缺失了124543条数据

age缺失了87990条数据

first_affiliate_tracked缺失了6065条数据



**sessions表：**

user_id缺失34496条

action缺失79626条

action_type缺失112604条

action_detail缺失112604条

secs_elapsed缺失136031条



**缺失值处理方式：**

date_first_booking的缺失主要由于用户没有下单，所以没有产生行为数据

age的缺失主要由于用户没有填写年龄信息

session表中user_id的缺失对于session表影响不大

其他缺失值可能是因为前端统计时未统计完全

处理：实际分析中需要在where条件排除掉空数据，再进行分析

### 2.5 异常值

age最小值为1，最大值为2014

有29条数据的date_account_created>date_first_booking，即账号创建时间>首次预定时间

有104624条数据的secs_elapsed为0



异常数据处理：

age的异常值可能是用户随意填写导致的，这里只统计10-80岁之间数据

删除date_account_created>date_first_booking

secs_elapsed可能是前端统计数据时为统计完全，不做修改



## 三.用户画像分析

### 3.1 用户分布

**（1）性别分布**

注册用户中女性注册用户占比53.66%，男性注册用户占比46.34&，女性用户占比略高于男性用户占比。

![image-20210922225415976](https://i.loli.net/2021/10/14/FiZvO2qnQL1co9H.png)



**（2）年龄分布**

注册用户分布广泛，主要的注册用户集中在26-40岁，总占比近60%，同时也是付费转化率最高的阶段。

其次是21-25岁，41-45岁的用户，这两个年龄段的用户付费转化率均在51%左右。46-50岁这个年龄段的注册用户占比也不低，但付费转化率只有48.82%，而56-70岁年龄段的注册用户总占比虽只有7%左右，但付费用户转化率却稳居52%左右。

![image-20210922225703079](https://i.loli.net/2021/10/14/Acy7zN4YtqROgP1.png)

**（3）设备分布**

Mac Desktop和Windows Desktop设备注册用户占比远超其他设备，合计占比约76%，其中Mac端设备占比高于Windows端设备。Desktop设备注册用户占比远高于移动端设备，在移动端设备中，苹果设备占比高于安卓设备以及其他设备。可能的原因是这份数据时间正处于2010-2014年间，此时移动端APP处于起步阶段，因此大部分用户使用Desktop设备。

![image-20210922230215450](https://i.loli.net/2021/10/14/xJ9p1vSr47Ylg3a.png)

**（4）浏览器分布**

从注册用户数来看，Chrome，Safari， Firefox， IE这四大浏览器带来了绝大部分的注册用户

从付费转化率来看，这四大浏览器的付费转化率也不错，其中Chrome浏览器付费转化率46.79%，Firefox浏览器的转化率46.78%

结合之前的设备分布来看，Chrome、Safari、Firefox、IE四大浏览器终端都是Desktop。Mobile Safari、Chrome Mobile、Android Browser终端都是移动设备，他们的付费转化率表现不错，都在32%左右。

![image-20210922231402940](https://i.loli.net/2021/10/14/QsA2lwS93LbZ4dR.png)

**（5）注册方式和APP分布**

从注册方式分布来看，使用基本注册方式（电子邮件）的注册用户占比高达71.63%，使用facebook的注册用户占比28.11%，极少数人采用google来注册，随着将来移动端APP的发展，旅行产品和社交网络平台的联合的潜力很大。

从注册app分布来看，85.60%的用户在网站上注册，8.91%的用户在iOS上注册，这也符合之前的设备分布情况，由此也可以看出，如果在网页上投放Airbnb广告可能会获得比较高的获客量。

![image-20210922233923204](https://i.loli.net/2021/10/14/21fPq5o6GRQMnUj.png)

**（6）国家目的地分布**

这里排除了NDF(未知目的地)后进行的分析，选择以美国作为旅行目的地的用户占比最高，高达70.16%，法国，意大利，德国依次随后，其余国家占比很小。

![image-20210922235101377](https://i.loli.net/2021/10/14/e7aEyVxmgU3d9rZ.png)

**（7）语言分布**

Airbnb的用户覆盖全球多个国家和地区，从树状图上显示，使用英语(en)的用户占比高达96.66%，使用其他语言的用户占比不到4%，可能是因为英语是世界上应用最广泛的语言，另外Airbnb创立于美国，前期业务市场主要集中在欧美市场。

在排除英语(en)后再进行分析，使用中文(zh)的用户占比0.76%，是最多用户使用的语言，使用中文的用户可能是海外华裔也可能是有出国旅行需求的国人。

![image-20210922235804958](https://i.loli.net/2021/10/14/lxTEfyHgwa4e9Jo.png)



### 3.2 用户行为评估指标分析

**（1）月活MAU**

session表中user_id字段缺失部分数据，只能显示部分月份的月活，定义行为数大于15为活跃用户。

由图可见，注册用户数和活跃用户数除2月份有所下跌外，总体呈上升趋势。

活跃率除3月份小幅度下跌外，次月就出现大幅增长，之后都保持在75%的活跃率水平。



![image-20210923025729538](https://i.loli.net/2021/10/14/GD43a87TIgl1Ryv.png)



**（2）用户增长趋势和付费转化率趋势**

由图可以看出，2011年之前，注册用户数和付费用户数在平稳增长，转化率约在50%-65%之间。

2012年开始，注册用户数和付费用户数增长开始在加快，2013年-2014年期间，注册用户数开始飞速增长，但付费用户数的增长速度没有跟上，因此这个时期的转化率下降趋势明显。

另外可以发现，每年1-9月注册用户数就在不断增长，其中从7月到9月逐渐增长至波峰，随后到12月份小幅下降。推测注册用户数的增长可能是受了季节规律的影响，尤其在7-9月的夏季正是旅游旺季。

![image-20210923030803619](https://i.loli.net/2021/10/14/4KJxYV1mwrhv78j.png)

**（3）用户注册与首次预定的时间间隔**

有24.1%的用户在注册当天就进行了首次预定，78.7%用户在注册50天以内便完成了首次预定，表明大部分用户对Airbnb的初始信任度和认可度较高。但仍有15.9%的用户在注册100天以后才首次预定。

![image-20210923032251574](https://i.loli.net/2021/10/14/Ovm8HFnJ3t26NeC.png)

![image-20210923032428270](https://i.loli.net/2021/10/14/UKEdsgC7xkOPcW8.png)



**(4) 用户首次活跃与首次预定的时间间隔**

有24.1%的用户在首次活跃的当天就进行了预定，65.9%的用户在首次活跃的10天之内完成了首次预定，18.1%的用户在首次活跃后的10-100天内完成预定，15.9%的用户在首次活跃后的100-400天内才首次预定，极少数用户在距离首次活跃的400天后进行预定。

![image-20210923110529735](https://i.loli.net/2021/10/14/vubSahmp5tOo2UP.png)

![image-20210923110652683](https://i.loli.net/2021/10/14/fjSkc2iuno8ybNQ.png)

![image-20210923110856464](https://i.loli.net/2021/10/14/8MYxsAKCerDiWOu.png)

## 四.营销渠道分析

### 4.1 各营销渠道用户规模和付费转化率

渠道注册量方面：

Direct(直接从应用商店下载)带来的注册用户数最多，占总注册量64.39%，推测是从各个渠道了解信息后到应用商店下载。

在排除Direct后，sem-brand-google(在Google上的搜索引擎营销)的渠道用户占比达到32.97%，sam-non-brand-google的渠道用户占比达到22.29%。

渠道注册量总体符合二八定律，注册用户数排名前五的渠道贡献了近80%的注册用户数

渠道转化率方面：

注册用户数排名前十的渠道的付费转化率都较为理想且相差不大，唯独content-google的付费转化率仅为15.59%，明显低于转化率的平均值，需要提升该渠道的质量。

![image-20211013205043986](https://i.loli.net/2021/10/14/4AD39XKfExa2MG6.png)



![image-20211013205112072](https://i.loli.net/2021/10/14/IQlfMDYzF8S9kPT.png)

### 4.2 各营销渠道每月增长用户数

排除direct,选取注册用户数量排名前20%的营销渠道进行分析

从2012年开始，各营销渠道的新增用户数开始有较为明显的增长，增长最快的是以sem-non-brand为营销方式的google渠道。

从2013年开始，各营销渠道的新增用户数快速的增长，以sem-brand为营销方式的google渠道逐渐超过同渠道的sem-non-brand。以api为营销方式的渠道新增用户数也在较大幅度的增长，content-google和seo-google在随后小幅增长。

从2014年开始，sem-brand-google营销渠道新增用户数以指数级别在增长，其他大部分渠道都出现了下滑现象。原因可能是airbnb在增加sem-brand-google的投放，减少其他渠道的投放，或者是应用产品更新迭代导致其他渠道的用户兴趣下降。![image-20211012211234788](https://i.loli.net/2021/10/14/X6eGMOb2SjkJlnt.png)

### 4.3 各营销渠道活跃用户数

这里定义行为数大于15为活跃用户，排除direct-direct营销渠道，选取活跃用户数量排名前10的营销渠道来展开分析。

从活跃用户数来看，google渠道带来的活跃用户数量远超其他渠道，前5名渠道中有4名都是google渠道。sem-brand-google，sem-non-brand-google，seo-google这三种营销渠道活跃用户数排名前三名

从活跃率来看，remarketing-google、sem-brand-bing,sem-brand-google活跃率排名前3名。活跃用户数前3名中，只有sem-non-brand-google营销渠道的活跃率低于平均值28.07%。



![image-20210923120423861](https://i.loli.net/2021/10/14/SIYbV4HZLzqaO1d.png)



### 4.4 不同营销内容的注册量和转化率分析

这里显示的是用户在第一次通过不同渠道接触到airbnb的营销内容之后，进行注册，预定的情况

由图可知，除了untracked(未跟踪到)的数据之外，linked的注册量最高，除去注册量很少的marketing之外，linked的转化率也是最高的。其次是omg，注册量和转化率都紧跟linked之后。marketing的转化率高达45%，但是注册用户数量远小于1%，local ops的注册用户数量和转化率都很低。

根据以上分析，可以结合营销渠道的分析，调整不同营销渠道上的投入。

![image-20211012225856355](https://i.loli.net/2021/10/14/nGiO8MlL6QkgVx4.png)



### 4.5 各营销渠道的用户平均总停留时长

sem-non-brand-baidu的用户平均总停留时长达96434s，约26.7小时，远超平均值

结合渠道用户表现来看，sem-non-brand-baidu渠道的注册用户数18人，付费用户数5人，活跃人数2人。推测可能是脏数据，那么就可以排除，或者这个渠道的用户很认可airbnb，所以可以尝试增加该渠道的投放。

google渠道中只有Sem-brand-google（33823s）达到了平均值，在之前的分析中，无论是在活跃用户数，活跃率还是在每月新增用户中，表现都很不错，这个情况可能是google渠道的吸引的用户目的性较强，另一方面也反映了airbnb能够高效的满足用户需求。

![image-20211012232345036](https://i.loli.net/2021/10/14/q7JIS6mFtpe8vOw.png)



### 4.5 各营销方式对国家目的地的影响

airbnb一共有8种营销方式进行推广，为各个国家目的地带来最多预定客户的营销方式是direct,尤其是美国，其他营销方式远不及direct营销方式。

在不考虑美国的情况下，除了direct营销方式，sem-brand和sem-non-brand这两种营销方式效果相当。

![image-20210923141213909](https://i.loli.net/2021/10/14/w5U1VZESdh9CH8f.png)

![image-20210923141330602](https://i.loli.net/2021/10/14/SDjT7iUJw324bEa.png)

### 4.6 各渠道对国家目的地的影响

airbnb一共有18个渠道进行营销推广，从图上可知，为各个国家目的带来最多预定客户的渠道是direct渠道，其次是google渠道，其他渠道远不及direct和google渠道。

![image-20210923141616579](https://i.loli.net/2021/10/14/mBIWRfQkYy3FSCN.png)

![image-20210923141739169](https://i.loli.net/2021/10/14/Vd29PbxpsQvhUHg.png)

### 4.7 不同渠道质量分析

渠道质量采取渠道规模和渠道活跃用户占比两方面进行衡量，排除direct，选取注册用户数量前十的渠道进行分析。

以注册用户数和活跃用户占比各自的均值作为轴，分成4个区域

高注册用户数，高活跃用户占比的渠道需要保持投放，稳中求升，比如sem-brand-google,

低注册用户数，高活跃用户占比的渠道需要增加投放，扩大注册用户基数,比如remarketing-google,seo-google,content-google,seo-face-book

低注册用户数，低活跃用户占比的渠道和高注册用户数，低活跃用户占比的渠道则需要结合其他数据，进行进一步分析。

![image-20211013215135660](https://i.loli.net/2021/10/14/ePrmO5w8Llfdt1b.png)



## 五.转化漏斗分析

漏斗模型中流失率最高的环节是从注册用户到预定用户，转化率仅有14.04%，可以按照用户注册时间或访问次数将用户分为新客户和老客户，对于新客户而言， 可能缺乏产品核心功能的引导，没有合适的房源，或者这些注册的用户并非目标客户等原因。对于老客户，可能是没有找到合适的房源等等原因。需要结合用户行为进一步分析用户流失的具体节点。

从预定到支付成功有87%的转化率，这意味着仍让有13% 的用户未支付成功，需要进一步分析支付不成功的原因，进而对产品功能进行优化。

后面三个环节转化率良好，其中从支付到复购的转化率达60.39%，说明airbnb的产品和服务能令客户满意，用户的回购意愿较高。可以对支付成功的用户进行详细的用户画像，分析一次消费后的节点，考虑刺激用户二次消费。

![image-20210923142046650](https://i.loli.net/2021/10/14/T5nNDIFc6qbrw1S.png)



## 六.分析结论汇总

### 6.1 用户画像分析总结

（1）用户分布

- 性别：女性用户占比略高于男性用户，但二者差别不大

- 年龄：用户年龄分布广泛，主要分布在26-40岁，其次是90后，然后是75后。

- 设备和浏览器：Desktop设备占据主流，Mac占比高于Windows,移动端仅占少数。浏览器以Chrome,Safari,Firefox为主，其付费转化率也较有优势

- 注册方式和APP:大多数用户采用基本注册方式（即电子邮件），少量用户采用Facebook注册，极少数采用Google注册；在注册APP方面，绝大部分用户都是在网站上进行注册，这与之前的以Desktop为主的设备分布情况一致

- 国家目的地和语言：Airbnb用户覆盖全球多个地区，较受欢迎的目的地集中在发达国家，美国占比最高，使用英语的用户占比高达96.66%，其余语言占比均未超过1%，中文是排名第二的用户语言。


（2）用户行为

- 在2014年1-6月期间，注册用户数和活跃率总体呈上升趋势，活跃率除3月份小幅度下跌外，次月就出现大幅增长，之后都保持在75%的活跃率水平。

- 用户增长趋势前期平缓，中后期快速增长，整体向上，趋势健康。用户增长受季节性规律的影响，每年1-9月都呈增长趋势，并在7-9月达到波段峰值，随后至12月则会小幅下降。

- 付费转化率初期约在50%-65%之间，较为理想。随着平台注册用户数增多，度过初期红利后付费转化率下降趋势明显，维持在40%的水平。

- 从用户注册、首次活跃分别与首次预定的时间间隔分布来看，用户注册后的50天内和首次活跃的10天之内是完成首次预定的关键时间段，表明大部分用户对Airbnb的初始信任度和认可度较高，而且越临近首次活跃日期，用户预定意愿越强烈。


### 6.2 营销渠道分析总结

- 在渠道注册量方面，Direct和sem-brand-google是最有力的拉新营销渠道，渠道注册量排名前五的渠道贡献了近80%的注册用户数，符合二八定律。

- 在渠道转化率方面，注册用户数排名前十的渠道的付费转化率都不低且相差不大，唯独content-google的付费转化率远低于平均值，需要提升该渠道的质量。

- 在渠道用户活跃率方面，google渠道带来的活跃用户数量远超其他渠道，活跃用户数前3名中，只有sem-non-brand-google营销渠道的活跃率低于平均值28.07%。

- Sem-non-brand_baidu的用户平均总停留时长最长。而google渠道吸引的用户目的性较强，用户平均总停留时长较短，基于该渠道在用户增长、转化率和活跃率方面都表现不错，说明Airbnb能较高效的满足用户的需求。

- Direct营销方式为各个国家目的地带来最多预定客户，其他营销方式远不及direct。sem-brand和sem-non-brand这两种营销方式效果相当。

- 为各个国家目的地带来最多预定用户的是direct渠道，其次是google渠道，其余渠道的效果远不及前两者。
- 注册用户数量排名前十的营销渠道中，sem-brand-google属于高注册用户数，高活跃用户占比的渠道，remarketing-google,seo-google,content-google,seo-face-book属于低注册用户数，高活跃用户占比的渠道。

### 6.3 转化漏斗总结

转化漏斗中流失率最高的是从注册用户到预定用户的部分，转化率仅为14.04%。从支付到复购的转化率有60.39%，表明用户的回购意愿较高，拥有较高的忠诚度。

### 6.4 业务和产品上的建议

基于用户画像：

- 基于用户画像，目标对象可针对26-40岁的用户，同时考虑高转化率的61-70岁中老年用户。
- 每年的7-9月正是业务旺季，建议在这段时间加大运营力度，同时加大渠道广告的投放力度，在冬季加强用户运营，提高用户留存。
- 针对用户注册后的50天内和首次活跃的10天内这两个关键时间段，加大对新注册用户的运营力度，比如发放折扣券等，并且在首页推送优质房源，吸引用户完成首次预定。

基于营销渠道：

- Direct_direct、sem-brand_google、sem-non-brand_google这三个营销渠道应重点关注，可考虑与google达成更深的战略合作，提升付费转化率。

- 在注册量前十的营销渠道中，content-google转化率较低，可以对该渠道的用户进一步做需求调研和用户特征分析，进而调整渠道投放量和内容。
- 对于不同营销内容，比如表现差的营销内容local ops，建议对其进行及时优化或者更换。另外结合营销渠道的分析，调整不同营销渠道上的投入。

基于转化漏斗：

- 针对从注册到预定过程的严重流失，可能是因为平台没有准确捕捉到用户的需求点，需要结合用户行为数据进一步挖掘用户流失节点，进一步提高转化率。

- 针对从预定到支付过程中13%的流失率，根据用户反馈对支付环节流程进行ABTest，找出阻碍用户支付流程的节点，优化支付页面和支付流程。

- 为支付成功的用户提高优惠回馈，刺激用户二次消费和适当召回。针对可能存在一次出游多次预定的复购用户，做好目的地的房源关联。




## 七.MySql代码

```
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
		from train_users_2 where age>0 and date_first_booking<>''	
		group by pay_agegroup	
		order by pay_agegroup
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
select	first_browser,count(1) as '新增用户',
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
		(select language,count(id) as c from train_users_2
		group by language 
		order by count(id) desc) t



# 用户行为评估指标分析

# 每月新增注册用户数和每月转化率
select	left(date_account_created,7) as YM,
		count(1) as '注册用户数',
		count(case when date_first_booking <>'' then 1 else null end) as '付费用户数',
		concat(round((count(case when date_first_booking <>'' then 1 else null end)/count(1))*100,2),'%') as '每月转化率'
from train_users_2 	
group by left(date_account_created,7)	
order by left(date_account_created,7) asc

# 转化率
select	left(date_account_created,4) as ym,
		concat(round((count(case when date_first_booking <>'' then 1 else null end)/count(1))*100,2),'%') as '每月转化率'
from train_users_2	
group by left(date_account_created,4)	
order by left(date_account_created,4) asc

# 注册用户中活跃用户比例-月活
select	d,count(id) as '注册用户数',
		count(user_id) as '活跃用户数',
		count(user_id)/count(id) as '活跃率' 
from
		(select id,user_id,left(date_account_created,7) as d from train_users_2 as t
left join 
		(select user_id,count(user_id) from sessions	group by user_id 	having count(user_id)>15) as s
on t.id=s.user_id) as b
group by d	
having count(user_id) <> 0	
order by d


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
from train_users_2 	
group by acp 
order by count(1) desc;


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
group by d,acp 
order by d asc;


select d,acp,count(1) as cc 
from 
	(select id,
			left(date_account_created,7) as d,
			acp 
	from train_users_2) t 
where acp in
			(select acp
			from	(select d,acp,count(1) as c, 
							ntile(5) over(order by count(1) desc) as n_rank 
					from (select id,left(date_account_created,7) as d,acp 
						from train_users_2) t 
						group by acp	
						order by count(1) desc) as s
						where n_rank=1 and acp<> 'direct-direct'
						)	
					group by d,acp order by d asc




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
				from sessions where user_id<>'' 
				group by user_id having count(user_id)>15
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
```

