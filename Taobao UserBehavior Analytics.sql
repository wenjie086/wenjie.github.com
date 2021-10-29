### 项目背景与指标拆解：
### 目的：结合市场、渠道、用户行为等数据分析，对用户展开有针对性的运营活动，提供个性化、差异化的运营策略，以实现运营目的行为。
### 本项目利用SQL 对淘宝用户行为数据进行分析，通过用户行为分析业务问题，提供针对性的运营策略。
### 本项目中具体指标有：
    ### 流量指标：访问量pv，访客数uv，平均访问量，跳失率
    ### 用户行为转化指标：点击，收藏，加购物车，购买，成交转化率
    ### 用户行为时间指标：每日活跃点击量，每时段活跃点击量
    ### 商品销售指标：商品销售排名，商品种类排名，价值用户的复购率及复购率最高用户购买商品种类分析


### 1 数据清洗 ###
#1.2 添加关于时间的3个新字段，把时间分别精确到datetime, date, hour:
ALTER TABLE userbehavior ADD COLUMN datetime TIMESTAMP(0) as null; 
UPDATE userbehavior SET datetime = FROM_UNIXTIME (timestamps);

ALTER TABLE userbehavior ADD COLUMN date CHAR(10) NULL;
UPDATE userbehavior SET date = SUBSTRING(datetime FROM 1 for 10);

ALTER TABLE userbehavior ADD COLUMN hour CHAR(2) NULL;
UPDATE userbehavior SET hour = substring(datetime FROM 12 FOR 2);

# 1.3 异常值处理: 删除关于不在范围内的时间。这里主要是看时间最大最小值是否有异常数据，则删除。
select max(timestamps), min(timestamps), max(datetime), min(datetime)
from userbehavior

DELETE FROM userbehavior 
WHERE datetime < '2017-11-25 00:00:00' or datetime >= '2017-12-04 00:00:00';

### 2 构建模型###
# 2.1 目标-构建流量与用户行为转化分析：用户从浏览到最终购买的整个过程的流失情况，确定夹点位置，提出改善转化率的意见。
# 2.2 获取访客数 UV，访问量PV，平均访问量PV/UV的数据：
select count(distinct user_id) as "UV",
	(select count(*) from userbehavior where behavior ='pv') as "PV",
	(select count(*) from userbehavior where behavior ='pv') / count(distinct user_id) as "PV/UV"
from userbehavior;

# 2.3获取跳失率（只有点击行为的用户/总用户数）的数据：
select count(distinct user_id) 
from userbehavior
where user_id not in (select distinct user_id from userbehavior where user_id = 'fav') 
	and(select distinct user_id from userbehavior where user_id = 'cart')
    and(select distinct user_id from userbehavior where user_id = 'buy');
    ### 结论：数据得到的只有点击行为却没有收藏、加入购物车以及购买行为的用户数是 1628，处以总用户数(UV)是29233，则跳失率为为 5.57%。

# 2.4 用户行为漏斗数据: 
select behavior, count(*) 
from userbehavior 
group by behavior;
	###结论：当我们用excel绘制出用户总行为漏斗柱状图时，可以发现的是：从浏览到有购买意向只有9.50%的转化率。
    # 同时，仍有部分用户行为路径为：点击-直接购买。这也同样说明了，用户浏览页面次数较多而使用加入购物车和收藏功能较少。
    # 因此，我们可以得到的大概猜测是问题出现在了收藏和加入购物车的阶段环节，且该环节也是我们需要重点提升的指标。

# 2.5 独立访客行为漏斗数据：
select behavior, count(distinct user_id) as DIS_user
from userbehavior 
group by behavior;
	###结论：当我们观察独立访客行为漏斗时，可以发现：使用app的用户成交率约为68.2% (19865/29116)，说明用户的购买欲望还是比较大的。


# 2.6 用户行为时间分析：
# 2.6.1:首先计算出"每日活跃点击量"为：
select date, count (*) as "pv"
from userbehavior 
where behavior = 'pv' 
group by date
order by date;
    ### 结论：从上图可以看出 11 月 25 日-12 月 1 日保持稳定的水平，12/2 开始出现较为明显的增长，点击量陡增，增长率约为 26.4%。
    ### 推测是上班族因工作逛淘宝的时间少，而周末(12 月 2 日-12 月 3 日)有充足的精力和有较多空闲时间访问淘宝。
    ### 可实行的运营动作：平日运营可以将活动集中在周末进行。

# 2.6.2:接着可以计算出"每时段活跃点击量"为：
select 'hour', count(*)/ 9 as "hour_pv"     
from userbehavior 
where behavior = 'pv'
group by 'hour'
order by 'hour';
	### 结论：在数据集观察的 9 天里，从 18 点开始点击量稳步上升，
    ### 到 21 点到达顶峰，22点稍有回落，到 23 点明显下降，说明大部分用户会在晚上 18 点到 22 点时段
    ### 频繁点击浏览网页，符合大部分人的作息时间。


### 3 商品销售分析 ###
# 3.1：目标-找出购买率最高的商品及商品类目。
# 3.1.1 浏览次数、收藏次数、加入购物车次数以及购买次数最多的商品：
select item_id, count(user_id) as times_pv
from userbehavior 
where behavior = 'pv'
group by item_id
order by times_pv desc;

select item_id, count(user_id) as times_fav
from userbehavior 
where behavior = 'fav'
group by item_id
order by times_fav desc;

select item_id, count(user_id) as times_cart
from userbehavior 
where behavior = 'cart'
group by item_id
order by times_cart desc;

select item_id, count(user_id) as times_buy
from userbehavior 
where behavior = 'buy'
group by item_id
order by times_buy desc;
	### 结论：在销量榜单中并没有看到浏览量第一第二的商品，说明这些吸引用户更多注意力的商品并没有很好的转化为实际销量.
    ### 但是，浏览量前排的商品均能在收藏量前列中，说明浏览量与收藏的关系更为直接。


# 3.2：目标-找出购买次数最多的用户以及最核心的付费用户群，统计出这些用户购买的产品以及类目，针对这些用户的购买偏好推送个性化的产品销售方案。
# 3.2.1 计算不同购买次数下的商品种类数：
select a.buy_num as buy_count, count(a.item_id) as item_num
from
(select item_id, count(user_id) as buy_num from userbehavior where behavior = 'buy' group by item_id) a 
group by a.buy_num
order by item_num desc;
	###结论：从上图可以看出只被购买一次的产品有 38248 种，而本次分析的商品（item_id）有 45931 种，
    ### 只被购买一次的产品占到 83.3%，意味着并没有销售非常集中的商品。

# 3.2.2 商品类目的累计销售情况：
select a.cat_buytimes,COUNT(category_id) as cat_type_count
from 
( select category_id,COUNT(user_id) as cat_buytimes from UserBehavior where behavior='buy' group by category_id ) as a
group by a.cat_buytimes
order by a.cat_buytimes;
	###结论：从上表可以更清楚的看出 27.7%的产品类目贡献了 1.6%的销售量，69.6%的产品类目贡献了 11.5%的销售量，
    ### 这个是不符合传统零售业的二八法则，可以说明其依靠长尾理论累计销售。

# 3.2.3 复购率：
# 3.2.3.1 不同购买次数下的用户数分布情况：
select a.buy_times, count(user_id) as "人数"
from (select user_id, count(behavior) as buy_times from userbehavior where behavior = 'buy' group by user_id) as a 
group by a.buy_times
order by a.buy_times;
	###结论：从上图可以得知整体复购率为(59329-6787)/59329=88.6%，
	###即有购买行为的用户中大概有 88.6%的用户会重复购买。上面是复购情况的可视图，可以看出大部分买家还是只购买一次。

# 3.2.3.2 复购率最高的用户以及他们购买的产品：
select user_id, count(behavior) as buy_times
from userbehavior 
where behavior = 'buy'
group by user_id
order by buy_times desc;
	###结论：从上面 SQL 语句的执行结果可以看到用户 user_id=337305 购买次数最多，高达 93 次。
    ### 下面以复购率最高的用户 user_id=337305 为例研究说明。

select category_id, count(*)
from userbehavior 
where behavior = 'buy' and user_id = 337305
group by category_id 
order by  count(*) desc;
	###结论：可以看出复购率最高用户 user_id=337305 购买的商品类目主要集中在上面表格中的前 3 大类.
    ### 如果数据集提供产品价格信息，我们就可以通过了解高价值用户的购买行为，比如购买时间、购买产品以及品类等等以推出有针对性的商品推荐，从而提高产品销售情况。


										### 总结与建议### 
### 获客Acquisition: 每天晚上 16 点到 22 点是用户频繁访问的时间,平台开展活动获取客户应首选这个时间段进行。
###					同时，基于平台用户基数大的特征可以利用用户在晚间时段做促销活动，邀请朋友拼团等运营手段来获取新客户。

### 用户激活Activation: 从用户从浏览到最终购买整个过程的流失情况中，我们可以发现点击量占总行为的 89.5%，而加入购物车和收藏只占 6%。
###	因此，重点优化环节可以放到【收藏和加入购物车环节上】。收藏和加入购物车较低的原因可能是由于“用户花了大量的时间寻找合适的产品”或者【用户没有找到他们想要的产品】
### 基于此原因，可以优化的建议是：优化电商平台的筛选功能，增加关键词的准确率，让用户可以更容易找到合适产品。

### 用户留存Retention：为了培养用户使用淘宝电商平台购物的消费习惯，可以做的是：
### 				按照使用频率和购买次数积攒积分，到月末换取购物礼券；
###					对于年购次数和金额达到一定额度的用户推出VIP服务，享受95折优惠；

### 增加收入Revenue：在独立用户中，我们可以发现最高复购次数高达93次。因此，我们可以通过复购率，购买金额等确定价值用户，通过分析找到目标用户的购买商品偏好，进一步做个性化推荐。
### 			 	同时，我们发现大部分用户购买商品的次数为1次。因此，可以通过利用淘宝平台商品种类多样的优势为客户提供多样的商品，吸引不同的购物人群。

### 推荐Referral：商品购买时可以提供拼团服务；让用户主动推荐给他人。同时也可以在用户购买完商品后在pyq打卡功能，实现传播功能。

