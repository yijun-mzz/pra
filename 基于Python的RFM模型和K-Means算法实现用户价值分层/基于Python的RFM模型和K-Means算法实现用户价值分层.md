

# 基于Python的RFM模型和K-Means算法实现用户价值分层

## 一.项目背景

通过真实电商订单数据，采用 RFM模型与K-Means聚类算法对电商用户按照其价值进行分层。

分析用户交易数据的用户行为特征，锁定最有价值的用户，从而实现个性化服务和运营。

## 二.理解数据

### 2.1 数据来源

https://archive.ics.uci.edu/ml/datasets/online+retail#

### 2.2 数据简介

这是一个交易数据集，里面包含了在2010年12月1日至2011年12月9日之间在英国注册的电子零售公司(无实体店)的所有网络交易订单信息。该公司主要销售礼品为主，并且多数客户为批发商。数据集一共包含541909 条数据，8个字段。

### 2.3 字段含义

| Columns     | 含义                                                         | 数据类型 |
| ----------- | ------------------------------------------------------------ | -------- |
| InvoiceNo   | 订单编号，由六位数字组成，对于每一笔交易唯一性，退货订单编号开头有字母’C | string   |
| StockCode   | 产品编号，由五位数字组成，对于不同类别的产品是唯一的         | string   |
| Description | 产品描述                                                     | string   |
| Quantity    | 产品数量，负数表示退货                                       | integer  |
| InvoiceDate | 订单日期与时间                                               | datetime |
| UnitPrice   | 单价（英镑）                                                 | float    |
| CustomerID  | 客户编号，由5位数字组成，对于每一个客户是唯一的              | string   |
| Country     | 国家，每个客户居住的国家/地区的名称                          | string   |



## 三.数据清洗

### 3.1数据加载及预览

```
import pandas as pd
import numpy as np
import datetime as dt

import matplotlib.pyplot as plt
import seaborn as sns 
plt.rcParams['font.sans-serif'] = ['SimHei']

from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
```

```
# 读取数据
data = pd.read_excel('Online Retail.xlsx')
data.head()
```

![image-20211009044414420](https://i.loli.net/2021/10/14/OEz4ydcFRGWfAJB.png)



### 3.2 查看数据基本信息

```
data.info()
```

![image-20211009044438561](https://i.loli.net/2021/10/14/9A4hoC3OkVMG6FY.png)

```
data.describe()
```

![image-20211009044507390](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141338490.png)



### 3.3 缺失值处理

```
# 查看缺失值的数量与比例
(pd.DataFrame({
        "NaN_num": round(data.isnull().sum(),2),
        "NaN_percent":(data.isnull().sum()/data.shape[0]).apply(lambda 					             			x:str(round(x*100,2))+'%'),
            })
  .sort_values('NaN_num', ascending=False))
```

![image-20211009044908514](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141337306.png)

CustomerID和Description存在缺失值，分别占比为24.93%和0.27%。

这里要做的是用户价值分析，CustomerID的缺失会对分析结果产生影响，故而选择删除缺失值。

Description的缺失并不会有影响，所以也选择删除。

```
# 将Description和CustomerID存在缺失值，做删除处理
data = data.dropna()
data.info()
```

![image-20211009044926193](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141337136.png)



### 3.4 重复值处理

```
dataUni = data.drop_duplicates()
data.shape[0]-dataUni.shape[0]
```

共删除5225条重复值

### 3.5 异常值处理

```
# 描述性统计
dataUni[['Quantity', 'UnitPrice']].describe()
```

![image-20211009044945492](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141338363.png)

Quantity是购买的产品数量，存在负数表示退货订单，这里分析不考虑退货订单信息，删除Quantity为负数的订单信息，UnitPrice是单价，不可能存在负值，直接删除异常值。

```
sale = dataUni.loc[(dataUni['Quantity']>0) & (dataUni['UnitPrice']>0)]
```

### 3.6 辅助列

```
# 辅助列
sale['CustomerID'] = sale['CustomerID'].astype(int)
# 添加总价列,表示购买某一种商品的总额
sale['TotalSum'] = sale['UnitPrice']*sale['Quantity']   
# 对时间属性做转换，保留年月日
sale['InvoiceDate'] = pd.to_datetime(sale.InvoiceDate)
sale['Date'] = sale['InvoiceDate'].dt.date
# 添加年,月,日,日期列
sale['Year'] = sale['InvoiceDate'].dt.year
sale['Month'] = sale['InvoiceDate'].dt.month
sale['Day'] = sale['InvoiceDate'].dt.day
sale.head()
```

![image-20211009045019370](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141338119.png)



## 四.RFM模型

使用RFM模型对用户进行分类，根据用户分类，识别出有价值的用户，对不同价值的用户使用不同的运营策略，把公司有限的资源发挥到最大的效果。

这3个指标针对的业务不同，定义也不同，要根据业务来灵活定义，各指标特征如下：
对于最近1次消费时间间隔R，上一次消费离的越近，也就是R值越小，用户价值越高。
对于消费频率F，购买的频率越高，也就是F的值越大，用户价值越高。
对于消费金额M，消费金额越高，也就是M的值越大，用户价值越高。

### 4.1  指标计算

#### R值

```
# 建立用户数据表，每一行代表一个用户的信息
# 取最大日期加1天为分析时间，以分析时间减去客户最后一次消费时间，时间差算出R频率
Nowdate = sale.Date.max()+dt.timedelta(days=1)   # 分析时间
CusDate = sale.groupby(['CustomerID']).agg({'Date':lambda x:(Nowdate-x.max()).days,
											'TotalSum':'sum'}).reset_index() 
CusDate.rename(columns={'Date':'Recency',
						'TotalSum':'MonetaryValue'
						},inplace=True)   # 重命名
CusDate.head()
```

![image-20211009045043853](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141338356.png)

R分布

```
# 查看R分布
CusDate['Recency'].describe()
```

![image-20211009045218869](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141338015.png)

```
# 分箱并评分,每层数量接近
Rquartiles = Rquartiles = pd.qcut(CusDate['Recency'], q=5, duplicates='drop',labels=[5,4,3,2,1]) 
CusDate = CusDate.assign(Recency_Q = Rquartiles.values )
CusDate.head()
```

![image-20211009045352164](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141340861.png)

```
# 定义一个分箱后的统计函数
def rfm_bins_statistics(feature, scores, name):
    feature_statistic= pd.concat([feature,CusDate['MonetaryValue'],scores],axis=1)
    feature_statistic.columns = [name, 'Monetary', 'label']
    feature_bins = feature_statistic.groupby('label')[name].max().tolist()
    feature_bins_min = [-1]+feature_bins # 辅助列
    feature_label_statistic = feature_statistic.groupby('label').agg({
            '{}'.format(name):['count',('per1', lambda x: "%.1f"%((x.count() / 										  feature_statistic[name].count()*100)) + '%')],
            'Monetary':['sum',('per2', lambda x: "%.1f"%((x.sum() / 										   feature_statistic.Monetary.sum()*100)) + '%')],
        }).assign(range_ = [str(i+1) + '-' + str(j) for i,j in zip(feature_bins_min, 							   feature_bins )] )
    return feature_statistic , feature_label_statistic, feature_bins
```

```
Recency_statistic,Recency_label_statistic,Recency_bins=rfm_bins_statistics(CusDate['Recency'], CusDate['Recency_Q'], 'Rec')
Recency_label_statistic
```

![image-20211009045416387](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141339908.png)



```
# 各天数消费金额之和
Monetary_sum=pd.concat([CusDate['Recency'].value_counts().sort_index(),
						CusDate.groupby('Recency').MonetaryValue.sum()], axis=1)
# 累计消费金额计算
Monetary_range = Recency_label_statistic['Monetary', 'sum'].cumsum().tolist()
```

绘制频数分布图

```
# 频数分布图
fig,ax = plt.subplots(figsize=(18, 10),facecolor='#f4f4f4')
ax.hist(CusDate['Recency'],bins = 50,alpha=0.5)
ax1 = ax.twinx()
ax1.plot(Monetary_sum.MonetaryValue.cumsum(),color='r')
# 文字注释
for i in range(5):
    ax1.text(
         Recency_bins[i]/2,
         Monetary_range[i],
        '天数范围:' + str(Recency_label_statistic['range_'].tolist()[i])+ '\n' 
        + '消费金额占比:' 
        + str(Recency_label_statistic['Monetary','per2'].tolist()[i]),
        bbox={'boxstyle': 'round',
              'edgecolor':'grey',
              'facecolor':'#d1e3ef',
              'alpha':0.5}
    )
    
ax.set_xlabel('距离最近一次的购买天数')
ax.set_ylabel('频数')
ax1.set_ylabel('消费累计金额')
ax.set_facecolor('#f4f4f4')
plt.show()
```

![image-20211009045438593](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141338188.png)

结合图表可得，距离最近一次购买天数为0-15天的客户群，其客户数量占全部客户的20%，消费金额占比53.2%。距离最近一次购买天数越大，创造的消费金额越低。

#### F值

```
# 计算每个客户购买的频次---一天内多次消费算一次，按照天数计次
# 去重，算的是客户消费次数，订单号相同在同一天，但同一天有很多订单
sale_F = sale.drop_duplicates(subset=['InvoiceNo']) 
CusDate_F = sale_F.groupby(['CustomerID'])
					.agg({'InvoiceNo':'count'}).reset_index()   # 重设索引
CusDate_F.rename(columns={'InvoiceNo':'Frequency'},inplace=True)   # 重命名
CusDate_F.head()
```

![image-20211009045510951](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341483.png)

```
# 查看消费次数占比
pd.DataFrame({'count':CusDate_F['Frequency'].value_counts(),						      	  'percent':CusDate_F['Frequency'].value_counts()
			  /CusDate_F['Frequency'].value_counts().sum()}).head(10)
```

![image-20211009045547511](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341536.png)

可以看出，消费次数为1的占比仅35%，消费次数为10的仅占比约1%。因此，为F值分箱时进行自定义分箱。

```
# 自定义边界分箱
bin_F = [1, 2, 3, 5, 8, CusDate_F['Frequency'].max()+1]
Fquartiles = pd.cut(CusDate_F['Frequency'],bin_F,labels=[1,2,3,4,5],right=False)
CusDate_F = CusDate_F.assign(Frequency_Q = Fquartiles.values)
CusDate_F.head()
```

![image-20211009045609622](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341298.png)

```
# 合并R,F值
CusDate = pd.merge(CusDate,CusDate_F,on='CustomerID')
# 重新排序列
col_name=['CustomerID','Recency','Frequency','MonetaryValue','Recency_Q','Frequency_Q']  
CusDate=CusDate.reindex(columns=col_name)
CusDate.head()
```

![image-20211009045634432](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341052.png)

```
Frequency_statistic,Frequency_label_statistic,Frequency_bins=rfm_bins_statistics(
CusDate['Frequency'], CusDate['Frequency_Q'], 'Freq')
Frequency_label_statistic
```

![image-20211009045652950](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341330.png)

```
# 消费次数的消费金额之和
Monetary_sum=pd.concat([CusDate['Frequency'].value_counts().sort_index(),
						CusDate.groupby('Frequency').MonetaryValue.sum()], axis=1)
# 层级消费金额累计之和
Monetary_range = Frequency_label_statistic['Monetary', 'sum'].cumsum().tolist()
```

```
#频数分布图
fig,ax = plt.subplots(figsize=(18, 10),facecolor='#f4f4f4')
ax.hist(CusDate['Frequency'], bins=50, alpha=0.5)  
ax1 = ax.twinx()
ax1.plot(Monetary_sum.MonetaryValue.cumsum(), color='#cc0033')
# 文字标注
for i in range(5):
    ax1.text(
        Frequency_bins[i]/2,
        Monetary_range[i],
        '购买次数范围:' + str(Frequency_label_statistic['range_'].tolist()[i])+ '\n' 
        + '消费金额占比:' + str(Frequency_label_statistic['Monetary','per2'].tolist()[i]),
        bbox={'boxstyle': 'round',
              'edgecolor':'grey',
              'facecolor':'#d1e3ef',
              'alpha':0.5})
ax.set_xlabel('购买次数')
ax.set_ylabel('频数')
ax1.set_ylabel('消费累计金额')
ax.set_facecolor('#f4f4f4')
plt.show()
```

![image-20211009045714560](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341240.png)

结合图表可知，购买次数范围在8-209天的消费频率最高，消费金额占比57%。

购买频率越高，用户价值越高。

#### M值

```
# M分布
CusDate['MonetaryValue'].describe()
```

![image-20211009045736274](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141341913.png)

```
# 分箱并依次评分
# 消费金额越大越好，所以labels为顺序
Mquartiles = pd.qcut(CusDate['MonetaryValue'], q=5,duplicates='drop',labels=[1,2,3,4,5]) 
CusDate = CusDate.assign(Moneytary_Q = Mquartiles.values)
CusDate.head()
```

![image-20211009045751776](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342844.png)

```
# 查看相关统计
Monetary_statistic = pd.concat([CusDate['MonetaryValue'], 
								CusDate['Moneytary_Q']], axis=1)
Monetary_statistic.columns = ['Monetary', 'label']
Monetary_label_statistic = Monetary_statistic.groupby('label').agg({
             'label':['count',('per1', lambda x: x.count() / 															Monetary_statistic.label.count())],
             'Monetary':['sum',('per2', lambda x: x.sum() / 															Monetary_statistic.Monetary.sum())],
         }).sort_values(('Monetary','sum'),ascending = False).round(2)

Monetary_label_statistic.head()
```

![image-20211009045808603](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342405.png)

```
# 绘图
fig,ax = plt.subplots(figsize=(18, 10),facecolor='#f4f4f4')
label_count_cumsum = Monetary_label_statistic.cumsum()['label', 'count'].values
label_percent_cumsum = Monetary_label_statistic.cumsum()['label', 'per1'].values
Monetary_sum_cumsum = Monetary_label_statistic.cumsum()['Monetary', 'sum'].values
Monetary_percent_cumsum = Monetary_label_statistic.cumsum()['Monetary', 'per2'].values
ax.plot(Monetary_statistic.Monetary.sort_values(ascending=False).cumsum().values)
for i in range(5):
    ax.text(label_count_cumsum[i],
            Monetary_sum_cumsum[i],
            '数量占比：%.1f%%'%(label_percent_cumsum[i]*100)+'\n'
            +'金额占比：%.1f%%'%(Monetary_percent_cumsum[i]*100), 
            va='center', # 垂直对齐方式
            ha='right',  # 水平对齐方式
            bbox={
                'boxstyle': 'round',
                'edgecolor':'grey',
                'facecolor':'#d1e3ef',
                'alpha':0.5 })
ax.set_xlabel('顾客数量')
ax.set_ylabel('消费累计金额')
ax.set_facecolor('#f4f4f4')
plt.show()
```

![image-20211009045828837](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342351.png)

由图表可知，20%的顾客数量，消费金额占比已达75%。40%的顾客数量，消费金额占比已达89%。

R,F,M分箱完毕，各分5层，各特征的头部客户均贡献了超过50%的消费。

### 4.2 RFM模型搭建（方法一）

分别计算R值,F值,M值的中位数，每个指标与中位数进行比较，为每一个用户的R，F, M值进行高低维度的划分。高用'H'表示，低用‘L’表示，高与低值针对用户的价值而言的。
R值若小于中位数，则为高，否则为低。
F值若大于中位数，则为高，否则为低。
M值若大于中位数，则为高，否则为低。

一共会得到8组分类

```
RFM_1 = CusDate.copy()
# 获取总分
RFM_1['RFM_Score'] = RFM_1[['Recency_Q','Frequency_Q','Moneytary_Q']].sum(axis=1)
RFM_1.head()
```

![image-20211009045856856](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342831.png)

```
# 为R值打分划分高低
R_median = RFM_1['Recency'].median()
RFM_1['R_label'] = pd.cut(RFM_1['Recency'],bins=[0,R_median,RFM_1['Recency'].max()+1],
                          right=False,labels=['H','L'])
RFM_1.groupby(['R_label'])['CustomerID'].count()
```

![image-20211009191922100](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342685.png)

```
# 为F值打分划分高低
F_median = RFM_1['Frequency'].median()
RFM_1['F_label'] = pd.cut(RFM_1['Frequency'],bins[0,F_median,RFM_1['Frequency'].max()+1],
                           right=False,labels=['L','H'])
RFM_1.groupby(['F_label'])['CustomerID'].count()
```

![image-20211009192055726](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342134.png)

```
# 为M值打分划分高低
M_median = RFM_1['MonetaryValue'].median()
RFM_1['M_label'] = pd.cut(RFM_1['MonetaryValue'],
						  bins=[0,M_median,RFM_1['MonetaryValue'].max()+1],
                          right=False,labels=['L','H'])
RFM_1.groupby(['M_label'])['CustomerID'].count()
```

![image-20211009192212026](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342888.png)

```
# 合并R,F,M
def add_rfm(x):
    return str(x['R_label'])+str(x['F_label'])+str(x['M_label'])

RFM_1['RFM_label']=RFM_1.apply(add_rfm,axis=1)
RFM_1.head()
```

![image-20211009192258222](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342599.png)

```
# 创造综合价值变量
map_dict = {'HHH':'重要价值客户', 'HLH':'重要发展客户', 'LHH':'重要保持客户', 
			'LLH':'重要挽留客户','HHL':'一般价值客户', 'HLL':'一般发展客户', 
			'LHL':'一般保持客户', 'LLL':'一般挽留客户'}
RFM_1['CustmerLevel'] = RFM_1['RFM_label'].map(map_dict)
RFM_1.head()
```

![image-20211009192318200](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141349023.png)

```
# 用户分类结果
RFM_1.groupby(['CustmerLevel'])['CustomerID'].count()
```

![image-20211009192335377](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342671.png)

### 4.3 RFM模型搭建（方法二）

分别计算出R值打分，F值打分，M值打分的平均值，将每个指标与平均值进行比较，为每一个用户的R,F,M值进行高低维度的打分，高用'H'表示，低用‘L’表示。一共会得到8组分类。

```
# 建立模型前的准备工作
RFM_2 = CusDate.copy()
RFM_2['RFM_Score'] = RFM_2[['Recency_Q','Frequency_Q','Moneytary_Q']].sum(axis=1)
for i in RFM_2[['Recency_Q','Frequency_Q','Moneytary_Q']]:
    RFM_2[i] = RFM_2[i].astype(float)
RFM_2.head()
```

![image-20211009050121301](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141342587.png)

```
# 分别求R,F,M的平均值
mean_R_score = RFM_2['Recency_Q'].mean()
mean_F_score = RFM_2['Frequency_Q'].mean()
mean_M_score = RFM_2['Moneytary_Q'].mean()
print(mean_R_score,mean_F_score,mean_M_score)
```

![image-20211009050135988](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343890.png)

```
# R，F，M高低划分
RFM_2['R_label'] = pd.cut(RFM_2['Recency_Q'],bins=[0,mean_R_score,6],
                            right=True,labels=['L','H'])  
RFM_2['F_label'] = pd.cut(RFM_2['Frequency_Q'],bins=[0,mean_R_score,6],
                            right=True,labels=['L','H'])  
RFM_2['M_label'] = pd.cut(RFM_2['Moneytary_Q'],bins=[0,mean_M_score,6],
                            right=True,labels=['L','H'])  
RFM_2.head()
```

![image-20211009050153143](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343120.png)

```
# 将高低划分后的R,F,M合并
def score_label_segment(x):
    return str(x['R_label'])+str(x['F_label'])+str(x['M_label'])

RFM_2['RFM_label']=RFM_2.apply(score_label_segment,axis=1)

# 创造综合价值变量
map_dict = {'HHH':'重要价值客户', 'HLH':'重要发展客户', 'LHH':'重要保持客户', 
			'LLH':'重要挽留客户','HHL':'一般价值客户', 'HLL':'一般发展客户', 
			'LHL':'一般保持客户', 'LLL':'一般挽留客户'}
RFM_2['CustmerLevel'] = RFM_2['RFM_label'].map(map_dict)
RFM_2.head()
```

![image-20211009050212406](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343320.png)

```
# 用户分类结果
RFM_2.groupby(['CustmerLevel'])['CustomerID'].count()
```

![image-20211009050227011](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343370.png)

### 4.4 两种求解RFM模型的方法比较

```
# 方法一：
rfm1=RFM_1.groupby(['CustmerLevel']).agg({'CustomerID':[('总数','count'),('占比',lambda x: "%.1f"%((x.sum()/ RFM_1['CustomerID'].sum()*100))+'%')]
                                  	}).sort_values(('CustomerID','数'),ascending=False)
                                
rfm1
```

![image-20211009192622088](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343246.png)



```
# 方法二
# 各分类用户人数
rfm2=RFM_2.groupby(['CustmerLevel']).agg({'CustomerID':[('总数','count'),('占比',lambda x: "%.1f"%((x.sum()/ RFM_2['CustomerID'].sum()*100))+'%')],
                                          'RFM_Score':'mean'
                                    }).sort_values(('CustomerID','总数'),ascending=False)
rfm2
```

![image-20211009171550749](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141348689.png)



```
# 可视化 
fig = plt.figure(figsize=(20,10),facecolor='#f4f4f4')
plt.rcParams['font.sans-serif'] = ['SimHei']  # 用来正常显示中文标签
plt.rcParams['axes.unicode_minus'] = False  # 用来正常显示负号
ax1 = fig.add_subplot(121)
ax1.bar(rfm1.index,rfm1['CustomerID','总数'].values,label="count")
ax1.set_title("RFM_1",fontsize=20)
ax3 = fig.add_subplot(122)
ax3.bar(rfm2.index,rfm2['CustomerID','总数'].values,label="count")
ax3.set_title("RFM_2",fontsize=20)
```

![image-20211009192841545](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343201.png)



方法一采用中位数来搭建RFM模型，重要价值客户数量最多，其次是一般挽留客户，一般保持用户最少，仅有30人，方法二采用平均值来搭建RFM模型。一般挽留客户数量最多，其次是重要价值用户，一般价值客户仅有42人，一般保持客户仅有30人，类别间用户数量差异相对明显。方法一得到的用户分类相对合理些。在现实中，应结合业务对模型的好坏进行评价。

### 4.5 分析

这里以RFM模型搭建（方法一）来进行以下分析

```
# 计算每类客户的消费总金额，订单数量，购买的商品总量等
data_temp1 = sale_F.groupby(['CustomerID']).agg({'InvoiceNo':'count'}).reset_index()   
data_temp2=sale.groupby(['CustomerID']).agg({'TotalSum':'sum',
											'Quantity':'sum'}).reset_index() 
RFM_data=pd.concat([RFM_1['CustmerLevel'],
					data_temp2,data_temp1['InvoiceNo'],
					RFM_1['Recency'],RFM_1['Frequency']],axis=1)
RFM_data.columns = ['客户等级','客户编号','消费金额', '购买商品总量', 
					'订单总量', '最近消费天数','消费次数']
RFM_data.head()
```

![image-20211009192943370](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343960.png)

```
# 定义一个统计函数
def customer_level_statistic(customer_data):
    customer_level = (customer_data
                 .groupby('客户等级')
                 .agg({
                        '消费金额':[('均值', 'mean'),
                                    ('总量', 'sum'),
                                    ('占比', lambda x: "%.1f"%((x.sum()/ customer_data['消										费金额'].sum()*100))+'%')], 
                        '购买商品总量':[('均值', 'mean'),
                                        ('总量', 'sum'),
                                       ('占比', lambda x:"%.1f"((x.sum()/customer_data['购											买商品总量'].sum()*100))+'%')],
                        '订单总量':[('均值', 'mean'),
                                    ('总量', 'sum'),
                                    ('占比', lambda x:"%.1f"%((x.sum()/ customer_data['订单										总量'].sum()*100))+'%')],
                        '客户等级':[('总量', 'count'),
                                    ('占比', lambda x:"%.1f"%((x.count()/customer_data['客										户等级'].count()*100))+'%')],
                        '最近消费天数':[('均值','mean')],
                        '消费次数':[('均值','mean')],
                    })
                 .sort_values(('消费金额','总量'),ascending=False)
                 .assign(客单价 = lambda x : x['消费金额','总量'] / x['订单总量','总量'])
                 .round(1)
                 )
    customer_level.columns = pd.Index(customer_level.columns[:-1].tolist() + [('客单价','均值')])
    return customer_level
```

```
RFM_level_statistic = customer_level_statistic(RFM_data)
RFM_level_statistic
```

![image-20211009193008009](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343785.png)



可视化

```
# 饼图
plt.rcParams['font.sans-serif'] = ['SimHei']  # 用来正常显示中文标签
plt.rcParams['axes.unicode_minus'] = False  # 用来正常显示负号
from matplotlib import cm 

def customer_level_pie(data_level):
    fig,axes = plt.subplots(nrows=2, ncols=2, figsize=(10,8),dpi=300,facecolor='#f4f4f4')
    cs=cm.Set1(np.arange(40)) 
    columns_list = [['消费金额', '购买商品总量'], ['订单总量', '客户等级']]
    
    for i in [0,1]:
        for j in [0,1]:
            values_p = data_level[columns_list[i][j],'总量'].sort_values().values			
            patches,texts,autotexts=axes[i[j].pie(values_p,autopct="%.2f%%",
    											  labels=data_level.index.tolist(),
    											  colors=cs,radius=1.1,pctdistance=0.9)
            for autotext,text in zip(autotexts,texts):
                autotext.set_color("w")
                autotext.set_size(6)
                text.set_size(5)
            axes[i][j].set_title(columns_list[i][j]+"对比",fontsize=10)
            plt.axis('equal')
            axes[i][j].set_facecolor('#f4f4f4')
    plt.show()
```

```
customer_level_pie(RFM_level_statistic)
```

![image-20211009193100234](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343329.png)

```
# 绘制各指标均值对比图
# 条形图
def customer_level_barh(data_level):
    fig, ax = plt.subplots(nrows=2, ncols=2, figsize=(20,12),
    					   dpi=300,facecolor='#f4f4f4')
    plt.rcParams['font.sans-serif'] = ['SimHei']  # 用来正常显示中文标签
    plt.rcParams['axes.unicode_minus'] = False  # 用来正常显示负号

    columns_list = [['消费金额', '客单价'], ['最近消费天数', '消费次数']]
    for i in [0,1]:
        for j in [0,1]:
            index = data_level[columns_list[i][j], '均值'].sort_values().index
            values = data_level[columns_list[i][j], '均值'].sort_values().values
            ax[i][j].barh(index, values)
            # 通过text可以在Axes对象上添加文本。只需要指定x和y的坐标以及文字内容就可以了。
            for k in range(len(data_level)):
                ax[i][j].text(values[k],k,values[k],size=10 )  

            ax[i][j].set_title(columns_list[i][j]+'均值对比')
            ax[i][j].set_facecolor('#f4f4f4')
```

```
customer_level_barh(RFM_level_statistic)
```

![image-20211009193239796](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343860.png)

根据R,F,M高低区分的8类客户，可以根据其特点，给出针对性的营销策略

结合图表，总结如下：

| 用户分类     | 行为特征                                                     | 精细化运营                                                   |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 重要价值客户 | 近期购买过，购买频率高，客单价较高，消费金额高，为主要消费客户 | 升级为VIP客户，提供个性化服务，倾斜较多的资源                |
| 重要发展客户 | 近期购买过，购买频率低，客单价高，消费金额较高，可能是新的批发商或企业采购者，想办法提高消费频率。 | 提供会员积分服务，给与一定程度的优惠来提高留存率             |
| 重要保持客户 | 近期没有购买过，购买频率较高，客单价较高，消费金额较高，可能是一段时间没来的忠实客户。 | 通过短信邮件等方式主动和客户保持联系，介绍最新产品/功能，提高复购率 |
| 重要挽留客户 | 近期没有购买，购买频率低，客单价高，消费金额较高，这种用户即将流失 | 通过电话短信等方式主动联系用户，调查清楚哪里出现问题，避免流失 |
| 一般价值客户 | 近期购买过，购买频率较高，客单价低，消费较低                 | 潜力股， 提供社群服务，介绍新产品/功能促进消费               |
| 一般发展客户 | 近期购买过，购买频率低，客单价较低，消费较低，可能是新用户   | 提供社群服务，介绍新产品/功能，提供折扣等提高留存率          |
| 一般保持客户 | 近期没有购买过，购买频率较高，，客单价低，消费低             | 介绍新产品/功能等方式唤起此部分用户                          |
| 一般挽留客户 | 近期没有购买过，购买频率低，客单价较低，消费低，已流失       | 通过促销折扣等方式唤起此部分用户，当资源分配不足时可以暂时放弃此部分用户 |

这样通过RFM分析方法来分析用户，可以对用户进行精细化运营，不断将用户转化为重要价值用户。



## 五.K-Means聚类

### 5.1 选择特征值和样本数据

选择RFM表中Recency，Frequency，MonetaryValue作为特征值

```
# 合并数据
RFM = CusDate[['CustomerID','Recency','Frequency','MonetaryValue']]
RFM.head()
```

![image-20211009050624256](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141343367.png)



对于R,F,M值分别绘制频数图，来查看数据的正态性

```
import matplotlib.pyplot as plt
import seaborn as sns
plt.rcParams['axes.unicode_minus'] = False  
#绘制频数图
f,ax = plt.subplots(3,1,figsize=(10, 12),facecolor='#f4f4f4')
plt.subplot(3,1,1); sns.distplot(RFM['Recency'],label='Recency')
plt.subplot(3,1,2); sns.distplot(RFM['Frequency'],label='Frequency')
plt.subplot(3,1,3); sns.distplot(RFM['MonetaryValue'],label='MonetaryValue')
```

![image-20211009050711913](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141344416.png)

可以看出，数据均呈长尾分布。

K-means算法对数据的要求：
（1）变量值是对称分布的
（2）变量进行归一化处理，平均值和方差均相同
由R,F,M三个变量的频数分布图可知，变量值分布不满足对称性，可以使用对数变换解决

### 5.2 数据预处理

#### (1)对数变换

```
# 将等于0的值替换成1，
RFM.Recency[RFM['Recency']==0]=0.01
RFM.Frequency[RFM['Frequency']==0]=0.01
RFM.MonetaryValue[RFM['MonetaryValue']==0]=0.01
RFM_log = RFM[['Recency','Frequency','MonetaryValue']].apply(np.log,axis=1).round(3)
```

```
# 绘制频数分布图
f,ax = plt.subplots(3,1,figsize=(10,12),facecolor='#f4f4f4')
plt.subplot(3,1,1); sns.distplot(RFM_log['Recency'],label='Recency')
plt.subplot(3,1,2); sns.distplot(RFM_log['Frequency'],label='Frequency')
plt.subplot(3,1,3); sns.distplot(RFM_log['MonetaryValue'],label='MonetaryValue')
```

![image-20211009050758442](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141344069.png)

由图上可以看出相较于之前更符合正态分布

#### (2)标准化处理

K-Means算法的本质是基于欧式距离的数据划分算法，均值和方差大的维度将对数据的聚类产生决定性影响。另外使用标准化对数据进行预处理可以减小不同量纲的影响。

```
from sklearn.preprocessing import StandardScaler   # 标准化
scaler = StandardScaler()
scaler.fit(RFM_log)
RFM_normalization = scaler.transform(RFM_log)
```

```
rfm_data = pd.DataFrame(RFM_normalization,columns = ['R', 'F', 'M'])
rfm_data.head()
```

![image-20211009050821254](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141344648.png)

### 5.3 K-Means建模

#### (1)k值的选取

肘部法则选择k值

```
from sklearn.cluster import KMeans
# 选取K的范围，遍历每个值进行评估
ks = range(1,9)
inertias=[]
for k in  ks:
    kc = KMeans(n_clusters=k, init='k-means++', random_state = 1)  # 设置模型参数
    kc.fit(rfm_data)
    inertias.append(kc.inertia_) 
    print('k=',k,' 迭代次数',kc.n_iter_)  # n_iter_实际的迭代次数
```

![image-20211009050843138](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141344368.png)

```
# 绘制每个k值对应的inertia_
fig,ax = plt.subplots(figsize=(10,6))
ax.plot(ks,inertias,'-o',linewidth=1)
plt.xlabel('k')
plt.ylabel('inertia_score')
plt.title('inertia变化图')
plt.grid()
plt.show()
```

![image-20211009050859098](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141344751.png)

当k=2时出现了明显的拐点，但实际业务将用户分成两类可能精确度不够高，所以继续使用轮廓系数来评估



轮廓系数

```
# 使用轮廓系数评估聚类效果—轮廓系数的区间为：[-1, 1]。
# -1代表分类效果差，1代表分类效果好。0代表聚类重叠，没有很好的划分聚类。
from sklearn import metrics

label_list = []
silhouette_score_list = []
kw = range(2,9)
for k in kw:
    model = KMeans(n_clusters = k,random_state=1 )
    kmeans = model.fit(RFM_normalization)
    silhouette_score = metrics.silhouette_score(RFM_normalization, kmeans.labels_)  
    silhouette_score_list.append(silhouette_score)
    label_list.append({k: kmeans.labels_})
    print('k:',k,'   silhouette_score=',silhouette_score)
```

![image-20211009050917236](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141344921.png)

```
# 绘图   
fig,ax = plt.subplots(figsize=(10,6))
#ax,plot(kw,silhouette_score_list,'-o',linewidth=1)
plt.plot(kw,silhouette_score_list,'-o',linewidth=1)
plt.xlabel('k')
plt.ylabel("silhouette_score") 
plt.title('轮廓系数变化图')
plt.grid()
plt.show()
```

![image-20211009050932223](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347134.png)

观察轮廓系数可得，分为2类效果最好，3-4类效果次之



calinski-harabaz Index：适用于实际类别信息未知的情况，为群内离散与簇间离散的比值，值越大聚类效果越好。

```
from sklearn import metrics
calinski_list = []
kk = range(2,9)
for k in kk:
    y_pred = KMeans(n_clusters=k, random_state=1).fit_predict(RFM_normalization) #k必须大于1
    calinski = metrics.calinski_harabasz_score(RFM_normalization, y_pred)
    calinski_list.append(calinski)
    print('k:',k,'   calinski=',calinski)
```

![image-20211009051001350](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347003.png)

```
# 绘图   
fig,ax = plt.subplots(figsize=(10,6))
plt.plot(kk,calinski_list,'-o')
plt.xlabel('k')
plt.ylabel("calinski_harabaz_score") 
plt.title('calinski_harabaz_score变化图')
plt.grid()
plt.show()
```

![image-20211009051043292](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347025.png)



分为2类效果最好，其次是3类，效果随k增大而变差
综上，分为2类的效果最好，但是不符合业务诉求，分3类效果次之，接下来选择k=3进行验证

#### (2)效果可视化

```
# 模型计算--分为3类
kc = KMeans(n_clusters=3, random_state=1)
kc.fit(rfm_data)
cluster_label = kc.labels_
RFM['K-means_label'] = cluster_label
RFM.head()
```

![image-20211009051110239](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347708.png)



```
from mpl_toolkits.mplot3d import Axes3D

fig1 = plt.figure(1, figsize=(12, 8))
ax1 = Axes3D(fig1, rect = [0,0,.95, 1], elev = 45, azim = -45)
c1_ax1 = ax1.scatter(rfm_data['R'][cluster_label == 0], rfm_data['F'][cluster_label == 0], 
                     rfm_data['M'][cluster_label == 0], edgecolor = 'k', color = 'r')
c2_ax1 = ax1.scatter(rfm_data['R'][cluster_label == 1], rfm_data['F'][cluster_label == 1], 
                     rfm_data['M'][cluster_label == 1], edgecolor = 'k', color = 'b')
c3_ax1 = ax1.scatter(rfm_data['R'][cluster_label == 2], rfm_data['F'][cluster_label == 2], 
                     rfm_data['M'][cluster_label == 2], edgecolor = 'k', color = 'c')
ax1.legend([c1_ax1,c2_ax1,c3_ax1], ['Cluster 1', 'Cluster 2', 'Cluster 3'])
ax1.invert_xaxis()
ax1.set_xlabel('R')
ax1.set_ylabel('F')
ax1.set_zlabel('M')
ax1.set_title('KMeans Clusters')
plt.show()
```

![image-20211009051128264](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347371.png)



#### (3)分析

```
# 选出每个客户的消费总金额，订单总量，购买的商品总数
data_temp3 = sale_F.groupby(['CustomerID']).agg({'InvoiceNo':'count'
												}).reset_index()   
data_temp4 = sale.groupby(['CustomerID']).agg({'TotalSum':'sum',
											   'Quantity':'sum'}).reset_index() 
kmeans_data = pd.concat([RFM['K-means_label'],data_temp4,data_temp3['InvoiceNo'],
RFM['Recency'],RFM['Frequency']],axis=1)
kmeans_data.columns = ['客户等级','客户编号','消费金额', '购买商品总量', '订单总量', '最近消费天数','消费次数']
rfm_level  = customer_level_statistic(kmeans_data)
rfm_level
```

![image-20211009051150557](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347861.png)

观察可知：
2类客户数量占比19.5%，是三类客户中人数占比最少，但是创造了近70%的消费金额，57.1%的订单总量，最近消费天数平均为半个月，消费次数平均在13次左右，客单价也是3类客户中最高的，是主要的消费客户。
1类客户数量占比38.5%，消费金额占比23.3%，订单总量占比30.5%，对平台具有一定的价值，其最近的消费天数平均在3个月内，客单价较高，消费次数较低，可以采取一定的措施提高消费频率来挽回此类客户。
0类客户数量占比41.9%，总人数最多，仅创造6.9%的消费金额，12.4% 的订单总量，最近消费天数均值已经超过5个月了，消费频率低，已基本流失。

```
rfm_level.index = ['重要价值客户', '中等价值客户', '低价值客户']
customer_level_pie(rfm_level)
customer_level_barh(rfm_level)
```

![image-20211009051207505](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347596.png)

![image-20211009051227288](https://gitee.com/chenyijun0510/pic_-store/raw/master/imgs/202110141347499.png)



## 六. 总结

本次分析主要使用Python语言对某份英国电子零售企业的交易数据进行数据挖掘，使用RFM模型和K-Means聚类算法对用户进行分层，寻找有价值的用户。

无论是进行传统的RFM模型搭建还是使用聚类算法，都能将用户进行分层，在进行传统的RFM模型搭建的时候，使用两种方法来对用户进行分层，两个方法得出的结果有所差距，需要结合具体的业务来衡量所搭建模型的好坏。使用K-Means聚类算法也能在一定程度上将用户分层。但这两大类方法都有使用场景，也都有局限性。

- RFM模型得到的不同层级的客户，可以采取针对性措施进行营销，但销售场景受限
- 聚类算法可以较好的区分出各层用户，对于业务来说解释性还不够，数据更新前后的两次聚类结果会不同。

